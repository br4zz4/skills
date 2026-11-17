# Learning Record Format

Learning records go in `./learning-records/` and are numbered in sequence: `0001-slug.md`, `0002-slug.md`, and so on. Create the directory lazily, when the first record gets written.

They play the role ADRs play in software: they hold non-obvious lessons, key insights, and stated prior knowledge that will guide later sessions. They feed the calculation of the zone of proximal development.

## Template

```md
# {Brief title for what was learned or established}

{One to three sentences saying what the user learned, or which prior knowledge was established, and why future sessions should care.}
```

That is the entire format. A learning record may be one paragraph. What counts is noting _that_ something is known now, and _why_ that shifts what to teach next, rather than filling in a form.

## Optional sections

Add these only when they bring real value. Most records need none.

- **Status** frontmatter (`active | superseded by LR-NNNN`): handy when an earlier understanding proves wrong and is replaced.
- **Evidence**: how the user showed the understanding (an answered question, a finished exercise, cited experience). Useful when the claim may be revisited.
- **Implications**: what this opens up or rules out for later sessions. Worth writing down when it isn't obvious.

## Numbering

Look in `./learning-records/` for the highest number in use and add one.

## When to write a learning record

Create a record whenever one of these applies:

1. **The user showed real understanding of something non-trivial**: more than exposure, with evidence they can apply the concept correctly. This raises the floor for what to teach next.
2. **The user revealed prior knowledge**: "I already know X." Record it so later sessions don't repeat it, along with the _depth_ they claim.
3. **A misconception was corrected**: the user used to believe something wrong and now sees why. These are very valuable, since they predict where related topics will trip them up.
4. **The mission shifted because of learning**: the user found they care about something other than what they assumed. Cross-link [[MISSION.md]] and revise it.

### What does _not_ qualify

- Topics that were merely covered. Coverage is not learning; wait for evidence.
- Anything [[GLOSSARY.md]] already holds as a concise term definition. Don't duplicate it.
- Per-session activity logs. A learning record is no diary: it holds insights strong enough to drive decisions.

## Supersession

Should a newer record contradict an older one, because understanding deepened or was corrected, mark the older record `Status: superseded by LR-NNNN` instead of deleting it. How understanding evolved is useful signal in itself.
