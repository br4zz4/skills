---
name: make
description: Use when writing or modifying Makefile targets.
version: 3.1.0
---

# commons:make

> **TLDR**: One `Makefile` per module; the root `Makefile` only includes them. Every target is a single command or a call to a script — never inline multi-line logic. Repo-level scripts live in `.project/scripts/` with **1 script ↔ 1 target**; module scripts live in `modules/<name>/code/{run,tasks}/` or `modules/<name>/infra/`. Project `bin/` holds only stack-native binstubs.

## File layout

```
<project>/Makefile                  # orchestrator: includes module Makefiles only
<project>/.project/make/_main.mk    # bootstrap: vars, ARGS, ROOT_MAKEFILE_INCLUDED, help
<project>/.project/scripts/<name>.sh# one script per repo-level target (1:1)
modules/<name>/code/Makefile        # app targets — root: core.up, core.run.*, core.test
modules/<name>/infra/Makefile       # deploy targets — root: core.gcp.*, core.secrets.*
```

```makefile
# root Makefile
include .project/make/_main.mk
include modules/core/code/Makefile
include modules/core/infra/Makefile
```

```makefile
# modules/core/code/Makefile
CODE_MODULE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
ROOT_DIR ?= $(abspath $(CODE_MODULE_DIR)/../../..)
COMPOSE_FILE ?= $(ROOT_DIR)/compose.yml
```

- Root sets `ROOT_MAKEFILE_INCLUDED := 1`; each module only defines its own
  `.DEFAULT_GOAL`/`help` when that is **not** set (standalone `make -C modules/...`).
- Use module-scoped variable names (`CODE_MODULE_DIR`, `DEPLOY_MODULE_DIR`); a
  shared `MODULE_DIR` is overwritten when the root includes several modules.
- Scripts get paths from the environment (`ROOT_DIR`, `COMPOSE_FILE`) so they work
  from the root and from a module directory.

## Root targets are module-prefixed

All module targets are namespaced as `<module>.<target>` — literally, in the
file, never global. If module `core` has a `start` target, it is written as
`core.start:` and invoked as `make core.start` (never `make start`). This
prevents collisions when several modules define the same target (`up`, `test`,
...) and makes the root help self-documenting.

Hardcode the prefix (no `$(PREFIX)` variable indirection): the names are the
same in the root and standalone (`make -C modules/...`), and the `help` targets
discover descriptions by grepping the **file text** — a `$(PREFIX)up:` line in
the source would not match the `^[a-zA-Z0-9_.-]+:` pattern.

```makefile
# modules/core/code/Makefile
.PHONY: core.up core.test core.start
core.up: ## Start app detached (builds if needed)
	@$(ROOT_DIR)/.project/scripts/up.sh

core.start: core.run.start   ## internal deps use the full names too
```

```makefile
# generated families follow the same pattern
define RUN_RULE
.PHONY: core.run.$(1)
core.run.$(1):
	@$(ROOT_DIR)/.project/scripts/run.sh $(1) $(ARGS)
endef
```

- The prefix is the **module** name (`core`), not the sub-scope: both
  `modules/core/code` and `modules/core/infra` use `core.`.
- Underscore helpers called only via `$(MAKE)` inside the module (e.g.
  `_gcp_run`) stay unprefixed — they are not part of the public surface.
- Docs, scripts and comments must reference the full name (`make core.test`),
  including backing-script headers.

## Rules

- Every target calls either a **simple one-liner** or a **script**
- **One-liner rule**: a target may have logic inline only if it is a single command (excluding `echo`/`printf` messages). Two or more real commands → extract to a script.
- **1:1 script ↔ target**: every script in `.project/scripts/` has exactly one target calling it, and every target that needs logic calls a `.project/scripts/` (or module) script. No orphan scripts, no orphan targets.
- **Runner exception**: a runner script (e.g. `.project/scripts/run.sh`) may back a generated family (`run.<name>`). Each generated target still maps 1:1 to its own script (`run/<name>`); the runner only adds the shared container invocation.
- Never put multi-line logic or conditionals inline in a Makefile
- Choose the right script type before creating anything (see below)

## Correct patterns

```makefile
# Simple one-liner — OK
deploy:
	@docker compose up -d

# Multi-command target — the logic lives in the backing script
up:
	@$(ROOT_DIR)/.project/scripts/up.sh

# Delegates to task — OK
n8n.workflows.promote:
	@bash modules/core/code/tasks/n8n/workflows/promote.sh

# Delegates to a shared bin — OK
db.load:
	@.commons/bin/db/load /data/dump.sql

# Named make target calling another — OK
staging.deploy:
	$(MAKE) deploy ENV=staging
```

## Wrong patterns

```makefile
# Logic inline — NOT OK
deploy:
	@if [ "$(ENV)" = "production" ]; then \
		echo "deploying..."; \
		kubectl rollout ...; \
	fi

# Two commands inline — NOT OK (extract to .project/scripts/deploy.sh)
deploy:
	@echo "deploying..."
	@kubectl rollout restart ...
```

## Script types

