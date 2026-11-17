---
name: prototype
description: Create a disposable prototype that answers a design question. Use when the user wants to sanity-check that a state model or business logic feels right, or to explore how a UI could look.
---

# Prototype

A prototype is **disposable code whose purpose is answering a question**, and the question dictates its form.

## Pick a branch

Work out which question is being asked, from the user's prompt and the code around it, or ask directly if the user is available:

- **Does this logic or state model feel right?** → [LOGIC.md](LOGIC.md). Build one shareable HTML file with free-play buttons and tabbed guided walkthroughs. It drives the state machine through cases that are awkward to reason about on paper, and a non-developer can operate it.
- **"What should this look like?"** → [UI.md](UI.md). Build several radically different variations of a UI on one route, switched with a URL search param and a floating bar at the bottom.

The artifacts of the two branches differ greatly, so a wrong pick wastes the whole prototype. If the question is truly ambiguous and the user can't be asked, choose the branch that fits the nearby code (a backend module points to logic; a page or component points to UI) and state that assumption at the head of the prototype.

## Shared rules

1. **Disposable from the first minute, and plainly labelled.** Keep the prototype code near where it would really be used (beside the module or page it explores) so its context is obvious, yet name it so that a casual reader knows it is not production. For throwaway UI routes, follow whichever routing convention the project already has instead of creating a new top-level structure (in Rails, reuse the existing namespaces in `config/routes.rb`).
2. **Trivial to run.** A UI prototype launches with a single command from the project's task runner, such as `bin/dev`, `make prototype`, `python <path>`, or `bun <path>`. A logic demo is one HTML file opened by double-click. Starting either takes no thinking.
3. **No persistence by default.** Hold state in memory. Persistence may be the very thing under test, so the prototype shouldn't lean on it. If the question explicitly involves a database, use a scratch DB or local file whose name screams "PROTOTYPE, wipe me".
4. **Skip the polish.** No tests, no error handling beyond what keeps the prototype _runnable_, no abstractions. Learning something quickly is the goal.
5. **Make state visible.** After every action (logic) or variant switch (UI), print or render all the relevant state so the user can tell what changed.
6. **Capture it at the end.** Fold each validated decision into the real code, then keep the prototype itself as a **primary source**. Commit it onto a throwaway branch that stays off main, and put a context pointer to that branch on the implementation issue. Record the answer as well (the verdict, and the question it settled) in the issue or a commit. Main retains only the validated decision.
