---
name: rails
description: Use when writing or reviewing Rails code.
version: 1.10.0
---

# commons:rails

> **TLDR**: Arrow Architecture in Rails — `core/ports/bridges/platform` folders, lucid-case cases (`app/core/cases`) named as the business speaks, explicit orchestration (no `flow`), async effects via the lucid-case transactional outbox (`emit`, `Subscriber`), Solid Cache and Cloud Tasks (or Solid Queue) on Postgres.

Principles and laws live in `br4zz4:architecture`. This skill is the Rails application of them.

## Setup

```ruby
# Gemfile
gem "lucid-case", github: "br4zz4/lucid-case", tag: "v0.2.0"
gem "lucid-tenancy", github: "br4zz4/lucid-tenancy", tag: "v0.2.0" # multi-tenant apps only
gem "solid_queue" # only when the project cannot take Cloud Tasks (see "Queue: Cloud Tasks by default")
gem "solid_cache"
# with RabbitMQ: gem "bunny" (publish) + gem "sneakers" (consume)
```

```ruby
# config/application.rb — every app/* subdir is already an autoload root;
# nested roots need registering so folder names never become namespaces:
# core/models/cart.rb → Cart (not Models::Cart)
# core/cases/cart/checkout.rb → Cart::Checkout (not Cases::Cart::Checkout)
# app/core and app/ports never become namespaces: they only hold autoload roots
%w[
  core/models core/models/concerns core/cases
  ports/controllers ports/controllers/concerns ports/reflexes ports/jobs ports/channels ports/serializers
].each do |dir|
  path = root.join("app/#{dir}")
  config.autoload_paths << path
  config.eager_load_paths << path
end

config.active_job.queue_adapter = ENV.fetch("ACTIVE_JOB_ADAPTER") { Rails.env.test? ? "test" : "async" }.to_sym # cloud_tasks in staging/production
config.cache_store = :solid_cache_store
```

Add `ports/consumers` to the list when the app consumes a broker. Keep `app/views`, `app/helpers`, `app/assets` and `app/javascript` where Rails expects them. `test/` mirrors `app/` (`test/core/cases/cart/checkout_test.rb`, `test/ports/controllers/...`).

Events: generate the outbox with `bin/rails g lucid:case:events` and keep subscribers in a directory listed in `config.events.load_paths` (the gem default is `app/models`; point it at `app/core/cases` when subscribers live there). Details in "Platform — events".

Cache (`solid_cache`) and ActionCable (`solid_cable`) live in Postgres (own databases), never Redis. The queue is **Cloud Tasks + Cloud Scheduler** by default (see "Queue: Cloud Tasks by default"); Solid Queue (`solid_queue`, own database) is the exception for a project that cannot take push delivery (a job longer than the 30 min dispatch deadline, or a runtime outside Cloud Run) and records it in an ADR.

Environment variables name what a thing is, never the implementation behind it: `DATABASE_URL`, `CACHE_URL`, `QUEUE_URL`, `CABLE_URL`, not `REDIS_URL`. Production and staging turn the cache on only when `CACHE_URL` is set (null store otherwise) and use Solid Cable only when `CABLE_URL` is set (`async` adapter otherwise), so a deploy never breaks for a missing database. Declare each Solid database in `database.yml` only when its URL is present, set `config.cache_store` in `config/environments/*.rb` (an initializer runs after `Rails.cache` is built), and keep the custom `db:migrate` creating each Solid table only when missing (`db:cache:prepare`, `db:cable:prepare`): a schema load on every deploy would wipe the cache and the sessions stored in it.

```ruby
# config/initializers/lucid_case.rb — Query cache uses Rails.cache (Solid Cache);
# multi-tenant apps must scope the cache key by tenant
Lucid::Case.configure do |config|
  config.cache_scope = -> { Current.organization&.id }
end
```

## Folder layout

```
app/
  core/                  # the business
    models/              # entities: state + invariants
      cart.rb            # Cart (ActiveRecord)
      order.rb
    cases/               # actions: entry points and steps, by noun
      cart/checkout.rb   # Cart::Checkout — case (entry point)
      cart/checkout/validate_stock.rb  # flow-private step
      payment/charge.rb  # reusable noun-level verb
      order/on_placed.rb # Lucid::Case::Subscriber — a reaction to a fact
  bridges/               # outside parties' knowledge (both directions)
    hotmart/payment_status.rb
    hotmart/verify_signature.rb
    hotmart/parse_webhook.rb
    mailers/order_confirmation.rb
    rabbit/publish.rb    # broker protocol (AMQP)
    webhooks/deliver.rb  # outbound webhook to partners
  platform/              # transport machinery the gem does not cover
    cloud_tasks/         # queue adapter and the worker endpoint's plumbing
    relay_pending_events_job.rb  # scheduled sweep: Lucid::Case::Events.relay_pending
  ports/                 # our surface
    controllers/checkouts_controller.rb
    controllers/webhooks/hotmart_controller.rb
    reflexes/
    jobs/
    channels/
    consumers/order_events_consumer.rb
    serializers/order_serializer.rb
```

`rails generate` still writes to the default folders — create files by hand in the right layer.

## Ports

