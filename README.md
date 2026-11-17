# br4zz4 skills

Agent skills for Claude (web, desktop, mobile, Claude Code) and OpenCode, shipped as one Claude plugin: `br4zz4`. Every skill shows up as `br4zz4:<skill>`.

## Install in Claude

1. Open Customize → Plugins → Add → Add marketplace.
2. Enter `br4zz4/skills`.
3. Add the plugin `br4zz4` and turn on **Sync automatically**.

Claude Code CLI alternative (installs on that machine only; do not combine it with the account sync, or each skill shows up twice):

```
/plugin install br4zz4 --marketplace br4zz4/skills
```

The plugin is saved to your account, so it reaches chat (web, desktop, mobile), Cowork and Claude Code signed in with the same account.

## Layout

```
.claude-plugin/marketplace.json
plugins/br4zz4/.claude-plugin/plugin.json
plugins/br4zz4/skills/<skill>/SKILL.md
scripts/validate.sh
```

## Add or edit a skill

1. Create `plugins/br4zz4/skills/<skill>/SKILL.md` with frontmatter `name` (lowercase, digits and hyphens, equal to the folder name) and `description` (up to 1024 characters).
2. Skills that only make sense on the author's own machine set `compatibility` and start the description with `Local machine only: `.
3. Run `make validate` and `make test`.
4. Commit to `main`.

## OpenCode

qwert keeps its own clone of this repo, syncs it daily and links each skill into `~/.config/opencode/skills/br4zz4:<skill>`.
