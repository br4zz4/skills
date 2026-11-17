# Phase boundaries

A **phase** is a block of work inside a session: the grilling, the implementation, the QA. The definition is loose on purpose: a phase ends the moment you think *"fine, that part is finished"*.

The **phase boundary** is the gap between two phases, and it is the only moment this decision belongs to. In the middle of a phase there is nothing to decide: either continue, or split what remains across subagents. Compacting mid-phase makes the agent lose the thread.

## The five options

| Option       | What it does                                                    |
| ------------ | --------------------------------------------------------------- |
| **Continue** | Remain in the session. No context switch whatsoever.             |
| **`/clear`** | Empty the context window and begin from nothing.                |
| **`/br4zz4:handoff`** | Write a portable markdown file and use it to seed a session anywhere. |
| **Subagent** | Give the task its own context window and receive a report.      |
| **`/compact`** | Compress this context and seed a fresh session with the summary. |

## The tree

At the boundary, go from top to bottom. The first **yes** wins.

**1. Can you continue in this session?** Two things make it a yes: the next phase needs this phase as a **primary source**, or enough of the **smart zone** remains (about 150k tokens) for the next phase to fit. Grilling → implementation is the classic yes: the implementation wants the reasoning word for word, not a summary of it. Continuing costs nothing and loses nothing, so rule it out before anything else.

**2. Is the context irrelevant to what comes next?** Is everything in this session (the exploration, the decisions, the dead ends) disposable? Then use **`/clear`**. It is the cheapest move available: it takes no time and gives back the whole window. `/clear` is not final either: the old session can still be resumed.

A wrong call here can only go one way. Clear a *relevant* context and you lose the **why** behind what you built, and reading the diff back will never return it.

**3. Do you need a handoff?** `/br4zz4:handoff` is narrow. You need it only when you are:

- switching to a **new harness** (Claude → Codex, or into OpenCode),
- moving to a **new directory** or repo,
- passing the work to a **colleague**,
- or forking a side task that you found **mid-phase** without derailing your current work.

That list is the whole clause. What `/br4zz4:handoff` buys is **portability**: a file that travels. If nothing is travelling, you do not need it.

**4. Can the task run AFK?** Is it scoped tightly enough to run while you are away from the keyboard, with no steering? Then give it to a **subagent** and leave this session untouched. Automated review is the standard case: the agent reads the diff and reports, and you are not needed meanwhile.

**5. Otherwise, `/compact`.** The context is relevant, the harness and directory are the same, and you need to stay in the loop: the tree ends up here, and often. Give it an instruction (`/compact we're going to QA this area`) so the summary keeps what the next phase needs.

`/compact` is the **default, not the first thing to reach for**. It sits at the bottom because the four questions above it are all cheaper or more precise. When people begin here, the typical failure is a fresh session that is confidently wrong about a decision the summary flattened.

## Primary and secondary sources

Every move except **Continue** turns a **primary source** into a **secondary source**: the session as it happened is replaced by a summary of it. The trade always has the same shape:

| Source                            | Information | Noise | Room to move |
| --------------------------------- | ----------- | ----- | ------------ |
| Primary (Continue)                | Full        | Lots  | Little       |
| Secondary (`/compact`, `/br4zz4:handoff`) | Lossy       | Less  | Lots         |

That is why question 1 comes first. You pay for the lossiness only when staying costs more than it saves.

## These are judgement calls

The questions are not objective: each carries some taste, and the same boundary can go either way on two different days. The value lies in asking them **in order**, at the boundary and not halfway through the work.
