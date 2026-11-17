# Logic Prototype

One self-contained HTML page, a **shareable demo**, in which anyone can click buttons to drive a state model. Pick it when the doubt is about **business rules, state transitions, or the shape of the data**: ideas that read fine in a document yet feel wrong once real cases run through them.

Because there is a single file and nothing to install, a non-developer (designer, PM, domain expert) can open it and get a feel for the model firsthand. For that reason it is written in their vocabulary, never the code's.

## When this is the right shape

- "Will this state machine survive X happening, then Y?"
- "Can this data model actually express the situation where..."
- "I'd like to sense what the API should feel like before building it."
- Any case where someone wants to **press buttons and watch the state react**.

If the doubt is really "what should this look like", this is the wrong branch. Go to [UI.md](UI.md).

## Process

### 1. State the question

Before writing code, record which state model is being prototyped and what you want to learn from it. Put one paragraph in a visible intro at the top of the demo, not merely in a code comment. A demo that answers the wrong question is wasted effort, so spell the question out where it can be verified later, whether the user is watching live or comes back AFK.

### 2. Isolate the logic in a portable module

Place the logic that answers the question in one `<script>` block, shaped as a small, pure module that could later be moved into the real codebase. Treat the page around it as disposable; the module is the part meant to survive.

Which shape fits depends on the question:

- **A pure reducer**, `(state, action) => state`, suits discrete events acting on one state value.
- **A state machine**, with explicit states and transitions, suits cases where "which actions are allowed right now" is part of the question (say, a Rails order moving through `pending`, `paid`, `shipped`, `refunded`).
- **A few pure functions** over a plain data type suit problems with no hidden current state, only transformations.
- **A class or module with a defined method surface** suits logic that truly owns internal state over time.

Select the shape that matches the question, *not* the one that wires into a page most easily. Keep it pure: no DOM access, no `document`, no button handlers poking inside. The page calls the module, and nothing goes back the other way. That separation keeps the prototype valuable beyond itself, since once the question is settled, the proven reducer, machine, or function set can move into the real module unchanged.

### 3. Build the shareable HTML file

Use one file of plain HTML, CSS, and JS, with no framework, bundler, or server. Inline everything so it opens on double-click and still works after being emailed. Anyone must be able to run it merely by opening it.

Write it for a non-developer. All labels use **domain language** rather than code terms, so buttons and state read like the business instead of the reducer. Describe what is happening in plain words.

Arrange the page from top to bottom as follows:

1. **A title with a one-line explanation** of what this demo lets someone explore, which is the question from step 1.
2. **Current state**: all of the relevant data, displayed as a readable panel of labelled fields instead of a raw JSON dump, redrawn after every click so changes are visible. When it helps a non-developer keep up, highlight whatever just changed.
3. **Free-play buttons**: a button for each action, always enabled, so anyone can try the model in whatever order they like. Each click dispatches that action and redraws the state.
4. **Guided walkthroughs**: **scenarios**, each on its own tab. A tab opens with a short plain-language description (the setup, and what to watch for), followed by the ordered **buttons to press**. Every step is a live button: pressing it performs the action and advances to the following step. Starting a walkthrough returns to a known initial state, so each scenario plays identically every time.

Choose scenarios that expose the awkward cases, which are the ones hard to reason about on paper. Include the happy path, a tricky edge case, and an attempt at something that must be illegal.

Keep it good-looking but restrained, with clean typography, generous spacing, and a single accent colour. No animations and no gimmicks; nothing may compete with the state and the buttons.

### 4. Hand it over

Give them the file or open it for them. They will click through walkthroughs and free-play when time allows. The best moments are their reactions: "wait, that shouldn't be possible" or "huh, I thought X would behave differently". Those reveal bugs in the _idea_, which is the whole purpose. If they ask for extra actions or another scenario, add them, since prototypes evolve.

### 5. Capture the answer and the prototype

When the prototype has settled its question, write down the answer, and then preserve the prototype as the [SKILL](SKILL.md) prescribes. The mapping for logic: the proven reducer, machine, or function set moves into the real module (the decision, absorbed), while the HTML shell goes to the throwaway branch that keeps the prototype as a primary source. Being a single self-contained file, it remains easy to re-run there.

## Anti-patterns

- **No tests.** If a prototype needs tests, it has stopped being one.
- **No real database.** Keep state in memory, unless persistence is exactly what the question is about.
- **No generalising.** Skip "what if we need X later". The prototype answers one question only.
- **No fusing logic with the page.** A pure module that touches the DOM, `document`, or button handlers can no longer be lifted out. Keep the page a thin shell around a pure module.
- **No framework, bundler, or server.** The recipient double-clicks one file; a React app or dev server undermines "shareable".
- **No shipping the HTML shell.** The page exists to be clicked by hand. What deserves to live on is the logic module behind it.
