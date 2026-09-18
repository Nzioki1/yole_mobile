# Poste Finance Offline Mock Screens (Customer Flutter) — Design

**Date:** 2026-09-17  
**Repo:** `Nzioki1/yole_mobile`  
**Surface:** Flutter customer app at repo root (`lib/`)  
**Out of scope:** `apps/admin_web`, `apps/agent_mobile`, Color Admin template drop-in

## Goal

Ship a **fully offline** Android demo of the customer neo-bank app that:

- Reuses existing **YOLE** screens and layout/colors
- Shows the product name **Poste Finance** in user-visible strings
- Seeds **DRC** demo data (CDF + USD) so core screens look lived-in without `core-api`

## Non-goals (v1)

- Do not modify `apps/admin_web` or adopt Color Admin v5.5.2 Bootstrap assets into Flutter
- Do not implement cards, credit, remittance, FX, or KYC as seeded demo features
- Do not require a running NestJS `services/core-api` for the demo path
- Do not invent Poste Finance visual branding beyond the product name (no new logo unless supplied later)

## Decisions (approved)

| Decision | Choice |
|----------|--------|
| Look source | Reuse YOLE screens; Poste Finance **name only**; keep YOLE colors/layout |
| Data mode | Fully offline mock; seeded data only |
| Market | DRC — CDF and USD, Congolese-style contacts/rails |
| Screen scope | Core banking: home/wallets, pay/send/withdraw, history, profile |
| Approach | Seed pack + mock repository layer behind `USE_MOCK_DATA` |

## Architecture

1. **Config switch** — `USE_MOCK_DATA=true` via `--dart-define=USE_MOCK_DATA=true` (and/or a small local config). When on, providers bind to mock implementations. When off, existing `CoreApiService` path remains available for later.  
   *(Implementation note: the canonical flag name in code is `OFFLINE_DEMO`; this design's `USE_MOCK_DATA` refers to the same intent.)*
2. **Seed pack** — single Dart (preferred) or JSON fixture loaded at startup in mock mode: demo customer, CDF+USD wallets, recent payments, favorites, profile/limits.
3. **Mock repositories** — implement the same contracts home/pay/history/profile already use (auth, wallets, payments). Return seed data; keep **in-memory session state** so demo actions update balances/history until process restart.
4. **Branding** — replace user-visible "YOLE" / "Yole" with "Poste Finance" on the customer app strings in scope; do not change theme colors or layout structure.
5. **Non-core screens** — leave UI reachable; if they would hit the network, short-circuit with a friendly offline-demo stub/empty state so the device never waits on `:3000`.

```
USE_MOCK_DATA=true
        │
        ▼
┌───────────────────┐     ┌────────────────────┐
│ Seed pack         │────▶│ Mock repositories  │────▶ Core screens
│ (customer, wallets│     │ (auth/wallets/pay) │     (home, pay, history, profile)
│  payments, etc.)  │     │ in-memory session  │
└───────────────────┘     └────────────────────┘

USE_MOCK_DATA=false → existing CoreApiService → core-api (unchanged)
```

## Seed content (DRC)

One demo customer, already lived-in:

- **Profile:** Kinshasa-based customer — name, `+243…` phone, email; FR/EN language toggle continues to work locally.
- **Wallets:** USD and CDF pockets with healthy available balances; small blocked/pending amounts so UI is not all zeros.
- **Favorites:** 3–5 Congolese contacts (names + phones) for Pay/Send.
- **History:** ~8–12 recent items mixing W2W, mobile money in/out, bills — CDF and USD, fees consistent with current demo UX.
- **Home:** wallets + recent slice + existing quick actions (Pay/Send, Add Money, Withdraw, etc.).
- **Session:** successful Pay/Send or Withdraw updates in-memory balances and prepends a history row; app restart resets to the seed pack.
- **Assets:** text name only for v1; no Poste Finance logo unless supplied later.

Exact numeric amounts and names may be chosen by the implementer within this shape unless the product owner supplies values.

## Wiring and behavior

- **Providers:** mock mode resolves auth/wallet/payment providers to mock classes; otherwise unchanged.
- **Login:** offline mode skips real auth — auto-enter as the seeded customer **or** accept any credentials against the seed profile, whichever matches the current login UI with least friction. Prefer auto-login if the current flow can skip cleanly.
- **Pay / Send / Withdraw / Add Money:** same screens; quote/confirm use simple in-memory fee math consistent with today’s demo; then update wallets + history.
- **History / Profile:** read from the same in-memory store.
- **Non-core (cards, credit, remittance, FX, KYC):** stub/short-circuit network calls in mock mode.
- **Admin / agent / core-api codebases:** untouched for this work.

## Success criteria

With `USE_MOCK_DATA=true` and **no** `core-api` running:

1. App title / headers say **Poste Finance**; colors and layouts still match today’s YOLE look.
2. Home shows seeded CDF + USD wallets and recent activity (not empty).
3. Pay/Send and Withdraw complete offline and update balances + history for the session.
4. History and Profile show seeded content.
5. Airplane mode / unreachable API does not break the core path.
6. `apps/admin_web` is unchanged (no file edits under that tree).

## Testing

- Unit/widget tests on mock repo: seed load; payment updates balances and history.
- Manual Android device run (owner’s device already in use): happy path home → pay → history → profile with airplane mode or API stopped.

## Implementation notes (non-binding)

- Prefer extracting thin interfaces if providers currently depend on concrete `CoreApiService`; avoid large refactors unrelated to mock mode.
- Keep seed data in one place (e.g. `lib/mock/` or `lib/data/seed/`) so content can be edited without hunting screens.
- Document the dart-define in `README_FLUTTER.md` (customer app only).

## Open items resolved for v1

- Color Admin v5.5.2: **not** used for Flutter; optional future theme-token alignment only if separately requested.
- Poste Finance expectations: **not** in repo; this design defines the offline demo product shape agreed with the owner.

## Approval

Approved in conversation 2026-09-17: architecture, seed pack, wiring, success criteria.
