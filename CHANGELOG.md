# Changelog

## Unreleased

### Known issues

- **`background_downloader` pinned to `^8.9.0`** — All 9.x releases fail to compile against AGP 9.x. The plugin conditionally skips applying `kotlin-android` when AGP ≥ 9, but still applies `org.jetbrains.kotlin.plugin.serialization` which depends on it, causing `Unresolved reference 'PermissionsService'` errors at build time. The 8.x line produces a KGP deprecation warning but builds and runs correctly. Upgrade once the plugin ships a fixed 9.x release. Tracked upstream at: https://github.com/781flyingdutchman/background_downloader
