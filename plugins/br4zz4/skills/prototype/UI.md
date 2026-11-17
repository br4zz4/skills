# UI Prototype

Build **several radically different UI variations** on one route, selectable from a floating bar at the bottom of the screen. The user flips between variants in the browser, chooses one (or mixes parts of several), and discards the others.

When the doubt is about logic or state instead of appearance, this is the wrong branch. See [LOGIC.md](LOGIC.md).

## When this is the right shape

- "How should this page look?"
- "Let me see a few options for this dashboard before I commit to one."
- "Try a different layout for the settings screen."
- Whenever the user would otherwise lose a day choosing between three fuzzy mockups imagined in their head.

## Two sub-shapes: strongly prefer sub-shape A

Judging a UI prototype is much easier when it **sits against the rest of the app**, with the real header, real sidebar, real data, and real density. A throwaway route on its own is a vacuum in which every variant looks fine. Whenever some plausible existing page could host the variants, use sub-shape A. Resort to sub-shape B only if the prototype truly lacks a nearby home.

### Sub-shape A: change to an existing page (preferred)

The route is already there. Variants render **on that same route**, chosen by a `?variant=` URL search param. Existing data loading, params, and auth stay untouched, and only the rendering swaps. This is the default, so take it unless a concrete reason says otherwise.

If the thing has no page yet but *belongs naturally inside one* (an extra section on the dashboard, a fresh card on the settings screen, one more step in a flow that already exists), that is still sub-shape A. Mount the variants within the host page.

### Sub-shape B: a new page (last resort)

Take this path only if the thing genuinely has no existing page to live in, such as a wholly new top-level surface or a flow that can't be embedded anywhere reasonable.

Make a **throwaway route** following the project's existing routing convention, without inventing a new top-level layout. Name it so it is plainly a prototype (put the word `prototype` in the path or filename). The `?variant=` pattern stays the same.

Before settling on sub-shape B, verify again: is there honestly no existing page that could carry this? A bare route conceals design problems that a populated one would reveal.

Either way, the floating bottom bar works identically.

## Process

### 1. State the question and pick N

Start with **3 variants**. Past 5, variants stop being radically different and become noise, so that is the ceiling.

Put the plan in one line, either where the prototype lives or in a comment at the top of the file:

> "Three variants of the orders index, switchable via `?variant=`, on the existing `/orders` route."

It holds up whether or not the user is available to push back.

### 2. Generate radically different variants

Draft each variant against these constraints:

- The page's purpose and the data it can reach.
- The project's component and styling system (TailwindCSS, ViewComponent, shadcn, MUI, plain CSS, or whatever is in use).
- A clear exported component name such as `VariantA`, `VariantB`, `VariantC`.

Variants have to be **structurally different**: another layout, another information hierarchy, another main affordance, and not just another palette. Three lightly modified card grids are wallpaper, not a UI prototype. When two drafts end up too close, redo one and add explicit guidance like "do not use a card grid".

### 3. Wire them together

Put a single switcher component on the route:

```tsx
// pseudo-code; adapt it to the project's framework
const current = searchParams.get('variant') ?? 'A';
const Variant = { A: VariantA, B: VariantB, C: VariantC }[current];
return (
  <>
    <Variant {...data} />
    <PrototypeSwitcher variants={['A', 'B', 'C']} current={current} />
  </>
);
```

With sub-shape A (existing page), keep all existing data loading above the switcher so that only the rendered subtree differs by variant.

With sub-shape B (new page), the throwaway route at `/prototype/<name>` mounts the same switcher.

### 4. Build the floating switcher

Make a small bar with a fixed position at the bottom centre of the screen, made of three parts:

- **Left arrow**: goes to the previous variant, wrapping around.
- **Variant label**: shows the active variant's key, plus its exported name when it has one, for example `B (Sidebar layout)`.
- **Right arrow**: goes forward, wrapping around.

Behaviour:

- A click on an arrow updates the URL search param through the framework's router (`router.replace` in Next, `navigate` in React Router, and so on), which keeps the variant shareable and stable across reloads.
- Keyboard: `←` and `→` cycle too, except while an `<input>`, `<textarea>`, or `[contenteditable]` has focus.
- Make it stand apart visually from the page (a high-contrast pill with a light shadow, for instance) so it clearly isn't part of the design being judged.
- Exclude it from production builds by gating on `process.env.NODE_ENV !== 'production'` or an equivalent check (`Rails.env.production?` server-side), so a stray prototype merge can't put the bar in front of users.

Keep the switcher in one shared component that both sub-shapes reuse, placed where the project keeps shared UI.

### 5. Hand it over

Give the user the URL and the `?variant=` keys. They will page through when they have time. The feedback that matters most tends to be **"the header from B, with the sidebar from C"**, because that is the design they actually want.

### 6. Capture the answer and clean up

After a variant wins, record the answer (which one, and why), then preserve the prototype as the [SKILL](SKILL.md) prescribes. Fold the winner into the real code and move everything else to the throwaway branch, away from main:

- **Sub-shape A**: fold the winner into the existing page, and take the losing variants and the switcher out of main.
- **Sub-shape B**: promote the winning variant to a real route, and take the throwaway route and the switcher out of main.

The complete set of variants is the primary source, so it goes to the throwaway branch and not the trash. Left on main, variant components and the switcher decay fast and mislead the next reader.

## Anti-patterns

- **Variants distinguished only by colour or copy.** That is a tweak and not a prototype. Real variants disagree about structure.
- **Too much code shared across variants.** A common `<Header>` is acceptable, but a common `<Layout>` defeats the exercise, since each variant needs freedom to discard the layout.
- **Variants wired to real mutations.** Read-only prototypes are fine. If a variant must write, route it to a stub, because the question is "what should this look like" and not "does the backend work".
- **Promoting the prototype directly into production.** Prototype constraints (no tests, minimal error handling) shaped that code, so rewrite it properly when you fold it in.
