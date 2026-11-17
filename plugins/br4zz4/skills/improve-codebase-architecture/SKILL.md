---
name: improve-codebase-architecture
description: Scan a codebase for deepening opportunities, show them in a visual HTML report, then grill through whichever one the user picks.
disable-model-invocation: true
---

# Improve Codebase Architecture

Find architectural friction and propose **deepening opportunities**: refactors that convert shallow modules into deep ones. The goals are testability and AI-navigability.

This command draws on the project's domain model and on a shared design vocabulary:

- Invoke the Skill tool with "br4zz4:codebase-design" to load the architecture vocabulary (**module**, **interface**, **depth**, **seam**, **adapter**, **leverage**, **locality**) and its principles (the deletion test, "the interface is the test surface", "one adapter = hypothetical seam, two = real"). Use these exact terms in every suggestion, and never slide into "component," "service," "API," or "boundary."
- The domain language in `CONTEXT.md` supplies names for good seams; ADRs in `docs/adr/` capture decisions this command must not reopen without cause.

## Process

### 1. Explore

**Decide scope before scanning: YAGNI.** Deepening pays off by easing future changes, so give extra weight to code that changed recently. Choose *where* to look before you look:

- If the user named a direction (a module, a subsystem, a pain point), follow it and skip the inference below.
- Otherwise, read a long stretch of commit history (`git log --oneline`) to find hot spots, meaning the files and areas that keep recurring, and let those paths draw your attention first. If changes are scattered with no clear hot spot, cast a wider net.

Start by reading the domain glossary (`CONTEXT.md`) and any ADRs near the area you are touching.

Then launch a sub-agent to walk the codebase. Skip rigid heuristics; explore organically and record where you hit friction:

- Where does grasping one concept force you to hop between many small modules?
- Which modules are **shallow**, their interface almost as intricate as their implementation?
- Where were pure functions extracted only for testability, while the real bugs hide in how they are called (no **locality**)?
- Where do tightly coupled modules leak across their seams?
- Which parts are untested, or awkward to test through their present interface?

Run the **deletion test** on anything you suspect is shallow: would removing it concentrate complexity, or merely relocate it? An answer of "concentrates" is the signal you are after.

### 2. Present candidates as an HTML report

Write one self-contained HTML file into the OS temp directory so nothing is added to the repo. Resolve that directory from `$TMPDIR`, falling back to `/tmp` (or `%TEMP%` on Windows), and save to `<tmpdir>/architecture-review-<timestamp>.html` so every run produces a new file. Open it for the user (`xdg-open <path>` on Linux, `open <path>` on macOS, `start <path>` on Windows) and tell them the absolute path.

The report styles itself with **Tailwind via CDN** and draws diagrams with **Mermaid via CDN** wherever a graph, flow, or sequence conveys the structure reliably. Blend Mermaid with hand-made CSS/SVG visuals: Mermaid for graph-shaped relationships (call graphs, dependencies, sequences), and hand-built divs/SVG for more editorial pictures (mass diagrams, cross-sections, collapse animations). Every candidate gets a **before/after visualisation**. Favour visuals.

Render each candidate as a card containing:

- **Files**: the files or modules involved
- **Problem**: why the current architecture creates friction
- **Solution**: a plain-English account of what would change
- **Benefits**: described through locality and leverage, plus how the tests would get better
- **Before / After diagram**: side by side, custom-drawn, showing the shallowness and then the deepening
- **Recommendation strength**: `Strong`, `Worth exploring`, or `Speculative`, shown as a badge

Close the report with a **Top recommendation** section naming the candidate you would tackle first and the reason.

**Name domain things with `CONTEXT.md` vocabulary and architecture things with the `br4zz4:codebase-design` vocabulary.** If `CONTEXT.md` defines "Order," write "the Order intake module," not "the FooBarHandler" and not "the Order service."

**ADR conflicts**: when a candidate contradicts an existing ADR, surface it only if the friction justifies reopening that ADR. Flag it clearly on the card (for example a warning callout: _"contradicts ADR-0007, but worth reopening because…"_). Do not enumerate every theoretical refactor that an ADR rules out.

The full HTML scaffold, diagram patterns, and styling guidance are in [HTML-REPORT.md](HTML-REPORT.md).

Do NOT propose interfaces yet. Once the file is written, ask the user: "Which of these would you like to explore?"

### 3. Grilling loop

When the user picks a candidate, invoke the Skill tool with "br4zz4:grilling" and walk the decision tree together: constraints, dependencies, the shape of the deepened module, what sits behind the seam, which tests survive.

Side effects occur inline as decisions crystallise; invoke the Skill tool with "br4zz4:domain-modeling" to keep the domain model current throughout:

- **A deepened module named after a concept missing from `CONTEXT.md`?** Add the term to `CONTEXT.md`, creating the file lazily if absent.
- **A fuzzy term sharpened mid-conversation?** Update `CONTEXT.md` on the spot.
- **User rejects the candidate for a load-bearing reason?** Offer an ADR, phrased as: _"Want me to record this as an ADR so future architecture reviews don't re-suggest it?"_ Offer it only when a future explorer would truly need the reason to avoid repeating the suggestion; skip ephemeral reasons ("not worth it right now") and self-evident ones.
- **Interested in alternative interfaces for the deepened module?** Invoke the Skill tool with "br4zz4:codebase-design" and apply its design-it-twice parallel sub-agent pattern.
