# 5.2.0 review validation — not a completed release

Final six-platform packaging remains blocked by outstanding acceptance tasks. No final release is claimed.

## Completed checks

- Full default Flutter suite (2026-11-17): 471 passed, 7 environment-dependent skips.
- Runtime Node suite: 352 passed, no failures before the additional browser-preview regression; targeted updated first-media/browser suite: 28 passed.
- Offline audited provider fixtures passed.
- Targeted account/library/cards suite: 29 passed; updated cleanup/source/identity regressions: 18 passed.
- Local debug Web compilation succeeded. Real Chromium checks passed panel back/forward, section history, reload, work/episode restoration and invalid-episode rejection, with zero page errors.
- Native TV target: 15 responsive/card/remote/focus/channel/season tests passed.

## Live source observations

The standard audit samples catalog/search/details and probes a container; it does not decode ten seconds or cover two films and fifteen series episodes per provider. Use the workspace network proxy for Node tests. Two parser families are not twice the number of independent websites.

- najd: 23 independent provider entries; failed=9, partial=6, passed=8.
- beta: 23 independent provider entries; failed=10, partial=5, passed=8.

Focused retry: AnimeZid catalog returned 181 rows in 5.7 seconds; Ahwak returned 52 rows in 0.5 seconds. Diagnostic request budget raised from 5 to 10 seconds based on that observation, preserving bounded requests and SSRF checks.

## Outstanding gates

- Physical Google TV hover/render and remote-key availability; iOS/native playback/background-download certification.
- Full requested source playback/quality/episode matrix, complete server background discovery and episode metadata enrichment.
- Recipient sharing and device-local PIN are implemented and tested in review; live database migration is applied. Real-device storage and notification delivery still require device verification.
- Remaining native background/whole-season queue behavior after leaving or closing the app; in-player channel/season selection and download/quality quick tools are implemented and tested.
- Short-drama source/category support, Asian catalog and classification audit, source-aware initial playback/retry errors.
- Secure revocable quick-watch link design; no promise of free unlimited video relay or multi-year upstream URL availability.
- Current package versions remain 5.0.1 until 5.2.0 acceptance is complete and version contracts are updated together.

Previous six-target review run 43921505393 had macOS cancelled and final verifier skipped; it did not produce the requested completed final release.

## Second review checkpoint

- MP4 browser playback and direct-file handoff, HLS browser playback, and live channel replacement/URL updates pass real Chromium tests using local codec fixtures, with no page exceptions. This is not a real provider or physical-TV playback certificate.
- Active native file downloads now finish after route disposal, with deferred client release. App termination/background execution and continuing the remainder of a season queue remain separate unfinished requirements.
- Web controller disposal waits briefly for deferred platform attachment; selecting the current channel updates list context without reopening its decoder. A fresh targeted player/lifecycle/download suite passed 48 tests.
- Backend-only PR #50 passed all GitHub checks and was merged as a1feef9a3964f294b914e12578a55fecbb39c64a. Render deploy dep-dbtohdh42hec73dk240g is live on the original single service. Health is 200; eight live groups and 50 Saudi catalog entries verified. API version remains 4.0.2 for installed-client compatibility. No final 5.2.0 packages have been published.
