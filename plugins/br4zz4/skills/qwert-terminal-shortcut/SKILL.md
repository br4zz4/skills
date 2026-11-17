---
name: qwert-terminal-shortcut
description: "Local machine only: Add, fix, or investigate keyboard shortcuts in the terminal environment — tmux, iTerm2, or zsh."
compatibility: Requires the user's own machine with qwert and OpenCode or Claude Code CLI; not for chat or cloud sessions.
---

# terminal-shortcut skill

Use this skill when the user wants to add, fix, or investigate a keyboard shortcut in the terminal environment — tmux, iTerm2, or zsh.

## Scope

- **tmux**: window/pane navigation, swap, actions
- **iTerm2**: key mappings, hex code forwarding
- **zsh**: key bindings via `bindkey`

## Machine context

- **Linux/Hyprland machine (olinda)**: NO tmux, NO iTerm2 here — only Hyprland.
  Shortcut work on this machine goes in **keyd** (`~/.qwert/config/keyd/default.conf`)
  + **hyprland** (`~/.qwert/config/hyprland-desktop/hypr/hyprland.conf`). Never touch
  tmux/iTerm2 configs for behavior on this machine.
- **Bind/unbind mirror rule**: every `cmd+X` bind added in keyd must have its mirror
  `unbind` in hyprland (e.g. keyd `w = C-w` → `unbind = $mainMod, W`;
  keyd arrows → `unbind = CTRL SHIFT, left/right/up/down`), so the combo passes
  through to the app instead of being swallowed by the compositor.

---

## Navigation model

### Modifier convention
- `Cmd+` → pane actions (navigation + swap)
- `Opt+` → window actions (navigation + swap)
- `Ctrl+` → reserved for shell/zsh (e.g. Home/End)

### Porpino style (applies to ALL hjuk bindings — panes and windows)
- `h` → left
- `j` → down
- `u` → up
- `k` → right

**Critical:** whenever touching any hjkl mapping, always convert to porpino style (hjuk). Never leave vim-style (hjkl) bindings.

### Consistency rule
Every navigation action must have parallel swap equivalent. If `Opt+hjuk` navigates panes, then `Opt+Shift+hjuk` or `Opt+Shift+arrow` swaps panes. Same for windows with `Cmd+Shift+`.

---

## iTerm2 GlobalKeyMap — two action types

When iTerm2 intercepts a key combo before it reaches tmux, you configure it in the GlobalKeyMap
(in `~/.qwert/config/iterm2/com.googlecode.iterm2.plist`):

- **Action 10** ("Send Escape Sequence"): prepends ESC to the Text char → tmux receives `M-<char>`
  - Use for: any `Opt+letter` combo that should map to a native `bind -n M-<letter>` in tmux
  - Example: `{Action: 10, Text: 'h'}` → sends ESC+h → tmux sees M-h
- **Action 11** ("Send Hex Code"): sends exact hex bytes
  - Use for: `Cmd+`, `Opt+Shift+`, `Ctrl+Shift+`, `Ctrl+/` — combos that can't produce a clean ESC sequence
  - Example: `{Action: 11, Text: '1b 5b 31 32 39 75'}` → sends `\e[129u` → tmux sees User19

**Rule: prefer Action 10 + native `M-` binding.** Only use Action 11 + `user-keys[N]` when
Action 10 is not possible (e.g. Cmd+, Shift combos, or when the raw letter conflicts with
something else in the terminal).

### Complete Opt+ binding table

| Key    | GlobalKeyMap action      | tmux binding           | Action |
|--------|--------------------------|------------------------|--------|
| Opt+n  | Action 10 'n' → M-n     | new window             | action |
| Opt+p  | Action 10 'p' → M-p     | project fzf picker     | action |
| Opt+q  | Action 10 'q' → M-q     | kill window (confirm)  | action |
| Opt+w  | Action 10 'w' → M-w     | kill pane (confirm)    | action |
| Opt+f  | Action 10 'f' → M-f     | find window            | action |
| Opt+,  | Action 10 ',' → M-,     | rename window          | action |
| Opt+.  | Action 10 '.' → M-.     | command prompt         | action |
| Opt+r  | Action 10 'r' → M-r     | reload config          | action |
| Opt+s  | Action 10 's' → M-s     | save session           | action |
| Opt+d  | profile Esc+ → M-d      | detach                 | action |
| Opt+Space | native M-Space       | session tree           | action |
| Opt+c  | Action 11 ESC+c → M-c   | copy mode              | action |
| Opt+-  | Action 10 '-' → M--     | split horizontal       | pane   |
| Opt+\  | Action 10 '\' → M-\     | split vertical         | pane   |
| Opt+/  | Action 10 '/' → M-/     | help windows popup     | help   |

