# Task: Build a Smart Video Compression Module in Flutter (Clean Architecture + BLoC)

## Context

This is a **brand-new Flutter project** — set it up from scratch. The feature: a user picks or records a video (max 60 seconds), the app analyzes it and compresses it intelligently on-device using the phone's hardware encoder, shows a progress screen, then a result screen where the user can preview the compressed video, see the size saved, save it to the device gallery, or continue to upload it in the app.

Do not use FFmpeg or any FFmpeg-wrapping package (`ffmpeg_kit_flutter` and its variants are retired/unmaintained and must not be used). All encoding must go through native hardware encoders.

## Packages to use

- `v_video_compressor` — hardware-accelerated compression (Media3 on Android, AVFoundation on iOS), exposes manual control over resolution, bitrate, codec, frame rate, progress stream, cancellation.
- `image_picker` — pick video from gallery or record from camera.
- `video_player` + `chewie` (or just `video_player` with custom controls) — preview playback on the result screen.
- `gal` — save the compressed video to the device gallery; it handles the platform permission flow internally, use it rather than requesting photo library / storage permissions manually.
- `permission_handler` — only for any permission not covered by `gal` (e.g. camera/microphone for recording).
- `flutter_bloc` + `equatable` — state management.
- `get_it` + `injectable` (or manual DI, your call, but must be consistent) — dependency injection.
- `dartz` or a custom `Result`/`Either` type — functional error handling instead of throwing across layers.

## Architecture

Strict clean architecture, three layers, feature-first folder structure:

```
lib/
  core/
    di/
    error/
    theme/
    utils/
    widgets/
  features/
    video_compression/
      domain/
        entities/
        repositories/
        usecases/
      data/
        datasources/
        models/
        repositories/
      presentation/
        bloc/
        screens/
        widgets/
  main.dart
```

Rules:
- `domain` has zero dependency on Flutter or any plugin package — pure Dart entities, abstract repository interfaces, single-responsibility usecases (`AnalyzeVideoUseCase`, `CompressVideoUseCase`, `SaveVideoToGalleryUseCase`, `PickVideoUseCase`).
- `data` implements the repository interfaces, wraps the actual plugin calls (`v_video_compressor`, `gal`, `image_picker`) behind datasource classes so the plugins never leak outside `data`.
- `presentation` only talks to the domain layer through usecases via BLoC. No plugin import should ever appear in a widget or a BLoC file.

## The video comparison/compression service (domain + data)

Build this as its own cohesive service, not scattered logic:

1. **`VideoMetadata` entity** — width, height, duration, bitrate, fps, file size, codec.
2. **`VideoAnalysisService`** (domain interface, implemented in data) — probes the source file and returns `VideoMetadata`.
3. **`VideoCompressionPlanner`** — pure domain logic, no plugin dependency, takes `VideoMetadata` and returns a `CompressionPlan` value object (target width/height, target video bitrate, target frame rate, codec, and a `shouldSkipCompression` flag). Encode this decision logic:
   - Cap the longest edge at 1080px, never upscale, keep aspect ratio, round dimensions to the nearest multiple of 16.
   - Bitrate ladder based on target resolution: ~2.5 Mbps at ≤720p-equivalent pixel area, ~4.5 Mbps at ~1080p, ~6 Mbps above that.
   - Cap frame rate at 30fps.
   - Audio target: AAC, 128kbps.
   - If the source is already under ~15MB and its bitrate-per-pixel is already efficient, set `shouldSkipCompression = true` and pass the file through untouched — never double-compress.
   - Enforce a hard 60-second trim regardless of the source duration, as defense in depth even if the picker/recorder already limits duration.
4. **`VideoCompressionRepository`** (domain interface) with methods `analyze(File)`, `compress(File, CompressionPlan)`, exposing a `Stream<CompressionProgress>` for live percentage updates and supporting cancellation.
5. **`VideoCompressionRepositoryImpl`** (data) — wraps `v_video_compressor`, maps its progress callbacks/exceptions into the domain's own types, deletes any intermediate temp files on both success and failure.
6. **`GalleryRepository`** (domain interface) + implementation wrapping `gal`, exposing `saveVideo(File)` that returns a `Result` type (success / permission denied / failed), never throwing raw plugin exceptions into the BLoC.

## BLoC design

One `VideoCompressionBloc` (or split into `VideoPickBloc` + `VideoCompressionBloc` + `GallerySaveBloc` if you judge that cleaner — your call, but keep single-responsibility per bloc, don't build one giant god-bloc).

States must at minimum cover:
- Idle / no video selected
- Video selected, analyzing
- Compressing, with live progress percentage and estimated size
- Compression complete — original size, compressed size, percentage reduced, output file path
- Compression failed — with a clear, user-facing reason
- Saving to gallery — in progress / success / failed (permission denied vs. other failure, distinct states)

Events: pick from gallery, record video, start compression, cancel compression, save to gallery, retry, reset/start over.

## Screens (presentation layer)

Three screens, professional and production-grade. **No gradients anywhere** — solid, deliberate color use, generous whitespace, clear type hierarchy, consistent with a real design system (define a small `AppColors`, `AppTextStyles`, `AppSpacing` set in `core/theme` and use them everywhere, no ad-hoc hex codes in widgets).

1. **Select/Upload Screen** — empty state with an icon and short copy, two clear actions (choose from gallery / record video), and once a video is picked: a thumbnail preview card, its duration and file size, and a primary "Compress Video" button.
2. **Compression Progress Screen** — a clean circular or linear progress indicator with live percentage, a short status label that changes as it moves through analyzing → compressing, an estimated output size once known, and a cancel action.
3. **Result Screen** — video preview player, a compact stats card showing original size vs. compressed size and percentage saved, and two primary actions: **Save to Gallery** and **Continue** (proceed to upload flow). The save action must show its own inline state (saving spinner → success confirmation with a subtle checkmark state, or a failure state with retry) without navigating away from the screen. Include a tertiary "start over" action.

Every screen must handle and visibly present loading, error, and empty states — no silent failures, no bare `Container()` placeholders.

## Code quality constraints — read carefully

- Write this the way a senior engineer with real production experience would — meaning: clear naming, small focused functions/classes, no premature abstraction, no over-engineering, no dead code, consistent formatting, proper null-safety, proper use of `const` constructors everywhere possible.
- **Do not write comments**, with exactly one exception: a heavy/non-obvious operation (e.g. the bitrate-ladder calculation, the 16px alignment rounding, a native-plugin quirk workaround) may get a comment, but it must be **at most two lines**.
- **Never comment on variables** — if a variable needs an explanation to be understood, rename it instead of adding a comment.
- No commented-out code left in place.
- No `print()` debugging left in the final code — use a proper logging abstraction if you need one.
- Handle every plugin call's failure path explicitly; don't let a native exception surface unhandled into the UI.

## Project setup

Since this is starting from scratch:
- Initialize the Flutter project, add all dependencies above with current stable versions.
- Configure Android (`AndroidManifest.xml`) and iOS (`Info.plist`) permission entries required by `image_picker`, camera recording, and `gal`.
- Set up `get_it`/DI registration for all repositories, usecases, and datasources in `core/di`.
- Wire a minimal, clean `main.dart` and `MaterialApp` theme using the `core/theme` definitions, routing to the Select screen as the entry point.
- Ensure the whole flow (pick → analyze → compress with live progress → preview → save to gallery / continue) runs end to end.
