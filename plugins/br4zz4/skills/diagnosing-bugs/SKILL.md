---
name: diagnosing-bugs
description: Diagnosis loop for stubborn bugs and performance regressions. Use when the user asks to "diagnose" or "debug this", or says something is broken, throwing, failing, or slow.
---

# Diagnosing Bugs

A discipline for stubborn bugs. Skip a phase only with an explicit justification.

While exploring the code, read `CONTEXT.md` when one exists, so you hold an accurate model of the modules involved, and look at the ADRs covering the area you are touching.

## Redact

Everything in this skill involves showing commands, outputs, and captured artifacts. **Redact each secret before showing it**, writing `<REDACTED>` in its place. Drive loops through environment variables so the credential stays in the environment and never appears in what you display. Captured artifacts often hold auth headers: quote only the lines that carry the signal.

If redaction leaves too little to work with, tell the user and ask for their help.

## Phase 1: Build a feedback loop

**This phase is the skill.** The rest is mechanical. A **tight** pass/fail signal (one that goes red on _this_ bug) is what finds the cause; bisection, hypothesis-testing, and instrumentation merely consume it. Without that signal, reading code for hours will not rescue you.

Put in far more effort here than feels proportionate. **Be aggressive, be inventive, never quit.**

### Ways to construct one, roughly in this order

1. **Failing test** at whichever seam reaches the bug: unit, integration, system (in Rails, a model test, a request test, or a Capybara system test).
2. **Curl / HTTP script** aimed at a running dev server.
3. **CLI invocation** with a fixture input, comparing stdout with a known-good snapshot.
4. **Headless browser script**, written with Playwright or Puppeteer, that operates the UI and checks the DOM, console output, or network traffic.
5. **Replay a captured trace.** Store a real request, payload, or event log on disk, then replay it through the code path in isolation.
6. **Throwaway harness.** Boot a minimal slice of the system (one service, stubbed dependencies) that reaches the buggy path through a single function call.
7. **Property / fuzz loop.** When the bug is "sometimes the output is wrong", feed 1000 random inputs and watch for the failure mode.
8. **Bisection harness.** For a bug that crept in between two known states (a commit, dataset, or version), script the cycle of booting at one state and checking it, which lets `git bisect run` do the searching.
9. **Differential loop.** Pass the same input through the old and new version (or two configs) and diff the outputs.
10. **HITL bash script.** The last resort. When a human has to click, direct _them_ with `scripts/hitl-loop.template.sh` so the loop stays structured, and the captured output flows back to you.

With the right feedback loop in hand, 90% of the bug is already fixed.

### Tighten the loop

A loop deserves product-level care. Once _a_ loop exists, **tighten** it:

- Can it run faster? (Cache the setup, skip unrelated initialisation, narrow the test scope.)
- Can the signal be sharper? (Assert on the exact symptom rather than "didn't crash".)
- Can it be more deterministic? (Pin the clock, seed the RNG, isolate the filesystem, freeze the network.)

A flaky 30-second loop barely beats having none; a deterministic 2-second loop is tight, and a debugging superpower.

### Non-deterministic bugs

Aim for a **higher reproduction rate** rather than a clean repro. Run the trigger 100 times, parallelise it, add stress, narrow the timing windows, inject sleeps. A bug that flakes 50% of the time can be debugged; one at 1% cannot, so keep pushing the rate up until it can.

### When you truly cannot build a loop

Stop and state it explicitly. List everything you attempted. Ask the user for: (a) access to an environment that reproduces it, (b) a redacted artifact captured from it, such as a HAR file, log dump, core dump, or screen recording with timestamps, or (c) permission to add temporary production instrumentation. Do **not** begin hypothesising while no loop exists.

### Completion criterion: a tight loop that goes red

Phase 1 ends once the loop is **tight** and **red-capable**. That means naming **one command** (a script path, a test invocation, or a curl) which you have **already executed at least once**, showing the invocation with its redacted output, and which meets every point below:

