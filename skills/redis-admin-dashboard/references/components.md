# Redis Admin Dashboard — Component Contracts

Eight reusable, typed components. Keep markup DRY — share `StatCard` and a `SectionCard` wrapper. All live under `components/redis/`. Each receives data + handlers via props (no data fetching inside leaf components except where noted).

## Prefix badge color map

Deterministically tint namespace badges so the same prefix always gets the same color. Keep it subtle.

```tsx
const BADGE_TINTS = [
  "bg-blue-500/10 text-blue-600",
  "bg-violet-500/10 text-violet-600",
  "bg-emerald-500/10 text-emerald-600",
  "bg-amber-500/10 text-amber-600",
  "bg-rose-500/10 text-rose-600",
  "bg-cyan-500/10 text-cyan-600",
  "bg-fuchsia-500/10 text-fuchsia-600",
];
const tintFor = (prefix: string) =>
  BADGE_TINTS[[...prefix].reduce((a, c) => a + c.charCodeAt(0), 0) % BADGE_TINTS.length];
```

## 1. `StatCard`
From `dashboard-foundations`. Props: `{ label, value, helper?, icon, tint?, delta? }`. Used for the 5 KPIs:

| Card | icon (lucide) | value | helper | tint |
|------|---------------|-------|--------|------|
| Total Keys | `Database` | `formatNumber(totalKeys)` | "across N namespaces" | blue |
| Expiring Keys | `Timer` | `formatNumber(expiringKeys)` | "% of total have TTL" | amber |
| Memory Usage | `MemoryStick` | `formatBytes(used)` | "of 256 MB (xx%)" | violet |
| Average TTL | `Clock` | `formatTtl(avgTtlSeconds)` | "across expiring keys" | cyan |
| Hash Keys | `Hash` | `formatNumber(hashKeys)` | "largest type" | emerald |

## 2. `NamespacesTable`
```ts
interface NamespacesTableProps {
  namespaces: RedisNamespace[];
  totalKeys: number;
  loading?: boolean;
  onInspect: (ns: RedisNamespace) => void;
  onViewList: (ns: RedisNamespace) => void;
  onDelete: (ns: RedisNamespace) => void;
}
```
- shadcn `Table`. Columns: **Namespace/Prefix** (`Badge` w/ `tintFor(prefix)`), **Keys** (`tabular-nums`, right-aligned), **% of Total** (`Progress` + `formatPercent`, value = `keys/totalKeys*100`), **Memory** (`formatBytes`), **Avg TTL** (`formatTtl`), **Expiring Keys**, **Actions**.
- Actions = three icon `Button`s (`ghost`, `size="icon"`), each in a `Tooltip` with `aria-label`: `Search` (Inspect), `List` (View list), `Trash2` (Delete, `text-destructive`).
- `loading` → render 6 `Skeleton` rows. Empty → muted "No namespaces" row. Wrap in `ScrollArea` if tall.

## 3. `KeyTypesChart`
```ts
interface KeyTypesChartProps { data: RedisKeyTypeSummary[]; loading?: boolean; }
```
- Donut via shadcn `ChartContainer` + Recharts `PieChart`/`Pie` (`innerRadius` set) with a center label showing total keys.
- Segments String/Hash/List/Set/ZSet with a fixed `chartConfig` color per type. Legend below with counts. Loading → `Skeleton` sized to chart.

## 4. `TtlRangeCard`
```ts
interface TtlRangeCardProps { ranges: RedisTtlRange[]; loading?: boolean; }
```
- `SectionCard` titled "Expiring Keys by TTL Range". One row per range: label (left), count (right), `Progress` whose value = `count / max(counts) * 100`. Keep neutral; the bar carries the comparison.

## 5. `QuickActionsCard`
```ts
interface QuickActionsCardProps {
  onScanByPrefix: () => void;
  onGetKey: () => void;
  onDeleteKeys: () => void;
  onToggleMaintenance: () => void;
  maintenanceOn: boolean;
}
```
- `SectionCard` "Quick Actions" with four full-width `Button`s + leading icons: `Scan Keys by Prefix` (`ScanSearch`), `Get Key` (`KeyRound`), `Delete Keys` (`Trash2`, destructive), `Maintenance Mode` (`Wrench`, shows on/off `Badge`). Destructive + maintenance go through confirm dialogs in the page.

## 6. `RecentActivityTable`
```ts
interface RecentActivityTableProps { items: RedisActivity[]; loading?: boolean; }
```
- `SectionCard` "Recent Activity". `Table` columns: **Time** (`relativeTime`), **Action**, **Key/Pattern** (`font-mono text-xs truncate`), **Status** (`Badge`: success=emerald, failed=rose, pending=amber), **By**.

## 7. `MemoryConsumersTable`
```ts
interface MemoryConsumersTableProps { items: RedisMemoryConsumer[]; loading?: boolean; }
```
- `SectionCard` "Top Memory Consumers". `Table` columns: **Key/Prefix** (`Badge`), **Type** (`Badge outline`), **Memory** (`formatBytes`, sorted desc), **Keys**. Optionally a thin `Progress` under Memory relative to the top consumer.

## 8. `ImportantNotesCard`
```ts
interface ImportantNotesCardProps { notes?: string[]; }
```
- shadcn `Alert` (default/warning tone) with `Info`/`TriggerAlert` icon, title "Important Notes", and a short bulleted list, e.g.:
  - "Deleting by pattern is irreversible — scan first to preview matches."
  - "`maintenance_mode` toggles read-only behavior across services."
  - "Keys without a TTL never expire and can grow memory unbounded."

## Shared `SectionCard`
```tsx
function SectionCard({ title, description, action, children }: {
  title: string; description?: string; action?: React.ReactNode; children: React.ReactNode;
}) {
  return (
    <Card className="rounded-xl">
      <CardHeader className="flex flex-row items-center justify-between gap-2 space-y-0">
        <div className="space-y-1">
          <CardTitle className="text-base">{title}</CardTitle>
          {description && <CardDescription>{description}</CardDescription>}
        </div>
        {action}
      </CardHeader>
      <CardContent>{children}</CardContent>
    </Card>
  );
}
```

## Page composition (`app/(dashboard)/redis/page.tsx`)
- `"use client"`. Holds state: data objects, `loading`, `autoRefresh` interval, dialog/sheet open state + selected key/namespace.
- `loadAll()` calls the `api.ts` getters (`Promise.all`), toggling `loading`.
- `useEffect` for auto-refresh `setInterval`; cleared on change/unmount.
- Confirm `Dialog`/`AlertDialog` for deletes & maintenance; `Sheet` for inspect/scan/get results.
- Renders Header → KPI grid → 12-col main grid (8/4) → bottom 2-col grid, passing data + handlers down.
