---
name: structure
description: Use to understand oporpino project structure.
version: 4.1.0
---

# commons:structure

> **TLDR**: All projects live under `oporpino/`. Each project symlinks `commons` as `.commons` and follows a strict layout: **`modules/<name>/code/`** holds the application and **`modules/<name>/infra/`** holds infrastructure/deploy; **`docs/`** at the repo root holds ALL documentation and **`.project/`** holds only customizations (make, scripts, docker yml). The root `Makefile` orchestrates modules. Run scripts go in the module's `code/run/`. Tasks go in `code/tasks/` (project-specific) or `.commons/shell/tasks/` (shared).

## Workspace layout

```
oporpino/
├── commons/                   # Shared tooling repo
│   ├── shell/tasks/           # Shared shell tasks (reused across projects)
│   ├── make/                  # Shared makefiles (core/, stacks/, shared/)
│   ├── bin/                   # Shared bins (e.g. bin/db/load, bin/db/drop)
│   ├── docker/                # Shared docker-compose dev files
│   └── ai/                    # AI rules and skills
│
├── gateway/                   # Example project (Elixir)
├── checkout-api/              # Example project (Ruby)
├── marketing-automation/      # Example project (N8N)
└── ...                        # Other projects
```

## Per-project layout

```
<project>/                                 # root = command surface only
├── .commons -> /path/to/oporpino/commons  # Symlink — never a git submodule
├── Makefile                               # Orchestrates modules; includes .project/make/*
├── compose.yml                            # Dev compose (thin; see br4zz4:docker)
├── .github/                               # CI/CD workflows
├── .project/                              # Customizations — NEVER docs
│   ├── make/                              # Bootstrap + custom make (vars, ARGS, help)
│   ├── scripts/                           # One script per repo-level target (1:1)
│   └── docker/                            # Custom compose yml (overrides, extras)
├── docs/                                  # ALL documentation — closed set, see below
├── .tool-versions
├── .env.example
└── modules/
    └── core/
        ├── code/                          # Application: sources, manifest, Dockerfile
        │   ├── Makefile                   # App targets (up, run.*, test, logs, ...)
        │   ├── bin/                       # Stack-native binstubs only (rails, rake, ...)
        │   ├── run/                       # oporpino run scripts (server, test, lint, ...)
        │   └── tasks/                     # Project-specific shell tasks
        └── infra/                         # Infrastructure & deploy
            ├── Makefile                   # Deploy targets (gcp.*, secrets, ...)
            ├── terraform/                 # Terraform workspaces
            ├── k8s/                       # Kustomize base/ + overlays/
            ├── build-args                 # STACK, STACK_VERSION, DISTRO, LOCK_FILES
            └── <scripts>                  # Deploy scripts (secrets push, release, ...)
```

Single-module projects always name the module **`core`** (`modules/core/`). Never put
`modules/`, `app code`, `terraform/` or `.infra/` at the repo root.

## `docs/` — closed set

All documentation lives in `docs/` at the **repo root**; its first level is a closed set (`specs/`, `plans/`, `features/`, `learnings/`, `architecture/`, `guides/`, `reference/<scope>/`, `rules/<scope>/` plus `README.md`, `RULES.md`, `modules.md`). Never `.project/docs/`, `modules/<m>/docs/` or a free-form folder at level 1. Layout, routing table and naming: skill `br4zz4:docs`.

## The .commons symlink

Each project has `.commons` as a **symlink** pointing to the `commons` repo:

```
.commons -> /Users/<user>/workspace/oporpino/commons
```

- Created/refreshed by: `make commons.projects.symlink` (run from commons)
- Tracked in git as a submodule pointer (SHA), not as a symlink
- Updated across all projects by: `make commons.projects.commit`

This means `.commons/shell/tasks/` in any project resolves to `commons/shell/tasks/`.

## compose.yml

The root `compose.yml` is the dev orchestration surface and stays thin. Its structure, the stack files and the project services (`.project/docker/`) are defined in skill `br4zz4:docker`. Never duplicate configuration that already exists in `.commons/docker/`; project overrides live in `.project/docker/` at the root, never inside a module.

## Makefile structure

**One `Makefile` per module**; the root `Makefile` only includes them, and a target lives in the module that owns the work. Conventions (module-scoped variables, standalone `ROOT_DIR`, root `help`): skill `br4zz4:make`.

The stack is **auto-detected** by `_contract.mk` based on file presence — no explicit include needed in `Makefile`:

| File present | Stack |
|---|---|
| `Gemfile` | Ruby/Rails |
| `package.json` | React/Node |
| `mix.exs` | Elixir/Phoenix |
| `pyproject.toml` / `requirements.txt` | Python/Django |

In this layout the manifests live in `modules/<name>/code/`, so detection paths are
declared explicitly in `.project/make/overrides.mk` (included automatically by
`main.makefile`):

```makefile
# .project/make/overrides.mk
PROJECT_MANIFEST := modules/core/code/Gemfile
APP_SERVICE      := app
```