A controller does exactly: authenticate, extract params, call **one** use case, render by result with the correct HTTP status. Zero business ifs, zero direct queries, zero calls to bridges.

```ruby
# BAD — business logic in the controller
class CheckoutsController < ApplicationController
  def create
    cart = current_user.cart
    if cart.items.any? { |i| i.stock <= 0 }
      render json: { error: "out of stock" }, status: :unprocessable_entity and return
    end
    order = Order.create!(cart: cart)
    OrderMailer.confirmation(order).deliver_later
    render json: order, status: :created
  end
end

# GOOD — thin: one use case, render by result
class CheckoutsController < ApplicationController
  def create
    result = Cart::Checkout.call(cart: current_cart, payment_method: params[:payment_method])

    if result.success?
      render json: OrderSerializer.new(result[:order]), status: :created
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end
end
```

Serializers are ports (they translate core → HTTP shape), not libs. Jobs and consumers follow the same shape: deserialize, call one use case, translate the result to the transport's vocabulary (retry/ack/requeue). Plain CRUD follows the same law: `Period::Create`, `Period::Update` and `Period::Destroy` are cases, never `@period.save` in a controller — the case is what records events and logs.

**Exception — framework controllers.** Devise controllers (`users/sessions`, `users/omniauth_callbacks`) are ports that are only moved: they authenticate through Devise/Warden and do not call a case. Wrapping them saves almost nothing on a future auth swap (routes, model, Warden, helpers, views and mailers change anyway) and has to be kept in sync with every Devise upgrade. If login auditing becomes a requirement, decide it in its own ADR.

```ruby
# app/ports/consumers/order_events_consumer.rb — broker consumer (sneakers): same shape
class OrderEventsConsumer
  include Sneakers::Worker
  from_queue "billing.order_placed",
             exchange: "app.events", exchange_type: :topic,
             routing_key: "order.placed"

  def work(raw)
    payload = JSON.parse(raw)
    result = Order::SendConfirmation.call(order_id: payload["order_id"])
    result.success? ? ack! : requeue!
  end
end
```

## Core

One use case = one class (`Lucid::Case::Command` when it writes, `Lucid::Case::Query` when it only reads) = one action someone performs, named noun + verb: `Cart::Add`, `Cart::Checkout`, `Auth::Login`. Never `CartService`, `CartManager`, `process(action:)`.

`flow` is banned — it hides where errors come from. Orchestration is explicit guard clauses:

```ruby
# app/core/cases/cart/checkout.rb — ENTRY POINT: only composes, may cross nouns
class Cart::Checkout < Lucid::Case::Command
  attributes :cart, :payment_method

  event_payload { |result| { order_id: result[:order].id } }

  def call!
    stock = Cart::Checkout::ValidateStock.call(cart: cart)
    return stock if stock.failure?

    charge = Payment::Charge.call(cart: cart, payment_method: payment_method)
    return charge if charge.failure?

    order = Order.create!(cart: cart, charge_id: charge[:charge_id])
    emit(:order_placed, order_id: order.id)

    success(order: order)
  end
end
```

A `Command` runs in a transaction by default: the order and its events (the Case event `cart.checkout` and the custom `order_placed`) commit together, and a `failure` or exception rolls both back. Use `transaction :disabled` for external I/O, independent batches, or when the case must persist its own failure.

Steps do one thing and never call another use case. Flow-private steps nest under the action (`Cart::Checkout::ValidateStock`); reusable verbs live at noun level (`Payment::Charge`). Entry points never call entry points — flatten, or the second flow is a reaction → event.

### Entities — two persistence variants

**Variant A — ActiveRecord in core (default).** The entity is the AR model. Less code, Rails-native:

```ruby
# app/core/models/cart.rb
class Cart < ActiveRecord::Base
  has_many :items, class_name: "CartItem"

  def checkout_ready?
    items.any? && status == "open"
  end

  def total
    items.sum { |i| i.quantity * i.unit_price }
  end
end
```

**Variant B — core isolated from persistence by composition.** The entity is a PORO wrapping a record; the record lives in bridges (the database schema treated as outside knowledge — it knows tables and SQL, nothing else):

```ruby
# app/bridges/cart_record.rb
class CartRecord < ActiveRecord::Base
  self.table_name = "carts"
  has_many :item_records, class_name: "CartItemRecord"
end
```

```ruby
# app/core/models/cart.rb
class Cart
  def self.find(id)
    new(CartRecord.find(id))
  end

  def self.where(**conditions)
    CartRecord.where(**conditions).map { |record| new(record) }
  end

  def initialize(record)
    @record = record
  end

  def id
    @record.id
  end

  def checkout_ready?
    @record.item_records.any? && @record.status == "open"
  end

  def total
    @record.item_records.sum { |i| i.quantity * i.unit_price }
  end

  def mark_as_paid!
    @record.update!(status: "paid")
  end
end
```

Rules for variant B:

- `Cart.find` and `Cart.where` are the only doors — nothing outside `app/core/models/cart.rb` references `CartRecord`
- Delegate only methods the code actually uses; never expose the whole schema because it exists
- A new attribute becomes a method on `Cart` — never reach into `@record` from outside
- Raw associations (`item_records`) never leave the entity; if items must be exposed, wrap them too