- [ ] **Red-capable**: it exercises the real bug path and asserts the **user's exact symptom**, so it can fail on this bug and pass once fixed. "Runs without erroring" does not count; it has to be able to _catch this specific bug_.
- [ ] **Deterministic**: the same verdict on every run (for flaky bugs: a pinned, high reproduction rate, as above).
- [ ] **Fast**: it finishes in seconds rather than minutes.
- [ ] **Agent-runnable**: it runs unattended, and a human takes part only via `scripts/hitl-loop.template.sh`.

Catching yourself reading code to build a theory before this command exists means **stop: leaping to a hypothesis is precisely the failure this skill exists to prevent.** Without a red-capable command, there is no Phase 2.

## Phase 2: Reproduce + minimise

Run the loop and watch it go red as the bug shows up.

Confirm each of these:

- [ ] The loop yields the failure the **user** described, and not some neighbouring failure. A wrong bug means a wrong fix.
- [ ] The failure repeats across several runs (or, for non-deterministic bugs, at a rate high enough to debug against).
- [ ] The precise symptom is on record (error text, incorrect output, measured slowness), so later phases can confirm the fix targets it.

### Minimise

With the loop red, shrink the repro to the **smallest scenario that still fails**. Cut inputs, callers, config, data, and steps **individually**, re-running the loop after each removal, and keep only what the failure depends on.

The payoff: a minimal repro narrows the hypothesis space in Phase 3 (fewer moving parts to suspect) and doubles as the clean regression test in Phase 5.

You are done when **each remaining element is load-bearing**: dropping any single one turns the loop green.

Do not continue until the bug is reproduced **and** minimised.

## Phase 3: Hypothesise

Produce **3–5 ranked hypotheses** before testing any. Generating just one anchors you on the first plausible idea.

Every hypothesis has to be **falsifiable**, meaning it states the prediction it makes.

> Write each as: "Should <X> be the cause, then altering <Y> makes the bug vanish, and altering <Z> makes it worse."

A hypothesis with no stateable prediction is a vibe: discard it or sharpen it.

**Show the ranked list to the user before you test.** Users frequently hold domain knowledge that re-ranks it at once ("we just shipped a change to #3") or know of causes already ruled out. It is a cheap checkpoint that saves a lot of time. Don't block on it; if the user is AFK, go ahead with your own ranking.

## Phase 4: Instrument

Every probe has to tie back to one particular prediction made in Phase 3. **Vary a single thing at a time.**

Preferred tools, in order:

1. **Debugger / REPL inspection** where the environment allows it. One breakpoint beats ten log lines (in Rails, `binding.irb` or `bin/rails console`).
2. **Targeted logs** at the boundaries that tell hypotheses apart.
3. Do not dump everything into the logs and grep through it afterwards.

**Mark every debug log** with a unique prefix like `[DEBUG-a4f2]`, so cleanup becomes one grep. Logs without a tag linger; tagged ones get removed.

**Perf branch.** Logs are usually the wrong tool for performance regressions. Take a baseline first (a timing harness, `performance.now()`, a profiler, or a query plan via `EXPLAIN`), then bisect. Measure before you fix.

## Phase 5: Fix + regression test

Begin with the regression test, **ahead of touching the fix**, though only if a **correct seam** exists.

A correct seam makes the test exercise the **real bug pattern** the way it occurs at the call site. When the only seam available is too shallow (a single-caller test for a bug that needs several callers, a unit test that cannot rebuild the chain that triggered it), a test there gives false confidence.

**No correct seam is itself a finding.** Record it: the architecture of the codebase is stopping the bug from being pinned down. Flag it for the next phase.

With a correct seam available:

1. Turn the minimised repro into a test at that seam, written so it fails.
2. Confirm that it fails.
3. Make the fix.
4. Confirm that it passes.
5. Run the Phase 1 feedback loop again, against the original (un-minimised) scenario.

## Phase 6: Cleanup

All of these before you declare done:

- [ ] The original repro stays quiet when you run the Phase 1 loop again
- [ ] The regression test passes (or the missing seam is documented)
- [ ] Every `[DEBUG-...]` probe is gone (`grep` for the prefix)
- [ ] Throwaway prototypes are deleted (or moved to an obviously marked debug location)
- [ ] The hypothesis that proved correct appears in the commit / PR message, so the next debugger benefits
