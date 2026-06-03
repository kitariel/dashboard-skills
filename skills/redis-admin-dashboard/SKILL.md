---
name: redis-admin-dashboard
description: Build a modern Redis key-management admin dashboard with Next.js, React, TypeScript, TailwindCSS, shadcn/ui, lucide-react, and Recharts. Use when the user wants a Redis dashboard, key inspector, cache admin panel, key-namespace/TTL/memory monitoring UI, a Redis health/server-status view, or to inspect/scan/delete Redis keys. Produces a server-health banner + vitals (memory, fragmentation, hit rate, evictions, persistence, replication) with warnings and debug hints, KPI cards, a namespaces table with % progress bars, a key-type donut chart, TTL-range breakdown, recent-activity and top-memory-consumer tables, and scan/get/delete actions over typed mock data that can later connect to a real Redis API.
---

# Redis Admin Dashboard

Build a clean, professional Redis **key management** admin dashboard for inspecting and managing keys — KPIs, namespaces, key types, TTL ranges, activity, and memory consumers, with scan/get/delete actions.

> **First apply the `dashboard-foundations` skill** for setup, design tokens, the responsive grid, `StatCard`, and loading/empty/error states. This skill adds the Redis-specific data model, layout, components, and interactions. If `dashboard-foundations` isn't installed, follow the inline rules in §"Design rules" below.

## Reference docs (read on demand)

- [`references/data-model.md`](references/data-model.md) — all TypeScript types + realistic mock data (game:*, main-tabs:*, session tokens, etc.).
- [`references/components.md`](references/components.md) — the 8 reusable components with prop contracts.
- [`references/layout.md`](references/layout.md) — exact grid/section breakdown with class names.

Start by reading `data-model.md`, scaffold the types + mock layer, then build components per `components.md` arranged per `layout.md`.

## Goal

A SaaS-grade admin dashboard: soft borders, rounded-xl cards, subtle shadows, compact spacing, clear data hierarchy. Color only for icons, badges, chart segments, status, and destructive actions.

An operator must be able to glance at the top of the page and instantly know **whether Redis is healthy**, and if not, **what's wrong and how to debug it** — memory pressure, fragmentation, low hit rate, evictions, persistence lag, replication problems. That's the server-health banner + vitals (below); the key-management tables sit underneath.

## File structure to produce

```
app/(dashboard)/redis/page.tsx          # composes everything; owns refresh/auto-refresh state
components/redis/
  stat-card.tsx                          # (from dashboard-foundations) or local
  server-health-banner.tsx               # status + warnings, above KPIs
  server-vitals-card.tsx                 # specs grid (memory, fragmentation, hit rate...)
  health-issues-list.tsx                 # issues + debug/remediation steps (in a Sheet)
  namespaces-table.tsx
  key-types-chart.tsx
  ttl-range-card.tsx
  quick-actions-card.tsx
  recent-activity-table.tsx
  memory-consumers-table.tsx
  important-notes-card.tsx
lib/redis/
  types.ts                               # RedisOverviewStats, RedisNamespace, RedisServerHealth, ...
  mock.ts                                # typed mock data (incl. seeded health issues)
  format.ts                              # bytes, ttl, number, percent helpers
  health.ts                              # threshold evaluation: INFO values -> severity
  api.ts                                 # getOverview()/getServerHealth()/... (mock now, fetch later)
```

## Data model (types — full versions in references/data-model.md)

Create these strongly typed interfaces first:

- `RedisOverviewStats` — totalKeys, expiringKeys, memoryUsedBytes, avgTtlSeconds, hashKeys (+ maxMemoryBytes for %).
- `RedisNamespace` — id, prefix, keys, memoryBytes, avgTtlSeconds, expiringKeys. (% of total is **computed**, not stored.)
- `RedisKeyTypeSummary` — type (`string|hash|list|set|zset`), count.
- `RedisTtlRange` — label (`No TTL | < 1 min | 1 min - 1 hr | 1 hr - 24 hr | > 24 hr`), count.
- `RedisActivity` — id, time (ISO), action, keyOrPattern, status (`success|failed|pending`), by.
- `RedisMemoryConsumer` — keyOrPrefix, type, memoryBytes, keys.
- `RedisServerHealth` — status (`ok|warning|critical`), version, role, uptimeSeconds, `vitals: RedisVital[]`, `issues: RedisHealthIssue[]`.
- `RedisVital` — id, label, value, display, severity, hint. `RedisHealthIssue` — id, severity, title, detail, metric?, remediation. (Severity is **computed from `INFO` thresholds** in `lib/redis/health.ts`, not stored — see data-model.md.)

Use realistic sample prefixes: `game:*`, `main-tabs:*`, `sub-tabs:*`, `entity-last-paths:*`, `step_*`, `wizard_*`, `logged-in-session-token-*`, `session_activity_debounce:*`, `debounce:*`, `account_id:*`, `unauth-code:*`, `maintenance_mode`, `schema:*`.

## Layout (details in references/layout.md)

