---
name: saas-analytics-dashboard
description: Build a modern SaaS / product analytics dashboard with Next.js, React, TypeScript, TailwindCSS, shadcn/ui, lucide-react, and Recharts. Use when the user wants an analytics overview, growth/revenue/product metrics page, KPI dashboard with trends and deltas, MRR/ARR/churn/retention/funnel/cohort visualizations, or a date-range-filtered metrics view. Produces trend KPI cards with up/down deltas, time-series area/line charts, a conversion funnel, a retention/cohort view, and top-N tables over typed mock data ready to connect to a real analytics API.
---

# SaaS Analytics Dashboard

Build a clean product/marketing analytics overview: trend KPIs with deltas, time-series charts, a conversion funnel, retention, and top-N breakdowns. The vibe is a modern growth dashboard (think Stripe/Linear/Vercel analytics) — calm, scannable, trend-forward.

> **First apply `dashboard-foundations`** for setup, design tokens, the responsive grid, `StatCard`, and loading/empty/error states. This skill adds the analytics data model, sections, and chart patterns.

## Goal

An at-a-glance "how is the business/product doing" page: each KPI shows current value **and** a delta vs the previous period (green up / red down, with the *direction that's good* respected — e.g. churn down is good). Charts emphasize trend over precision.

## File structure

```
app/(dashboard)/analytics/page.tsx       # owns date range + comparison state
components/analytics/
  metric-card.tsx                         # trend KPI (value + delta + spark)
  trend-chart.tsx                         # area/line time series
  funnel-card.tsx
  retention-card.tsx                      # cohort grid or retention curve
  top-list-card.tsx                       # reusable top-N table
  date-range-picker.tsx
lib/analytics/
  types.ts  mock.ts  format.ts  api.ts
```

## Data model (define first)

```ts
export type Trend = "up" | "down" | "flat";
export interface MetricPoint { date: string; value: number; }        // ISO date
export interface Metric {
  id: string; label: string;
  value: number; unit: "currency" | "percent" | "count" | "duration";
  delta: number;            // signed % change vs previous period
  trend: Trend;
  goodWhen: "up" | "down";  // is "up" good for THIS metric? (churn => "down")
  series: MetricPoint[];     // for sparkline
}
export interface FunnelStep { label: string; users: number; }          // ordered, descending
export interface RetentionCohort { cohort: string; sizes: number[]; }   // sizes[0]=100%
export interface TopListItem { label: string; value: number; secondary?: string; }
export interface AnalyticsOverview {
  metrics: Metric[];                 // MRR, Active Users, Signups, Churn, Conversion, ARPU...
  revenueSeries: MetricPoint[];
  signupsSeries: MetricPoint[];
  funnel: FunnelStep[];               // Visited -> Signed up -> Activated -> Paid
  retention: RetentionCohort[];
  topPages: TopListItem[];
  topReferrers: TopListItem[];
}
```

Make mock data internally consistent (deltas reflect series; funnel strictly descending). Put async getters in `api.ts` mapping to `GET /api/analytics/overview?from=&to=` etc.

## Layout

1. **Header** — Title "Analytics" + subtitle. Right: `DateRangePicker` (Last 7d / 30d / 90d / Custom), a "Compare to previous period" toggle, Refresh.
2. **KPI row** — 4–5 `MetricCard`s (MRR, Active Users, Signups, Churn, Conversion). Each: value + signed delta badge colored by `goodWhen` (not just sign) + tiny sparkline (Recharts `<Area>` no axes).
3. **Main 12-col grid:**
   - **Left (`col-span-8`):** big `TrendChart` — revenue or signups over time (area chart, gradient fill, `Tabs` to switch metric, hover tooltip, optional dashed previous-period line).
   - **Right (`col-span-4`):** `FunnelCard` (horizontal bars per step + conversion % between steps).
4. **Bottom 2-col grid:**
   - **Left:** `RetentionCard` — cohort heatmap grid (rows = cohorts, cols = weeks/months, cell opacity ∝ retention %) **or** a retention curve.
   - **Right:** two stacked `TopListCard`s — Top Pages, Top Referrers (label + value + bar).

## Chart patterns (Recharts via shadcn `chart`)

- Use `ChartContainer` + `chartConfig` for consistent colors; one accent color for the primary series, muted gray for the comparison/previous line.
- Area charts: gradient fill (`<defs><linearGradient>`), `strokeWidth={2}`, hidden or minimal axes, `CartesianGrid` only horizontal + faint.
- Sparklines: no axes, no grid, no tooltip, ~40px tall, `isAnimationActive={false}` for snappy KPI cards.
- Format Y values with `lib/analytics/format.ts` (currency `$1.2k`, percent `12.4%`, compact counts `8.3k`).

## Delta logic (don't just color by sign)

```ts
function deltaTone(m: Metric): "positive" | "negative" | "neutral" {
  if (m.trend === "flat") return "neutral";
  const good = (m.trend === "up" && m.goodWhen === "up") ||
               (m.trend === "down" && m.goodWhen === "down");
  return good ? "positive" : "negative";
}
```
Positive → emerald, negative → rose, neutral → muted. Arrow icon follows `trend` (`ArrowUp`/`ArrowDown`), color follows `deltaTone`.

## Interactions

- **Date range** change re-reads data (mock loading state / skeletons).
- **Compare** toggle adds the previous-period line + shows deltas.
- **Metric tabs** on the main chart switch the series without layout shift.
- **Refresh** mock loading; **Export** button (placeholder) optional.

## Design rules (fallback if dashboard-foundations absent)

White cards, light-gray page, `rounded-xl border shadow-sm`, compact spacing, `tabular-nums`, color only for deltas/charts/badges. Responsive KPIs 5→2/3→1; main 8/4; bottom 2-col.

## Definition of done

- [ ] Typed model (Metric/Funnel/Retention/TopList/Overview) + mock + format + api getters
- [ ] 4–5 trend KPI cards with sparkline + tone-aware delta (goodWhen respected)
- [ ] Main area chart with metric tabs + optional previous-period comparison
- [ ] Funnel with step conversion %
- [ ] Retention cohort heatmap (or curve)
- [ ] Top Pages + Top Referrers lists with bars
- [ ] Date-range filter + compare toggle + refresh, all driving loading states
- [ ] Reusable components, no duplicated markup, color used sparingly
