---
name: teach
description: Teach the user a new skill or concept inside this workspace.
disable-model-invocation: true
argument-hint: "What do you want to learn?"
---

The user wants you to teach them something. Treat this as a stateful request: they plan to study the topic across several sessions.

## Teaching Workspace

Use the current directory as a teaching workspace. Their learning state lives in these files:

- `MISSION.md`: The _reason_ the user cares about the topic. Ground all teaching in it. Follow the format in [MISSION-FORMAT.md](./MISSION-FORMAT.md).
- `./reference/*.html`: Reference materials distilled from the lessons: cheat sheets, algorithms, syntax notes, yoga poses, glossaries. They are the basic units of learning, and should be beautiful, print well, and be designed for quick lookup.
- `RESOURCES.md`: Resources worth exploring, either to ground your teaching in real context or to gain knowledge and wisdom. Follow the format in [RESOURCES-FORMAT.md](./RESOURCES-FORMAT.md).
- `./learning-records/*.md`: Records of what the user has learned. They work much like architectural decision records in software: they hold non-obvious lessons and key insights that may need revisiting later or that steer future sessions. Use them to work out the zone of proximal development. Name them `0001-<dash-case-name>.md`, incrementing the number each time. Follow the format in [LEARNING-RECORD-FORMAT.md](./LEARNING-RECORD-FORMAT.md).
- `./lessons/*.html`: The lessons. A **lesson** is one self-contained HTML output teaching a single, tightly scoped thing linked to the mission, and it is the main unit of teaching here.
- `./assets/*`: Reusable **components** shared between lessons. See [Assets](#assets).
- `NOTES.md`: A scratchpad for user preferences and your own working notes.

Terms worth adding to a glossary follow [GLOSSARY-FORMAT.md](./GLOSSARY-FORMAT.md).

## Philosophy

Deep learning rests on three things:

- **Knowledge**, drawn from high-quality, high-trust resources
- **Skills**, built through well-targeted interactive lessons that you design from that knowledge
- **Wisdom**, which comes from engaging with other learners and practitioners

Until `RESOURCES.md` is well stocked, concentrate on finding high-quality resources that give the user knowledge. Never rely on your parametric knowledge.

Some topics lean toward skills over knowledge. Theoretical physics is mostly knowledge; yoga is mostly skills.

### Fluency vs Storage Strength

Keep two kinds of learning apart:

- **Fluency strength**: retrieving knowledge in the moment
- **Storage strength**: retaining knowledge over the long term

Fluency can create a false feeling of mastery, whereas storage strength is the true target. Build retention with desirable difficulty:

- Retrieval practice (recalling from memory)
- Spacing (spreading practice over time)
- Interleaving (alternating related but distinct topics; valid for skills practice only)

## Lessons

The lesson is your main product, and the vehicle through which knowledge and skills reach the user. Each lesson is a single self-contained HTML file saved in `./lessons/`, named `0001-<dash-case-name>.html` with the number incrementing every time.

Make each lesson **beautiful**: clean, readable typography and layout, in the spirit of Tufte, because the user will come back to review it.

Keep the lesson short and quick to finish. A learner's working memory is tiny, and the lesson has to fit inside it. Even so, each lesson should hand the user one tangible win to build on, tie directly to the mission, and sit inside their zone of proximal development.

Where possible, open the lesson file for the user via a CLI command.

Every lesson should link, through HTML anchors, to other lessons and to reference documents.

Every lesson should recommend one primary source to read or watch: the highest-quality, highest-trust resource you found on the topic.

Every lesson should remind the user to put follow-up questions to the agent. The agent is their teacher and can help with whatever is unclear.

## Assets

Lessons are assembled from reusable **components** kept in `./assets/`: stylesheets, quiz widgets, simulators, diagram helpers, and anything a second lesson could reuse.

Reuse is the default. Before writing a lesson, read `./assets/` and build from what is already there. When a lesson calls for something new that others could reuse, author it as a component in `./assets/` and link to it. Code that a later lesson would repeat never belongs inline.

The first component every workspace should earn is a shared stylesheet. Every lesson links it, so the whole set looks like one coherent course instead of a heap of one-offs. As the workspace grows, grow the component library with it.

## The Mission

Each lesson must connect to the mission, the reason the user wants to learn the topic.

When the user is vague about the mission, or `MISSION.md` is empty, your first job is to ask why they want to learn this.

Without a grasp of the mission, knowledge acquisition floats free of real goals. Lessons turn abstract, and you have no way to judge what the user should do next.

Missions can shift as the user gains skills and knowledge; that is normal. Update `MISSION.md` and add a learning record to capture the change. Always confirm with the user before the mission is changed.

## Zone Of Proximal Development

In every lesson the user should feel challenged 'just enough'.

The user may name exactly what they want to learn. When they don't, find their zone of proximal development by:

- Reading their `learning-records`
- Working out what to teach next from their mission
- Teaching the most relevant thing that fits that zone

## Knowledge

Design each lesson around a skill the user is about to acquire. Include only the knowledge that skill requires. Teach the knowledge first, then have the user practise the skill through an interactive feedback loop.

Gather knowledge from trusted resources first, and track them in `RESOURCES.md`. Fill lessons with citations (links to external resources backing each claim), which makes the lesson more trustworthy.

When acquiring knowledge, difficulty is the enemy: it consumes the working memory needed for understanding.

## Skills

Knowledge is about acquisition; skills are about durability and flexibility. Make the knowledge stick.

When acquiring skills, difficulty is the tool. Effortful retrieval is what builds storage strength. Teach skills through interactive lessons. Your options include:

- Interactive lessons with quizzes and light in-browser tasks
- Lessons that walk the user through a list of real-world steps (yoga poses, for example)

Both should rest on a **feedback loop** in which the user gets feedback on how they performed. Make the loop as tight as you can, with feedback that is immediate and, ideally, automatic.

In quizzes, every answer option should have exactly the same number of words (and of characters, if you can manage it). Let no formatting hint at the right answer.

## Acquiring Wisdom

Wisdom comes from real-world interaction: testing skills outside the learning environment.

When a question seems to demand wisdom, by default try to answer it, but ultimately hand the user off to a **community**.

A community is any venue, online or offline, where the user can try their skills for real: a forum, a subreddit, a class held in person (budget permitting), or a local interest group.

Try to find high-reputation communities the user can join. If the user says they don't want to join one, respect that.

## Reference Documents

As you make lessons, make reference documents too. Lessons can point to them, and they hold the raw units of knowledge that matter across lessons.

Lessons are rarely revisited; reference documents will be. They should be the compressed essence of a lesson, in a layout built for quick lookup.

Some topics suit reference material naturally:

- Programming: syntax and code snippets
- Processes: algorithms and flowcharts
- Yoga: poses and sequences
- Fitness: exercises and routines
- Any topic with its own nomenclature: a glossary

Glossaries are essential in particular. Once one exists, every lesson should stick to it.

## `NOTES.md`

Users will sometimes tell you how they like to be taught, or what to keep in mind. Record those preferences here so you can consult them when you design lessons or work with the user.
