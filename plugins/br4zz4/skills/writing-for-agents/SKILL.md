---
name: writing-for-agents
description: Writing documents that agents consume. Use when authoring or editing skills, or when changing AGENTS.md or CLAUDE.md.
---

This is a reference for authoring anything an agent reads: a skill, an `AGENTS.md` or `CLAUDE.md`, a doc that something else points to. Packaging differs between them, but the craft is shared. The same levers keep each one predictable, because what stays constant from run to run is the agent's _process_, not its literal output.

Authoring a skill specifically? Also read [`SKILL-MECHANICS.md`](SKILL-MECHANICS.md), which covers frontmatter, how a skill gets invoked, and router skills.

## Context pointers

Think of a **context pointer** as a short entry living in the agent's context. It names material that sits elsewhere and spells out when to go and fetch it. Skill descriptions work this way, and so does an `AGENTS.md` line that mentions a doc. What determines whether, and how dependably, the agent fetches the material is the wording of the pointer, not the target it names. If essential material hides behind a limp pointer, you have a variance bug. Rewrite the pointer first; copy the material inline only when a sharper pointer still fails.

Pointers do two things: describe the material, and enumerate the **branches** that justify fetching it. (A branch is one distinct situation the document handles, which is why separate runs walk different routes through it.) Since a pointer that is always loaded is paid for on every single turn, prune it harder than you would prune the body:

- **Lead with the leading word.** The pointer is exactly where that word triggers behaviour.
- **One trigger per branch.** Two synonyms for one situation are the same branch listed twice. Merge them, and keep only the branches that really differ.
- **Skip whatever the body already says about identity.**

## The two loads

Anything you add, whether a document or a pointer, draws on one of two budgets:

- **Context load**: what resident material costs the agent's window. An `AGENTS.md` line, a skill description, and any other text present on every turn burn tokens and attention, firing or not.
- **Cognitive load**: what it costs the person, who must know which documents exist and when each applies. The human serves as the index. Do not try to drive this to zero; it is what human agency costs. Pay it where judgement matters and remove it elsewhere.

Material fetched only through a pointer skips context load and pays just the pointer's one line. Material with no pointer relies wholly on cognitive load.

## Information hierarchy

