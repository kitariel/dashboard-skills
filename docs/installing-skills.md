# Installing & Using Dashboard Skills

Claude Code Skills live in a `skills/` directory and are auto-discovered. You install one by placing its folder where Claude looks.

## Where skills go

| Scope | Path | Applies to |
|-------|------|------------|
| **Project** | `<your-project>/.claude/skills/<skill>/` | just that repo (commit it to share with your team) |
| **User** | `~/.claude/skills/<skill>/` | every project on your machine |

A skill is "installed" when its folder (containing `SKILL.md`) sits at one of those paths:

```
.claude/skills/redis-admin-dashboard/
├── SKILL.md
└── references/...
```

## Methods

### 1. One-line installer

```bash
# project-level
curl -fsSL https://raw.githubusercontent.com/kitariel/dashboard-skills/main/install.sh | bash -s -- redis-admin-dashboard

# user-level
curl -fsSL https://raw.githubusercontent.com/kitariel/dashboard-skills/main/install.sh | bash -s -- --user redis-admin-dashboard

# list / install everything
curl -fsSL .../install.sh | bash -s -- --list
curl -fsSL .../install.sh | bash -s -- --all
```

### 2. Clone & copy

```bash
git clone https://github.com/kitariel/dashboard-skills.git
cp -r dashboard-skills/skills/redis-admin-dashboard .claude/skills/
```

### 3. Single-folder download

Paste a skill folder's GitHub URL into <https://download-directory.github.io>, unzip into `.claude/skills/`.

## Using them

### Claude Code (CLI)

After installing, skills are picked up automatically (restart the session if it was already running). Then either:

- **Let it auto-trigger** — describe your task naturally: *"Build a Redis key management dashboard in my Next.js app."* Claude matches the skill's `description`.
- **Invoke explicitly** — type `/redis-admin-dashboard`.

Check what's loaded with `/skills` (or list the `.claude/skills` directory).

### Claude apps (desktop / web) & Agent SDK

The same `SKILL.md` format works wherever Skills are supported. For the Agent SDK, point your agent's skills/plugin directory at the installed folder. See the [Skills docs](https://code.claude.com/docs/en/skills) for the integration specific to your surface.

## Recommended combo

Install **`dashboard-foundations`** alongside any specific dashboard skill — the others reference it for shared setup, design tokens, the responsive grid, and loading/empty/error patterns:

```bash
curl -fsSL .../install.sh | bash -s -- dashboard-foundations redis-admin-dashboard
```

## Updating

Re-run the installer (it overwrites the skill folder) or `git pull` your clone and re-copy. To remove a skill, delete its folder from `.claude/skills/`.

## Troubleshooting

- **Skill not triggering?** Make sure the folder name matches the `name:` in its frontmatter and sits directly under `.claude/skills/`. Restart the session.
- **Two skills overlap?** That's fine — install `dashboard-foundations` + one specific skill; Claude composes them.
- **Want it team-wide?** Commit `.claude/skills/` to your repo.
