# Poste Finance Biometrics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable opt-in device biometrics (fingerprint / Face Unlock) for (1) app login after splash screen and (2) Pay/Send transaction confirmation in the Flutter customer app. Both flows are gated by a user-controlled Profile toggle and tested on Pixel 8 using the offline demo mode.

**Architecture:** Add `local_auth` package + `BiometricAuthService` wrapping `local_auth` and `flutter_secure_storage`. Store unlock payload (email/password/transactionPin) in secure storage. Profile Settings toggle controls enable/disable. Splash screen attempts unlock on cold start when enabled. PinConfirmSheet replaces mock biometric with real implementation. Logout clears biometric data.

**Tech Stack:** Flutter, `local_auth`, `flutter_secure_storage` (already in use via `StorageService`), Riverpod, existing `AuthNotifier`, `OfflineDemoRepository.demoPin`, Pixel 8 for testing.

## Global Constraints

- Do **not** modify any file under `apps/admin_web/`.
- `flutter_secure_storage` is already in `pubspec.yaml` and used via `lib/services/storage_service.dart` — extend `StorageService` with biometric keys OR create `BiometricAuthService` that takes `FlutterSecureStorage` — pick one and be consistent in all tasks.
- `OfflineDemoRepository.demoPin = '123456'` is already seeded on login — use this for offline PIN confirms.
- `PinConfirmSheet` in `lib/widgets/pin_confirm_sheet.dart` currently mocks biometric with `onPinEntered('1234')` — must replace with real implementation.
- Splash (`lib/screens/splash_screen.dart`) is button-driven (Get Started / Login) — plan must add post-logo auto biometric attempt when enabled.
- Profile Settings (`lib/screens/profile_screen.dart`) has Language + Dark Mode tiles — add biometric `SwitchListTile` after Dark Mode using `l10n.biometricLogin`.
- `AuthNotifier.login` / `logout` exist in `lib/providers/auth_provider.dart` — wire biometric unlock to `login(email, password)` and logout to clear biometric data.
- Use `AuthenticationOptions(biometricOnly: true, stickyAuth: true)` for biometric prompts.
- Spec: `docs/superpowers/specs/2026-09-17-poste-finance-biometrics-design.md`.

### Unlock payload design (locked in)

**Storage key:** `biometric_unlock_payload` (JSON string)  
**Storage key:** `biometric_enabled` (boolean)

**Payload structure:**
```json
{
  "email": "kasee.demo@yole.com",
  "password": "Password1!",
  "transactionPin": "123456"
}
```

**Enable flow:** After successful biometric authentication, show password dialog asking for current password. On success, store email (from auth user) + password + transactionPin (`demoPin` for offline, user-entered PIN for live — v1 can default to `demoPin` for both) + set `biometric_enabled=true`.

**Splash unlock flow:** Attempt biometric → on success load payload → `AuthNotifier.login(email, password)` → `Navigator.pushReplacementNamed('/home')` on success. On fail/cancel, stay on splash (user can tap Login button).

**Transaction confirm flow:** In `PinConfirmSheet`, on biometric success call `onPinEntered(transactionPin)` from payload when offline OR when live. For v1, store `transactionPin` in payload at enable time (default to `demoPin` for both offline and live for simplicity; future versions can ask user to enter PIN separately for live mode).

**Logout:** Clear `biometric_enabled` + `biometric_unlock_payload` (extend `AuthNotifier.logout` or add `StorageService.clearBiometricData` / `BiometricAuthService.clearUnlock`).

**Design choice:** Extend `StorageService` with biometric methods (preferred for consistency) OR create `BiometricAuthService` that accepts `FlutterSecureStorage` instance (preferred for separation). Choose extending `StorageService` for this plan to keep all secure storage in one place.

### File map (create / modify)

| Path | Role |
|------|------|
| `pubspec.yaml` | Add `local_auth` dependency |
| `android/app/src/main/AndroidManifest.xml` | Add `USE_BIOMETRIC` permission (+ `USE_FINGERPRINT` if needed) |
| `lib/services/storage_service.dart` | Extend with biometric storage methods: `getBiometricEnabled`, `setBiometricEnabled`, `getBiometricUnlockPayload`, `saveBiometricUnlockPayload`, `clearBiometricData` |
| `lib/services/biometric_auth_service.dart` | **New** — wraps `local_auth` + delegates storage to `StorageService`: `canCheckBiometrics()`, `authenticate({required String reason})`, `isEnabled()`, `setEnabled(bool)`, `getUnlockPayload()`, `saveUnlockPayload(BiometricUnlockPayload)`, `clearUnlock()` |
| `lib/models/biometric_unlock_payload.dart` | **New** — model for unlock payload: `class BiometricUnlockPayload { final String email; final String password; final String transactionPin; ...}` |
| `lib/providers/biometric_provider.dart` | **New** — Riverpod provider for `BiometricAuthService` |
| `lib/screens/profile_screen.dart` | Add biometric toggle `SwitchListTile` after Dark Mode in Settings section; enable flow shows password dialog; disable clears data |
| `lib/screens/splash_screen.dart` | Add post-logo biometric unlock attempt (~900ms after logo animation) when enabled; success → login → navigate `/home`; fail/cancel → stay on splash |
| `lib/widgets/pin_confirm_sheet.dart` | Replace mock `_useBiometric()` with real biometric; show button only if enabled + available; on success call `onPinEntered(transactionPin)` |
| `lib/providers/auth_provider.dart` | Extend `AuthNotifier.logout()` to call `BiometricAuthService.clearUnlock()` |
| `test/biometric_auth_service_test.dart` | **New** — unit tests for `BiometricAuthService` using test-double storage |
| `test/storage_service_test.dart` | **New** or extend existing — unit tests for `StorageService` biometric methods |
| `README_FLUTTER.md` | Add Biometric Testing checklist for Pixel 8 |

---

