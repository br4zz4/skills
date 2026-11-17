# Skill mechanics

This is the skill-only branch of [`writing-for-agents`](SKILL.md). It covers what changes once the document is a skill: frontmatter, how the skill is invoked, and router skills. Everything else about authoring lives in the general reference in `SKILL.md`.

## Invocation

Two options exist, and each swaps one load for the other:

- A **model-invoked** skill retains a `description`, which lets the agent trigger it unaided and lets other skills reach it. Typing its name still works, because model-invocation always _contains_ user reach. A description only adds agent discovery and never removes anything from the human. That description acts as the skill's top-level context pointer and stays loaded for good: you pay permanent context load to buy discoverability. If such a skill is entirely reference, it can also be the one place for shared reference, since other skills may invoke it. Mechanics: omit `disable-model-invocation`, and write a description aimed at the model that lists the trigger branches (the pointer rules in `SKILL.md` apply fully).
- A **user-invoked** skill takes its description out of the agent's reach. Only a human typing the name can run it, and no skill can. Context load is nil, but cognitive load rises, because you become the index who must remember it. Mechanics: set `disable-model-invocation: true`, and write the `description` for humans as a one-line summary with no trigger lists.

Choose model-invocation only if the agent has to reach the skill itself or another skill has to. A skill that only ever fires by hand should be user-invoked, at no context cost.

Reference shared by two user-invoked skills can belong to neither, since without descriptions neither can trigger the other. Move it into a plain file outside the skill system, an external reference that any skill can point to.

## Splitting by invocation

This is the invocation cut of splitting (the sequence cut is covered in `SKILL.md`). Break out a model-invoked skill when a distinct leading word should trigger it independently, meaning a word you really use in prompts, or when another skill must reach it. The new always-loaded description adds context load, so the independent reach has to justify that cost.

## Router skills

When your user-invoked skills grow beyond what you can remember, a **router skill** removes that growing cognitive load. It is one user-invoked skill that names the rest and says when each applies, leaving the human a single skill to remember. It can only suggest, never trigger: user-invoked skills carry no description, so only a person can reach them. In this plugin, `br4zz4:which-skill` plays that role.
