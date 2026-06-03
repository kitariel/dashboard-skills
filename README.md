# Dashboard Skills

A collection of downloadable **Claude Code Skills** for building beautiful, production-ready dashboards.

Instead of telling an AI *"make a nice dashboard"* and getting a random admin template, you install a Skill that teaches Claude the **data model, layout sections, components, interactions, and computed logic** for a specific kind of dashboard. The output looks intentional — because the intent is encoded in the Skill.

> **Not just one dashboard.** Each Skill is a different *style and experience*. Download the one you want, or stack several. Want a different look? Grab another Skill.

---

## What's a "Skill"?

A [Claude Code Skill](https://code.claude.com/docs/en/skills) is a folder containing a `SKILL.md` file (with YAML frontmatter) plus optional reference docs. When Claude detects your task matches a Skill's `description`, it loads the Skill's instructions and follows them. You can use these with **Claude Code** (CLI), the **desktop/web app**, or the **Agent SDK**.

```
skills/redis-admin-dashboard/
├── SKILL.md                 # frontmatter + instructions Claude reads
└── references/              # deep-dive docs Claude pulls in on demand
    ├── data-model.md
    ├── components.md
    └── layout.md
```

---

## Available Skills

| Skill | What you get | Best for |
|-------|--------------|----------|
| **[dashboard-foundations](skills/dashboard-foundations)** | Shared design system: shadcn/ui setup, Tailwind tokens, responsive 12-col grid, loading/empty/error states, accessibility. | The base every dashboard builds on. Install this first. |
| **[redis-admin-dashboard](skills/redis-admin-dashboard)** | Redis key-management admin: server-health banner + vitals (memory, fragmentation, hit rate, evictions, persistence, replication) with warnings & debug hints, KPI cards, namespace table, key-type donut, TTL ranges, activity log, memory consumers, scan/get/delete actions. | Infra & ops monitoring / admin tooling. |
| **[saas-analytics-dashboard](skills/saas-analytics-dashboard)** | Product/marketing analytics: trend KPIs with deltas, time-series area charts, funnel, cohort/retention, top-N tables, date-range filtering. | Growth, product, and revenue analytics. |
| **[admin-crud-dashboard](skills/admin-crud-dashboard)** | Data-management admin: server-style data tables, faceted filters, search, pagination, row actions, create/edit forms with validation, bulk actions. | Internal tools & back-office CRUD. |

All four share the same visual language (soft borders, rounded-xl cards, compact spacing, color used sparingly), so you can mix them in one app and it stays coherent.

---

## Install a Skill

### Option A — one-line installer (recommended)

```bash
# Project-level (just this repo) — run from your project root
curl -fsSL https://raw.githubusercontent.com/kitariel/dashboard-skills/main/install.sh | bash -s -- redis-admin-dashboard

# User-level (all your projects)
curl -fsSL https://raw.githubusercontent.com/kitariel/dashboard-skills/main/install.sh | bash -s -- --user redis-admin-dashboard

# Install several at once
curl -fsSL https://raw.githubusercontent.com/kitariel/dashboard-skills/main/install.sh | bash -s -- dashboard-foundations saas-analytics-dashboard
```

### Option B — clone and copy

```bash
git clone https://github.com/kitariel/dashboard-skills.git
# Project-level
cp -r dashboard-skills/skills/redis-admin-dashboard .claude/skills/
# or User-level
cp -r dashboard-skills/skills/redis-admin-dashboard ~/.claude/skills/
```

### Option C — download a single Skill folder

Use any GitHub directory downloader (e.g. [download-directory.github.io](https://download-directory.github.io)) on the Skill's folder URL, then drop it into `.claude/skills/`.

See [`docs/installing-skills.md`](docs/installing-skills.md) for app/desktop/SDK details.

---

## Use a Skill

Once installed, just ask Claude in natural language — it auto-selects the matching Skill:

```
Build a Redis key management dashboard for my Next.js app.
```

```
I need a SaaS analytics overview page with MRR, churn, and a signups trend chart.
```

You can also invoke explicitly: `/redis-admin-dashboard`.

> 💡 Install **dashboard-foundations** alongside any other Skill — the dashboard Skills reference it for the shared design system and component setup.

---

## Tech stack the Skills assume

- **Next.js** (App Router) + **React** + **TypeScript**
- **TailwindCSS** + **shadcn/ui** components
- **lucide-react** icons
- **Recharts** (via shadcn `chart`) for visualizations

The Skills are written so the *patterns* transfer to Vite/Remix too — only the install commands differ. Mock data is strongly typed and structured to swap in a real API later.

---

## Contributing a new dashboard style

Want a `kanban-dashboard`, `iot-telemetry-dashboard`, or `finance-portfolio-dashboard`? Adding a Skill is intentionally easy — see [CONTRIBUTING.md](CONTRIBUTING.md). The short version: copy an existing Skill folder, rewrite the `SKILL.md` (data model → layout → components → interactions → design rules), and open a PR.

---

## License

MIT — see [LICENSE](LICENSE). Use these Skills in personal and commercial projects freely.