Choosing: A is the default. Move to B when the domain must survive schema churn or the table no longer mirrors the business concept — the cost is a delegation layer maintained by hand. Behavior must be identical either way: a shared test asserting the business methods (`checkout_ready?`, `total`) return the same results with the same data is what proves a migration changed structure, not behavior.

### Validations

```ruby
# app/core/models/user.rb — invariant: a user row can NEVER exist without email
class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
end

# Use case — context: coupon code is required only when applying a coupon
class Cart::ApplyCoupon < Lucid::Case::Command
  attributes :cart, :coupon_code

  validates :coupon_code, presence: true

  def call!
    # ...
  end
end
```

## Bridges

Wrap every outside party; also a lucid-case use case (uniform contract) — `Query` when it only reads, `Command` with `transaction :disabled` when it writes outside. Translate their vocabulary into ours; capture infra errors into `failure`; never decide business.

```ruby
# app/bridges/hotmart/payment_status.rb
class Hotmart::PaymentStatus < Lucid::Case::Query
  attributes :email

  validates :email, presence: true

  def call!
    user = fetch_user
    return failure(:user_not_found, error: "user not found") if user.nil?

    success(overdue: user["status"] == "BLOCKED")   # our vocabulary out
  rescue Faraday::Error => e
    failure(:unavailable, error: e.message)
  end
end
```

`overdue: true` leaves; `status: "BLOCKED"` never leaks upward. Who blocks the login is `Auth::Login` — the bridge answers, the use case decides.

## Platform — events

Event contract (see `br4zz4:architecture` § The core's I/O contract): name is a fact in the past tense owned by the noun whose state changed; payload carries ids and the changed fields; the record is immutable once created. The outbox is the one shipped by `lucid-case` (`lucid_case_events`, written in the Command's transaction): never a hand-rolled `Event` model, subscriptions map, relay job or dead letter table.

```sh
bin/rails g lucid:case:events   # migrations + config/initializers/lucid_case_events.rb
bin/rails db:migrate
```

```ruby
# the fact: emitted inside the Command, recorded in the same transaction as the data
class Cart::Checkout < Lucid::Case::Command
  event_payload { |result| { order_id: result[:order].id } }   # ids, never the whole record

  def call!
    order = Order.create!(cart: cart)
    emit(:order_placed, order_id: order.id)
    success(order: order)
  end
end
```

Every recording Command also produces a Case event named after its class (`cart.checkout`); `emit` is for a fact the result does not tell. `emit` in a Query or Subscriber raises. Failures are recorded after the rollback; exceptions record nothing.

```ruby
# app/core/cases/order/on_placed.rb — the reaction: a case of kind :subscriber
class Order::OnPlaced < Lucid::Case::Subscriber
  subscribe :order_placed

  def call!
    order = Order.find(event.content[:order_id])
    delivery = Mailers::OrderConfirmation.call(order: order)
    return delivery if delivery.failure?

    success
  end
end

# a one-liner that deserves no class
Lucid::Case.subscribe(Order::Place, as: :confirmation_mailer) do |event|
  OrderMailer.confirmation(event.content[:order_id]).deliver_later
end
```

- `subscribe` takes a Command class (Case event) or a name (custom event); `on:` picks the outcome (`:success` default, `:failure`, `:any`, a failure type); `step:` follows a step of a stepped command; `ordered: true` delivers in recording order, one at a time.
- Delivery is at-least-once and unordered by default: a subscriber is idempotent through `event.id`, or turn on `config.events.deduplication = :enabled`. Idempotency lives in the reacting case, never in a `processed_at` column of a hand-rolled table.
- `stale_on Dashboard::Metrics, on: Enrollment::Approve` drops a Query's cache right after the commit, in process; use a subscriber only for reactions that may run later in a job.
- Subscribers load from `config.events.load_paths`; a directory that does not exist raises `ArgumentError`.
- Multi-tenant apps capture the schema in `config.events.context` and restore it in `config.events.around_delivery`; point `config.events.table_name` at a table every tenant sees (`public.lucid_case_events`).
- The outbox is not an audit trail: it purges delivered rows after `config.events.retention`. Keep your own record when you need history.

External broadcast (a broker, a partner webhook) is a subscriber that calls a bridge:

```ruby
class Order::PublishPlaced < Lucid::Case::Subscriber
  transaction :disabled
  subscribe :order_placed

  def call!
    Rabbit::Publish.call(name: "order.placed", payload: event.content)
  end
end
```

```ruby
# app/bridges/rabbit/publish.rb — broker protocol lives in a bridge
class Rabbit::Publish < Lucid::Case::Command
  transaction :disabled

  attributes :name, :payload

  def call!
    exchange.publish({ name: name, payload: payload }.to_json, routing_key: name, persistent: true)
    success(published: name)
  rescue Bunny::Exception => e
    failure(:publish_failed, error: e.message)
  end

  private

  def exchange
    Rabbit::Connection.channel.topic("app.events", durable: true)
  end
end
```

The relay runs after the commit; if the process dies between the commit and the relay, the row stays pending until the sweep runs. Schedule it (Cloud Scheduler → worker, or Solid Queue `config/recurring.yml`) with a job in `platform/`:

