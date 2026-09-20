# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter application (Dart SDK `^3.13.4`). Currently the default `flutter create` counter-app scaffold in `lib/main.dart` — no domain code has been added yet. Only the Android platform folder is present; iOS/web/desktop targets have not been scaffolded.

Note: `lib/main.dart` as committed contains two syntactically invalid tokens (`.fromSeed(...)` at line 31 and `.center` at line 105) — the leading type/enum name is missing. These need to be `ColorScheme.fromSeed(...)` and `MainAxisAlignment.center` before the app will compile.

## Commands

```bash
flutter pub get                     # install dependencies
flutter run                         # run on the connected device/emulator
flutter analyze                     # static analysis (uses analysis_options.yaml)
flutter test                        # run all tests
flutter test test/widget_test.dart  # run a single test file
flutter test --name "<substring>"   # run tests whose names match a substring
flutter build apk                   # build Android APK (only Android is configured)
```

## Lints

`analysis_options.yaml` extends `package:flutter_lints/flutter.yaml` and excludes `build/**` and `android/**` from analysis. Add project-specific rules under the `linter.rules:` block in that file rather than sprinkling `// ignore:` comments.
