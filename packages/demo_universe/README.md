# demo_universe

Shared **offline** demo seed graph for YOLE Poste Finance DEM-01…DEM-12.

## Single source of truth

`data/universe.json` is the only seed. TypeScript and Dart loaders deep-clone it so session mutations do not corrupt the seed.

> `apps/admin_web/lib/demo-seed.ts` was not present on this branch; useful rows from `apps/admin_web/lib/mockData.ts` were migrated into this JSON. Mandatory shared IDs (`cust_kasee`, `cust_amina`, `agent-001`, `emp_poste`, …) are authoritative.

## TypeScript (admin)

```ts
import { loadUniverse } from 'demo_universe';

const u = loadUniverse(); // structuredClone of universe.json
```

Workspace package name: `demo_universe`.

## Dart (customer + agent)

```dart
import 'package:demo_universe/demo_universe.dart';

final u = DemoUniverse.load(); // reads ../data/universe.json (or pass path:)
```

Flutter apps should path-depend on `packages/demo_universe/dart` and optionally declare an asset pointing at `../data/universe.json` (or the synced `dart/assets/universe.json` copy).

## Honesty banners (in meta.honesty)

- Global: **Offline demo — no live API**
- Cards: **MOCK — not Visa/Mastercard certified**
- Resilience: **DEMO STORYBOARD — not a live HA failover**

## Test

```bash
cd packages/demo_universe && pnpm install && pnpm exec vitest run ts/load.test.ts
```

## Collections

staff, customers, wallets, agents, employers, employees, salaryHistory, journals, payments, agentTransactions, loanSchedules, loans, cards, cardAuths, remittances, fxRates, conversions, products, feeLimits, pendingApprovals, cases, reconDays, kyc, notifications, meta.demBookmarks.
