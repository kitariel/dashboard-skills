# Redis Admin Dashboard — Data Model & Mock Data

Strongly typed model first. Structure it so a real Redis API can replace the mock with **no component changes**.

## `lib/redis/types.ts`

```ts
export type RedisKeyType = "string" | "hash" | "list" | "set" | "zset";

export type RedisActivityStatus = "success" | "failed" | "pending";

export interface RedisOverviewStats {
  totalKeys: number;
  expiringKeys: number;        // keys with a TTL set
  memoryUsedBytes: number;
  maxMemoryBytes: number;      // for memory-usage %
  avgTtlSeconds: number;       // avg over keys that have a TTL
  hashKeys: number;
}

export interface RedisNamespace {
  id: string;
  prefix: string;              // e.g. "game:*"
  keys: number;
  memoryBytes: number;
  avgTtlSeconds: number | null; // null => no TTL on this namespace
  expiringKeys: number;
  // NOTE: "% of total" is computed at render time, not stored.
}

export interface RedisKeyTypeSummary {
  type: RedisKeyType;
  count: number;
}

export type RedisTtlRangeLabel =
  | "No TTL"
  | "< 1 min"
  | "1 min - 1 hr"
  | "1 hr - 24 hr"
  | "> 24 hr";

export interface RedisTtlRange {
  label: RedisTtlRangeLabel;
  count: number;
}

export interface RedisActivity {
  id: string;
  time: string;                // ISO timestamp
  action: string;              // "SCAN" | "GET" | "DELETE" | "EXPIRE" | "SET" ...
  keyOrPattern: string;
  status: RedisActivityStatus;
  by: string;                  // user / service identity
}

export interface RedisMemoryConsumer {
  keyOrPrefix: string;
  type: RedisKeyType;
  memoryBytes: number;
  keys: number;
}

// ---- Server health / vitals (the "is Redis OK?" model) ------------------
export type HealthSeverity = "ok" | "warning" | "critical";

// A single monitored metric, evaluated against thresholds at read time.
export interface RedisVital {
  id: string;
  label: string;            // "Memory used", "Fragmentation", "Hit rate"...
  value: number;            // raw numeric value for comparisons/sorting
  display: string;          // human-formatted ("182 MB / 256 MB", "94.2%")
  severity: HealthSeverity; // computed from thresholds (see format.ts/evaluate)
  hint?: string;            // short debug guidance shown when not "ok"
}

// A surfaced problem with a remediation/debug step.
export interface RedisHealthIssue {
  id: string;
  severity: "warning" | "critical";
  title: string;            // "Memory above 90% of maxmemory"
  detail: string;           // what's happening, plain language
  metric?: string;          // related value, e.g. "RSS 1.9× used"
  remediation: string;      // how to debug/fix (often a command to run)
}

export interface RedisServerHealth {
  status: HealthSeverity;   // overall = worst severity among issues/vitals
  version: string;          // e.g. "7.2.4"
  role: "master" | "replica";
  uptimeSeconds: number;
  vitals: RedisVital[];
  issues: RedisHealthIssue[];
}
```

### Thresholds & evaluation (the rules that turn raw INFO into severity)

These map directly to fields from Redis `INFO`. Keep them in `lib/redis/health.ts`:

| Vital | Source (`INFO` field) | warning | critical | debug hint |
|-------|-----------------------|---------|----------|------------|
| Memory used % | `used_memory` / `maxmemory` | > 75% | > 90% | `MEMORY DOCTOR`; review `maxmemory-policy`; find big keys (Top Memory Consumers) |
| Fragmentation ratio | `mem_fragmentation_ratio` | > 1.5 | > 2.0 **or** < 1.0 | >1.5 = fragmented (consider `activedefrag`); <1.0 = swapping to disk, add RAM |
| Hit rate | `keyspace_hits/(hits+misses)` | < 90% | < 80% | Low ratio → check TTLs / key design / cache warmup |
| Evicted keys | `evicted_keys` (rate) | > 0/min | rising fast | Hitting `maxmemory`; raise memory or tune eviction policy |
| Blocked clients | `blocked_clients` | > 0 | sustained | Inspect `CLIENT LIST`; long `BLPOP`/`WAIT`? |
| Rejected connections | `rejected_connections` | — | > 0 | Past `maxclients`; raise it / fix connection leaks |
| Connected clients | `connected_clients` / `maxclients` | > 80% | > 95% | Pool/leak check via `CLIENT LIST` |
| Persistence (RDB) | `rdb_last_bgsave_status`, `rdb_changes_since_last_save` | stale + many changes | `err` | `BGSAVE`; check disk space / `LASTSAVE` |
| Persistence (AOF) | `aof_enabled`, `aof_last_bgrewrite_status`, `aof_last_write_status` | — | `err` | Check disk; `BGREWRITEAOF`; review logs |
| Replication | `master_link_status` (replica) | `connecting` | `down` | Network/auth; check master `INFO replication` |
| Slowlog | `SLOWLOG LEN` | growing | large | `SLOWLOG GET 10`; optimize slow commands |

