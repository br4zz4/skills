# Multi-module projects (br4zz4:structure)

Load when the project has more than one module under `modules/`.


A project always groups its code under `modules/<name>/`, and **every module has exactly two
sides: `code/` (what runs) and `infra/` (how it ships)**. Single-module projects name the
module `core`.

```
<project>/
├── modules/
│   ├── frontend/
│   │   ├── code/                  # app source + manifest (package.json) + Dockerfile
│   │   │   ├── Makefile           # module targets
│   │   │   ├── bin/
│   │   │   ├── run/               # server, test, lint, ...
│   │   │   └── tasks/
│   │   └── infra/                 # k8s + terraform + build-args + deploy scripts
│   │       ├── Makefile           # module deploy targets
│   │       ├── build-args         # STACK, STACK_VERSION, DISTRO, LOCK_FILES
│   │       ├── k8s/base/ + overlays/staging/ + production/
│   │       └── terraform/
│   └── backend/
│       ├── code/                  # Gemfile, config/, app/, Makefile, bin/, run/, tasks/
│       └── infra/
│           ├── Makefile
│           ├── build-args
│           ├── k8s/
│           └── terraform/         # envs/staging/ + production/
├── docs/                          # ALL docs here — never inside a module
│   ├── specs/  plans/  features/  learnings/
│   └── architecture/  guides/  reference/  rules/
├── .commons -> ...
├── .project/                      # custom make/, scripts/, docker yml — never docs
├── Makefile                       # orchestrates: includes modules/*/{code,infra}/Makefile
├── compose.yml                    # dev orchestration → build contexts in modules/*/code
├── .github/                       # workflows (build contexts also point at modules/*/code)
├── .env.example
└── .gitignore
```

**Why `modules/` and not `apps/` or `packages/`:** `apps/` implies only user-facing apps; `packages/` implies npm libs. `modules/` is generic — workers, jobs, mobile apps, APIs all fit. It also never conflicts with Rails' `app/` directory.

**`code/` vs `infra/` — the only split that matters:**
- `code/` holds everything the runtime needs: sources, manifest, Dockerfile, `.rubocop.yml`,
  `run/`, `tasks/`, `bin/`, stack tooling config, the module's `.gitignore`.
- `infra/` holds everything needed to ship it: `terraform/`, `k8s/`, `build-args`, deploy
  scripts (secrets push, release, assets). It replaces the former `.infra/`.
- Docs **never** go in a module — always `docs/` at the repo root.
- Specs **never** go in a module — they are `docs/specs/` at the repo root.
- AI commands **never** go in a module — always `.project/` or `.claude/` at the repo root.
- A `.project/` directory **never** goes inside a module.
- Infra never leaks into `code/` — no `.tf` files next to the app.

**Module self-declaration (infra is per module):**
- Each module **self-declares** its deploy target: cloud/provider (GCP, AWS, other),
  terraform, k8s manifests, `build-args`, deploy scripts — all inside
  `modules/<name>/infra/`.
- Each module **self-resolves** its paths and credentials: CI and scripts read only
  that module's `infra/` directory. Nothing is looked up at the repo root.
- Different modules may target different clouds (e.g. `modules/api` on GCP,
  `modules/worker` on AWS). Never assume a single provider for the repo.
- The repo stays clean: no root-level `infra/`, `.infra/`, terraform, k8s or
  cloud-specific CI files.

**`infra/` in multi-module projects:**
- Every module owns its own `infra/` — never a shared `infra/` or `.infra/` at the project root.
- `build-args` lives inside the module's `infra/` — CI reads it from the module path.
- `k8s/` and `terraform/` also live inside the module's `infra/`.
- The project root has **no** `infra/` and **no** `.infra/`.

**Root `Makefile` delegation pattern:**
```makefile
include $(COMMONS_DIR)/make/main.makefile

frontend.%:
    @$(MAKE) -C modules/frontend $*

backend.%:
    @$(MAKE) -C modules/backend $*
```

**Root `compose.yml` pattern:**
```yaml
name: <project>
include:
  - path:
      - ${COMMONS_DIR}/docker/compose/shared/database.yml
      - .project/docker/compose/services.yml
```

**Rules:**
- Every module lives inside `modules/` — never at the project root.
- Every module has `code/` and, if it deploys, `infra/`. Never `src/`, `app/` or `.infra/` at the module root.
- Each module is self-contained: its own manifest (`package.json`, `mix.exs`, `Gemfile`), its own tooling config, its own `infra/`.
- No cross-module source imports at the language level.
- The project root holds only: `modules/`, `docs/`, `.project/`, `.github/`, `.commons` symlink, `Makefile`, `compose.yml`, `.env.example`, `.gitignore`, `.tool-versions`.
- No `infra/` or `.infra/` at the project root — infra lives inside each module's `infra/`.
- No `.project/` inside a module — that is a repo-level concept only.
- Docker compose for local dev (`n8n.yml`, stack overrides) lives in `.project/docker/compose/` at the root, not inside a module.
- Legacy docker swarm files go in `.project/docker/swarm/` at the root — never inside a module.
- A placeholder module (stack not yet chosen) has only `code/` and `infra/` with empty stubs — no `.gitkeep`.
- Stack auto-detection by `_contract.mk` looks at the project root. Detection files live inside `modules/<name>/code/` — declare explicit paths in `.project/make/overrides.mk`.

For the full convention see `docs/modules.md` in the project.

