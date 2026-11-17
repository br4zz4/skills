# MISSION.md Format

`MISSION.md` sits at the root of the workspace and records the _reason_ the user is learning the topic. Each teaching decision (what comes next, which resources to surface, which exercises to build) should be traceable to it.

## Template

```md
# Mission: {Topic}

## Why
{One to three sentences naming the concrete real-world goal driving the user. What shifts in their life or work once they hold this skill? Steer away from abstractions like "to understand X" and dig for the outcome underneath.}

## Success looks like
- {A specific, observable capability the user gains}
- {A second capability}
- {…}

## Constraints
- {Time available, budget, existing commitments, learning preferences, anything that limits the approach}

## Out of scope
- {Neighbouring topics the user explicitly doesn't want to chase right now, which keeps the zone of proximal development protected}
```

## Rules

- **One mission per workspace.** Two unrelated learning goals mean two workspaces.
- **Concrete beats abstract.** "Run a half marathon by October" is better than "get fitter." "Ship a Rails engine my team can install" is better than "learn Ruby."
- **Challenge vagueness.** If the user can't say why, interview them before writing a word. A bad mission does more harm than none.
- **Revise as reality moves.** Missions change. When the goal shifts, update the file; a stale mission quietly steers later sessions the wrong way.
- **Keep it short.** Once `MISSION.md` outgrows a single screen, it has stopped being a compass and become a plan.
