# yole_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Prerequisites and common build issues ⚠️

This project expects a Flutter SDK compatible with the versions listed in
`pubspec.lock` (requires Flutter >= 3.35.0). If you see an error like:

```
Because every version of flutter_test from sdk depends on path 1.9.0 and flutter_native_splash >=2.4.5 depends on path ^1.9.1, flutter_test from sdk is incompatible with flutter_native_splash >=2.4.5.
```

This is usually caused by an older Flutter SDK on your machine. To fix it,
update to the latest stable Flutter version (recommended):

```bash
flutter upgrade
flutter pub get
```

If you cannot upgrade Flutter right away, a temporary workaround is to pin the
`flutter_native_splash` package to `^2.4.4` in `pubspec.yaml`, which is compatible
with older Flutter SDKs. This is a temporary mitigation; prefer updating Flutter
as soon as possible to benefit from the latest SDK and package improvements.

### macOS / iOS codesign failures (resource forks / Finder info)

If you see a codesign error like:

```
/path/to/Your.app: resource fork, Finder information, or similar detritus not allowed
Command CodeSign failed with a nonzero exit code
```

This usually means some files or bundles in your app have extended attributes or
Finder metadata that `codesign` rejects. To clean this up, we've added a small
utility script `tools/clean_app_resources.sh` that strips extended attributes and
`.DS_Store` files from an app bundle or folder.

Quick fix (recommended for local development):

```bash
# Clean a built macOS app bundle
tools/clean_app_resources.sh build/macos/Build/Products/Release/yole_mobile.app

# Clean a built iOS app bundle (if you tried building to a device)
tools/clean_app_resources.sh build/ios/iphoneos/Runner.app
```

If you still have attributes after running the script (sometimes host file
systems add persistent metadata), run the cleanup as an administrator (sudo):

```bash
sudo tools/clean_app_resources.sh build/macos/Build/Products/Release/yole_mobile.app
```

For CI, add a step that runs the script after the build product is generated and
before codesigning.

#### Add an Xcode post-process Run Script Build Phase (macOS / iOS)

To permanently fix this in Xcode builds, add a Run Script Build Phase to the
Runner project that runs `macos/clean_bundle_post_process.sh` after the
embedding of frameworks and before the `codesign` step.

1. Open ${PROJECT_DIR}/macos/Runner.xcworkspace in Xcode.
2. Select the Runner target, go to "Build Phases".
3. Add a new "Run Script" phase and set the script to:

```bash
(cd "${SRCROOT}" && sh macos/clean_bundle_post_process.sh)
```

4. Ensure the build phase runs **after** embedding frameworks and before codesigning.

This ensures the app bundle is cleaned of Finder/Resource metadata on every build,
preventing the `codesign` failure.


