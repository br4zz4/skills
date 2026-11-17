# Design It Twice

Use this parallel sub-agent pattern when the user wants to explore alternative interfaces for a deepening candidate they picked. It follows "Design It Twice" (Ousterhout): the first idea you have is unlikely to be the best.

It uses the vocabulary of [SKILL.md](SKILL.md): **module**, **interface**, **seam**, **adapter**, **leverage**.

## Process

### 1. Frame the problem space

Before launching any sub-agent, write an explanation of the problem space for the user, covering the chosen candidate:

- The constraints a new interface would have to meet
- The dependencies it would use, and the category of each (see [DEEPENING.md](DEEPENING.md))
- A rough illustrative code sketch that makes the constraints concrete; it is not a proposal

Show this to the user and go straight to Step 2. While the sub-agents work in parallel, the user reads and thinks.

### 2. Launch sub-agents

Start 3 or more sub-agents in parallel. Each one must produce a **radically different** interface for the deepened module.

Give each sub-agent its own technical brief (file paths, coupling details, the dependency category from [DEEPENING.md](DEEPENING.md), what lies behind the seam). This brief is separate from the user-facing problem-space explanation of Step 1. Set a different design constraint for each agent:

- Agent 1: "Shrink the interface: 1–3 entry points at most. Get the most leverage from each entry point."
- Agent 2: "Maximise flexibility: cover many use cases and allow extension."
- Agent 3: "Serve the most frequent caller best: the default path should need almost no effort."
- Agent 4 (when it applies): "Build around ports and adapters for dependencies that cross the seam."

Put the vocabulary of [SKILL.md](SKILL.md) and of CONTEXT.md in every brief, so each sub-agent names things consistently with the architecture language and with the project's domain language.

Each sub-agent returns:

1. The interface (types, methods, params, plus invariants, ordering, error modes)
2. A usage example showing how callers use it
3. What the implementation hides behind the seam
4. The dependency strategy and adapters (see [DEEPENING.md](DEEPENING.md))
5. Trade-offs: where leverage is high and where it is thin

### 3. Present and compare

Show the designs one after another so the user can take each in, then compare them in prose. Contrast them on **depth** (leverage at the interface), **locality** (where change gathers), and **seam placement**.

After the comparison, give your own recommendation: say which design you find strongest and why. If parts of different designs fit together well, suggest a hybrid. Take a position: the user wants a firm opinion, not a menu.