## Where scripts live

| Location | Purpose | Extension |
|---|---|---|
| `modules/<name>/code/run/<name>` | oporpino run scripts — the module command surface (`server`, `test`, `lint`, ...). Exposed as `make run.<name>`. | none |
| `modules/<name>/code/tasks/<domain>/<name>.sh` | Project-specific tasks. Only meaningful inside this repo. | `.sh` |
| `modules/<name>/code/bin/` | Stack-native binstubs only (`rails`, `rake`, `manage.py`, ...). | none |
| `modules/<name>/infra/<script>` | Deploy-only scripts (secrets push, release, assets). | `.sh` / none |
| `.project/scripts/<name>.sh` | Repo-level scripts that back a make target — **1 script ↔ 1 target**. | `.sh` |
| `.commons/shell/tasks/<domain>/<name>.sh` | Shared tasks reused across multiple projects. | `.sh` |
| `.commons/bin/<domain>/<name>` | Shared executables reused across multiple projects. | none |

**Decision rule:**
- Is it one of the project's standard operations (server, test, lint, migrate, ...)? → `code/run/`
- Does it use this project's env vars, kubectl context, or docker compose? → `code/tasks/`
- Does it only run during deploy? → `modules/<name>/infra/`
- Is it generic enough to work in any project? → `.commons/bin/`
- Is it already used by another project? → `.commons/shell/tasks/` or `.commons/bin/`
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
- Duplicate in `code/tasks/` what already exists in `.commons/shell/tasks/`
- Reference `.commons/bin/` for tasks that live in `.commons/shell/tasks/`

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

## Environment vs setup

- **environment init** = configura a máquina e todos os projetos (ferramentas globais + clone dos repos)
  - Script: `environment/init.sh`
  - Run: `gh api repos/ibft-corp/commons/contents/environment/init.sh --jq '.content' | base64 -d | bash`
- **project.init** = inicializa este projeto na máquina pela primeira vez (`.commons`, `.env`, asdf)
  - Script: `.commons/shell/tasks/setup/project/init.sh`
  - Run: `make project.init`
- **setup** = reconfigura este projeto (`.env`, asdf)
  - Script: `.commons/shell/tasks/setup/project.sh`
  - Run: `make setup`

## Commons shared tasks reference

Key shared tasks available via `.commons/shell/tasks/`:

```
setup/
  project.sh            # Setup do projeto (.project, .claude, .codex, .env)
  env.sh                # Substituição de PROMPT_USER no .env
commons/
  setup-symlink.sh      # Create .commons symlinks in all projects
  projects-commit.sh    # Sync commons SHA across all projects
  projects-push.sh      # Push main branch across all projects
release/
  create.sh             # Create a release
git/
  branch-cleanup.sh     # Delete merged branches
deploy/                 # Deployment tasks
terraform/              # Terraform secret management
```

```
environment/init/
  tools.sh              # Verifica ferramentas da máquina
  asdf.sh               # Instala asdf + versões de linguagens
  oporpino.sh             # Instala oporpino CLI globalmente
```

## `run/` — container entrypoints

Scripts in `modules/<name>/code/run/` are the module command surface and the compose services' `command`. Contents, shebang rules and the per-script table: skill `br4zz4:docker`.

## Multi-module projects

When the project has more than one module under `modules/`, read `MULTI_MODULE.md` in this skill's directory (module boundaries, shared infra and per-module layout) before changing structure.

## Checklist when creating a new project

- [ ] Create `.commons` symlink via `make commons.projects.symlink`
- [ ] Create `modules/core/code/` with the application + manifest + Dockerfile + `.gitignore`
- [ ] Create `modules/core/infra/` (terraform/, k8s/, build-args, deploy scripts) if the project deploys
- [ ] Add `Makefile` at the root that only includes `.project/make/_main.mk` + each module Makefile
- [ ] Add a `Makefile` per module with its own targets (app targets in `code/`, deploy targets in `infra/`)
- [ ] Add `.project/make/overrides.mk` with project vars and explicit manifest paths (`modules/core/code/<manifest>`)
- [ ] Add `.env.example` with every variable (`$VAR` references; plausible, non-real values)
- [ ] Add `compose.yml` at the root following `br4zz4:docker`
- [ ] Add `.project/docker/compose/services.yml` defining all services
- [ ] Add `modules/core/code/run/server`, `run/migrate`, etc. for each compose service used
- [ ] Add the `docs/` directories the project actually needs (closed set — see above)
- [ ] Put project-specific tasks in `modules/core/code/tasks/<domain>/<name>.sh`
- [ ] Every `.project/scripts/<name>.sh` has exactly one make target calling it (1:1)
- [ ] Any target with more than one command is a script, not inline make lines
- [ ] Point CI workflows at `modules/core/code` (working-directory, build context, dependabot dir)
- [ ] Keep each module's infra self-declared in `modules/<name>/infra/` (cloud, k8s, terraform)
- [ ] Never duplicate what's already in `.commons/`