Overall `status` = the worst severity across all vitals/issues. A small pure helper:

```ts
export function evaluateMemory(usedPct: number): HealthSeverity {
  if (usedPct > 90) return "critical";
  if (usedPct > 75) return "warning";
  return "ok";
}
export function evaluateFragmentation(ratio: number): HealthSeverity {
  if (ratio > 2 || ratio < 1) return "critical";
  if (ratio > 1.5) return "warning";
  return "ok";
}
export function evaluateHitRate(pct: number): HealthSeverity {
  if (pct < 80) return "critical";
  if (pct < 90) return "warning";
  return "ok";
}
export const worst = (s: HealthSeverity[]): HealthSeverity =>
  s.includes("critical") ? "critical" : s.includes("warning") ? "warning" : "ok";
```

## `lib/redis/mock.ts`

Realistic, internally consistent sample. Keep `totalKeys` equal to the sum of namespace keys so computed percentages add up.

```ts
import type {
  RedisOverviewStats, RedisNamespace, RedisKeyTypeSummary,
  RedisTtlRange, RedisActivity, RedisMemoryConsumer, RedisServerHealth,
} from "./types";

export const mockNamespaces: RedisNamespace[] = [
  { id: "1",  prefix: "game:*",                       keys: 18432, memoryBytes: 84_500_000, avgTtlSeconds: 3600,   expiringKeys: 18432 },
  { id: "2",  prefix: "main-tabs:*",                  keys: 9210,  memoryBytes: 12_300_000, avgTtlSeconds: 86400,  expiringKeys: 1200  },
  { id: "3",  prefix: "sub-tabs:*",                   keys: 7640,  memoryBytes: 9_800_000,  avgTtlSeconds: 86400,  expiringKeys: 900   },
  { id: "4",  prefix: "entity-last-paths:*",          keys: 5120,  memoryBytes: 6_200_000,  avgTtlSeconds: null,   expiringKeys: 0     },
  { id: "5",  prefix: "step_*",                       keys: 4300,  memoryBytes: 3_100_000,  avgTtlSeconds: 1800,   expiringKeys: 4300  },
  { id: "6",  prefix: "wizard_*",                     keys: 3850,  memoryBytes: 2_700_000,  avgTtlSeconds: 1800,   expiringKeys: 3850  },
  { id: "7",  prefix: "logged-in-session-token-*",    keys: 2980,  memoryBytes: 5_400_000,  avgTtlSeconds: 604800, expiringKeys: 2980  },
  { id: "8",  prefix: "session_activity_debounce:*",  keys: 2140,  memoryBytes: 1_200_000,  avgTtlSeconds: 30,     expiringKeys: 2140  },
  { id: "9",  prefix: "debounce:*",                   keys: 1760,  memoryBytes: 900_000,    avgTtlSeconds: 10,     expiringKeys: 1760  },
  { id: "10", prefix: "account_id:*",                 keys: 1430,  memoryBytes: 4_100_000,  avgTtlSeconds: null,   expiringKeys: 0     },
  { id: "11", prefix: "unauth-code:*",                keys: 980,   memoryBytes: 600_000,    avgTtlSeconds: 300,    expiringKeys: 980   },
  { id: "12", prefix: "schema:*",                     keys: 120,   memoryBytes: 2_000_000,  avgTtlSeconds: null,   expiringKeys: 0     },
  { id: "13", prefix: "maintenance_mode",             keys: 1,     memoryBytes: 64,         avgTtlSeconds: null,   expiringKeys: 0     },
];

const totalKeys = mockNamespaces.reduce((s, n) => s + n.keys, 0);

export const mockOverview: RedisOverviewStats = {
  totalKeys,
  expiringKeys: mockNamespaces.reduce((s, n) => s + n.expiringKeys, 0),
  memoryUsedBytes: mockNamespaces.reduce((s, n) => s + n.memoryBytes, 0),
  maxMemoryBytes: 256 * 1024 * 1024, // 256 MB
  avgTtlSeconds: 4200,
  hashKeys: 21640,
};

export const mockKeyTypes: RedisKeyTypeSummary[] = [
  { type: "string", count: 28900 },
  { type: "hash",   count: 21640 },
  { type: "list",   count: 4200  },
  { type: "set",    count: 3100  },
  { type: "zset",   count: 2123  },
];

export const mockTtlRanges: RedisTtlRange[] = [
  { label: "No TTL",         count: 6671  },
  { label: "< 1 min",        count: 3900  },
  { label: "1 min - 1 hr",   count: 9210  },
  { label: "1 hr - 24 hr",   count: 24200 },
  { label: "> 24 hr",        count: 15982 },
];

export const mockActivity: RedisActivity[] = [
  { id: "a1", time: "2026-06-02T09:41:00Z", action: "SCAN",   keyOrPattern: "game:*",                    status: "success", by: "admin@svc" },
  { id: "a2", time: "2026-06-02T09:39:12Z", action: "DELETE", keyOrPattern: "debounce:*",                status: "success", by: "cron" },
  { id: "a3", time: "2026-06-02T09:36:05Z", action: "GET",    keyOrPattern: "account_id:8842",           status: "success", by: "support" },
  { id: "a4", time: "2026-06-02T09:30:48Z", action: "EXPIRE", keyOrPattern: "unauth-code:*",             status: "pending", by: "api" },
  { id: "a5", time: "2026-06-02T09:22:31Z", action: "DELETE", keyOrPattern: "logged-in-session-token-*", status: "failed",  by: "admin@svc" },
];

export const mockMemoryConsumers: RedisMemoryConsumer[] = [
  { keyOrPrefix: "game:*",                    type: "hash",   memoryBytes: 84_500_000, keys: 18432 },
  { keyOrPrefix: "main-tabs:*",               type: "string", memoryBytes: 12_300_000, keys: 9210  },
  { keyOrPrefix: "sub-tabs:*",                type: "string", memoryBytes: 9_800_000,  keys: 7640  },
  { keyOrPrefix: "entity-last-paths:*",       type: "string", memoryBytes: 6_200_000,  keys: 5120  },
  { keyOrPrefix: "logged-in-session-token-*", type: "string", memoryBytes: 5_400_000,  keys: 2980  },
].sort((a, b) => b.memoryBytes - a.memoryBytes);

// Server health — deliberately seeded with one warning + one critical so the
// UI shows the "Redis has a problem, here's how to debug it" state by default.
export const mockServerHealth: RedisServerHealth = {
  status: "critical", // = worst of the issues below
  version: "7.2.4",
  role: "master",
  uptimeSeconds: 1_904_400, // ~22 days
  vitals: [
    { id: "mem",   label: "Memory used",    value: 71.1, display: "182 MB / 256 MB", severity: "ok",       hint: undefined },
    { id: "frag",  label: "Fragmentation",  value: 2.1,  display: "2.10×",            severity: "critical", hint: "RSS far exceeds used — possible swapping. Check `MEMORY DOCTOR` / add RAM." },
    { id: "hit",   label: "Hit rate",       value: 87.4, display: "87.4%",            severity: "warning",  hint: "Below 90% — review TTLs and cache warmup." },
    { id: "ops",   label: "Ops / sec",      value: 12480,display: "12.5k",            severity: "ok" },
    { id: "evict", label: "Evicted keys",   value: 0,    display: "0",                severity: "ok" },
    { id: "cli",   label: "Clients",        value: 64,   display: "64 / 10000",       severity: "ok" },
    { id: "block", label: "Blocked clients",value: 0,    display: "0",                severity: "ok" },
    { id: "rdb",   label: "Last RDB save",  value: 8400, display: "2h 20m ago",       severity: "warning",  hint: "1.2M changes since last save — run `BGSAVE`." },
    { id: "aof",   label: "AOF status",     value: 1,    display: "OK",               severity: "ok" },
    { id: "repl",  label: "Replication",    value: 1,    display: "1 replica · linked",severity: "ok" },
  ],
  issues: [
    {
      id: "i1", severity: "critical",
      title: "Memory fragmentation ratio is 2.10×",
      detail: "Resident memory (RSS) is more than double the used memory. This usually means fragmentation or that Redis is swapping to disk, which causes severe latency.",
      metric: "mem_fragmentation_ratio = 2.10",
      remediation: "Run `MEMORY DOCTOR`. Enable `activedefrag yes`, or restart during a maintenance window. If RSS < used (ratio < 1) instead, the OS is swapping — add RAM.",
    },
    {
      id: "i2", severity: "warning",
      title: "Cache hit rate dropped to 87.4%",
      detail: "More requests are missing the cache than usual, increasing load on the backing store.",
      metric: "keyspace_hits / (hits + misses) = 87.4%",
      remediation: "Inspect short-TTL namespaces (debounce:*, unauth-code:*). Confirm cache warmup and that hot keys aren't being evicted.",
    },
    {
      id: "i3", severity: "warning",
      title: "1.2M changes since last RDB save (2h 20m ago)",
      detail: "A crash now would lose a large window of writes.",
      metric: "rdb_changes_since_last_save = 1,204,300",
      remediation: "Run `BGSAVE`, verify disk space, and check the snapshot schedule (`save` directives).",
    },
  ],
};
```