```ruby
# app/platform/relay_pending_events_job.rb
class RelayPendingEventsJob < ApplicationJob
  def perform
    Lucid::Case::Events.relay_pending
  end
end
```

Test events with `include Lucid::Case::TestHelpers` (`assert_event`, `assert_no_event`, `capture_events`) and call a subscriber directly with `Order::OnPlaced.call(event: event)`. Side effects of a `Command` that must not exist for a rolled-back write (jobs, mail) go in its `after_commit`; an effect that does not belong to the response is an event, never a direct call.

## Webhooks

Inbound — the endpoint is ours (ports); the vendor dialect lives in bridges:

```ruby
# app/ports/controllers/webhooks/hotmart_controller.rb — zero vendor knowledge
class Webhooks::HotmartController < ApplicationController
  def create
    result = Webhook::Receive.call(headers: signature_headers, payload: request.raw_post)

    result.type == :invalid_signature ? head(:unauthorized) : head(:ok)
  end
end
```

```ruby
# app/core/cases/webhook/receive.rb — entry point: verify, translate, record the fact, answer fast
class Webhook::Receive < Lucid::Case::Command
  attributes :headers, :payload

  def call!
    signature = Hotmart::VerifySignature.call(headers: headers, payload: payload)
    return failure(:invalid_signature) if signature.failure?

    parsed = Hotmart::ParseWebhook.call(payload: payload)
    return success(ignored: true) if parsed.failure?

    WebhookReceipt.create!(external_id: parsed[:external_id])   # unique index: a redelivered webhook is a duplicate
    emit(parsed[:name], **parsed[:payload])
    success(received: true)
  rescue ActiveRecord::RecordNotUnique
    success(duplicate: true)
  end
end
```

```ruby
# app/bridges/hotmart/parse_webhook.rb — all vendor dialect lives here
class Hotmart::ParseWebhook < Lucid::Case::Query
  EVENTS = { "PURCHASE_REFUNDED" => "payment.refunded" }.freeze

  attributes :payload

  def call!
    data = JSON.parse(payload)
    name = EVENTS[data["event"]]
    return failure(:unknown_event) if name.nil?

    success(
      name: name,
      external_id: data["id"],
      payload: { email: data.dig("data", "buyer", "email") }
    )
  end
end
```

Reactions go through the relay as usual. Outbound webhooks (we POST to their endpoint) are `Webhooks::Deliver` in bridges, triggered by the event flow.

## Multi-tenancy

Schema per tenant (Postgres) through the `lucid-tenancy` gem (`github: "br4zz4/lucid-tenancy", tag: "v0.1.2"`). Never `acts_as_tenant`; never hand-rolled `search_path` wrappers (`SET search_path`, `Apartment`-style switchers).

```ruby
Lucid::Tenancy.with(tenant: org) { Student.create!(...) }   # run inside a tenant, restores after
Lucid::Tenancy.shared { Organization.find(id) }              # run in the shared (public) schema
Lucid::Tenancy.set(tenant: org)                              # switch for the rest of the request/job
Lucid::Tenancy.each { |tenant| ... }                         # iterate every tenant (batches, backfills)
```

- Declare where a thing lives with `tenancy :tenant` or `tenancy :shared` in migrations, models and jobs; a migration without it fails. Tenant migrations carry no guards or wrappers (`table_exists?`, `in_*`, `for_all_tenants`).
- Tenant tables come from the template schema, dumped to `db/schema_tenant.rb` and used to provision new tenants. After changing tenant migrations run `rake lucid:tenancy:dump`; CI runs `rake lucid:tenancy:check`. Pre-existing tenants: `rake lucid:tenancy:baseline`.
- The middleware resolves the tenant at the port and Active Job carries it; outside a request (jobs without it, console, seeds, tasks) wrap code in `with`, `each` or `shared`. Never set the tenant inside a use case.
- Isolation is the schema: never filter by `organization_id`/`tenant_id`.
- Cached queries scope their key by tenant (see `Lucid::Case.configure` above).
- Declare `tenancy :tenant|:shared` followed by a blank line. The gem ships the cop (`Lucid/Tenancy/BlankLineAfterDeclaration`, `require: lucid/tenancy/rubocop`); because `db/**` is usually excluded from the main rubocop config, run it as a second pass over `db/migrate` with a small `.rubocop_migrations.yml`, and make `lint.fix` run both. Never copy the cop into the app.
- Never call `set(tenant:)` without a block in a controller, reflex or cable connection: the state stays on the server thread and leaks into the next request. Use `around_action`, `around_reflex` and, for Action Cable, `include Lucid::Tenancy::ActionCable` in `ApplicationCable::Connection` (`around_command` also covers the StimulusReflex page morph, which runs after `around_reflex`).
- Resolve the tenant only from hosts under `base_domain`: `config.base_domain`, `config.strict_base_domain = true` (no subdomain fallback), `config.ignored_identifiers = %w[www]`; `config.hosts = Lucid::Tenancy::Hosts.allowed` (set in an initializer, after the tenancy config; production/staging only) and mailer URLs from `Lucid::Tenancy::Hosts.url_options_for(tenant, port:)`, never from `request.domain` (host header poisoning). Dev needs `TENANT_BASE_DOMAIN` too (`localhost`), there is no fallback without it. Do not write a custom resolver lambda for this.
- `db:migrate` and `db:rollback` dump only the primary schema (`db:schema:dump:primary`), so `cache_schema.rb` and `cable_schema.rb` stay untouched; `Lucid::Tenancy.pending?` tells whether any schema has pending migrations (use it in seeds and boot checks).
- Active Storage is `tenancy :tenant`: `active_storage_attachments` stores `record_type`/`record_id` of models that live in each school, and ids repeat across schools, so a shared table mixes attachments between tenants. Create the three tables in every school (a new `tenancy :tenant` migration; never edit the old one) and regenerate the dump.
- The admin panel (Avo, `/admin`) runs in the shared schema: keep only resources whose tables live there (`Admin`, `Organization`); tenant resources raise "relation does not exist". Tenant data belongs to a screen that picks a tenant first.
- Configure `config.after_provision` only for data a new tenant needs: migrations create structure, not rows, and singletons made on demand (`Setting.current`) do not need a hook. If a hook exists, its spec must fail without it.
- `db:cache:prepare`/`db:cable:prepare` load a schema; in production Rails aborts with `ProtectedEnvironmentError`. The tasks only load when the table is missing (nothing to destroy), so set `DISABLE_DATABASE_ENVIRONMENT_CHECK=1` around that call and restore it afterwards.
- Never run `bundle update <gem>` bare: it drags transitive majors (`json` 3 broke `sprockets`). Use `--conservative` with the explicit list of the gem and its dependencies, then boot the app.
    - Seeds find by key: `Model.find_or_create_by!(key) { ... }`, never `first_or_create!` (it returns any existing row, so a second tenant is never created). Check pending migrations with `Lucid::Tenancy::Migrator.pending`, not a custom rake task.
