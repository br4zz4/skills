# Context

## Glossary

- **Skill**: a directory with a `SKILL.md` (frontmatter `name` + `description`) that teaches an agent a repeatable workflow. Its id is the directory name.
- **Plugin `br4zz4`**: the single Claude plugin in this repo that bundles every skill; Claude surfaces each skill as `br4zz4:<skill>`.
- **Marketplace**: this repository itself, as seen by Claude (`.claude-plugin/marketplace.json`). Added once to the Claude account; it reaches web, desktop, mobile, Cowork and Claude Code.
- **Source**: the working copy where skills are authored (`~/workspace/br4zz4/skills`). Only humans and agents editing skills touch it.
- **Synced copy**: the read-only clone that qwert owns (`~/.local/share/qwert/skills/br4zz4`). Reset to `origin/main` on every sync; never edited by hand.
- **Daily sync**: the scheduled job that refreshes the synced copy and rebuilds the OpenCode links.
- **OpenCode link**: a symlink `~/.config/opencode/skills/br4zz4:<skill>` pointing into the synced copy, so OpenCode sees the same `br4zz4:<skill>` id that Claude shows.
- **Machine-local skill**: a skill that only makes sense on the user's own machine (qwert, OpenCode agents, local project tree). Marked with `compatibility` and a description prefix so chat surfaces skip it.
