---
name: dashboard-foundations
description: Shared design system and setup for building modern admin/analytics dashboards with Next.js, React, TypeScript, TailwindCSS, shadcn/ui, lucide-react, and Recharts. Use when building ANY dashboard, admin panel, analytics overview, or data-heavy SaaS UI, or when another dashboard skill references "dashboard-foundations". Covers shadcn install commands, design tokens, the responsive 12-column grid, reusable StatCard/section primitives, and loading/empty/error states.
---

# Dashboard Foundations

The shared base for building dashboards that look like a polished SaaS product instead of a generic admin template. Other dashboard skills (redis-admin, saas-analytics, admin-crud) build on this. Apply these rules first, then layer the specific dashboard's data model and sections on top.

## When to use

Use whenever the task is to build a dashboard, admin panel, analytics overview, metrics page, or data-heavy internal tool — alone, or together with a more specific dashboard skill.

## 0. Project setup

Assumes Next.js (App Router) + TypeScript + Tailwind + shadcn/ui already initialized. If not, run `pnpm dlx shadcn@latest init` first.

Install the components dashboards need:

```bash
pnpm dlx shadcn@latest add card button badge table progress select \
  dropdown-menu chart sheet dialog alert separator skeleton tooltip scroll-area tabs

pnpm add lucide-react recharts
```

Adapt the package manager (`npm`/`yarn`/`bun`) to the project. Recharts is the engine behind shadcn's `chart`.

## 1. Design tokens & visual language

Hold this consistent across every dashboard:

- **Page background:** light gray (`bg-muted/40` or `bg-neutral-50`). **Cards:** white (`bg-card`).
- **Cards:** `rounded-xl border` with a subtle shadow (`shadow-sm`). Neutral/gray borders (`border-border`). No heavy drop shadows.
- **Spacing:** compact. Card padding `p-4` to `p-6`. Section gaps `gap-4` to `gap-6`.
- **Text hierarchy:** dark, semibold titles (`text-foreground font-semibold`); muted descriptions and helper text (`text-muted-foreground text-sm`). Big metric numbers `text-2xl`/`text-3xl font-bold tabular-nums`.
- **Color discipline:** the UI is mostly neutral. Use color **only** for: icons (in soft tinted squares), badges/status, chart segments, and destructive actions. Avoid rainbow dashboards.
- **Numbers:** always `tabular-nums` so columns align. Format with `Intl.NumberFormat` (counts, bytes, durations, percentages).
- **Icons:** `lucide-react`, typically `h-4 w-4` inline and `h-5 w-5` in tinted squares.

### Soft tinted icon square (used in every KPI card)

```tsx
<div className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary/10 text-primary">
  <Icon className="h-5 w-5" />
</div>
```

Swap the tint per metric: `bg-blue-500/10 text-blue-600`, `bg-amber-500/10 text-amber-600`, `bg-emerald-500/10 text-emerald-600`, `bg-rose-500/10 text-rose-600`, `bg-violet-500/10 text-violet-600`.

## 2. Responsive 12-column grid

The backbone of dashboard layout. Page wrapper, then sections:

```tsx
// Page shell
<div className="min-h-screen bg-muted/40">
  <div className="mx-auto max-w-screen-2xl space-y-6 p-4 md:p-6">
    {/* Header */}
    {/* KPI row */}
    {/* Main 12-col grid */}
    {/* Bottom grid */}
  </div>
</div>
```

- **KPI cards:** `grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5` — 1 col mobile, 2–3 tablet, up to 5 desktop.
- **Main content:** `grid grid-cols-1 gap-6 lg:grid-cols-12`, then `lg:col-span-8` (left) and `lg:col-span-4` (right).
- **Bottom split:** `grid grid-cols-1 gap-6 lg:grid-cols-2`.

Never hardcode pixel widths for columns — use the grid + `col-span-*`.

## 3. Reusable primitives (build these, don't inline-repeat)

Always extract reusable components instead of duplicating markup. At minimum, every dashboard gets a `StatCard`. Keep them in `components/dashboard/`.

### StatCard

