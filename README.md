# Kids Podcasts

A simple Android podcast app for kids — curated whitelist of feeds, no social features, Wi-Fi-only downloads, background playback with lock-screen controls.

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) 3.x (Dart ^3.13.4)
- Android SDK (API 24+)
- A physical Android device or emulator for audio/download features

## Setup

```bash
flutter pub get
```

## Development

Run on a connected device or running emulator:

```bash
flutter run
```

Run on a specific device (use `flutter devices` to list):

```bash
flutter devices
flutter run -d <device-id>
```

Run with verbose output (useful for debugging plugin init errors):

```bash
flutter run --verbose
```

## Testing

```bash
# Full test suite
flutter test

# Single file
flutter test test/foo_test.dart

# Match by test name
flutter test --name "<substring>"

# Lint check (must stay clean)
flutter analyze
```

## Building a release APK

```bash
flutter build apk
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

Install directly to a connected device:

```bash
flutter install
```

Or via ADB after building:

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Whitelist

Edit `assets/catalog.json` to add or remove podcast feeds. Each entry:

```json
{
  "id": "unique-slug",
  "title": "Podcast Title",
  "feedUrl": "https://example.com/feed.xml",
  "artworkUrl": "https://example.com/art.jpg"
}
```

## Debugging a crash

```bash
# Stream logs from a running device
adb logcat -s flutter

# Dump recent logs after a crash
adb logcat -d | grep -E "FATAL|flutter|AndroidRuntime"
```
