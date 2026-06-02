# Contributing a Dashboard Skill

Thanks for adding to the collection! Every skill here teaches Claude to build **one style of dashboard** really well. The bar is: a fresh Claude session, given only your `SKILL.md`, should produce a coherent, production-feeling dashboard — not a generic template.

## The golden rule

> Don't tell the AI "make a dashboard." Tell it the **data model, layout sections, components, interactions, and computed logic.** That specificity is what makes output look intentional.

## Anatomy of a good skill

```
skills/<your-skill-name>/
├── SKILL.md            # required: frontmatter + instructions
└── references/         # optional: deep-dive docs Claude loads on demand
    ├── data-model.md
    ├── components.md
    └── layout.md
```

### `SKILL.md` frontmatter

```yaml
---
name: your-skill-name          # lowercase-hyphenated, matches the folder, ≤64 chars
description: >                  # ≤1024 chars, third person, STARTS WITH WHEN TO USE.
  Build a <thing> with Next.js... Use when the user wants <triggers...>.
  Produces <what the output contains> over typed mock data ready to connect to a real API.
---
```

The `description` is the single most important field — it's how Claude decides to load your skill. Pack it with concrete trigger phrases ("Redis dashboard", "key inspector", "MRR/churn", "data table with filters") and a one-line summary of what gets produced.

### `SKILL.md` body — follow this section order

1. **One-paragraph goal / vibe** — what it should feel like (and a reference product or two).
2. **"First apply `dashboard-foundations`"** note — reuse the shared design system; don't redefine tokens.
3. **File structure** to produce.
4. **Data model** — strongly typed interfaces, defined *before* UI. Computed values stay computed.
5. **Layout** — sections with the responsive grid (header → KPIs → main 8/4 → bottom).
6. **Components** — reusable, typed, with prop contracts; no duplicated markup.
7. **Computed logic** — what must be derived, never hardcoded.
8. **Interactions** — refresh, filters, confirm-on-delete, sheets/dialogs, all wired.
9. **Design rules** — short inline fallback for when `dashboard-foundations` isn't installed.
10. **Future real API** — endpoint mapping the mock mirrors.
11. **Definition of done** — a concrete checklist.

Keep the `SKILL.md` itself scannable; push long type dumps and component code into `references/` so Claude only loads them when needed.

## Style conventions (shared across all skills)

- Stack: Next.js (App Router) + TypeScript + Tailwind + shadcn/ui + lucide-react + Recharts (CRUD skill may add TanStack Table).
- Visual language: white cards on light-gray page, `rounded-xl border shadow-sm`, compact spacing, `tabular-nums`, **color only** for icons/badges/charts/status/destructive.
- Always typed mock data behind async getters that map 1:1 to a future API.
- Always handle loading (skeletons) / empty / error states.
- Destructive actions always behind a confirm dialog.

## Adding your skill

1. `cp -r skills/redis-admin-dashboard skills/<your-skill-name>` as a starting point.
2. Rewrite `SKILL.md` and the `references/`.
3. Add a row to the **Available Skills** table in `README.md`.
4. Test it: install locally (`./install.sh <your-skill-name>`) and ask Claude to build the dashboard in a scratch Next.js app — confirm it follows your spec.
5. Open a PR describing the dashboard style and who it's for.

## Naming ideas welcome

`kanban-dashboard`, `iot-telemetry-dashboard`, `finance-portfolio-dashboard`, `observability-dashboard`, `ecommerce-orders-dashboard`, `support-inbox-dashboard`, `ml-experiment-dashboard`… each a different *experience*. That's the point — people download the one that fits.
