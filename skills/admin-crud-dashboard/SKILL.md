---
name: admin-crud-dashboard
description: Build a modern admin / back-office CRUD dashboard with Next.js, React, TypeScript, TailwindCSS, shadcn/ui, lucide-react, and TanStack Table. Use when the user wants an internal tool, admin panel, data-management UI, resource browser, or a data table with search, faceted filters, sorting, pagination, row actions, bulk actions, and create/edit forms with validation. Produces a reusable DataTable, a filter toolbar, row + bulk actions, and a create/edit form Sheet over typed mock data ready to connect to a real CRUD API.
---

# Admin CRUD Dashboard

Build a polished internal-tool / back-office dashboard centered on a powerful **data table**: search, faceted filters, sorting, pagination, row actions, bulk selection, and create/edit forms. The reference experience is Linear/Retool/Stripe back-office — dense but legible, keyboard-friendly, fast.

> **First apply `dashboard-foundations`** for setup, design tokens, the responsive grid, and loading/empty/error states. This skill adds the CRUD table, filter toolbar, and form patterns.

## Extra setup

On top of foundations:

```bash
pnpm dlx shadcn@latest add checkbox input label form command popover calendar
pnpm add @tanstack/react-table zod react-hook-form @hookform/resolvers date-fns
```

TanStack Table powers sorting/filtering/pagination/selection; `react-hook-form` + `zod` power the create/edit form.

## Goal

A resource manager (use **Users** as the default example resource, but keep it generic): a header with summary stats, a filter toolbar, a feature-rich table, and a create/edit `Sheet`. Everything strongly typed and column-driven so a new resource = a new column definition + schema.

## File structure

```
app/(dashboard)/admin/page.tsx           # owns data + table state
components/admin/
  data-table.tsx                          # generic <DataTable<TData>> (TanStack)
  data-table-toolbar.tsx                  # search + faceted filters + view options
  data-table-pagination.tsx
  data-table-column-header.tsx            # sortable header
  data-table-row-actions.tsx              # dropdown per row
  resource-form.tsx                       # create/edit form in a Sheet
  columns.tsx                              # column defs for the example resource
lib/admin/
  types.ts  mock.ts  schema.ts            # zod schema + inferred type  api.ts
```

## Data model (example: User)

```ts
export type UserRole = "owner" | "admin" | "member" | "viewer";
export type UserStatus = "active" | "invited" | "suspended";
export interface AdminUser {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  status: UserStatus;
  lastActive: string;   // ISO
  createdAt: string;     // ISO
}
```

`schema.ts` holds the `zod` object used by both the form and (later) the API; infer the create/edit type from it. `api.ts` exposes `listUsers(query)`, `createUser`, `updateUser`, `deleteUsers(ids)` mapping to `GET/POST/PATCH/DELETE /api/admin/users`.

## Layout

1. **Header** — Title + subtitle, right: "Add User" primary `Button` (opens create Sheet), Refresh.
2. **(Optional) KPI strip** — 3–4 `StatCard`s: Total Users, Active, Invited, Suspended (computed counts).
3. **Toolbar** (`data-table-toolbar`):
   - Left: search `Input` (filters name/email, debounced), faceted filter `Popover`s for **Role** and **Status** (multi-select with counts; show active filters as removable chips + "Reset").
   - Right: "View" `DropdownMenu` to toggle column visibility.
4. **DataTable**:
   - Selection checkbox column (header selects page), sortable columns via `data-table-column-header` (`ArrowUpDown`), status/role as colored `Badge`s, `lastActive` via relative time, per-row `data-table-row-actions` dropdown (View, Edit, Copy ID, Delete).
   - **Bulk action bar** appears when rows are selected: "N selected" + Delete (confirm) + Clear.
   - Sticky header; wrap body in `ScrollArea` if needed.
5. **Pagination** (`data-table-pagination`): rows-per-page `Select` (10/20/50), page count, prev/next + first/last.

## Generic DataTable contract

```ts
interface DataTableProps<TData, TValue> {
  columns: ColumnDef<TData, TValue>[];
  data: TData[];
  loading?: boolean;
  toolbar?: (table: Table<TData>) => React.ReactNode;
  onRowAction?: (action: string, row: TData) => void;
}
```
Keep it resource-agnostic: state (sorting, columnFilters, rowSelection, pagination, columnVisibility) lives inside via `useReactTable`. Swapping resources only changes `columns.tsx` + schema.

## Create / Edit form (`resource-form.tsx`)

- Opens in a `Sheet` (right side). Same form for create and edit (`mode`, optional `defaultValues`).
- `react-hook-form` + `zodResolver(schema)`; shadcn `Form`/`FormField`/`FormMessage` for inline validation.
- Fields: name (`Input`), email (`Input` type=email), role (`Select`), status (`Select`). Submit → `createUser`/`updateUser` (mock), close sheet, refresh table, toast.
- Disable submit while pending; show field-level errors.

## Interactions

- **Delete** (row or bulk) → `AlertDialog` confirm, destructive button, shows count, then mock delete + refresh.
- **Search & filters** update the table immediately (client-side on mock data; structured so the same query object can be sent to the server later — `{ search, role[], status[], sort, page, pageSize }`).
- **Refresh** mock loading → skeleton rows.
- **Row actions** wired via `onRowAction`/handlers — no dead menu items.
- Empty filtered result → friendly empty state with "Reset filters".

## States

- Loading → skeleton rows (match column count). Empty (no data) vs empty (filtered) are different messages. Error → `Alert` + retry.

## Design rules (fallback if dashboard-foundations absent)

White cards, light-gray page, `rounded-xl border shadow-sm`, compact dense rows (`h-12`), `tabular-nums` for numeric/date columns, color only for status/role badges + destructive. Fully responsive: toolbar wraps, table scrolls horizontally on mobile, KPI strip 4→2→1.

## Definition of done

- [ ] Typed model + zod schema (shared by form) + mock + api getters
- [ ] Generic `DataTable<TData>` (sort, filter, paginate, select, column visibility)
- [ ] Toolbar: debounced search + faceted Role/Status filters + reset + view options
- [ ] Row actions dropdown + bulk action bar (delete behind confirm)
- [ ] Create/Edit Sheet form with zod validation + toasts
- [ ] Pagination with rows-per-page
- [ ] Loading skeletons, distinct empty/filtered-empty/error states
- [ ] Resource-agnostic structure (new resource = new columns + schema)
