---
name: wayfinder
description: Plan a chunk of work too large for one agent session as a shared map of decision tickets on the issue tracker, then resolve those tickets one at a time until the route to the destination is clear.
disable-model-invocation: true
---

A loose idea has shown up. It is too large for one agent session and surrounded by fog: the route from where you stand to the **destination** cannot be seen yet. Wayfinding means finding that route, not rushing at the destination. This skill draws the route as a **shared map** on the repo's issue tracker, then works through its **decision tickets** (questions whose answer is a decision, not a slice of a build) one by one until the route is clear.

Each effort has its own destination, and naming it is the first step of charting because it shapes every ticket. It could be a spec to hand over and refine, a decision to lock before planning begins, or a change made in place such as a data-structure migration. The map does not care about the domain: engineering work, course content, anything with this shape.

## Plan, don't do

By default wayfinder **plans**. Every ticket resolves a decision, and the map is finished when the route is clear and nothing is left to decide before someone goes and does the work. The urge to simply do the work usually means you have reached the edge of the map and it is time to hand off. An effort may override this in its **Notes** and pull execution into the map, but without that, produce decisions, not deliverables.

## Refer by name

Each map and ticket is an issue, so each has a **name**: its title. Wherever a human reads (narration, the map's Decisions-so-far), use that name, never a bare id, number, or slug. A string of `#42, #43, #44` is unreadable; names can be scanned. The id and the URL are still there, since a name wraps its link, but they live _inside_ the name and never replace it.

## The Map

The map is one issue on this repo's issue tracker, labelled `wayfinder:map`, and it is the canonical artifact. Its tickets are child issues of the map.

The map is an **index**, not a store. It lists the decisions already made and points to the tickets holding their detail. A decision lives in exactly one place, its ticket, so the map never repeats it: it gives a gist and a link.

**How the map, its child tickets, blocking links, and frontier queries are stored depends on the tracker.** You should have been given the issue tracker. If not, tell the user to run `/br4zz4:setup-repo`. Read the "Wayfinding operations" section of the tracker doc to learn how _this_ repo expresses them. With no tracker provided, fall back to the local-markdown tracker.

### The map body

The map shows the whole effort at low resolution and is loaded once per session. Open tickets are **not** listed in it: they are open child issues, found by query.

```markdown
## Destination

<what arriving at the end of this map looks like: the spec, decision, or change this effort is heading toward. One or two lines; each session orients on it before picking a ticket.>

## Notes

<the domain; skills every session should consult; standing preferences for this effort>

## Decisions so far

<!-- the index: one line per closed ticket, enough to judge relevance, then follow the link for the detail the ticket holds -->

- [<closed ticket title>](link): <one-line gist of the answer>

## Not yet specified

<!-- see "Fog of war": in-scope fog that cannot be ticketed yet; moves out as the frontier advances -->

## Out of scope

<!-- see "Out of scope": work ruled beyond the destination; closed, never moves out -->
```

### Tickets

Every ticket is a **child issue** of the map, and the tracker's issue id is its identity. Its body is the question, sized for one 100K-token agent session:

```markdown
## Question

<the decision or investigation this ticket resolves>
```

Each ticket has a `wayfinder:<type>` label, one of `research`, `prototype`, `grilling`, `task` (see [Ticket Types](#ticket-types)).

A session **claims** a ticket by assigning it to the dev driving the map, **before** doing any work, so concurrent sessions leave it alone. That assignee _is_ the claim: an open, unassigned ticket is unclaimed.

Blocking uses the tracker's **native** dependency relationship. This matters because the tracker's own UI then draws the frontier _visually_, and a human sees what can be picked up without opening the map. Only a tracker with no native blocking falls back to a convention in the body. A ticket is **unblocked** once every ticket blocking it is closed; the **frontier** is the set of open, unblocked, unclaimed children, the edge of what is known.

The answer is not part of the body. It is recorded on resolution (see [Work through the map](#work-through-the-map)). Assets made while resolving a ticket are linked from the issue, not pasted into it.

## Ticket Types

Each ticket is either **HITL** (human in the loop, worked _with_ a human who speaks for themselves) or **AFK**, driven by the agent alone. A HITL ticket resolves only through that live exchange; the agent never plays the human's part (a grilling agent that answers its own questions has broken the rule).

- **Research** (AFK): Read documentation, third-party APIs, or local resources such as knowledge bases, to bring out a fact that a decision depends on. A subagent resolves it by calling the Skill tool with "br4zz4:research". Use it when the knowledge lives outside the current working directory.
- **Prototype** (HITL): Make the discussion more concrete by building a cheap, rough artifact to react to (an outline, a rough draft, a stub, or UI/logic code), by calling the Skill tool with "br4zz4:prototype". The prototype is linked as an asset. Use it when "how should it look" or "how should it behave" is the central question.
- **Grilling** (HITL): Conversation. This is the default. Always call the Skill tool twice, for "br4zz4:grilling" and "br4zz4:domain-modeling".
- **Task** (HITL or AFK): Manual work that has to happen before a _decision_ is possible: nothing to decide, prototype, or research, yet the discussion is stuck until it is done. Examples: signing up for a service so its API can be judged, provisioning access, moving data so its shape becomes visible. This is the only type that _does_ rather than decides, and it earns its place by unblocking a decision, not by delivering the destination. The agent works it alone when it can (AFK); otherwise it gives the human a precise checklist (HITL). It resolves when the work is finished; the answer states what was done and any resulting facts (where credentials live, new URLs, row counts) that later tickets rely on.

## Fog of war

The map is _intentionally_ incomplete: do not chart what you cannot see yet. Past the live tickets lies the **fog of war**: the faint outline of decisions and investigations you know are coming but cannot pin down, because they depend on questions still open. Resolving a ticket clears the fog ahead of it and turns whatever has become specifiable into new tickets, one at a time, until the route to the destination is clear and no tickets remain.

The map's **Not yet specified** section holds that faint outline: the suspected question and the area to revisit. It is the unexplored frontier _toward_ the destination: all of it is in scope, just not sharp enough for a ticket. Write it as loosely or as fully as your view allows; it also tells collaborators where the effort is going.

**Fog or ticket?** What matters is whether the question can be stated precisely today, _not_ whether it can be answered today.

- **Ticket** when the question is already sharp, even if it is blocked and cannot be acted on yet.
- **Not yet specified** when you cannot phrase it that sharply. Do not cut the fog into ticket-sized pieces: it is coarser than a ticket, and a single patch may become several tickets, or none, once the frontier gets there.

**Not yet specified** leaves out what is already decided (Decisions so far), what is already a live ticket, and what is out of scope (next section).

## Out of scope

Fog only ever gathers _toward_ the destination. Since the destination sets the scope, anything beyond it is **out of scope**: not fog, and not part of **Not yet specified**. It gets its own **Out of scope** section on the map, for work you have deliberately ruled out of _this_ effort. Scope, not sharpness, puts it there.

Out-of-scope work never moves out (the frontier stops at the destination). It comes back only if the destination is redrawn, and then as a new effort, not a continuation.

Ruling something out of scope is a scoping decision, not a step on the route. When an existing ticket turns out to lie past the destination (mis-scoped while charting, or exposed by a resolution), **close it** (a closed ticket is clearly off the frontier) and add one line to the **Out of scope** section: the gist and the reason, linking the closed ticket. Keep it out of **Decisions so far**, which records the route actually walked; a scope boundary is not a step on it.

## Invocation

There are two modes. In both, **never resolve more than one ticket per session**, except for research tickets.

### Chart the map

The user comes with a loose idea.

1. **Name the destination.** Call the Skill tool twice, for "br4zz4:grilling" and "br4zz4:domain-modeling", to fix what this map heads toward: the spec, decision, or change. The destination sets the scope, so settle it first.
2. **Map the frontier.** Grill once more, this time **breadth-first**: spread across the whole space instead of digging into one thread, and surface the open decisions and the first steps that can be taken now. **If no fog appears** (the route is already clear and the whole journey fits one session), no map is needed. Stop and ask the user how to proceed.
3. **Create the map** (label `wayfinder:map`) with Destination and Notes filled in, Decisions-so-far empty, and the fog sketched under **Not yet specified**.
4. **Create the tickets you can already specify** as child issues of the map, then wire the blocking edges in a **second pass** (issues need ids before they can refer to one another). Wiring sorts them into the frontier and the blocked; anything you cannot specify yet stays in the fog, the **Not yet specified** section.
5. **Launch the research subagents.** For every `research` ticket just created, start a subagent that calls the Skill tool with "br4zz4:research" and resolves it in parallel, saving its findings on a throwaway `research/<name>` branch with a pointer back from the ticket.
6. Stop: charting is the work of one session and resolves nothing by hand.

### Work through the map

The user invokes with a map (URL or number). A ticket is **optional**: without one, you choose the next decision, not the user.

1. Load the **map**: the low-resolution view, not every ticket body.
2. Choose the ticket. Use the one the user named; otherwise take the first frontier ticket in order. **Claim it** by assigning it to yourself before doing any work.
3. Resolve it. **Zoom in as needed**: fetch the full body of any related or closed ticket on demand, and call the Skill tool for each skill the `## Notes` block names. When unsure, call the Skill tool twice, for "br4zz4:grilling" and "br4zz4:domain-modeling".
4. Record the resolution: write the answer as a **resolution comment**, **close** the issue, then **add a context pointer** to the map's Decisions-so-far.
5. Add any tickets that surfaced (create, then wire); turn any fog the answer made specifiable into tickets, removing each such patch from **Not yet specified** so it exists only as its new ticket. If the answer shows that a ticket (this one or another) lies beyond the destination, **rule it out of scope** rather than resolving it on the route. If the decision invalidates other parts of the map, update or delete those tickets.

The user may run unblocked tickets in parallel, so expect other sessions to be editing the tracker at the same time.
