# NajdTV v4.0.2 — verified continuation and device handoff

Date: 2026-11-08. This document records repository evidence; it is **not** new proof of real-device playback.

## Immutable release identity

- **Verified actual release source:** `5e11a4abdd7750f5600cd30118109665148532e1`.
- Release tag: [v4.0.2](https://github.com/th-505/NajdTV/releases/tag/v4.0.2), **prerelease** (published 2026-11-08).
- Flutter source version: `4.0.2+402`; same version in `version.json`.
- Current public `main` was `adabac75142d83278b0cd18b73a666e1262ef344` when inspected; subsequent publication commits changed only `main.dart.js`, `source-manifest.json` and `version.json` relative to the release source.
- Reviewed six-target build: [Actions #42454773533](https://github.com/th-505/NajdTV/actions/runs/42454773533), all nine jobs successful including artifact verifier. Release promotion: [#42455529107](https://github.com/th-505/NajdTV/actions/runs/42455529107), successful. Pages deployment for `main`: [#42455746667](https://github.com/th-505/NajdTV/actions/runs/42455746667), successful.

## Distribution — already completed, do not recreate blindly

The release contains Android Mobile ARM64, Android TV ARM32, unsigned iOS IPA, Windows installer and ZIP, unsigned macOS DMG and Web ZIP, plus checksum files and verification documentation. Release artifacts are tied to the reviewed source; any subsequent client-code change needs a **new build and version**, not a replacement of the existing v4.0.2 binaries.

## What v4.0.2 actually fixed

- TV introduction: full Arabic verse/author, safe-area Continue button, delayed reveal and remote focus isolation.
- TV hero: shorter viewport-aware layout, deduplicated featured content; catalog identifiers are not displayed.
- Regression tests: `flutter_app/test/tv_photo_regression_test.dart` checks verse/button geometry at 640×360, 960×540, 1280×720 and 1920×1080, large text scrolling, focus, and duplicate/catalog rendering.
- Sources and browser limitations remain as specified in `docs/najd/RELEASE_4.0.2.md`; UI fixtures cannot certify a live upstream host.

## Remaining acceptance gates — do not mark completed without new evidence

| Priority | Work | Evidence required | State |
|---|---|---|---|
| P0 | Physical Android TV photo and remote regression | Install released TV APK; check verse/button at real overscan/scaling, D-pad focus and Back; open featured/detail/player and return; include model, resolution, timestamp | DEVICE_REQUIRED_PENDING |
| P0 | Real episode playback and source parity | For each accessible source, verify an observed episode ID, season, title and playable frame/audio with seek; keep access blocks distinct from parsing errors | LIVE_PENDING |
| P0 | Android in-place update identity | Verify installed app's certificate and release APK signing identity; do not uninstall or wipe private user data to mask mismatch | DEVICE_REQUIRED_PENDING |
| P1 | iPhone offline/download and playback | Sign IPA externally, then download → restart → library → offline play/seek → export; record errors | DEVICE_REQUIRED_PENDING |
| P1 | Web runtime + player in deployed browser | Check public site version, navigation, browser-supported MP4/HLS under actual CORS/codec policy, refresh/back and PiP on supported browser | LIVE_PENDING |
| P1 | macOS/Windows playback and controls | Install release, inspect OS trust warnings, actual play/seek, close/reopen and resume | DEVICE_REQUIRED_PENDING |
| P2 | Operational source health | Independently probe 3ckTV, 5TV and WitAnime; preserve ACCESS_BLOCKED if denied; no bypass claims | LIVE_PENDING |

## Next implementation rule

Create a new scoped branch from the current product head for any future code fixes. Preserve v4.0.2 release artifacts and the Android signing identity. Run source tests, Flutter analyze/tests, six-target artifact verifier and release promotion on the **exact reviewed commit** before shipping an increment. Do not interpret GitHub Actions success as real TV/iPhone certification.

## References

- [v4.0.2 release documentation](RELEASE_4.0.2.md)
- [Owner photograph regression evidence](PHOTO_REVIEW_4.0.2.md)
- [v4 database, provenance and recovery](V4_DATABASE_AND_RECOVERY.md)
- [v4.0.1 source and test baseline](V4_EXECUTION.md)