- Gem behaviour that bit us (fixed in 0.1.5 and 0.1.6): switching schema must clear the Active Record query cache, otherwise the same SQL in another tenant is answered with the previous tenant's rows; a freshly provisioned tenant must have every tenant migration version recorded, otherwise the next `db:migrate` replays them (`relation already exists`). Data from the wrong tenant, or `already exists` on a new tenant, points here first.

## Environments (k8s)

oporpino Rails projects use three environments: `development`, `staging`, `production`.

**`staging`** is a first-class Rails environment — not an alias for production. Create `config/environments/staging.rb` explicitly:

```ruby
# config/environments/staging.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.assume_ssl = true
  config.force_ssl = true
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL")
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = true
  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false

  if ENV["RAILS_ALLOWED_HOSTS"].present?
    config.hosts = ENV["RAILS_ALLOWED_HOSTS"].split(",").map(&:strip)
  end

  # Exclude health check from host authorization (k8s probes use pod IP as host)
  config.host_authorization = { exclude: ->(request) { request.path == "/health" || request.path == "/up" } }
end
```

**`production.rb`** is identical but with `log_level=info` and `report_deprecations=false`.

**`config.hosts`** is always configured via `RAILS_ALLOWED_HOSTS` env var — injected by k8s per environment overlay. Never hardcode hostnames in the config file.

### Environment variables — never default