1. **Header** — Title "Overview" + subtitle "Inspect and manage your Redis keys". Right side: Refresh button, Auto-refresh `Select` (Off / 10s / 30s / 1m), current timestamp.
2. **Server Health banner** — full-width `Alert` colored by overall `status` (ok → slim, warning → amber, critical → destructive). Shows status + warning/critical count, `v{version} · {role} · uptime`, and "View details" → opens a `Sheet` with the `HealthIssuesList` (title, detail, metric, remediation). First thing visible so problems aren't missed.
3. **KPI row** — 5 `StatCard`s: Total Keys, Expiring Keys, Memory Usage, Average TTL, Hash Keys. Each: tinted icon square + value + helper text. Responsive 5 → 2/3 → 1.
4. **Main 12-col grid:**
   - **Left (`col-span-8`):** `NamespacesTable` — columns: Namespace/Prefix (colored `Badge`), Keys, % of Total (`Progress` bar, computed), Memory, Avg TTL, Expiring Keys, Actions (Inspect/search, View list, Delete — icon buttons with `Tooltip`).
   - **Right (`col-span-4`):** stacked — `ServerVitalsCard` (specs grid: memory used/max, fragmentation, hit rate, ops/sec, evictions, clients, persistence, replication — each tile color-coded by severity with a debug tooltip when not ok), `KeyTypesChart` (donut: String/Hash/List/Set/ZSet), `TtlRangeCard` (5 ranges as labeled progress rows), `QuickActionsCard` (Scan Keys by Prefix, Get Key, Delete Keys, Maintenance Mode), `ImportantNotesCard` (`Alert`).
5. **Bottom 2-col grid:**
   - **Left:** `RecentActivityTable` — Time, Action, Key/Pattern, Status (`Badge`), By.
   - **Right:** `MemoryConsumersTable` — Key/Prefix, Type, Memory, Keys.

Wrap long tables in `ScrollArea`.

## Components (contracts in references/components.md)

Build these as reusable, typed components — **no duplicated markup**:
`StatCard`, `NamespacesTable`, `KeyTypesChart`, `TtlRangeCard`, `QuickActionsCard`, `RecentActivityTable`, `MemoryConsumersTable`, `ImportantNotesCard`, plus the health trio `ServerHealthBanner`, `ServerVitalsCard`, `HealthIssuesList`.

## Computed logic (never hardcode)

- `% of total` per namespace = `namespace.keys / totalKeys * 100`.
- Memory usage % = `memoryUsedBytes / maxMemoryBytes * 100`.
- Format **bytes** (B/KB/MB/GB), **TTL** (`45s`, `12m`, `3h`, `2d` or `No TTL`), **counts** (`Intl.NumberFormat`), **percent** (1 decimal). Put these in `lib/redis/format.ts`.
- Sort memory consumers by `memoryBytes` desc; namespaces by `keys` desc by default.
- **Health severity is computed, never hardcoded** (`lib/redis/health.ts`): evaluate each vital against its threshold (memory used % > 75/90; fragmentation > 1.5/2.0 or < 1.0; hit rate < 90/80; evictions/rejections/blocked clients; persistence & replication status — full table in data-model.md). Overall `status` = worst severity. Sort issues critical-first.

## Interactions

- **Refresh** → mock loading state (skeletons), then re-read from `api.ts`.
- **Auto-refresh** `Select` → `setInterval` per chosen interval; clear on change/unmount. "Off" disables.
- **Inspect / Scan / Get** → open a `Sheet` (or `Dialog`) showing a placeholder key/scan result (key name, type, TTL, value preview, memory). Wire `Scan Keys by Prefix` to a `prefix` input.
- **Delete** (row action, Quick Actions "Delete Keys", bulk) → **confirm `Dialog`/`AlertDialog`** first, destructive button styling, then placeholder handler.
- **Maintenance Mode** → toggle with confirm; reflect the `maintenance_mode` key.
- **Health "View details"** → opens a `Sheet` with `HealthIssuesList` (each issue + remediation/debug step). Non-ok vitals show their `hint` in a `Tooltip`. Health re-reads on refresh/auto-refresh so warnings stay current.
- Every action button wired to a typed handler prop (placeholders OK) — no dead buttons. Icon buttons get `Tooltip` + `aria-label`.

## Design rules (inline fallback if dashboard-foundations absent)

White cards on light-gray page; `rounded-xl border shadow-sm`; neutral borders; compact spacing; dark semibold titles + muted descriptions; `tabular-nums` everywhere; color only for icons/badges/charts/status/destructive. Responsive KPIs 5→2/3→1.

## Future real API (structure mock to match)

`api.ts` functions map 1:1 to endpoints so swapping in real data needs no component changes:

```
GET    /api/redis/overview            -> getOverview()
GET    /api/redis/health              -> getServerHealth()   // derived from INFO
GET    /api/redis/namespaces          -> getNamespaces()
GET    /api/redis/keys?prefix=game:*  -> scanKeys(prefix)
GET    /api/redis/key/:key            -> getKey(key)
DELETE /api/redis/keys                -> deleteKeys(pattern)
POST   /api/redis/scan                -> scan(opts)
```

## Definition of done

- [ ] Typed model (incl. `RedisServerHealth`/`RedisVital`/`RedisHealthIssue`) + mock + `format.ts` + `health.ts` + `api.ts` getters
- [ ] Server-health banner (status + counts) above KPIs; `ServerVitalsCard` specs grid; `HealthIssuesList` sheet with remediation/debug steps
- [ ] Health severity **computed** from INFO thresholds (memory/fragmentation/hit-rate/evictions/persistence/replication); overall = worst
- [ ] 5 KPI cards, responsive 5→2/3→1
- [ ] Namespaces table with **computed** % progress bars + 3 row actions (tooltipped)
- [ ] Key-types donut + TTL-range card + Quick Actions + Important Notes alert
- [ ] Recent Activity + Top Memory Consumers tables (status badges, sorted)
- [ ] Refresh + auto-refresh (Off/10s/30s/1m) + skeleton loading
- [ ] Delete behind confirm dialog; scan/get open a Sheet/Dialog
- [ ] All components reusable; no duplicated markup; color used sparingly