## `lib/redis/api.ts` (mock now, fetch later)

Async getters so components never change when the real API lands:

```ts
import * as mock from "./mock";

const delay = (ms = 400) => new Promise((r) => setTimeout(r, ms));

export async function getOverview()        { await delay(); return mock.mockOverview; }
export async function getNamespaces()       { await delay(); return mock.mockNamespaces; }
export async function getKeyTypes()         { await delay(); return mock.mockKeyTypes; }
export async function getTtlRanges()         { await delay(); return mock.mockTtlRanges; }
export async function getActivity()          { await delay(); return mock.mockActivity; }
export async function getMemoryConsumers()   { await delay(); return mock.mockMemoryConsumers; }
export async function getServerHealth()      { await delay(); return mock.mockServerHealth; } // GET /api/redis/health (from INFO)

// Action placeholders — swap for fetch() to /api/redis/* later.
export async function scanKeys(prefix: string)  { await delay(); return { prefix, matched: 0, sample: [] as string[] }; }
export async function getKey(key: string)       { await delay(); return { key, type: "string", ttl: 3600, value: "<preview>", memoryBytes: 128 }; }
export async function deleteKeys(pattern: string){ await delay(); return { pattern, deleted: 0 }; }
```

## `lib/redis/format.ts`

```ts
const nf = new Intl.NumberFormat("en-US");

export const formatNumber = (n: number) => nf.format(n);

export function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  const units = ["KB", "MB", "GB", "TB"];
  let v = bytes / 1024, i = 0;
  while (v >= 1024 && i < units.length - 1) { v /= 1024; i++; }
  return `${v.toFixed(v >= 10 ? 0 : 1)} ${units[i]}`;
}

export function formatTtl(seconds: number | null): string {
  if (seconds == null) return "No TTL";
  if (seconds < 60) return `${seconds}s`;
  if (seconds < 3600) return `${Math.round(seconds / 60)}m`;
  if (seconds < 86400) return `${Math.round(seconds / 3600)}h`;
  return `${Math.round(seconds / 86400)}d`;
}

export const formatPercent = (n: number) => `${n.toFixed(1)}%`;

export function relativeTime(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const m = Math.round(diff / 60000);
  if (m < 1) return "just now";
  if (m < 60) return `${m}m ago`;
  const h = Math.round(m / 60);
  if (h < 24) return `${h}h ago`;
  return `${Math.round(h / 24)}d ago`;
}
```
