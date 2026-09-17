# demo_universe

Shared **offline** demo seed graph for Poste Finance DEM-01…DEM-12.

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

final u = DemoUniverse.load(); // embedded kUniverseJson (web-safe)
```

Flutter apps path-depend on `packages/demo_universe/dart`. Runtime load uses embedded `dart/lib/universe_json.dart` (Chrome/web-safe). Authoring source of truth remains `data/universe.json`.

### Extend seed + regenerate Dart embed

1. Edit **`data/universe.json`** only (never hand-edit `dart/lib/universe_json.dart`).
2. Regenerate the embedded Dart constant from the JSON:

```bash
cd packages/demo_universe
node <<'NODE'
const fs = require('fs');
const raw = fs.readFileSync('data/universe.json', 'utf8').replace(/\s*$/, '');
const out =
  '/// Auto-generated embedded universe.json — do not edit by hand.\n' +
  "const String kUniverseJson = r'''\n" +
  raw +
  "\n''';\n";
fs.writeFileSync('dart/lib/universe_json.dart', out);
console.log('Wrote dart/lib/universe_json.dart (' + raw.length + ' chars)');
NODE
```

3. Re-run package tests: `pnpm exec vitest run ts/load.test.ts`
4. Re-run Flutter offline repository tests (customer + agent).
5. DEM click paths / acceptance: [`docs/demo/DEM-SCRIPT.md`](../../docs/demo/DEM-SCRIPT.md)

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
