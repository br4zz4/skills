---
name: qwert-opencode-plugin
description: "Local machine only: Write, build, publish, and install an opencode plugin (TUI or server). Use when creating a plugin, fixing one that won't load, publishing to npm, or adding it to the qwert setup. Covers the validated working pattern (JS build + npm/ scoped name) and the known broken ones (raw .tsx in npm)."
compatibility: Requires the user's own machine with qwert and OpenCode or Claude Code CLI; not for chat or cloud sessions.
---

# br4zz4:qwert-opencode-plugin

> **TLDR**: Plugins must ship a **built `.js`** (`dist/index.js`) with `exports["./tui"]`, referenced in `tui.json` (TUI) or `opencode.json` (server). **Npm packages work — scoped names (`@scope/name`) included.** Raw `.tsx`/`.ts` never loads from npm (runtime can't transpile from `node_modules` — fails silently); it only works via a local `file://` path. Build to JS and it just works.

## Two kinds of plugins

| Kind | Installed in | Export | Used for |
|------|--------------|--------|----------|
| **server** | `opencode.json` → `"plugin"` | `server(ctx)` | tools, hooks, providers, shell env |
| **TUI** | `tui.json` → `"plugin"` | `tui(api)` | slash commands, keybindings, dialogs, routes |

A module exports **one or the other**, never both:

```ts
export default { id: "my-plugin", tui: async (api) => { /* ... */ } }
```

The exported `id` is required for file plugins and used as the plugin id.

---

## The working recipe (validated end-to-end)

### 1. Write source (`src/index.tsx`)

TUI plugins use Solid JSX (`@opentui/solid`) for dialogs. A picker/slash-command example that works:

```tsx
import type { TuiPlugin, TuiDialogSelectOption } from "@opencode-ai/plugin/tui"

const tui: TuiPlugin = async (api) => {
  api.command.register(() => [
    {
      title: "Pick",
      value: "pick",
      slash: { name: "pick" },
      onSelect: () => {
        api.ui.dialog.replace(
          () => (
            <api.ui.DialogSelect<string>
              title="Pick"
              options={[{ title: "A", value: "a" }]}
              onSelect={(opt) => { api.ui.dialog.clear(); api.ui.toast({ message: opt.value }) }}
            />
          ),
          () => {},
        )
      },
    },
  ])

  api.keymap.registerLayer({
    bindings: [{ key: "#", desc: "Pick", preventDefault: true, cmd: () => { /* open same picker */ } }],
  })
}

export default { id: "my-plugin", tui }
```

### 1b. Persistent UI (slots)

To draw something fixed on screen — a status bar, a footer, a badge — you don't use dialogs. TUI plugins register **slots**: named render regions on the host screen. Each slot receives a Solid JSX renderer with a `ctx` carrying the live theme:

```tsx
import type { TuiPlugin } from "@opencode-ai/plugin/tui"

const tui: TuiPlugin = async (api) => {
  api.slots.register({
    // order is optional; lower renders first. Multiple plugins can fill a slot.
    slots: {
      app_bottom(ctx) {
        const theme = ctx.theme.current
        return (
          <box flexDirection="row" justifyContent="flex-end" paddingRight={2}>
            <text fg={theme.accent}>◆ </text>
            <text fg={theme.textMuted}>R$ 0,00</text>
          </box>
        )
      },
    },
  })
}

export default { id: "my-plugin", tui }
```

Available host slots (see `TuiHostSlotMap` in `@opencode-ai/plugin/tui`):
`app`, `app_bottom`, `home_logo`, `home_prompt`, `home_prompt_right`, `home_bottom`,
`home_footer`, `session_prompt`, `session_prompt_right`, `sidebar_title`,
`sidebar_content`, `sidebar_footer`. For a global bottom bar visible everywhere, use
**`app_bottom`**. `ctx.theme.current` exposes `text`, `textMuted`, `accent`, `border`,
etc.

The slot renderer is a Solid function: if it calls a Solid store/signal, the host
re-renders it when the store changes. So reading `api.state.session.get(id)` inside the
renderer updates automatically as sessions change — no event wiring needed for simple
cases. To force a re-render on demand, hold a `createSignal` from `solid-js` and read it
in the renderer.

### 2. Build to plain JS with esbuild (REQUIRED for npm)

The npm registry must ship **compiled `.js`**. The opencode runtime imports from `~/.cache/opencode/node_modules` and **does not transpile `.ts`/`.tsx` from there** — it fails *silently* (no log, plugin just never loads). This is the #1 cause of "installed but nothing happens".

`build.mjs`:

```js
import { build } from "esbuild"

await build({
  entryPoints: ["src/index.tsx"],
  bundle: true,
  format: "esm",
  outfile: "dist/index.js",
  jsx: "automatic",
  jsxImportSource: "@opentui/solid",
  external: ["@opentui/solid/jsx-runtime", "@opencode-ai/plugin"],
  target: "esnext",
})
```

### 3. `package.json`

```json
{
  "name": "@scope/my-plugin",      // scoped works; unscoped also works
  "version": "1.0.0",
  "type": "module",
  "main": "./dist/index.js",
  "exports": { ".": "./dist/index.js", "./tui": "./dist/index.js" },
  "files": ["dist"],
  "scripts": { "build": "node build.mjs", "prepublishOnly": "npm run build" },
  "publishConfig": { "access": "public" }   // required to publish scoped as public
}
```

- `exports["./tui"]` (or `["./"]`) is what the TUI loader resolves.
- `files: ["dist"]` — never ship `src` unless you mean to.
- `publishConfig.access: "public"` is mandatory for `@scope/` packages (else npm treats them private → 402 Payment Required).
- Commit `dist/` to the repo (the org convention).

### 4. Install into opencode

`~/.config/opencode/tui.json` (TUI plugin):

```json
{ "plugin": ["@scope/my-plugin@1.0.0"] }
```

Or `opencode.json` (server plugin):

```json
{ "plugin": ["my-plugin@1.0.0"] }
```

Pin the version for stability; omit it for `latest`.

### 5. Wire into the qwert setup (optional)

If the plugin should exist on every machine, add the `tui.json` (or `opencode.json`) reference to `~/.qwert/config/opencode/`, symlink it in the recipe (`recipes/agents/setup.toml`), and let opencode's npm install handle the rest:

```
[ -d ~/.config/opencode ] && [ ! -e ~/.config/opencode/tui.json ] \
  && ln -sfn ~/.qwert/config/opencode/tui.json ~/.config/opencode/tui.json || true
```

---

## Local dev / quick test

Point `tui.json` at a `file://` URL. A `file://` path to the **built** `.js` is the most reliable:

```json
{ "plugin": ["file:///Users/you/code/my-plugin/dist/index.js"] }
```

`file://` to the raw `index.tsx` also loads (transpiled at runtime) — fine for quick iteration, but the built `.js` matches what npm will load, so prefer it to catch build issues early.

**Note:** a `:` (colon) anywhere in a `file://` path breaks the import (e.g. a `/tmp/foo:bar` dir). Avoid colons in dev paths; npm caches never have them.

---

## What does NOT work (validated gotchas)

### ❌ Shipping raw `.tsx`/`.ts` to npm

```json
{ "main": "./index.tsx", "exports": { "./tui": "./index.tsx" } }
```

Installs fine (files land in cache) but **never loads**. Runtime can't transpile TS/JSX from `node_modules`, and the failure is silent. **Always build to `.js`.**

### ❌ Referencing a GitHub/git URL directly

```json
{ "plugin": ["github:you/my-plugin"] }
```

The installer puts it under `~/.cache/opencode/packages/<spec>` and fails to import (missing build / weird target). **Use the npm name or `file://` instead.**

### ❌ Server plugin in `tui.json` (or TUI plugin in `opencode.json`)

Each kind loads only from its own config key. Wrong key → "Loads nothing, no error."

### ❌ Expecting hot-reload

Config is read once at startup. Restart opencode after any change to `tui.json`, `opencode.json`, or the plugin itself.

---

## Diagnosing "the plugin doesn't load"

OpenCode 1.18.x is bad at logging plugin load failures (known issue — it publishes to the event bus, not the logger). Walk this order:

1. **Package landed?** `ls ~/.cache/opencode/packages/<spec>/node_modules/<name>/`
2. **Built file present?** Confirm `dist/index.js` (not `index.tsx` / `src/`).
3. **`tui.json` intact?** Real file (not clobbered by another process), symlink valid (`ls -la ~/.config/opencode/tui.json`).
4. **Entrypoint imports?** From the project dir:
   ```bash
   node -e "import('<abs path to dist/index.js>').then(m => console.log(Object.keys(m.default ?? m)))"
   ```
5. **Can the runtime load a built JS from the npm cache?** Copy the installed `.js` to a clean path, point `file://` at it, restart. If it loads → build/package issue. If not → cache path issue.
6. **Restart** and re-trigger (the `#` key or slash).

### In-plugin tracing (fastest when nothing else helps)

Silent load failure means the plugin body may never execute, and the host won't tell you.
Make the plugin log its own milestones via the SDK client — those land in the server log
(`~/.local/share/opencode/log/opencode.log`) which you CAN read:

```ts
const log = (api: TuiPluginApi, message: string) => {
  try { void api.client.app.log({ service: "my-plugin", level: "info", message }) } catch {}
}

const tui: TuiPlugin = async (api) => {
  log(api, "tui() called")
  api.slots.register({ slots: { app_bottom() { log(api, "app_bottom rendered"); return <></> } } })
}
```

After restart, grep the log for `service=my-plugin`. Markers that show up mean the load
pipeline reached that point; a missing `tui() called` means the module never loaded
(entrypoint/build/cache problem, not a render problem).

### `tui.json` is being clobbered

Every running opencode instance rewrites `~/.config/opencode/tui.json` at startup (it
installs/pins plugins it knows). Run several opencode terminals at once and they write
over each other — your `"plugin"` entry can vanish between writes. This makes plugin
"disappear" mysteriously. Prevent it:
- **Only run one opencode instance while iterating on plugins.**
- After editing `tui.json`, verify it survived: `cat ~/.config/opencode/tui.json`.
- Prefer pinning the npm version (`foo@1.0.0`) over `file://` — npm entries survive a
  rewrite (opencode re-resolves them), while a `file://` you added may be dropped when
  another instance rewrites the array.

---

## Testing a TUI plugin headlessly

Drive the TUI in a `tmux` pane and assert the UI responds:

```bash
tmux kill-session -t t 2>/dev/null
cd /tmp && tmux new-session -d -s t -x 220 -y 50 'opencode'
sleep 20                                   # give plugins time to load
tmux send-keys -t t '#'                    # trigger the key binding
sleep 3
tmux send-keys -t t 'search'
sleep 2
tmux capture-pane -t t -p | grep -E "Skills|br4zz4:"   # assert picker opened
tmux kill-session -t t 2>/dev/null
```

---

## npm publishing notes

- Scoped packages: `npm publish` with `publishConfig.access: "public"`. The first publish may 409 "previous package not fully processed" if you recently unpublished that name — wait a minute and retry.
- Account requires a 2FA OTP on publish; keep `npm whoami` to a user that owns/`read-write` the package name.
- Renaming a published package: you can't republish under the old name immediately (npm keeps a cooldown after unpublish). Pick the final name before publishing.
- Set author consistently: `oporpino <dev@porpi.no>`.

### Registry propagation is slow — don't trust `npm view` immediately

`npm publish` returns before the registry fully propagates. `npm view <pkg> version` can
show the OLD version for minutes, and an `npm install <pkg>` during that window fails
with `notarget`. There's also a brief "staged" state where `npm publish` re-run 409s.
If something looks wrong after publish, wait 15-60s and recheck — don't re-publish.

### `@latest` staleness and the empty cache-dir trap

opencode resolves an unpinned spec (`"foo"` or `"foo@latest"`) **once** and keeps the
resolved version in its cache. After you publish `0.1.1` + `0.1.2`, an existing
`~/.cache/opencode/packages/foo@latest` may still hold `0.1.0`. And if the install
failed mid-run (e.g. during registry propagation), the cache dir can exist but be
**empty** — no `node_modules` — while the log shows nothing.

```bash
ls -la ~/.cache/opencode/packages/foo@latest/          # empty dir => broken install
find ~/.cache/opencode/packages/foo@latest -type f     # want node_modules/foo/dist/index.js
# Fix: remove the stale entry so opencode reinstalls
rm -rf ~/.cache/opencode/packages/foo@latest ~/.cache/opencode/packages/foo@*
# Or pin the exact published version in tui.json to bypass `@latest` entirely
```

Pin versions (`"foo@1.0.0"`) in config to avoid the `@latest` cache trap.

---

## Checklist

- [ ] `build.mjs` → produces `dist/index.js`
- [ ] `package.json`: `main`/`exports["./tui"]` → `dist/index.js`
- [ ] `files: ["dist"]`; commit `dist/` to the repo
- [ ] Name scoped or unscoped (both work); scoped needs `publishConfig.access: public`
- [ ] Module exports `tui` **or** `server` (not both), with `id`
- [ ] `prepublishOnly: npm run build`
- [ ] Referenced in the correct config file (tui.json vs opencode.json), version pinned
- [ ] `tui.json`/`opencode.json` symlinked from `.qwert` if it should be global
- [ ] After restart, plugin didn't vanish → confirm `tui.json` wasn't clobbered by another opencode instance
- [ ] After republishing a version, pinned it AND removed stale `~/.cache/opencode/packages/<name>@*` if `@latest` used
- [ ] Restart opencode and trigger to confirm it loads

## License / quality notes

- Org convention: `AGPL-3.0` with a `LICENSE` file, `Copyright (C) <year> <author> <email>` header (e.g. `Copyright (C) 2026 oporpino <dev@porpi.no>`).
- Author identity: `oporpino <dev@porpi.no>`.