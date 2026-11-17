---
name: grilling
description: Interrogate the user without letting up about a plan, decision, or idea. Use when the user wants their thinking stress-tested, or says anything that sounds like "grill me".
---

Keep interviewing the user until you both share the same understanding. Model the conversation as a **design tree**: each decision opens up further decisions that depend on it.

Walk the tree in **rounds**. The **frontier** is the set of decisions whose prerequisites are already settled, meaning the questions you can ask _right now_ without guessing at answers you have not heard. Put the whole frontier to the user in a single round, numbering each question and attaching your recommended answer. Then stop and wait for their replies before starting the next round.

Lay a round out like this:

```
❓ **Q1** - **<question title>**: <question body, may run several paragraphs and include multiple choices>

➡️ <your recommended answer>

---

❓ **Q2** - **<question title>**: <question body, may run several paragraphs and include multiple choices>

➡️ <your recommended answer>
```

Every set of answers reshapes the tree: settled decisions move the frontier outward and unlock questions that were waiting on them. Recompute the frontier, then ask the next round. If a question hinges on another one that is still open in the current round, it belongs to a _later_ round.

Looking up _facts_ is your job, not the user's. If a frontier question needs something from the environment (the filesystem, installed tools, the Rails schema, qwert state), send a sub-agent to find it rather than asking the user for what you can look up. Do not stall on it: an exploration in flight is an unsettled prerequisite, so only the questions downstream of it wait for the report, and the rest of the frontier goes out now. The _decisions_ belong to the user: present each one and wait.

You are finished when the frontier is empty, every branch has been visited, and nothing is left silently assumed. Do not act on the outcome until the user confirms that you have reached a shared understanding.