Env vars name what the thing is, never the implementation: `DATABASE_URL`, `CACHE_URL`, `CABLE_URL`, and for parts `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `WEB_PORT` (never `REDIS_URL`, `DB_PORT`, `SERVER_PORT`). Compose and run scripts follow the same rule with no default: `${DATABASE_PORT:?set DATABASE_PORT in .env}`.

Never give an env var a default in code: use `ENV.fetch("VAR")` (raises if missing). `ENV.fetch("VAR", default)`, `ENV.fetch("VAR") { default }` and `ENV["VAR"] || default` are forbidden — missing config must fail loudly. Only add a default when explicitly requested for that var. See `@rules/shared/env.md`.

**k8s base deployment** sets `RAILS_ENV=production` as default. Each overlay patch overrides to `staging` or keeps `production`:

```yaml
# base: RAILS_ENV=production (safe default)
# overlays/staging/patches/deployment.yaml: RAILS_ENV=staging
# overlays/production/patches/deployment.yaml: RAILS_ENV=production (explicit)
```

### Environments on Cloud Run + commons (staging in Rails)

A project that deploys `staging` and `production` from the same image still needs a real `staging` Rails environment, so `ENV=staging` locally and the remote console match the deployed one.

- `config/environments/staging.rb`: `require_relative "production"` plus `config.log_level = ENV.fetch("RAILS_LOG_LEVEL")` (debug in staging). Never copy `production.rb`.
- Add `staging:` wherever `production:` is keyed: `database.yml` (`staging: <<: *production`, so `production: &production` needs the anchor), `cable.yml` (`staging: <<: *production`), and every `Rails.env.production?` / `ENV["RAILS_ENV"] == "production"` check (Puma workers, PDF binary path), otherwise staging silently runs the dev branch.
- `br4zz4/commons` exports only `ENVIRONMENT`, never `RAILS_ENV`. Every `run/*` that boots Rails sources `lib/rails_env.sh`, which maps `ENVIRONMENT` to `RAILS_ENV` (`development`, `test`, `staging`, `production`; anything else exits 64). Without it `make core.console ENV=staging` opens a dev console on the local database.
- Destructive scripts (`db.create`, `db.drop`, `db.reset`, `db.rollback`, `db.prepare`) source `lib/local_env.sh`, which calls `rails_env.sh` and refuses anything but development and test. `console`, `routes`, `db.migrate*` and `db.seed` may target staging and production; the commons asks for the project name on restricted environments.
- The console prompt shows the env (`(prod)`, `(staging)`): check it before pasting data-changing code.

### Tenant per subdomain on Cloud Run

One Cloud Run service serves every tenant; the tenant is the host, the schema is per tenant. Cloud Run has no wildcard domain mapping, so each new tenant needs its own CNAME and domain mapping (plus a managed certificate, a few minutes).

- The tenant base domain is a plain env var, `TENANT_BASE_DOMAIN` (`staging.example.com` in staging, `example.com` in production), set in Terraform `base_env_vars` from the environment host. It is not a secret and does not go in ward. The resolver strips it from the host to get the subdomain; a host outside the base falls back to `tld_length`.
- Provisioning is a use case plus a Cloud Tasks job, not an `after_create` callback: persist a `SubdomainProvisioning` row (`pending`, `running`, `succeeded`, `failed`, `current_step`, `attempts`, `last_error`), enqueue the job, run idempotent steps (Cloudflare CNAME to `ghs.googlehosted.com`, `proxied: false`; Cloud Run `domainmappings`, 409 means already there). The worker answers 503 on failure so the queue retries with backoff; the admin monitor lists rows and retries `failed` ones.
- Reserve subdomains (`www`, `admin`, `avo`, `api`, `app`, `staging`, `production`) and validate a single DNS label on create.
- Cloudflare needs `Zone:Read` and `DNS:Edit` on the zone; the runtime service account needs `roles/run.admin`, and the domain must be verified for it in Search Console.
- A host that resolves to the wrong tenant shows the school's 404: check the `organizations` table of that environment first, then the logs of `TenantMiddleware`. The log line prints `request.subdomain`, not the value the resolver used.

### Queue: Cloud Tasks by default

Cloud Tasks delivers each job as an authenticated HTTP POST to a private `worker` Cloud Run service (same image and module as `web`, `APP_ROLE=worker`, no custom `command`); Cloud Scheduler posts `{"job":"<name>"}` to the same endpoint for crons. Nothing polls the database, so the worker scales to zero and Neon can suspend.

- `ACTIVE_JOB_ADAPTER=cloud_tasks` in staging and production, `async` in development, `test` in the tests; the adapter reads `CLOUD_TASKS_QUEUE_PATH`, `CLOUD_TASKS_TARGET_URL` and `CLOUD_TASKS_SA_EMAIL` and sets `dispatch_deadline` to 1800 s.
- `POST /tasks/worker` answers 404 unless `APP_ROLE=worker` (the web service is public), 415 without JSON, 422 for an unknown job or invalid payload (never a retry), 503 when the job raises (the queue redelivers with backoff, 5 attempts).
- Terraform: queue (`max_attempts 5`, `max_retry_duration 3600s`), a `queue-invoker` and a `scheduler` service account with `run.invoker` on the worker, `cloudtasks.enqueuer` plus `serviceAccountUser` for the web service account, token creator for the Cloud Tasks service agent. Enable `cloudtasks` and `cloudscheduler` APIs and grant the CI service account `cloudtasks.admin` and `cloudscheduler.admin` **before** the first deploy that creates the queue (apply it with `-target`): the first attempt right after enabling the API answers 403 and the retries fall inside the propagation window.
- The worker URL is deterministic (`https://<service>-<project number>.<region>.run.app`), so web and worker can both receive it without a cycle.

### Deploy default: Cloud Run + Neon

- **Region match.** Cloud Run `us-west1` pairs with Neon `aws-us-west-2`. Neon cannot move a project between regions: a wrong region means a new project plus `pg_dump`/`pg_restore`.
- **Neon is created by Terraform** (`neondatabase/neon`, one project per environment, `prevent_destroy`, databases `<app>_<module>`, `<app>_<module>_cache`, `<app>_<module>_cable`; names follow `br4zz4:structure` "Resource naming carries the module"), and Terraform writes `DATABASE_URL`, `CACHE_URL` and `CABLE_URL` into Secret Manager. They never live in ward, and the secret-push script must skip those three keys and never prune them. Provider notes: the project resource does not expose the role password, so read it from `GET /projects/{id}/branches/{branch}/roles/{role}/reveal_password` through the `http` data source (`store_password = true`, mark the body `sensitive`); use `primary_compute.host` and `branch.id` (the `database_host` and `default_branch_id` attributes are deprecated).
- **Direct endpoint only.** Tenancy switches schema with `SET search_path`, which leaks between clients behind PgBouncer (`-pooler`). Fail the boot when `DATABASE_URL`, `CACHE_URL` or `CABLE_URL` contains `-pooler`. Connection ceiling: `max_instances` × pool of each service plus the migrate job must stay under the compute limit (105 at 0.25 CU).
- **Let Neon sleep.** No periodic query without a user: worker without polling, `/up` without the database, crons at most daily, `cpu_idle = true` on web and worker.
- **Sessions in Active Record** (`activerecord-session_store`, `tenancy :shared` table): the cookie store breaks StimulusReflex and the cache store evicts by size and age and logs users out.
- **Web `timeout = 3600s`** so the StimulusReflex websocket is not cut every 2 minutes, `startup_cpu_boost = true`.
- **Artifact Registry** cleanup policy keeping the 10 most recent images plus deleting older ones.
- **Terraform vs. named revisions.** If the deploy creates revisions with `--revision-suffix`, a Terraform update that re-sends the stored revision name with a new configuration fails with `409 Revision named ... with different configuration already exists`. Never pin `template.revision`; fix it in the module, not in the deploy.

### Lessons from the first Neon-by-Terraform apply

- **Move before you collide.** When a secret that already exists (`CACHE_URL`) changes owner from a generic `for_each` module to a dedicated one, add `moved { from = module.app_secrets["CACHE_URL"] to = module.cache_url_secret }` **and** drop the key from the list that feeds the `for_each` (a `moved` whose source is still declared fails with "Moved object still exists"). Without both, the apply answers 409 "already exists" after it has already created the Neon project. Check that the env actually passes the variable you changed: if `envs/*` do not forward `app_secret_keys`, the module default is what runs, and the CI export is silently ignored.
- **`latest` is the newest version, enabled or not.** A Secret Manager `latest` alias points at the highest version number even when it is disabled or destroyed, so reading it fails. To undo a bad version, add a new version with the good value; do not disable the bad one and hope `latest` falls back.
- **A new database is not migrated by a "skip when `db/migrate` did not change" hook.** After Terraform creates or replaces the database, run the bootstrap (`db:prepare`) once, or make the hook compare the live schema version. `/up` that never touches the database will say green while every page is 500.
- **Cloud Run maps a custom domain only for a verified owner.** The principal that calls `domainmappings` (the web service account when the app provisions subdomains) must be a verified owner of the base domain in Search Console; otherwise the mapping is created with `Ready=False` ("Caller is not authorized to administer the domain") and the DNS and provisioning rows still look successful.
- **Neon suspends on its own.** With `suspend_timeout_seconds = 0` (plan default, 300 s) the compute went `idle` about 8 minutes after the last query, as long as the worker has no polling; any `psql` session from a developer keeps it `active`.
- **Org-wide keys live once.** The Neon API key is an organization key shared by every project of the org: keep it in the shared CI scope (`secrets.ci.common`) and read it in the plan/apply scripts, exporting `TF_VAR_<name>`; the organization id is not a secret and belongs in the Terraform variable default.

### Neon: backup is history, not a copy

Neon restores a root branch to any second inside the history window (Free 6 h, Launch up to 7 days, Scale up to 30 days) and keeps snapshots (scheduled ones up to 35 days). Everything lives inside the Neon project, so it is recovery, not an off-site backup, and it does not protect against a bad migration found after the window. For production: a paid plan with the window at 7 days or more, a daily scheduled snapshot, a manual snapshot before risky migrations, and a daily `pg_dump` to a bucket outside Neon (Cloud Scheduler plus Cloud Run Job). Rehearse one restore.

## Credentials

Only production has its own credentials file. Staging uses the default credentials.

| Environment | Credentials file | Key source |
|---|---|---|
| `development` | `config/credentials.yml.enc` | `config/master.key` (gitignored) |
| `staging` | `config/credentials.yml.enc` | `RAILS_MASTER_KEY` env var (from k8s secret) |
| `production` | `config/credentials/production.yml.enc` | `RAILS_MASTER_KEY` env var (from k8s secret) |

**Rules:**
- Never create `config/credentials/staging.yml.enc` — staging shares the default credentials
- `config/credentials/production.yml.enc` is committed (encrypted); the key is in ward and injected via k8s secret
- `RAILS_MASTER_KEY` in the k8s secret must match the key used to encrypt the credentials file for that environment

**Setup:**
```bash
# Edit default credentials (used by development + staging)
bin/rails credentials:edit

# Edit production credentials
bin/rails credentials:edit --environment production
```

The `RAILS_MASTER_KEY` in the k8s secret (`nectar-charges-secrets`) is the **default** master key (`config/master.key`) — Rails uses it for both development and staging. Production uses a separate key stored under `credentials/production.key` (gitignored, in ward).

## Console sandbox (production/staging)

O Rails console em production e staging deve rodar em sandbox por default para evitar alterações acidentais.

**Implementação via initializer:**

```ruby
# config/initializers/console.rb
Rails.application.configure do
  console do
    next if ENV["CONSOLE_SANDBOX"] == "false"
    next unless Rails.env.production? || Rails.env.staging?

    puts "\e[33m[console] sandbox mode — changes will be rolled back on exit\e[0m"
    puts "\e[33m[console] set CONSOLE_SANDBOX=false to disable\e[0m"

    ActiveRecord::Base.connection.begin_transaction(joinable: false)
    at_exit { ActiveRecord::Base.connection.rollback_transaction }
  end
end
```

**Convenção `CONSOLE_SANDBOX`:**
- Agnóstica de linguagem — o mesmo padrão se aplica a Django, Node, etc.
- Default: sandbox ativo em production e staging
- Para desativar: `CONSOLE_SANDBOX=false bin/rails console`
- Devs seniors usam `CONSOLE_SANDBOX=false` quando precisam persistir mudanças

**Como acessar o console via make:**
- `make console.staging` → readonly + sandbox ativo
- `make console.production` → readonly + sandbox ativo
- `make console.staging.fullaccess` → fullaccess + sandbox desligado (requer ser owner no access.yml)
- `make console.production.fullaccess` → fullaccess + sandbox desligado (requer ser owner no access.yml)

O script `console.sh` injeta `DATABASE_URL` e `CONSOLE_SANDBOX` automaticamente no pod temporário — não precisa configurar manualmente.

## Tests

The Brazza standard for Rails apps is Minitest, mocha and fixtures. Tests live in `test/`, mirroring `app/` (`test/integration` for HTTP flows against the real database).

```ruby
class Enrollment::ApproveTest < ActiveSupport::TestCase
  test 'approve under review creates the contract' do
    # arrange
    enrollment = enrollments(:under_review)
    Contract::Generate.expects(:call).with(enrollment: enrollment).returns(stub(failure?: false))

    # act
    result = Enrollment::Approve.call(enrollment: enrollment)

    # assert
    assert_predicate result, :success?
    mocha_verify
  end
end
```

- `ActiveSupport::TestCase` with `test 'description' do`. Triple-A with a comment per section in every test. No `setup` that hides data the test depends on; `setup` is only for global state (ENV, configuration).
- mocha for stubs and expectations: `stubs`/`expects` in the arrange (`.never` for "not called"), `mocha_verify` in the assert. Use `stub(attrs).responds_like_instance_of(Klass)` for verified doubles.
- Fixtures and factories carry only the bulk of a record, with fixed values (no Faker, no random ERB). Whatever the test result depends on is explicit in the arrange: `Model.new(...)`, `Model.create!(...)` or `update!` over a fixture. Faker is allowed inside tests only.
- Multi-tenant apps (`lucid-tenancy`): fixtures only for tenant tables, loaded with the test tenant already set at boot; shared tables are created inline. `include Lucid::Tenancy::Minitest` plus `tenant "name"` sets the tenant per test case.

### Tests in CI

The pipeline calls three hooks of the code side, each a `run/<name>` script (`br4zz4/pipelines`: `test` in the pull request, `regression` and `e2e` in the promote after a green staging deploy):

- `run/test` — in a pull request it receives `BASE_SHA` (the merge-base) and runs only the tests the change touches; with `BASE_SHA` empty (main, dispatch) it runs everything. Map by convention (`app/x.rb` → `test/x_test.rb`) and run everything when the diff touches `Gemfile.lock`, `config/**`, `db/**`, `test/test_helper.rb`, `test/support/**`, `test/fixtures/**` or a `.rb` file without a test. `retest` stays a local watcher (`run/test.watch`); the smarter selection is tracked in br4zz4/pipelines#16.
- `run/regression` — the whole suite and the slow tests (`bin/rails test:all`, system tests included), prepared exactly like `run/test`, with the `test` ward scopes.
- `run/e2e` — real tests against the live staging release, with the `staging` ward scopes and `TARGET_URL`.
  - Tools: Capybara + Cuprite (Chrome over CDP, no chromedriver, no Node) in a `group :e2e` of the Gemfile, tests in `e2e/**/*_test.rb`, never in `test/`, so `bin/rails test` skips them.
  - `Capybara.run_server = false` and `Capybara.app_host` built from `TARGET_URL` (a multi-tenant app prefixes the tenant subdomain). The test talks only HTTP and the browser, never the database: it acts as a real user.
  - A dedicated test account lives in the staging ward (`E2E_EMAIL`, `E2E_PASSWORD`, plus `E2E_TENANT` when multi-tenant) and is provisioned by the infra, never created by the test run.
  - Tests are idempotent: every record carries a unique suffix (`run-<GITHUB_RUN_ID>`) and nothing is deleted.
  - Cover the critical paths of the product, one independent test each, so a Critical issue names the path that broke.
  - On failure write `tmp/artifacts/failures.md` (test name, assertion, stack; no secret, no personal data) and screenshots to `tmp/artifacts/`. `tmp/artifacts/` is ignored by git and exists only on the runner.

The pipeline forbids the Autofix to edit `run/`, `ci/` and `e2e/`, so the hooks and the end-to-end tests are always written by people.

## Review checklist

- Would a PM understand the file tree?
- Does every test show in its arrange what the result depends on, with no hidden `setup` data or random fixtures?
- Does `run/test` use `BASE_SHA`, and do `run/regression` and `run/e2e` exist, with the e2e tests in `e2e/` and no database access?
- Any business `if` in a controller?
- Any core file mentioning HTTP, params, or vendor names?
- Any use case crossing nouns without being the entry point?
- Every async effect an event (`emit` + `Lucid::Case::Subscriber`), never a direct call or a `after_commit` enqueue?
- Does every controller (except Devise) call exactly one case, with no `save`/`update`/`destroy` on a model?
- Every outside call wrapped in a bridge returning `success/failure`?