| Type | Nature | Location |
|---|---|---|
| **run** | Project run script — the public command surface (`server`, `test`, `lint`, `migrate`, ...), exposed as `make run.<name>` | `modules/<name>/code/run/<name>` |
| **bin** | Generic executable — could be installed on the system, usable outside the project without context | `.commons/bin/<domain>/<name>` |
| **task** | Project-scoped script — executes a task within the project context, even if it accepts parameters | `modules/<name>/code/tasks/<domain>/<name>.sh` |
| **project script** | Backs exactly one repo-level make target (compose orchestration, release steps) | `.project/scripts/<target>.sh` |

**How to decide:**
- Is it one of the project's standard operations (start, test, lint, install, migrate, ...)? → **run**
- Would this script make sense installed as a system command, used by any project? → **bin**
- Does it back a repo-level target and touch several modules or the root compose? → **project script** (`.project/scripts/`)
- Does it depend on one module's structure, env vars, kubectl context, docker compose, or paths? → **task**
- Does it orchestrate other scripts in sequence? → **task** (recipe)

**Naming:**
- **bin** → no extension (e.g. `.commons/bin/db/load`, `.commons/bin/db/drop`) — called like a system command
- **task** → `.sh` extension (e.g. `modules/core/code/tasks/n8n/workflows/export.sh`) — explicitly a shell script

**Examples:**
- `.commons/bin/db/load` — loads a SQL dump into any postgres instance. Generic. **bin**
- `modules/core/code/tasks/n8n/workflows/export.sh` — exports from the project's n8n instance. **task**
- `modules/core/infra/release.sh` — deploys to the project's k8s cluster. **task**
- `tasks/n8n/workflows/promote.sh` — backup + deploy sequence. **task** (recipe)

**Additional rules:**
- A task may call other tasks or bins
- A recipe task orchestrates other tasks/bins in sequence — never duplicates their logic
- A recipe calling another recipe is a smell — flatten or extract

## Where scripts live

| Location | Purpose |
|---|---|
| `run/` | Project run scripts — the public command surface, exposed as `make run.<name>`. |
| `tasks/` | Project-specific tasks. Belong to this repo only. |
| `bin/` | Stack-native binstubs only (`rails`, `rake`, `bundle`, `manage.py`, ...). |
| `.commons/shell/tasks/` | Shared tasks reused across multiple projects. |
| `.commons/bin/` | Shared bins reused across multiple projects. (e.g. `db/load`, `db/drop`) |

- Never put project-specific logic in `.commons/`
- Never duplicate in `run/` or `tasks/` what already exists in `.commons/`
- Scripts must be executable (`chmod +x`)
- `run/` scripts are the **source of truth** — never delegate to `.commons/shell/tasks/` from a project `run/` script. Write the commands directly.
- `make code.*` targets do not exist — use `run/` scripts directly (`run/test`, `run/lint`, `run/audit`) or their `make run.*` targets

## Commons make structure

```
.commons/make/
  main.makefile          ← único entry point (.makefile só aqui)
  core/
    _main.mk             ← loads shared core modules
    commands.mk          ← scans run/*, generates run.<name> targets, loads matching command files
    help.mk, release.mk, compose.mk, setup.mk
  commands/
    <name>.mk            ← command-owned rules only when a run/ script needs special behavior
```

**Como usar num projeto:**

O `Makefile` do projeto inclui `main.makefile`:

```makefile
include $(COMMONS_DIR)/make/main.makefile
```

- `main.makefile` delegates run/ discovery to `make/core/commands.mk`
- `make/core/commands.mk` scans `run/*` (subdirectories like `run/terraform/` excluded) and loads only the `make/commands/<name>.mk` files that match existing run/ scripts
- `make/commands/<name>.mk` is keyed by script name (e.g. `run/test` → `test.mk`) and defines the `run.<name>` target — it exists only when a run/ script needs special behavior beyond the default runner path
- generic `run/*` scripts are exposed as `run.<name>` targets through the shared devmode runner
- the devmode runner chooses `exec` for local and `docker compose run` for container when the command needs a service
- no automatic stack discovery: only run-matched command files and generated `run.<name>` targets are loaded from the entrypoint

## Commons make targets and run/

Commons make targets must delegate to `run/` scripts in the project when the command is not command-file owned, **not** inline the command themselves.

The project owns the implementation. Commons owns the invocation path.

```makefile
# commons/make — CORRECT: delegates to project run/
run.migrate:
	run/migrate

# commons/make — WRONG: implements logic directly
run.migrate:
	$(_django) python manage.py migrate
```

The `run/` script is the single source of truth for how a task runs — Make, CI, k8s Jobs, and other callers all use it.

## Alignment rule

Makefile targets and scripts are a pair — they must always stay in sync.

- Script **moved or renamed** → update every Makefile target that references it
- Target **renamed** → update the script call and any docs referencing the old name
- Script **deleted** → remove the corresponding target
- Script **created** → add a corresponding target in the Makefile

Never leave a target pointing to a path that doesn't exist, and never leave a script with no target.