Documents contain two kinds of content: **steps** (the actions the agent performs, in order) and **reference** (definitions, rules, and facts to look up when needed). A document may hold either or both, such as a pure recipe, pure reference (a code review's rule set, or this skill), or a mix. The main design call is where each item sits on the **information hierarchy**, which ranks material by how soon the agent needs it:

1. **In-file steps** form the top tier, being what the agent does, in sequence.
2. **In-file reference** is looked up as needed. It frequently forms a flat set of equals (all of a review's rules at one level), and that is a perfectly good layout, not a smell.
3. **Disclosed reference** lives in its own file, behind a context pointer, and loads only when that pointer fires. This runs from a sibling file in the same folder to wholly external material that any document may point at.

Demote too little and the top swells; demote too much and you bury what the agent truly needs. Resolving that tension is the entire job.

**Progressive disclosure** means moving material down the ladder, out of the main file and behind a pointer, so the top stays readable. Saving tokens is a side effect; the real purpose is protecting the hierarchy. Branching offers the cleanest test: keep inline what every branch requires, and put behind a pointer what only certain branches reach. In a document built on steps, reference that should have been disclosed but stayed in-file buries those steps, making the agent's attention to them a coin-flip. That is a variance lever, and more than a readability concern.

**Co-location** complements this inside a single file. The ladder fixes _how deep_ something sits; co-location fixes _what sits next to it_. Gather a concept's definition, rules, and caveats under one heading so that reading one piece pulls in the rest. Test it by asking whether the document reads like docs written for the agent: grouped material does, scattered material doesn't. (Do not confuse it with duplication, which states one meaning in two places. Scattering splits one meaning across many places.)

**Sprawl** is the failure to watch for: a document that is just too long, even when each line is unique and live. Attention spreads thin over the surplus, and every extra line is another to keep current. The remedy is the ladder, plus splitting by branch or sequence so every route through the document stays light.

## Steps and completion criteria

Each step closes with a **completion criterion**, a condition telling the agent the work is finished. It becomes a lever through two properties:

- **Clarity**: does the agent know finished from unfinished? A fuzzy bound such as "understanding reached" invites **premature completion**, where the agent wraps up early with attention sliding toward _being done_. The steps visible further down (**post-completion steps**) exert the pull, and a clear criterion supplies the resistance. Counter it in this order: **tighten the bound** first, which is local and cheap. Only if the bound is irreducibly fuzzy _and_ you actually see the rushing should you conceal the later steps by splitting the sequence. Concealment works only over a true context boundary, like a hand-off or a subagent dispatch; an inline call keeps the later steps in view and hides nothing.
- **Demand**: how much work it requires. "Every modified model accounted for" pushes thorough effort in a way "produce a change list" does not. Demand creates **legwork**, the digging the agent does within the work, implicit in the phrasing instead of its own step. It is not limited to steps: "every rule applied" constrains a block of flat reference exactly as "every step done" constrains a sequence, so even a reference-only document can carry an exhaustiveness bar.

The best criteria can be both checked and exhausted.

## When to split

A split spends one of the two loads, so make it only when the cut pays off:

- **By sequence**: cut a series of steps when the post-completion steps lure the agent into hurrying the current one. Keeping them out of view pushes more effort into the present task. The reverse also holds: joining sequences shows each step what comes after, which encourages premature completion.
- **By invocation**, which applies to skills only: see [`SKILL-MECHANICS.md`](SKILL-MECHANICS.md).

## Leading words

A **leading word** is a short concept the model already knows from pretraining, which the agent reasons with while executing the document (_lesson_, _fog of war_, _tracer bullets_). Reuse it as a bare token and never as a sentence. It gathers a spread-out definition over time and pins down a large area of behaviour in few tokens, using priors already in the model. You may invent a word if you define it well, but an invented word brings no priors, so you spend definition tokens on what a pretrained word hands over free. Look for an existing word before coining one.

The anchoring works in two places. In the body it drives _execution_: the agent falls back on the same behaviour whenever the word shows up, and within flat reference it aims attention at one class of thing. In a pointer it drives _invocation_: if the same word appears in your prompts, docs, and codebase, the agent ties that shared vocabulary to the material and fetches it more dependably.

Go hunting for places to refactor into leading words. A triad written out at three sites, or a pointer burning a full sentence to hint at one idea, is a passage asking to shrink into one token:

- "fast, deterministic, low-overhead" becomes _tight_ (a _tight_ loop).
- "a loop you believe in" becomes _red_, converting a fuzzy gate into a binary, observable state (the loop turns _red_ on the bug, or it does not).

The gain is double: fewer tokens, and a sharper hook for the agent's reasoning. Presume that every document carries restatements a leading word could retire, and go find them.

**Negation** is the failure mode sitting beside this lever. Steering by prohibition pulls the forbidden behaviour into context and makes it _more_ reachable. Tell someone _not to think of an elephant_ and the elephant is all they have; the negation is a weak modifier the strongly activated concept overpowers, so the ban partly reads as an instruction to do the thing. Prompt the **positive** instead: name the target behaviour ("write one-line comments") so the unwanted one is never uttered. A prohibition is justified only as a hard guardrail you cannot state positively, and even then it should come with the positive target, so attention settles on what to do.

## Pruning

- Give each meaning a **single source of truth**, one authoritative place, so altering the behaviour means editing one spot. **Duplication**, one meaning in several places, costs upkeep and tokens, and it also lifts a meaning's prominence on the ladder past its true rank. (It is the unintended mirror of a leading word, which repeats a token deliberately and never a meaning.)
- The **environment** counts as a source of truth as well (`Gemfile`, `Makefile` targets, config files, directory layout, `--help` output). A document restating it is a **cache**, a copy of a lookup, which justifies its load only when the lookup is costly. Cache what the agent can't discover by looking: the unwritten convention, the reasoning behind a choice, the trap no config reveals. Leave single-file, single-command lookups with the environment, where they can't drift.
- Test every line for **relevance**: does it still relate to what the document does? Lines lose relevance either by never bearing on the task (pure exposition, or a branch that ought to be disclosed) or by going stale when the behaviour or world they describe moves on. Short documents stay relevant more easily. Without a pruning habit, the usual end state is **sediment**: layers of staleness that accumulate because adding feels safe and deleting feels risky, until you must dig through them to find what's alive.
- Seek out **no-ops** one sentence at a time: an instruction the model already obeys unprompted costs load while saying nothing. The test (does it alter behaviour relative to the default?) is relative to the model and not to the reader. Two people who disagree over a no-op disagree about the default, and the way to settle that is to run the document rather than argue. When a sentence fails the test, cut the entire sentence instead of trimming words. The same test grades leading words: one too weak to beat the default (_be thorough_ for an agent already thorough-ish) is a no-op, and the cure is a stronger word (_relentless_), not another technique.
