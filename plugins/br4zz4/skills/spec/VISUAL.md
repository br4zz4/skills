# Visual companion (br4zz4:spec)

Load only when the user accepts the visual option in Phase 3.


Some decisions are understood better seen than read. When a question is genuinely visual — UI layout/wireframe, architecture diagram, side-by-side comparison of two directions, spatial/flow relationships — offer the browser companion instead of describing options in text. Skip it for conceptual, requirements, or tradeoff questions: those stay in the terminal.

**When to reach for it:** "which of these layouts feels right?" is visual. "What kind of screen do you want?" is conceptual — stay in the terminal. Decide per question, not per session, and always offer it — never force it.

**Start the server** (after the user agrees):

```bash
.commons/shell/tasks/visual/start-server.sh --project-dir "$HOME/workspace/.worktrees" --open
```

It returns JSON with `url`, `port`, `screen_dir`, and `state_dir`. Save `screen_dir` and `state_dir`. Give the user the **complete** `url` (it carries a session key — never strip the query string). Point `--project-dir` at a path outside any repo (e.g. `$HOME/workspace/.worktrees`) so mockups never pollute the project — the server writes under `<project-dir>/.oporpino-visual/`.

**The loop:**

1. Write an HTML **content fragment** to a fresh file in `screen_dir` (semantic name: `layout.html`, `visual-style.html`). Never reuse a filename; the server serves the newest file and wraps your fragment in the frame template. Use your file tool — never `cat`/heredoc.
2. Tell the user what's on screen in one line, remind them of the URL, and ask them to look and respond in the terminal (clicking to select is optional). End your turn.
3. Next turn: read `$STATE_DIR/events` (JSONL of their clicks) if it exists, and merge it with their terminal reply. The terminal text is primary; events add structure.
4. Iterate (`layout-v2.html`) until the choice is validated; only then move on.
5. When the next question is not visual, push a `waiting.html` fragment ("Continuing in terminal…") so a resolved choice isn't left on screen.

**Fragment shape** — write just the inner content; the frame provides CSS and interactivity:

```html
<h2>Which layout works better?</h2>
<p class="subtitle">Consider readability and hierarchy</p>
<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content"><h3>Single column</h3><p>Focused reading</p></div>
  </div>
  <div class="option" data-choice="b" onclick="toggleSelect(this)">
    <div class="letter">B</div>
    <div class="content"><h3>Two column</h3><p>Sidebar + content</p></div>
  </div>
</div>
```

Available classes: `.options` (add `data-multiselect` for multi), `.cards`, `.mockup` / `.mockup-header` / `.mockup-body`, `.split` (side-by-side), `.pros-cons`, wireframe blocks (`.mock-nav`, `.mock-sidebar`, `.mock-content`, `.mock-button`, `.mock-input`, `.placeholder`), and typography (`h2`, `h3`, `.subtitle`, `.section`, `.label`). Keep mockups simple; 2–4 options per screen; explain the question on every page.

**Stop the server** when the visual part is done:

```bash
.commons/shell/tasks/visual/stop-server.sh "$SESSION_DIR"
```
