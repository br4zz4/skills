---
name: to-questionnaire
description: Turn a decision you can't settle by yourself into a questionnaire that someone else fills in.
disable-model-invocation: true
---

Take whatever the user can't resolve alone and produce a **questionnaire**: a Markdown file they pass to one person to complete asynchronously, or to go through jointly in a meeting. The recipient knows things the user doesn't, and the questionnaire is how that knowledge gets out.

**Grill the send, not the subject.** Interview the user only on the _send_, which they can always answer: who receives it and what they need in return. The questions inside the document then aim at the **gap**, the distance between the recipient's knowledge and the user's needs.

1. **Who is it going to?** In one exchange, ask for the recipient's role, expertise, and relationship with the user. That fixes the tone and the amount of context the document must carry. You are done when you know who the recipient is and which knowledge they have that the user lacks.

2. **What do you need back?** In one exchange, ask which specific decisions or facts the user can't resolve alone and wants from this person. You are done when you hold a concrete list of what the user should be able to do or decide afterwards.

3. **Write the questionnaire.** Draft questions that aim at the gap found in steps 1–2, following the Document structure below. Save the result as `to-questionnaire-<slug>.md` in the current directory (slug derived from the topic) and tell the user the path. You are done when the file exists and a question covers every item the user listed in step 2.

## Document structure

Present the document as a **discovery questionnaire**, where the user lacks context and the recipient has it. Order the questions with the most important first, since an async send may get only a single pass, and once there are more than a few, group them under `##` headings by theme. Use the template below.

<questionnaire-template>

# <Questionnaire title>

**Purpose:** the reason this questionnaire exists and the decision that hinges on it.

**From:** <the user> | **To:** <the recipient> | **Where your answers end up:** <destination>

## Context

A single paragraph that orients a recipient who was never in the user's head. It should be enough to answer well and no longer than a paragraph.

## How to answer

The deadline and the rough effort involved. Partial answers and "I don't know" both help: mark anything you're unsure about instead of skipping it.

## <Theme heading>

One `##` section for each theme, with its questions beneath, most important first. Each question holds one idea and is never compound, has an answer stub right below it, and carries a one-line _why this matters_ only when the question might be misread or might attract a throwaway reply.

<question-example>
### How many background jobs per minute must the queue handle at peak?

_Why this matters: it settles whether we size the worker pool now or put it off._

>
</question-example>

## Anything else?

A closing catch-all. Is there something we failed to ask that we should know?

</questionnaire-template>