**Opt (pane nav/swap):** pane navigation uses native `M-h/j/u/k` and `M-[ / ]` (Action 10).
Pane swap uses Action 11 + user-keys (Shift combos can't use Action 10).

**Opt+Shift+ (pane swap):** All use Action 11 + user-keys.

## user-keys index ranges (tmux)

- 10–19: misc / misc bindings
- 24–29: help popups / last-window (Cmd+a/l)
- 30–35: (removed — Ctrl+Shift pane swap was deleted)
- 36–39: (removed — Cmd+arrow pane nav moved to native M-arrow)
- 40–49: window nav (Cmd+[] → User40/41, Cmd+hjuk → User40-45), window swap (Cmd+Shift+arrow → User46/49, Opt+Shift+arrow pane swap → User17/18/47/48)
- 50–58: window swap (Cmd+Shift+hjuk → User50-52, Cmd+Shift+[] → User15/16) & pane swap (Opt+Shift+hjuk → User53-56, Opt+Shift+[] → User57/58)
- 63–70: Cmd+numpad window nav (User63-66); Opt+numpad pane nav (User67-70)
- 71–76: pane swap Opt+Shift+numpad (User71-74), window swap Cmd+Shift+numpad (User75/76)
- 77–81: Opt+Shift+numpad diagonal pane move (7/9/3/1) + layout toggle (*)
- 82–90: window select by number (Cmd+1..9)
- next available: 91+

---

## Step-by-step process

### 1. Understand what the user wants
Ask: what key combo, and what action? Which layer — tmux, iTerm2, or zsh?

### 2. Check the full impact
Before doing anything, think through the consistency rules:
- Does this affect navigation? → check if swap needs updating too
- Does this use hjuk? → ensure porpino style throughout
- Does this add a new modifier pattern? → ensure all 4 directions are covered

### 3. Capture the terminal sequence
Ask the user to run:
```
cat -v
```
Press the key combo, then `ctrl+c`. Record what is printed.

### 4. Evaluate the sequence
- If it's a **clean, unique sequence** (e.g. `^[[112u`) → map directly
- If **nothing appears** → key is captured by macOS/iTerm2. **Skip all debugging. Go straight to step 7 (configure hex in iTerm2).** This is always the fix — don't waste time investigating why the sequence is missing.

**Most Cmd+, Opt+Shift+, Ctrl+Shift+, Ctrl+/ combos will show nothing.** For any of these, immediately compute the iTerm2 key ID, pick the next free sequence (next \e[NNNu number), and write it to the plist.

### 5. Check for conflicts

**tmux** — grep all mappings:
```
grep -rn "user-keys\[" ~/.qwert/config/tmux/config/mappings/
```
- Pick the next free index in the appropriate range
- Check if the same action already has another binding that would become redundant

**zsh** — check existing bindings:
```
bindkey | grep <sequence>
```

**iTerm2** — read the plist to see all active hex mappings:
```
python3 -c "
import plistlib
with open('/Users/gporpino/.qwert/config/iterm2/com.googlecode.iterm2.plist', 'rb') as f:
    data = plistlib.load(f)
gkm = data.get('GlobalKeyMap', {})
for k, v in sorted(gkm.items()):
    text = v.get('Text', '') if isinstance(v, dict) else ''
    if '1b 5b' in text:
        print(f'  {k}: {text}')
"
```

### 6. Remove redundant bindings

Before adding, always remove:
- Old bindings for the same action (both `set -s user-keys[N]` and `bind -n UserN`)
- iTerm2 entries for keys that no longer exist in tmux (edit the plist directly)
- Vim-style hjkl entries replaced by porpino-style hjuk

Never leave dead or duplicate bindings in tmux config or the iTerm2 plist.

### 7. Configure iTerm2 (when needed)

Two equivalent ways — plist edit (scriptable) or GUI (manual).

**GUI way (Settings → Keys → Key Mappings → +):**
1. Click `+` to add a mapping
2. Press the keyboard shortcut (recorded as the key ID)
3. Set **Action: Send Hex Code**
4. Paste the hex (e.g. `1b 5b 31 38 35 75` for `\e[185u`)
5. Repeat per key, then restart iTerm2

**Plist way** — edit the plist directly via python (see step 5 for how to read it).
To add/remove entries:

```python
import plistlib

path = '/Users/gporpino/.qwert/config/iterm2/com.googlecode.iterm2.plist'
with open(path, 'rb') as f:
    data = plistlib.load(f)

gkm = data.get('GlobalKeyMap', {})
hex_entry = lambda text: {'Action': 11, 'Apply Mode': 0, 'Escaping': 2, 'Text': text, 'Version': 2}

# add
gkm['<iterm-key-id>'] = hex_entry('1b 5b NNN 75')

# remove
del gkm['<iterm-key-id>']

with open(path, 'wb') as f:
    plistlib.dump(data, f, fmt=plistlib.FMT_XML)
```

To convert `\e[NNNu` to hex: `\e` = `1b`, `[` = `5b`, each digit as ASCII hex, `u` = `75`.

### iTerm2 key ID format

`0x<keycode>-0x<modifier>-0x<virtualkey>`

**Modifier values:**
- `Cmd` = `0x100000`
- `Opt` = `0x80000`
- `Ctrl` = `0x40000`
- `Shift` = `0x20000`
- `Cmd+Shift` = `0x120000`
- `Opt+Shift` = `0xa0000`
- `Ctrl+Shift` = `0x60000`
- `Cmd+Shift+Numpad` = `0x320000` (Cmd 0x100000 + Shift 0x20000 + NSNumericPad 0x200000)
- `Opt+Shift+Numpad` = `0x2a0000` (Opt 0x80000 + Shift 0x20000 + NSNumericPad 0x200000)

**Numpad keys carry the NSNumericPad mask in the modifier** (`0x200000`), so a
numpad combo is the base modifier OR'd with `0x200000`.

**Keycode rules:**
- Letters with `Cmd` or `Opt` alone: use **lowercase** keycode (`h`=`0x68`, `j`=`0x6a`, `k`=`0x6b`, `u`=`0x75`)
- Letters with `Shift` (any combo): use **uppercase** keycode (`H`=`0x48`, `J`=`0x4a`, `K`=`0x4b`, `U`=`0x55`)
- Arrow keys: `Up`=`0xf700`, `Down`=`0xf701`, `Left`=`0xf702`, `Right`=`0xf703`
- `[`=`0x5b`/`{`=`0x7b`, `]`=`0x5d`/`}`=`0x7d`

**Common virtualkeys:**

| Key | Keycode | Virtualkey |
|-----|---------|------------|
| `d/D` | `0x64/0x44` | `0x2` |
| `h/H` | `0x68/0x48` | `0x4` |
| `j/J` | `0x6a/0x4a` | `0x26` |
| `k/K` | `0x6b/0x4b` | `0x28` |
| `u/U` | `0x75/0x55` | `0x20` |
| `l/L` | `0x6c/0x4c` | `0x25` |
| `n/N` | `0x6e/0x4e` | `0x2d` |
| `m/M` | `0x6d/0x4d` | `0x2e` |
| `p/P` | `0x70/0x50` | `0x23` |
| `[/{` | `0x5b/0x7b` | `0x21` |
| `]/}` | `0x5d/0x7d` | `0x1e` |
| `/` | `0x2f` | `0x2c` |
| `\` | `0x5c` | `0x2a` |
| `,` | `0x2c` | `0x2b` |
| `.` | `0x2e` | `0x2f` |
| `Up` | `0xf700` | `0x7e` |
| `Down` | `0xf701` | `0x7d` |
| `Left` | `0xf702` | `0x7b` |
| `Right` | `0xf703` | `0x7c` |
| `1`–`9` | `0x31`–`0x39` | `0x12`–`0x19` |

**Numpad keys** (keycode same as digit row, virtualkey differs):

| Numpad key | Keycode | Virtualkey |
|------------|---------|------------|
| `Numpad 0` | `0x30` | `0x52` |
| `Numpad 1` | `0x31` | `0x53` |
| `Numpad 2` | `0x32` | `0x54` |
| `Numpad 3` | `0x33` | `0x55` |
| `Numpad 4` | `0x34` | `0x56` |
| `Numpad 5` | `0x35` | `0x57` |
| `Numpad 6` | `0x36` | `0x58` |
| `Numpad 7` | `0x37` | `0x59` |
| `Numpad 8` | `0x38` | `0x5b` |
| `Numpad 9` | `0x39` | `0x5c` |
| `Numpad *` | `0x2a` | `0x43` |

**Keycode is the ASCII character the key produces**, not the physical keycode: `*` prints
ASCII `0x2a`, so its keycode is `0x2a` (confirmed by recording in the iTerm2 GUI).
Digits append: `Numpad 7` keycode = `0x37` (char `7`), etc.

Numpad example: `Cmd+Shift+Numpad7` → id `0x37-0x320000-0x59`;
`Cmd+Shift+Numpad*` → id `0x2a-0x320000-0x43`.

**IMPORTANT:** `~/.qwert/config/iterm2/com.googlecode.iterm2.plist` is the source of truth.

- iTerm2 reads from `~/.qwert/config/iterm2/` on startup
- On exit, it syncs `~/.qwert/config/iterm2/` → `~/Library/Preferences/`

The correct flow:
1. Edit `~/.qwert/config/iterm2/com.googlecode.iterm2.plist`
2. **Verify in the same Python process** (read the file back immediately after writing)
3. Close and reopen iTerm2 to apply

**Critical:** always write AND verify in the same Python invocation. If you verify in a
separate run, iTerm2 may have already overwritten the file with its in-memory state between
the two runs, giving a false negative.

Never edit `~/Library/Preferences/com.googlecode.iterm2.plist` — it gets overwritten on close.

Confirm with `cat -v` after reopening.

### 8. Add the binding in tmux

Choose the right file under `~/.qwert/config/tmux/config/mappings/`:
- `panes.conf` → pane actions
- `windows.conf` → window actions
- `basic.conf` → general/misc

```tmux
set -s user-keys[N] "\e[NNNu"
bind -n UserN <action>
```

Reload:
```
tmux source ~/.qwert/config/tmux/tmux.conf
```

#### Pane MOVE vs SWAP, and layout TOGGLE (numpad diagonals)

Distinct from `swap-pane`, moving a pane uses `join-pane` against a neighbor.
Works on N-pane windows — the neighbor is chosen by geometry (for 7/9 prefer the
pane above, for 3/1 prefer the one to the left, then nearest):

- `~/.qwert/config/tmux/bin/move-pane-dir.sh <pane_id> <7|9|3|1>` — join relative to neighbor:
  - `7` = left of neighbor (`-b -h`), `9` = right of neighbor (`-h`),
    `3` = below neighbor (`-v`), `1` = above neighbor (`-b -v`)
- `~/.qwert/config/tmux/bin/toggle-pane-layout.sh <pane_id>` — circular ↕/↔ toggle
  against the nearest neighbor (same column → join `-h`, else join `-v`)

Always pass the explicit pane id as `#{pane_id}` from the binding — never `-t '{up-of}'`
from a raw shell (it resolves against the wrong session when run detached).

Current bindings (panes.conf):
```
set -s user-keys[77] "\e[185u"   # Opt+Shift+Numpad7  → move left-of sibling
set -s user-keys[78] "\e[186u"   # Opt+Shift+Numpad9  → move right-of sibling
set -s user-keys[79] "\e[187u"   # Opt+Shift+Numpad3  → move below sibling
set -s user-keys[80] "\e[188u"   # Opt+Shift+Numpad1  → move above sibling
set -s user-keys[81] "\e[189u"   # Opt+Shift+Numpad*  → toggle layout ↕/↔
```

### 9. Update the helpers (tmux only)

Update all three files:
- `~/.qwert/config/tmux/bin/help-panes.sh` → pane shortcuts
- `~/.qwert/config/tmux/bin/help-windows.sh` → window shortcuts
- `~/.qwert/config/tmux/bin/help-fzf.sh` → both (fzf searchable list)

### 10. Commit and push

**MANDATORY RULE: always push immediately after every commit in `~/.qwert`. Never leave commits unpushed.**

```
cd ~/.qwert
git add <changed files>
git commit -m "feat: <description>"
git push
```
