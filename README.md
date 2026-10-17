# Hue Rush

A casual, one-tap colour-sort puzzle. Colours flow into their matching lanes,
and when the rail jams you can flip the flow direction — the player controls
order and timing, not just placement.

Built with Flutter (Android + iOS from a single codebase).

## Run locally

```bash
flutter pub get
flutter run
```

## Android / iOS project folders

The `android/` and `ios/` folders are not committed here. The GitHub Actions
workflow generates `android/` automatically when building the APK. To build for
iOS or the desktop platforms locally, run:

```bash
flutter create . --platforms=ios,windows,macos,linux
```

iOS builds require macOS with Xcode.

## Build the APK

Push to `main` (or run the **Build APK** workflow manually from the Actions
tab). The release APK is attached to the workflow run, and a manual run or a
`v*` tag also publishes it to a GitHub Release.
