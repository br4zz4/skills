---
name: research
description: Answer a question by reading high-trust primary sources, then save the findings as a Markdown note in the repo. Use when the user asks for a topic to be researched, for docs or API facts to be collected, or for reading legwork to be handed to a background agent.
---

Launch a **background agent** for the reading, so this session can carry on with other work in the meantime.

The agent must:

1. Answer the question from **primary sources** only: official docs, source code, specifications, first-party APIs. A blog post summarising them does not count. Trace each claim to the place that owns it (for a Rails question, the Rails guides or the framework source; for a qwert question, the repo itself).
2. Write everything into one Markdown file, with a source cited next to every claim.
3. Put the file where the repo already stores notes of this kind and follow that convention. If no convention exists, choose a reasonable location and tell the user which one.
