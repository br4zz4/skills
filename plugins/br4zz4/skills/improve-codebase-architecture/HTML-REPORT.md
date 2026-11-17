# HTML Report Format

The architecture review is delivered as one self-contained HTML file placed in the OS temp directory. Tailwind and Mermaid are both loaded from CDNs. Mermaid is dependable for graph-shaped diagrams; hand-built divs and inline SVG cover the more editorial visuals (mass diagrams, cross-sections). Combine them: relying on Mermaid for everything makes the report look generic.

## Scaffold

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Architecture review for {{repo name}}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script type="module">
      import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
      mermaid.initialize({ startOnLoad: true, theme: "neutral", securityLevel: "loose" });
    </script>
    <style>
      .seam { stroke-dasharray: 4 4; }
      .leak { stroke: #dc2626; }
      .deep { background: linear-gradient(135deg, #0f172a, #1e293b); }
    </style>
  </head>
  <body class="bg-stone-50 text-slate-900 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header>...</header>
      <section id="candidates" class="space-y-10">...</section>
      <section id="top-recommendation">...</section>
    </main>
  </body>
</html>
```

The `<style>` block is the small custom layer for what Tailwind does not cover cleanly: dashed seam lines, leak strokes, the dark deep-module background.

## Header

Show the repo name, the date, and a compact legend: solid box = module, dashed line = seam, red arrow = leakage, thick dark box = deep module. Skip any introductory paragraph and go directly to the candidates.

## Candidate card

Diagrams do the heavy lifting. Prose stays sparse and plain, using the glossary terms (from the `br4zz4:codebase-design` skill) without fuss.

Every candidate is a single `<article>` holding:

- **Title**: short, naming the deepening (for example "Collapse the Order intake pipeline").
- **Badge row**: the recommendation strength (`Strong` = emerald, `Worth exploring` = amber, `Speculative` = slate) and a tag naming the dependency category (`in-process`, `local-substitutable`, `ports & adapters`, `mock`).
- **Files**: a monospaced list, `font-mono text-sm`.
- **Before / After diagram**: the centrepiece, in two side-by-side columns. Patterns are below.
- **Problem**: a single sentence on what hurts.
- **Solution**: a single sentence on what changes.
- **Wins**: bullets of six words or fewer, such as "Tests hit one interface", "Pricing logic stops leaking", "Delete 4 shallow wrappers".
- **ADR callout** (when relevant): one line in an amber-tinted box.

Never write paragraphs of explanation. If a diagram needs a paragraph before it makes sense, redraw it.

## Diagram patterns

Choose the pattern that suits the candidate and vary them. Not every diagram should look alike; variety is part of the point.

### Mermaid graph (the workhorse for dependencies and call flow)

Reach for a Mermaid `flowchart` or `graph` when the message is "X calls Y calls Z, and look at the mess." Wrap it in a Tailwind-styled card so it does not look dropped in from elsewhere. Use classDef to paint leakage edges red and the deep module dark. Sequence diagrams suit "before: 6 round-trips; after: 1."

```html
<div class="rounded-lg border border-slate-200 bg-white p-4">
  <pre class="mermaid">
    flowchart LR
      A[CheckoutController] --> B[OrderValidator]
      B --> C[OrderRepo]
      C -.leak.-> D[PricingClient]
      classDef leak stroke:#dc2626,stroke-width:2px;
      class C,D leak
  </pre>
</div>
```

### Hand-built boxes-and-arrows (when Mermaid's layout fights you)

Draw modules as `<div>`s with borders and labels, and arrows as inline SVG `<line>` or `<path>` elements absolutely positioned over a relative container. Use this when the "after" picture should read as one thick-bordered deep module with greyed-out internals, which Mermaid cannot render with the right weight.

### Cross-section (good for layered shallowness)

Stack horizontal bands (`h-12 border-l-4`) to represent the layers a call travels through. Before: six thin layers that each do nothing. After: one thick band labelled with the consolidated responsibility.

### Mass diagram (good for "interface as wide as implementation")

Give each module two rectangles, one for interface surface area and one for implementation. Before: the interface rectangle is almost as tall as the implementation rectangle (shallow). After: the interface rectangle is short and the implementation rectangle is tall (deep).

### Call-graph collapse

Before: a tree of function calls drawn as nested boxes. After: that same tree folded into one box, with the calls that are now internal shown faded inside it.

## Style guidance

- Aim for editorial, not corporate dashboard. Leave generous whitespace. Serif headings are optional (`font-serif` pairs well with stone/slate).
- Use colour sparingly: one accent (emerald or indigo), red for leakage, amber for warnings.
- Hold diagrams to roughly 320px tall so before and after sit comfortably side by side with no scrolling.
- Set module labels inside diagrams in `text-xs uppercase tracking-wider` so they look schematic rather than like UI.
- The only scripts allowed are the Tailwind CDN and the Mermaid ESM import. Otherwise the report stays static: no app code, and no interactivity beyond Mermaid's own rendering.

## Top recommendation section

A single larger card with the candidate's name, one sentence of rationale, and an anchor link to its card. Nothing more.

## Tone

Plain, concise English, with architectural nouns and verbs taken straight from the `br4zz4:codebase-design` skill. Brevity is no excuse for drifting from them.

**Always use these terms:** module, interface, implementation, depth, deep, shallow, seam, adapter, leverage, locality.

**Never substitute:** component, service, unit (for module) · API, signature (for interface) · boundary (for seam) · layer, wrapper (for module, when module is what you mean).

**Phrasings that fit the style:**

- "Order intake module is shallow: its interface nearly mirrors the implementation."
- "Pricing leaks across the seam."
- "Deepen: one interface, one place to test."
- "Two adapters justify the seam: HTTP in production, in-memory in tests."

**Wins bullets** state the gain in glossary terms: *"locality: bugs concentrate in one module"*, *"leverage: one interface, N call sites"*, *"interface shrinks; implementation absorbs the wrappers"*. Avoid *"easier to maintain"* or *"cleaner code"*; those phrases are not in the glossary and do not earn a place.

Do not hedge or clear your throat with "it's worth noting that…". A sentence that could be a bullet should be one. A bullet that could be cut should go. When a term is missing from the `br4zz4:codebase-design` glossary, pick one that is there before coining a new one.
