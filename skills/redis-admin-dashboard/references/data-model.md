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
```

## `lib/redis/mock.ts`

Realistic, internally consistent sample. Keep `totalKeys` equal to the sum of namespace keys so computed percentages add up.

```ts
import type {
  RedisOverviewStats, RedisNamespace, RedisKeyTypeSummary,
  RedisTtlRange, RedisActivity, RedisMemoryConsumer,
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
