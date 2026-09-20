# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Single-user Flutter (Dart `^3.13.4`) podcast app for a teenager, Android-only. Feeds are whitelisted in a bundled `assets/catalog.json`. No social / chat / comments — flat UI. Downloads are Wi-Fi only via `background_downloader` and go to app-private internal storage. Playback runs through `audio_service` + `just_audio` with lock-screen controls.

## Commands

```bash
flutter pub get
flutter analyze                          # must stay clean
flutter test                             # runs the whole suite
flutter test test/foo_test.dart          # single test file
flutter test --name "<substring>"        # match a test name
flutter run                              # requires a real device for audio/downloads
flutter build apk                        # only Android is scaffolded
```

## Architecture

Layered Riverpod app.

- `lib/data/catalog/` — `PodcastCatalog` interface + `BundledCatalog` impl reading `assets/catalog.json`. Designed so a future PIN-gated editable catalog can be swapped in without touching consumers.
- `lib/data/feed/` — `RssParser`, HTTP `FeedClient` honoring `If-None-Match` / `If-Modified-Since`, `FeedCache` (file-backed prod / in-memory test), and `FeedRepository` gluing them. 304 short-circuits to cached data. Feed cache lives at `<appDocs>/feed_cache/feed_<hash>.json`.
- `lib/data/playback/` — `PlaybackController` interface with a `FakePlaybackController` for widget tests and an `AudioServicePlaybackController` backed by an `EppAudioHandler` (extends `BaseAudioHandler`). Position is persisted every 5s to `LocalEpisodeStore` (shared_preferences JSON blob). `AutodeleteListener` watches for `completed=true`, and when the LocalEpisode has `autodelete=true`, deletes the file **before** the store row.
- `lib/data/download/` — `EpisodeDownloader` interface, `BackgroundEpisodeDownloader` wraps `background_downloader` with `requiresWiFi=true` and files under `<appDocs>/downloads/`, `FakeEpisodeDownloader` completes synchronously for tests.
- `lib/ui/` — home grid, podcast detail (paginated 10-per-page via a `PodcastFeedController`), downloads screen, mini-player + now-playing.

## Testing patterns

- Widget tests inject fakes via Riverpod overrides. `playbackControllerProvider`, `episodeDownloaderProvider`, and `localEpisodeStoreProvider` all throw `UnimplementedError` if not overridden — this is intentional so tests are forced to declare their dependencies explicitly.
- `SharedPreferences.setMockInitialValues({})` in `setUp` for anything touching prefs.
- Screens that overflow a 800×600 test viewport (`NowPlayingScreen`, tall lists in `PodcastDetailScreen`) resize `tester.view.physicalSize` to a taller window and `addTearDown(tester.view.reset)`.
- HTTP tests use `package:http/testing.dart`'s `MockClient`, not real sockets.

## Android specifics

- `minSdk=23` (pinned in `android/app/build.gradle.kts`).
- Manifest declares `INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, `POST_NOTIFICATIONS`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`. `audio_service`'s own manifest handles the service/receiver merge.
- `res/xml/backup_rules.xml` and `res/xml/data_extraction_rules.xml` exclude `downloads/` and `feed_cache/` from auto-backup.
- Runtime `POST_NOTIFICATIONS` prompt on Android 13+ is not yet requested by the app; users must grant it manually until this is wired up.

## Planning artifacts

The design doc backing this app lives at `~/.claude/plans/please-create-a-planning-functional-kahn.md`. Two deviations from the plan:

- Local persistence uses `shared_preferences` (JSON blob) rather than drift/sqlite. Reasonable while the schema is a single tiny KV; revisit if the schema grows.
- Artwork fallback is a `Material` icon inside a colored container, not a bundled illustration asset.
