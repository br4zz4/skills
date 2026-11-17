---
name: structure
description: Use to understand oporpino project structure.
version: 5.0.0
---

# commons:structure

> **TLDR**: All projects live under `oporpino/`. Each project mounts `br4zz4/commons` as the `.commons` git submodule and follows a strict layout: **`modules/<name>/code/`** holds the application and **`modules/<name>/infra/`** holds infrastructure/deploy; **`docs/`** at the repo root holds ALL documentation and **`.project/`** holds only customizations (make, scripts, docker yml). The root `Makefile` only includes the commons. Local commands go in the module's `code/run/`; project-specific tasks go in `code/tasks/`.

## Workspace layout

```
oporpino/
├── commons/                   # Legacy repo (not used by new projects)
│
├── gateway/                   # Example project (Elixir)
├── checkout-api/              # Example project (Ruby)
├── marketing-automation/      # Example project (N8N)
└── ...                        # Other projects
```

## Per-project layout

```
<project>/                                 # root = command surface only
├── .commons/                              # git submodule of br4zz4/commons, pinned at v1
├── commons.ctx                            # project name, environments, vaults
├── Makefile                               # Orchestrates modules; includes .project/make/*
├── compose.yml                            # Dev compose (thin; see br4zz4:docker)
├── .github/                               # CI/CD workflows
├── .project/                              # Customizations — NEVER docs
│   ├── make/                              # Project-only make targets
│   ├── scripts/                           # One script per repo-level target (1:1)
│   └── docker/                            # Custom compose yml (overrides, extras)
├── docs/                                  # ALL documentation — closed set, see below
├── .tool-versions
├── .env.example
└── modules/
    └── core/
        ├── code/                          # Application: sources, manifest, Dockerfile
        │   ├── bin/                       # Stack-native binstubs only (rails, rake, ...)
        │   ├── run/                       # oporpino run scripts (server, test, lint, ...)
        │   └── tasks/                     # Project-specific shell tasks
        └── infra/                         # Infrastructure & deploy
            ├── ops/                       # remote.sh, secrets.sh (commons ops hooks)
            ├── terraform/                 # Terraform workspaces
            ├── k8s/                       # Kustomize base/ + overlays/
            ├── build-args                 # STACK, STACK_VERSION, DISTRO, LOCK_FILES
            └── <scripts>                  # Deploy scripts (secrets push, release, ...)
```

Single-module projects always name the module **`core`** (`modules/core/`). Never put
`modules/`, `app code`, `terraform/` or `.infra/` at the repo root.

## `docs/` — closed set

All documentation lives in `docs/` at the **repo root**; its first level is a closed set (`specs/`, `plans/`, `features/`, `learnings/`, `architecture/`, `guides/`, `reference/<scope>/`, `rules/<scope>/` plus `README.md`, `RULES.md`, `modules.md`). Never `.project/docs/`, `modules/<m>/docs/` or a free-form folder at level 1. Layout, routing table and naming: skill `br4zz4:docs`.

## The .commons submodule

`.commons` is a **git submodule** of `br4zz4/commons`, pinned at the `v1` tag:

```sh
git submodule add https://github.com/br4zz4/commons .commons
.commons/bin/init
```

- Updated with `make commons.update` (fetches tags and checks out `COMMONS_REF` from `commons.ctx`).
- CI checks it out with `submodules: recursive`.
- The commons knows no project, language or provider; everything specific lives in `commons.ctx`, `.github/modules.json` and the module scripts.

## compose.yml

The root `compose.yml` is the dev orchestration surface and stays thin. Its structure, the stack files and the project services (`.project/docker/`) are defined in skill `br4zz4:docker`. Never duplicate configuration that already exists in `.commons/docker/`; project overrides live in `.project/docker/` at the root, never inside a module.

## Makefile structure

The root `Makefile` is `include .commons/make/main.mk` plus `.project/make/*.mk`. There is **no Makefile per module**: the commons generates `<module>.<step>` and `<module>.<run>` targets from `.github/modules.json`. Details: skill `br4zz4:make`.

## Where scripts live

| Location | Purpose | Extension |
|---|---|---|
| `modules/<name>/code/run/<name>` | oporpino run scripts — the module command surface (`server`, `test`, `lint`, ...). Exposed as `make run.<name>`. | none |
| `modules/<name>/code/tasks/<domain>/<name>.sh` | Project-specific tasks. Only meaningful inside this repo. | `.sh` |
| `modules/<name>/code/bin/` | Stack-native binstubs only (`rails`, `rake`, `manage.py`, ...). | none |
| `modules/<name>/infra/<script>` | Deploy-only scripts (secrets push, release, assets). | `.sh` / none |
| `.project/scripts/<name>.sh` | Repo-level scripts that back a make target — **1 script ↔ 1 target**. | `.sh` |
| `modules/<name>/infra/ops/{remote,secrets}.sh` | Ops hooks run by `make <m>.remote` and `make <m>.secrets`. | `.sh` |
| `modules/<name>/{code,infra}/ci/checks/<step>.sh` | CI hooks; `make <m>.<step>` runs the same script. | `.sh` |

