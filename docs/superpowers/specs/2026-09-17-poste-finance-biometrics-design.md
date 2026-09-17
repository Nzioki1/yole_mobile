# Poste Finance Biometrics Design

**Date:** 2026-09-17  
**Repo:** `Nzioki1/yole_mobile`  
**Surface:** Flutter customer app at repo root (`lib/`)  
**Test environment:** Pixel 8 with `OFFLINE_DEMO`

## Goal

Enable opt-in device biometrics (fingerprint / Face Unlock) for:
1. App login after splash screen
2. Pay/Send transaction confirmation

Both flows are gated by a user-controlled Profile toggle and tested on Pixel 8 using the offline demo mode.

## Non-goals (v1)

- iOS-specific biometric polish beyond `local_auth` defaults
- Biometric features in `apps/admin_web` or `apps/agent_mobile`
- Changes to live `core-api` PIN verification APIs
- Replacing transaction PIN entirely — password and PIN remain available as fallback

## Decisions (approved)

| Decision | Choice |
|----------|--------|
| Scope | Both Pay/Send confirm AND app login |
| Gating | Opt-in Profile toggle; OFF until user enables |
| Login UX | Prompt biometrics on app open AFTER splash; cancel/fail → Login screen |
| Approach | `local_auth` + existing `flutter_secure_storage` (not mock-only, not custom BiometricPrompt channel) |
| Unlock payload | Store enough data to restore session after successful biometric prompt |
| Enable requirement | Biometric success required before setting flag + storing payload |
| Disable flow | Clear flag + payload immediately (no biometric required) |
| Logout behavior | Clear unlock payload and turn `biometric_enabled` off |

## Architecture

### Core service

**BiometricAuthService** wraps `local_auth` and `flutter_secure_storage`:

- **Methods:**
  - `canCheckBiometrics()` — hardware + enrollment check
  - `authenticate(reason)` — prompt user for biometric verification
  - Get/set `biometric_enabled` flag
  - Get/set unlock payload (secure storage)

- **Storage keys:**
  - `biometric_enabled` — boolean flag
  - `unlock_payload` — encrypted session restore data

### Unlock payload

**Offline mode:** Store sufficient data to restore Jean-Paul's session (email / session restore for `OfflineDemoRepository`).

**Live mode:** May store access token using the same mechanism; exact structure deferred to implementation.

### Profile Settings

- **Control:** `SwitchListTile` using existing `l10n` key `biometricLogin`
- **Label:** Can be worded "Biometric Login & Pay" to cover both use cases
- **State:** Disabled + helper text if no enrolled biometrics detected
- **Enable path:**
  1. User toggles switch ON
  2. Prompt biometric authentication
  3. On success: set flag + store unlock payload
  4. On failure/cancel: revert toggle, show error
- **Disable path:**
  1. User toggles switch OFF
  2. Clear flag + payload immediately (no biometric prompt required)

### Splash screen flow

After logo animation completes:

```
if (biometric_enabled && biometricsAvailable) {
  prompt("Unlock Poste Finance")
  → on success: restore session → navigate to Home
  → on failure/cancel: navigate to Login screen
} else {
  navigate to Login screen (existing behavior)
}
```

### PinConfirmSheet (Pay/Send transaction confirm)

- **Current mock behavior:** Shows snackbar + calls `onPinEntered('1234')` — **replace with real implementation**
- **New behavior:**
  - Show "Use Biometric" button only when toggle ON AND hardware available
  - On tap: prompt biometric authentication
  - On success: confirm transaction via existing `verifyPin` code path
  - **Offline demo:** Use seeded PIN `123456` under the hood (do NOT keep current mock that submits `1234`)
  - User can still type PIN manually as fallback

### Logout

When user logs out:
1. Clear unlock payload from secure storage
2. Set `biometric_enabled` to `false`
3. Proceed with existing logout flow

## Android

Add required permissions to `android/app/src/main/AndroidManifest.xml`:

- `USE_BIOMETRIC` (primary)
- `USE_FINGERPRINT` (legacy, if required by `local_auth` for older API levels)

Use biometric-only prompts (no device-credential PIN fallback for this feature).

## Existing hooks to replace/extend

- **`lib/widgets/pin_confirm_sheet.dart`** — currently mocks biometric with snackbar + `onPinEntered('1234')`; replace with real `local_auth` gated by toggle
- **`flutter_secure_storage`** — already in `pubspec.yaml`
- **`l10n` key `biometricLogin`** — already exists for Profile UI
- **Profile tip text** — already mentions enabling biometric login

## Success criteria

With toggle enabled and fingerprint enrolled on Pixel 8:

1. **Cold start:** App unlocks to Home after successful biometric prompt (skips Login screen)
2. **Pay/Send confirm:** Transaction confirms with fingerprint without typing PIN
3. **Toggle off:** App requires password login + PIN confirm (today's behavior)
4. **Fallback:** Cancel/failure on biometric prompt falls back to password/PIN entry
5. **Logout:** Clears biometric unlock; next open requires login

## Testing

- **Unit tests:**
  - `BiometricAuthService`: flag persistence, payload storage/retrieval
  - Enable/disable flows update storage correctly
- **Widget tests:**
  - Profile Settings: biometric button hidden when toggle disabled
  - PinConfirmSheet: biometric button appears only when enabled + available
- **Manual verification (Pixel 8):**
  - Enable toggle → enroll fingerprint → cold start unlocks
  - Pay/Send confirms with fingerprint
  - Disable toggle → password + PIN required
  - Logout clears unlock data

## Implementation notes (non-binding)

- Document Pixel 8 verification steps in `README_FLUTTER.md` under a "Biometric Testing" or similar checklist section
- Keep biometric service thin: delegate to `local_auth` for platform UX, use `flutter_secure_storage` for keys only
- Offline demo PIN value `123456` should be referenced from seed pack or constants, not hardcoded in multiple places

## Approval

Approved in conversation 2026-09-17: scope (login + pay confirm), toggle-gated approach, `local_auth` + `flutter_secure_storage` architecture, success criteria.
