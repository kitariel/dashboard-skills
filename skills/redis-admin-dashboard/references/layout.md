# Redis Admin Dashboard — Layout Map

Exact responsive structure with Tailwind classes. Page background light gray, content max-width centered.

## Page shell

```tsx
<div className="min-h-screen bg-muted/40">
  <div className="mx-auto max-w-screen-2xl space-y-6 p-4 md:p-6">
    <Header />
    <KpiRow />
    <MainGrid />
    <BottomGrid />
  </div>
</div>
```

## 1. Header

```tsx
<div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
  <div className="space-y-1">
    <h1 className="text-2xl font-semibold tracking-tight">Overview</h1>
    <p className="text-sm text-muted-foreground">Inspect and manage your Redis keys</p>
  </div>
  <div className="flex items-center gap-2">
    <span className="hidden text-xs text-muted-foreground sm:inline tabular-nums">{timestamp}</span>
    <Select value={interval} onValueChange={setInterval}>{/* Off / 10s / 30s / 1m */}</Select>
    <Button variant="outline" size="sm" onClick={refresh} disabled={loading}>
      <RefreshCw className={cn("mr-2 h-4 w-4", loading && "animate-spin")} /> Refresh
    </Button>
  </div>
</div>
```

Auto-refresh `Select` options: `off | 10 | 30 | 60` (seconds). Render the timestamp client-side to avoid hydration mismatch (set it in `useEffect`).

## 2. KPI row — 5 cards

```tsx
<div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
  {/* Total Keys, Expiring Keys, Memory Usage, Average TTL, Hash Keys */}
</div>
```

Breakpoints: 1 col (mobile) → 2 (`sm`) → 3 (`lg`) → 5 (`xl`). When loading, render 5 skeleton stat cards.

## 3. Main grid — 8 / 4 split

```tsx
<div className="grid grid-cols-1 gap-6 lg:grid-cols-12">
  <div className="lg:col-span-8">
    <NamespacesTable ... />
  </div>
  <div className="space-y-6 lg:col-span-4">
    <KeyTypesChart ... />
    <TtlRangeCard ... />
    <QuickActionsCard ... />
    <ImportantNotesCard ... />
  </div>
</div>
```

On mobile the right column stacks below the table (single column).

## 4. Bottom grid — 2 equal columns

```tsx
<div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
  <RecentActivityTable ... />
  <MemoryConsumersTable ... />
</div>
```

## Dialogs & sheets (rendered once at page level)

- **Delete confirm** — `AlertDialog`: title "Delete keys?", shows the target prefix/pattern, destructive confirm button. Used by row delete, Quick Actions "Delete Keys", and maintenance toggle (its own confirm).
- **Inspect / Scan / Get** — `Sheet` (right side) or `Dialog`: header = key/prefix, body = type, TTL, memory, value preview, and (for scan) a prefix input + matched count + sample list. Placeholder content in mock mode.

## Loading strategy

- Initial mount: `loading = true`, show skeletons in each section, then `loadAll()`.
- Refresh / auto-refresh: set `loading` true briefly, keep layout stable, swap skeletons in per-section (avoid full-page flash).

## Spacing recap

- Outer padding `p-4 md:p-6`; section vertical rhythm `space-y-6`.
- Card padding via shadcn defaults (`CardHeader`/`CardContent`), tighten KPI cards to `p-4`.
- Grid gaps: KPIs `gap-4`, main/bottom `gap-6`.