**Decision rule:**
- Is it one of the project's standard operations (server, test, lint, migrate, ...)? → `code/run/`
- Does it use this project's env vars, kubectl context, or docker compose? → `code/tasks/`
- Does it only run during deploy? → `modules/<name>/infra/`
- Is it generic enough to work in any project? → propose it to `br4zz4/commons`
- Is it only for this project? → `code/tasks/` or `code/run/`

**Script ↔ target rule:**
- Every script in `.project/scripts/` has exactly one make target that calls it —
  and every target that needs a script calls one (1:1, both ways).
- Exception: a **runner** script may back a generated family (`run.<name>`); each
  generated target still maps 1:1 to its own `run/<name>` script.
- A target with **more than one command** must be a script, never inline make
  lines (see `skill:make`). The target only calls the script.
- Scripts receive configuration via environment (`ROOT_DIR`, `COMPOSE_FILE`, …)
  so they work from the root and from `make -C modules/<name>`.

**Never:**
- Put project-specific logic in `.commons/`
- Duplicate in `code/tasks/` what the commons already offers (`make help`)

## Temporary artifacts and backups — always `./tmp`

Any file a script writes that is not source — DB dumps, exported workflows,
backups, generated output, scratch files — goes under `./tmp` (project root or
module root), never in a bespoke directory like `tasks/.../backups/`. `./tmp` is
gitignored once; a per-purpose backup dir tends to get committed by accident.

- Scripts write to `$APP_ROOT/tmp/<purpose>-<timestamp>/` (e.g.
  `tmp/exported-production-20260731_101500/`).
- The module/project `.gitignore` lists `tmp/` and nothing else for artifacts.
- Never add a second ignore pattern for a new backup folder — reuse `./tmp`.

## Environment files — `.env.example` only

Every project keeps a **committed `.env.example`** at the repo root (and one per
module that has its own variables). The real `.env` is **never committed** — it is
gitignored and created locally from the example (`cp .env.example .env`).

Rules:

- `.env.example` lists **every** variable the project reads (compose, Makefile,
  scripts, app).
- Values are **plausible but not real** — `CHANGE_ME`, `your-api-key`,
  `user@example.com`, `sk_test_...`. Exception: explicit, non-secret data that must
  be real/known — app name, database name, host names, ports, version pins.
- Reference other variables with `$VAR` inside `.env` and `.env.example` — never
  duplicate a value:

```dotenv
# .env.example
APP_NAME=my-app
DB_USER=postgres
DB_PASSWORD=CHANGE_ME
DB_HOST=localhost
DB_PORT=5432
DB_NAME=${APP_NAME}_development
DATABASE_URL=postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}
```

- Never put a real secret in the example, even "temporarily".
- Compose and Makefiles read the same `.env`; modules that run standalone document
  their variables in the same root example (or a module-level `.env.example`).

## modules/<name>/infra/ layout

Present only in modules that deploy. It is the former `.infra/` moved inside the module —
see `skill:infra` for details.

```
modules/<name>/infra/
├── build-args                 # STACK, STACK_VERSION, DISTRO, LOCK_FILES (used by CI)
├── k8s/                       # only when the module deploys to k8s
│   ├── base/specs/
│   └── overlays/staging/ + production/
├── terraform/
│   ├── main.tf, data.tf, versions.tf, backend.tf
│   ├── envs/staging/ + production/
│   └── secrets/staging.enc.yml, production.enc.yml
└── <deploy scripts>           # secrets push, release, asset upload — never app logic
```

Ward vaults stay at the repo root (`.ward/`): they are repo-level secrets, not a
module artifact.

## `run/` — local commands

Scripts in `modules/<name>/code/run/` are the module's local command surface, one `make <module>.<name>` target each. They run on the host under `mise`, never in a container, and must not use a reserved name (see `br4zz4:make`).

## Multi-module projects

When the project has more than one module under `modules/`, read `MULTI_MODULE.md` in this skill's directory (module boundaries, shared infra and per-module layout) before changing structure.

## Checklist when creating a new project

- [ ] Add the `.commons` submodule and run `.commons/bin/init`
- [ ] Create `modules/core/code/` with the application + manifest + Dockerfile + `.gitignore`
- [ ] Create `modules/core/infra/` (terraform/, k8s/, build-args, deploy scripts) if the project deploys
- [ ] Root `Makefile` is just the commons include; fill `commons.ctx` and `.github/modules.json`
- [ ] Add `mise.toml` and the CI hooks to each side of each module
- [ ] Add `.env.example` with every variable (`$VAR` references; plausible, non-real values)
- [ ] Add `compose.yml` including the commons fragments (see `br4zz4:docker`)
- [ ] Add the `docs/` directories the project actually needs (closed set — see above)
- [ ] Put project-specific tasks in `modules/core/code/tasks/<domain>/<name>.sh`
- [ ] Every `.project/scripts/<name>.sh` has exactly one make target calling it (1:1)
- [ ] Any target with more than one command is a script, not inline make lines
- [ ] Point CI workflows at `modules/core/code` (working-directory, build context, dependabot dir)
- [ ] Keep each module's infra self-declared in `modules/<name>/infra/` (cloud, k8s, terraform)
- [ ] Never duplicate what's already in `.commons/`; run `make conform`
