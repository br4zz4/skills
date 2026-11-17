---
name: to-spec
description: "Convert the conversation so far into a spec and file it in the project's issue tracker, with no interview and only a synthesis of what's already been said."
disable-model-invocation: true
---

This skill takes the conversation so far, plus your grasp of the codebase, and turns them into a spec. Never interview the user here; only synthesize what you already hold.

The issue tracker and triage label vocabulary should already be known to you. If they aren't, tell the user to run `/br4zz4:setup-repo`.

## Process

1. Unless you already have, explore the repo to learn where the code currently stands. Write the spec in the vocabulary of the project's domain glossary, and honour any ADRs for the area you will touch.

2. Outline the seams where the feature gets tested. Existing seams beat new ones, and the highest available seam beats lower ones. When new seams are unavoidable, propose them as high up as possible. Fewer seams across the codebase is better, and one is the ideal.

Ask the user to confirm that these seams match their expectations.

3. Write the spec from the template below and file it in the project's issue tracker. Apply the `ready-for-agent` triage label; nothing further is needed for triage.

<spec-template>

## Problem Statement

The problem the user faces, written in the user's own point of view.

## Solution

How the problem gets solved, again in the user's own point of view.

## User Stories

A LONG numbered list of user stories, every one formatted as:

1. As a <role>, I need <capability>, so that <outcome>

<user-story-example>
1. As a storefront admin, I want refunds grouped by payment method, so that I can reconcile them with the processor's monthly statement
</user-story-example>

This list has to be extremely extensive and span every aspect of the feature.

## Implementation Decisions

A list of the implementation decisions reached so far. It may cover:

- Modules to be built or modified
- Interface changes to those modules
- Technical clarifications given by the developer
- Architecture choices
- Schema changes
- API contracts
- Particular interactions

Leave out specific file paths and code snippets, because they quickly become outdated.

One exception: when a prototype produced a snippet that expresses a decision more precisely than prose can (a state machine, reducer, schema, or type shape), place it inside the decision it supports, with a short remark that a prototype produced it. Trim it to the decision-bearing parts; it should be the important bits and not a working demo.

## Testing Decisions

A list of the testing decisions made, including:

- What a good test looks like (assert only on external behaviour, never on implementation details)
- Which modules will be tested
- Prior art, meaning similar tests that already exist in the codebase

## Out of Scope

What this spec deliberately excludes.

## Further Notes

Anything else worth knowing about the feature.

</spec-template>
