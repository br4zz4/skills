---
name: handoff
description: Condense the running conversation into a handoff document that a fresh agent can pick up and continue from.
argument-hint: "What will the next session focus on?"
disable-model-invocation: true
---

Produce a handoff document that summarises this conversation, so a new agent can carry on without re-reading it. Write the file into the operating system's temporary directory, never into the current workspace.

Add a "suggested skills" section that lists the skills the next agent should load through the Skill tool (for example `br4zz4:tdd` or `br4zz4:verify`).

Anything already recorded elsewhere (specs, plans, ADRs, issues, commits, diffs) stays out of the document. Point to it with a path or URL.

Strip every secret and piece of personal data: API keys, passwords, tokens, personally identifiable information.

When the user supplied arguments, read them as the focus of the next session and shape the document around that focus.