```tsx
// components/dashboard/stat-card.tsx
import { Card, CardContent } from "@/components/ui/card";
import { type LucideIcon } from "lucide-react";
import { cn } from "@/lib/utils";

export interface StatCardProps {
  label: string;
  value: string;
  helper?: string;
  icon: LucideIcon;
  tint?: string; // e.g. "bg-blue-500/10 text-blue-600"
  delta?: { value: string; trend: "up" | "down" | "flat" };
}

export function StatCard({ label, value, helper, icon: Icon, tint = "bg-primary/10 text-primary", delta }: StatCardProps) {
  return (
    <Card className="rounded-xl">
      <CardContent className="flex items-start justify-between gap-3 p-4">
        <div className="min-w-0 space-y-1">
          <p className="truncate text-sm text-muted-foreground">{label}</p>
          <p className="text-2xl font-bold tabular-nums">{value}</p>
          {helper && <p className="truncate text-xs text-muted-foreground">{helper}</p>}
          {delta && (
            <span className={cn("text-xs font-medium",
              delta.trend === "up" ? "text-emerald-600" : delta.trend === "down" ? "text-rose-600" : "text-muted-foreground")}>
              {delta.value}
            </span>
          )}
        </div>
        <div className={cn("flex h-9 w-9 shrink-0 items-center justify-center rounded-lg", tint)}>
          <Icon className="h-5 w-5" />
        </div>
      </CardContent>
    </Card>
  );
}
```

### SectionCard

A titled card wrapper for tables/charts so headers stay consistent (title + optional description + optional right-side action slot). Use shadcn `Card`/`CardHeader`/`CardTitle`/`CardDescription`/`CardContent`.

## 4. Loading / empty / error states (don't skip these)

Every data section must handle all three — this is what separates production UIs from demos.

- **Loading:** shadcn `Skeleton` matching the shape (KPI cards → skeleton cards; tables → 5–8 skeleton rows; charts → a `Skeleton` block the chart's height). Never a bare spinner for the whole page.
- **Empty:** centered muted icon + short message + (optional) primary action. Not a blank area.
- **Error:** `Alert` (destructive variant) with a retry `Button`.

Drive these from explicit state, e.g. `type AsyncState = "idle" | "loading" | "error" | "ready"`.

## 5. Data layer pattern (mock now, API later)

1. Define **strongly typed** interfaces for every entity first.
2. Put mock data in `lib/mock/*.ts` returning those types.
3. Wrap reads in async functions (`getOverview()`, `getNamespaces()`) that currently return mock data but can later `fetch()` a real endpoint — components don't change.
4. **Compute** derived values (percentages, totals, averages) from the data; never hardcode a "% of total".

## 6. Interactions

- **Refresh** button triggers a mock loading state (set `loading`, await a short delay, swap data).
- **Auto-refresh** `Select`: `Off / 10s / 30s / 1m` driven by `setInterval` in a `useEffect` (clear on unmount/change).
- **Destructive actions** (delete) always go through a confirm `Dialog` / `AlertDialog`. Style the confirm button destructive.
- **Detail / scan / get** actions open a `Sheet` or `Dialog` with the relevant content (placeholder is fine in mock mode).
- Wire all action buttons to typed handler props (`onInspect`, `onDelete`, …), even if they're placeholders — never dead buttons.
- Add `Tooltip`s to icon-only action buttons.

## 7. Accessibility & polish

- Icon-only buttons need `aria-label` / `sr-only` text.
- Tables: real `<th scope="col">`; wrap long/scrolling tables in `ScrollArea`.
- Maintain visible focus rings (don't remove outlines).
- Respect `prefers-reduced-motion` for any transitions.

## Definition of done

- [ ] shadcn components + lucide-react + recharts installed
- [ ] Typed data model + mock layer behind async getters
- [ ] Reusable `StatCard` + section components (no duplicated markup)
- [ ] Responsive grid (5→2/3→1 KPIs; 8/4 main split)
- [ ] Loading skeletons, empty states, error+retry on every section
- [ ] Computed percentages/totals (nothing hardcoded)
- [ ] Refresh + auto-refresh + confirm-on-delete wired
- [ ] Color used only for icons/badges/charts/status/destructive
