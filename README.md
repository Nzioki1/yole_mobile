# Yole Mobile — Phase 0 Scaffold

This repository is a clean Flutter skeleton following the structure you specified.

## Quick start
```bash
flutter pub get
flutter gen-l10n --arb-dir=lib/core/i18n/arb --output-dir=lib/core/i18n/generated --output-class=S --output-localization-file=l10n.dart
flutter run
```

### Env files
Copy one of the examples:
```
cp environments/debug.env.example debug.env
cp environments/prod.env.example prod.env
```
(You can later wire a proper runtime config loader.)

## Notes
- Uses Riverpod for state management, Dio for networking.
- Basic i18n with Flutter's gen-l10n (English & French).
- Reusable widgets under `shared/widgets`.
- Feature-first folders under `lib/features`.