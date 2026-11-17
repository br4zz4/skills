---
name: wizard
description: Produce an interactive bash wizard that guides a human through steps only a human can do. Use when provisioning infrastructure, configuring credentials or CI secrets, walking through an unfamiliar third-party dashboard, or running a one-off migration or cutover. Do not use it for steps the agent can carry out itself.
---

# Wizard

A **wizard** is a bash script that leads a human through a manual procedure, one step at a time: the kind of procedure that is boring to do by hand and boring to explain to an AI over and over. It opens each URL, states exactly what to click and copy, captures the values, stores them where they belong (`.env`, GitHub secrets), asks for confirmation at every stage, and shows how many stages remain. It can configure third-party services, run a one-off migration, or move a project from one state to another (say, setting up Rails credentials for a new environment).

The pleasant UX is already solved by [TEMPLATE.md](TEMPLATE.md): progress per stage, confirmation gates, URL opening on any platform (WSL included), hidden entry of secrets, idempotent `.env` upserts, `gh secret` and `gh variable` writes, and a closing summary. **You only scope the procedure and write its stages.** The library (everything before the final `TOTAL_STAGES=1` block, whose banner and example stage you replace) is the same in every wizard, and that sameness is intentional: never edit it by hand.

By default a wizard is disposable: made for a single run, saved in a scratch path or under `scripts/`, and deleted when the job is done. Commit it only if the user wants a repeatable setup path to live in the repo.

## Process

### 1. Scope the procedure

List every manual step the human must perform and every value captured on the way. Read the repo first instead of asking from nothing:

- For setup: `.env`, `.env.example`, `.env.*`, the `README`, `docker-compose*`, framework config, and `.github/workflows/*` (each `secrets.*` or `vars.*` reference is a value the wizard has to produce).
- For a migration or transition: the current state, the target state, and the irreversible actions in between.

Next, show the user the ordered stages and the values each one produces, and ask for confirmation: they can add, remove, or reorder stages.

**Done when:** every stage is named in order, and for each captured value you know (a) where the human obtains it, (b) where it gets written (`.env`, a GitHub secret, both, or nowhere, since some stages are plain actions), and (c) whether it is secret (hidden entry) or public.

### 2. Map each stage's journey

For every stage, write the exact path a human follows: the URL to open, what to do there, where a value appears, and which variable it fills. For example: "Dashboard → Developers → API keys → Reveal test key → copy". If you are unsure of the current UI or of the exact command, say so and ask the user or check the docs: never make up steps that might not exist.

**Done when:** each stage maps to concrete instructions that a stranger could follow.

### 3. Write the wizard

Copy the script from `TEMPLATE.md` to the target path and make it executable. Swap the example stage for one `stage` per step, in dependency order. Use the library helpers: `stage`, `say`/`step`, `open_url`, `ask`/`ask_secret`, `write_env`, `set_secret`/`set_var`, `pause`/`confirm`. Set `TOTAL_STAGES` to the count of stages you wrote.

Keep to the standard the template sets: open the URL before asking for its value, use `ask_secret` for anything secret, call `write_env` for every value that must persist, call `set_secret` only for values CI really needs, and use `confirm` ahead of any irreversible action. Every `stage` clears the screen so only the current step shows: keep each stage to one focused task so nothing the human needs scrolls out of view. Leave the library part of the file alone.

### 4. Verify and hand off

- Run `bash -n <script>`, and `shellcheck` when it is installed.
- Run `chmod +x <script>`.
- Do not run it end to end yourself: it opens browsers and waits for human input. Trace it statically instead: each value from step 1 is captured and ends up where step 1 said, and each `set_secret` name matches a `secrets.*` reference in CI exactly.
- Tell the user how to launch it. If it is a repeatable setup path, commit it and link it from the README, so the next person runs the script rather than asking an AI.
