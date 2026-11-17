---
name: qwert-ops
description: "Local machine only: How to operate qwert (dev environment manager) safely — declared tools, profiles, recipes, hooks, apply/uninstall risks. Load before touching any qwert machine."
compatibility: Requires the user's own machine with qwert and OpenCode or Claude Code CLI; not for chat or cloud sessions.
---

# qwert-ops

Operational guide for agents asked to do anything with **qwert** (dev environment manager), **yuiop** (its package bridge), recipes, profiles or hooks.

## MCP tools (server: `node ~/.qwert/mcp/qwert-mcp.mjs`, tool prefix `qwert_`)

Prefer MCP tools over shelling out — they carry the safety gates:

| Tool | Read/Mutate | Use for |
|---|---|---|
| `qwert_state` | read | FIRST call: profile ativo, profiles declarados, `qwert list`, `qwert doctor` |
| `qwert_machine` | read | config.yml + machine.yml (estado declarado vs runtime) |
| `qwert_doctor` | read | live `qwert doctor` |
| `qwert_info {tool}` | read | live `qwert info <tool>` (recipe + status de install/setup) |
| `qwert_recipes` / `qwert_recipe_documentation` | read | catálogo, install.toml/setup.toml completos |
| `qwert_skill` / `qwert_ops {intent}` | read | este manual (qwert_skill = completo, qwert_ops = filtrado) |
| `qwert_help {command}` | read | manual dos subcommands |
| `qwert_cli {args: [...], confirm?}` | **gate** | executa comando contra a máquina: read-only direto; `apply/setup/install/use/upgrade` exigem `confirm: true` APÓS aprovação humana; `uninstall/drop/self` NUNCA passam pelo MCP |

MCP registration: opencode links `~/.config/opencode/opencode.json → ~/.qwert/config/opencode/opencode.json` (setup da recipe `agents`); o server usa `{env:HOME}` — portável entre usuários.

## Iron rules

1. **Never sweep-install without reading state first**. `qwert apply` uninstalls "orphans" — declarations not in the active profile. For tools of type `package` that means `pacman`/`brew`/`apt` removal of **system-wide** packages, shared by all users of the machine. Read `qwert_state` (MCP) or run `qwert status` before any apply.
2. **Prefer `qwert use <tool>`** over `install` (installs AND sets up config). Use `install` only when setup must wait.
3. `qwert uninstall <tool>` runs the recipe's `[uninstall]`; for `package` recipes that removes the system package. For user-local ones it's safe. When in doubt, remove the declaration only (edit `config.yml`, then `qwert apply <tool>`), or ask the user.
4. NEVER `qwert drop` unless asked for full teardown.
5. State lives in `$HOME/.local/share/qwert/` (state.yml, machine.yml, recipes, plugins). The repo is `~/.qwert/` (config.yml, hooks, recipes, skills) — versioned in git.

## Intents → playbook

### "Bootstrap a new machine with qwert"
1. Clone the user's dotfiles repo to `~/.qwert`.
2. `qwert profile <profile>` (personal|work|root|server) — the profile decides tools+hooks.
3. `qwert apply` — review first: `qwert doctor`; before apply, list what will install.
4. Ensure shell hooks: `.zshrc` needs `eval "$(qwert hook prepare)"` before everything and `eval "$(qwert hook init)"` after editor config.
5. Expect `~/.local/share/qwert/machine.yml` to contain `profile: <name>`.

### "Add a tool to a profile"
1. `qwert search <term>` → is there a recipe? `qwert info <tool>` shows type/platforms/what setup does.
2. Read the recipe's `install.toml`+`setup.toml` (`qwert_info <tool>` or the MCP tool `qwert_recipe_documentation`).
3. If the tool only fits one machine profile, add it to that profile in `~/.qwert/config.yml` (profiles<name>.tools), commit, push — NOT a bare `qwert use`, which adds it outside a profile.
4. `qwert apply` on target machine(s) with that profile active.
5. Warn user about undoes: `qwert drop <tool>` tears down fully.

### "Change machine profile"
- `qwert profile <name>` then `qwert apply`. Warn: tools outside the new profile get **uninstalled** (including system packages for `package`-type recipes). If sharing system packages across users (root + user), re-install missing packages with `pacman -S` right away.

### "Author a recipe"
See `install.toml`/`setup.toml` grammar (in qwert manual). Local recipes: `~/.qwert/recipes/<name>/`. Setup sections resolve all → linux → macos/debian ARCH (no debian fallback for arch). `[check]` = binary + `--version` flag. Custom `type = "custom"/"qwert"` uses `[install].<platform>` commands.

### "Hooks must load per profile"
Layout: `~/.qwert/hooks/zsh/{prepare,init}/` drop-ins are scoped by subdir:
`shared/` loads on every machine; `personal/`, `work/`, `root/`, `server/` load only when `machine.yml`'s profile matches. Loader: `~/.qwert/hooks/zsh/init.sh` (see `_qwert_load_hooks`). New script → put in the right scope subdir; nothing else to wire.

## Verification

- `qwert doctor` → config dir, qwert.yml, recipes, machine profile all ✓.
- `qwert list` → declared tools for the active profile.
- `hyprctl`/shell reload after keyd/hyprland-related setup (`hyprctl reload`, `systemctl restart keyd`).

## Repo map

```
~/.qwert/
├── config.yml            ← tools + profiles + configs + hooks declarations
├── config/               ← per-tool configs (opencode.json, agents/, zsh, ...)
├── hooks/zsh/{prepare,init}[/shared,/personal,/work,/root,/server]/*.sh
├── recipes/              ← local recipe overrides (win over catalog)
├── .ward/{config.yaml,qwert.key,vaults}  ← secrets vault ( ward loads API keys via hook 00-ward.sh )
└── .project/             ← docs, specs, agent skills (mac-hyprland etc.)
```
