# Current release work: 5.2.0

Published 2026-11-21: [v5.2.0](https://github.com/th-505/NajdTV/releases/tag/v5.2.0), immutable application source `715b6273ccdef0e5e358232dad33f45fd298b693`. All six target packages passed the aggregate verifier in run 44280734955 attempt 3. Public Web manifest now reports 5.2.0+520 from that source. Older release-hold statements below are historical. Deferred server features and physical-device certification remain explicitly incomplete.

Latest steering (2026-11-18): prioritize completing client/package changes, distinguish them from later server-only delivery, and do not claim installed applications gain new UI from a backend update. See [delivery matrix](DELIVERY_5.2.0.md).

Latest user decision: email/password login; signup with display name/email/password. Email confirmation remains supported, not a mandatory newly implemented OTP-only design. Local quick unlock must not become username + short-code remote authentication. Six target builds are authorized after completion, with no partial release. The older intake below is retained as history; the final status section identifies what is actually implemented.

# Pending account/settings work — approval required before any build

User steering, 2026-11-16: accumulate build tasks; do not build or release until the user explicitly approves. This supersedes earlier requests to rebuild automatically. Do not trigger a build indirectly through a push, PR, merge or automatic deployment. Current instructions are saved in AGENTS.md. No version number should be guessed: voice mentioned “5.2” followed by “صفر اثنين”; confirm the exact valid version before a release.

## Earlier task intake (historical; current implementation status below)

- Email-code authentication instead of requiring a long account password. A four-digit PIN is a device-local quick-unlock mechanism, not a four-digit Supabase account password or proof of account ownership.
- Explicit logout and account switching, keeping each account's library, progress, pending writes and local snapshot isolated.
- Persistent Supabase session recovery on reopening the same site/origin; diagnose expiry, refresh and storage before choosing a fix. Never create an anonymous replacement account on failure. Keep secrets out of preferences/diagnostics for any new PIN implementation; decide on appropriate platform storage and retry controls before coding.
- Separate settings routes: account/profile (avatar, name, confirmed email, identifier, logout), device linking, library backup, and independent routes for the other existing settings categories. Avoid putting unrelated controls into one long page. Preserve back navigation and all existing features.
- Prepare and verify the email templates required by OTP flows (signup, magic-link/login, email change for legacy upgrades). The template must actually include the code, not merely a confirmation link. Do not publish a code-only interface before email delivery/verification is tested.

## Background work allowed without starting a build

- Read-only diagnostics of authentication/session state and delivery configuration, without consuming one-time links or exposing tokens.
- Prepare reviewable backend/configuration changes that do not deploy automatically. Any Docker/Render rebuild or production-code push needs explicit build approval first.
- Document required Supabase dashboard settings if the connected tool cannot update Auth configuration. Do not simulate a successful configuration change with an unrelated SQL setting.

## Current state when this policy was recorded

- Original single-server production hotfix and new identity assets are live; the eight live playlists return data. PR #48 and publication safety PR #49 were already merged before this policy.
- User's Supabase return URLs have been verified: default returns to the HTTPS Najd site; explicit confirmation return reaches the HTTPS callback page. No localhost redirect was observed in that check. The user's real account was already confirmed.
- Client work remains draft PR #47, review branch `build/mitv-5.0.1`, source e1f27fae340c54c9d94181d0d5338181e8ef5039. No new code for the accepted PIN/OTP/settings-page request has been applied yet.
- Previously authorized six-target review run 43921505393 is completed with failure; inspect the failed job read-only and record the cause. Do not rerun it without approval. No new client release was published.

## TV-browser report, 2026-11-16 — original intake

User clarified Google TV third-party browser with mouse; screenshots show the same source-picker route before/after a white rectangle, not wrong provider-page content. Do not confuse this Web environment with the native TV package.

- Investigate white rectangle appearing near global scroll-to-top hover; proximity is evidence, not proven compositor/tooltip cause. Capture browser name/version and reproduce before attributing root cause.
- Show scroll-to-top only for an active visible vertically overflowing route, with meaningful scroll offset; hide/reset on navigation and player, reject stale/detached scroll positions and unrelated nested scrolls. Current code wraps the entire Navigator, stores last observed position and only checks pixels >600; no route or overflow gate. This explains stale visibility risk, not the white paint rectangle conclusively.
- Review landscape/TV-browser typography using actual logical viewport, browser zoom and accessibility text scale. Native TV multiplier is conditional on MITV_TARGET=tv, so it does not establish why the public Web page has large text. Preserve accessibility and adequate remote focus targets.
- Compact poster cards to poster aspect ratio with short title over a readable translucent gradient; avoid long repeated type/provider/title text extending cards. Keep accessible labels and title details.
- Experimental provider browser: keep entered query unchanged on provider switch; add RTL-positioned clear X on the left; allow independent browsing of any selected provider without silently switching the main scraper. Audit both parser families for drift.
- Ahwak episode durations/posters: investigate first-index missing duration, ten-episode report and metadata availability per episode. Existing selected-watch-page observations do not prove full episode-index enrichment. Never fabricate durations or episode counts.
- Investigate initial no-compatible-source result followed by successful retry: resolution/probe freshness, supported container, async status race and stale error state. Do not present definitive failure while discovery is still pending. User reports forward/back seek works, center OK does not pause in Web.
- Remote mapping as a separate settings route: record only events actually delivered by browser/OS, map center/Enter/select and play/pause with focus-aware handling; allow per-device defaults/reset and avoid interference with text input. Web cannot request arbitrary system-wide remote interception or control television system volume. Home/settings/power and other OS-reserved buttons remain unassignable; browser may never deliver them. Native Android handling needs its own platform verification, not a universal promise.

Acceptance after explicit build approval: physical Google TV browser mouse hover/scroll/navigation/player checks, responsive portrait/landscape cards, query preservation, source-specific episode metadata, initial playback versus retry, and available remote key capture. No new build, version bump, CI dispatch, push or deployment performed for this report.

## Expanded authorized release scope — 2026-11-16

User explicitly authorizes server updates and six release targets AFTER completing client tasks and acceptance. Do not publish partial completion; do not equate passing build with physical playback. Version must be resolved before version edits.

- Responsive smaller landscape/TV posters and text, poster-overlay titles; stable internal back navigation and browser history; scroll button only on overflowing current routes, never lingering on player.
- Provider verification matrix: where available, two films and three series with five episodes each per provider; distinguish real 10-second playback/quality observations from HTTP/container probes, unavailable samples and device limitations. Preserve all servers, prioritize observed quality and offer alternatives; first playable promptly, bounded background discovery with durable/resumable progress rather than silently discarding remaining hosts. Retain network safety and resource bounds; no protection bypass or unlimited concurrent requests.
- Account verification before cloud identity acceptance; persistent sessions; guest local mode remains. Clarify coherent username/password versus email-code UX from current competing user suggestions before changing account schema. Never represent locally saved display name as verified cloud identity.
- Separate personal library/history/downloads and consent-based shared library; explicit selected-item sharing, separate progress and no silent ownership merge. Library state filters favorite/watched/watching/watchlist, media filters all/movie/series/anime/Turkish, accessible icon actions/tooltips.
- Web downloads capability-aware single state, direct-download action and quality in quick tools; native supported background download permissions/service with resumable season/episode queue. Browser cannot guarantee app-closed background execution; no exploit-based downloads. Preserve existing downloads/history/sorts.
- Investigate TMDB shelf refresh timestamps/TTL, stalled navigation loaders, classification of anime versus Western animation, all episode-page continuation without repeated manual 100-item clicks and without invented counts. Dedicated normalized duration display, no duplicated episode/title/duration strings.
- Live logos, adaptive channel player/list with groups and next/previous channels; existing series player season navigation without leaving player. Maintain one-server architecture.
- Record provider-specific verified parsing knowledge in the existing maintenance documentation, not claims of bypassing protections or successful playback without observation.

Implementation started locally: route-change scroll-target invalidation, overflow check, preserve provider search query, clear button, narrower provider grid. No final build or deploy started.

## New requests appended 2026-11-16

Finish previous acceptance first. Home featured carousel: 3 wide / 2 narrow portrait posters, rotating, entire poster opens details, verify RTL previous/next. Audit Asian category and provider availability and exclude adult content via actual metadata/policy, never infer from arbitrary labels. Add short-drama category only with verified provider support and classification.

Consent-based film sharing to a selected signed-in recipient: owner-isolated authenticated invitation with accept/reject, no leaking source headers/signed URLs, durable unread state plus realtime when connected. Separate from automatic library merging.

Quick-watch link proposal needs design review before implementation: existing single-server architecture remains. Never publish source headers/credentials or derive bearer authorization from first eight UID characters. Use opaque high-entropy revocable access tokens, renew expiring source links, validate recipient/access boundaries. A header-injecting HLS relay necessarily consumes server bandwidth and requires playlist/segment safety, concurrency, expiry, resource limits and media authorization; cannot promise unlimited users or 1–2 years of external-source availability. No additional repository/service was supplied or created.

Local regression reproduced a concrete scroll-button defect: RawTooltip had no ancestor Overlay in MaterialApp.builder. Overlay.wrap added; test now checks long-list scroll, player navigation, return and actual scroll-to-top with no widget exceptions. This reproduces an implementation error consistent with hover trouble, not physical-TV proof.

Release version explicitly confirmed by user: **5.2.0**. Keep final package builds gated on remaining client acceptance.

## Implemented locally in this session (not final release)

- Global scroll-button target resets on route changes and verifies overflow/current route. Reproduced `RawTooltip: No Overlay widget found` and added its missing ancestor Overlay; route/scroll regression passes. Physical Google TV hover remains unverified.
- Compact poster-overlay work cards; no native TV text multiplier; 2 narrow / 3 wide featured cards, whole hero opens details, save remains separate, RTL carousel arrows use explicit physical direction.
- Provider query preserved on switch, left-side RTL clear button, compact grid.
- Settings groups navigate to separate pages; device linking and backup also separate account destinations. Remote remapping page stores only app-delivered keys locally, blocks reserved system keys, and applies only while player surface owns focus. Enter/Select toggle playback without overriding focused controls.
- Browser downloads avoid unsupported local-file enumeration and show capability-specific guidance. Live channel rows display supplied logos instead of fixed icons.
- Accounts retain email/password login, creation gains display name and minimum 6-character password per user's latest answer. Existing verified sessions cannot approve creation of a different account; confirmed account requires an SDK session and nonempty email. Quick-unlock PIN, persistence diagnosis and shared-library authorization are still incomplete.
- Library states favorite/watchlist/watching/watched persisted in existing owner-scoped favorite metadata, no new sync kind, no history deletion; Turkish filter and state picker added. Shared libraries/invitations still incomplete.
- Episode cursor continuation is now automatic and sequential, cancels stale season results and rejects non-advancing cursors, retains explicit retry after failure. No invented episode cap; full catalog and metadata/device checks remain.

Verification records are private under /workspace/artifacts. Runtime 346/346 and audited offline provider fixture suites passed. First broad Flutter run 440 pass/7 skip preceded final account/settings/library changes; later full run exposed five outdated navigation/fixture expectations which were fixed and affected suites passed. Run full final checks before any release claim.

Live checks must use the workspace's existing network proxy (`node --use-env-proxy`); initial all-timeout results without it are invalid as provider-health evidence. Proxy-aware one-sample checks passed catalog/search/details/container for 8 providers in each parser family. This is not 10-second decoded playback and is not the requested full per-provider film/episode matrix. AnimeZid returned 181 catalog rows in 5.7s and Ahwak 52 in 0.5s on focused retry with 15s request timeout; a 5s diagnostic timeout can produce false availability failures. Do not weaken SSRF or provider protections.

Latest completed checks: full Flutter suite 444 passed / 7 environment-dependent skips; Node runtime 346 passed; provider offline fixtures passed; analysis passes after brace/style fixes. A real local debug Web preview is being used for Chromium back/forward regression (this is local test compilation, not the final six-platform release). Flutter widget-test navigation channel setup does not provide the real browser-history bridge; its attempted Web harness was replaced by the existing Playwright end-to-end check instead of claiming it passed.

Prior six-target run 43921505393: macOS job **cancelled**, verify-release **skipped**. Do not describe cancellation as a compiler failure or claim a published six-target release.

Real Chromium navigation now passes: auxiliary settings pages receive distinct browser history entries, back/forward restores the parent/child, section and title/player refresh tests pass with zero page errors. Native TV target suite: 13 passed. Scroll hover still needs physical Google TV verification. Review branch: fix/najd-5.2.0-review; do not trigger final release workflows while outstanding gates remain.

## Second checkpoint and explicit outstanding work

Backend-only PR #50 is merged and live on the existing service (a1feef9a3964f294b914e12578a55fecbb39c64a; dep-dbtohdh42hec73dk240g). No new service or database was created. Current review adds channel/group browsing and next/previous channel paging; season selection fetches source-owned seasons without leaving the player; quality/download quick tools; browser MP4 handoff with explicit header limitations; active-file download continuation across route disposal; and Web decoder attachment/disposal protection. Actual Chromium MP4/HLS/live-fixture checks pass. Main still serves compatible API version 4.0.2; this is not the final client release.

Still open before a complete 5.2.0 release: secure device-local quick PIN; full persistent-session reproduction; separate consent-based shared library and recipient accept/reject notifications; OS-managed background transfers/permissions and a season queue independent of page lifetime; first-play false-error investigation against real providers; resumable complete server discovery with fast first playable response; per-source episode duration enrichment and the requested real video sample/quality matrix; Asian/adult/anime classification and TMDB shelf freshness audit; verified short-drama source/category; secure quick-watch link/relay design. Physical Google TV/iOS checks remain unverified. Never claim all sources or six final builds are complete.

## Saved checkpoint — user paused for daily token budget (2026-11-16)

User explicitly requested saving progress now. Continue from `fix/najd-5.2.0-review`; do not restart implementation or claim a release. No new build/publication was started. The previously authorized six final targets remain gated on ALL acceptance tasks; version remains planned 5.2.0.

Implemented in this checkpoint (review code, not shipped):
- Device-local four-digit quick unlock setup under Account settings, with password reauthentication before enrollment/disable. Uses flutter_secure_storage 10.3.4; macOS legacy Keychain mode avoids adding a paid Keychain Sharing requirement.
- A gate above the owned Navigator hides routes until local unlock, with password recovery and logout/local browsing. Guest browsing remains available; widget tests use an injectable Auth boundary instead of production SDK networking.
- Salted PBKDF2-HMAC-SHA256 (100,000 iterations), owner-bound verifier, no plaintext PIN/password/session in the verifier. Attempts persist BEFORE derivation; 5 failures trigger 30-second cooldown, 10 require password; clock rollback fails closed; concurrent attempts cannot overwrite counters. Logout removes the current owner's local PIN best-effort.
- Android secure preference backup exclusions preserve unrelated user backups. iOS Runner entitlement generation adds an empty app-local Keychain group, preserving other entitlements. Native signing/device integration has NOT been verified.
- background_downloader 9.6.6 was added as preparation ONLY. It is NOT wired into DownloadService, startup reconciliation, OS permissions, cleanup or season queues. Existing active-file continuation still only survives route disposal. Do not claim OS-termination support.

Evidence:
- PIN + existing email Auth tests: 14 passed (`/workspace/artifacts/najdtv-pin-auth-tests.log`). PBKDF2 matches independent Python hashlib vector.
- First complete Flutter run: 454 passed / 7 skipped / 1 failed (new gate accidentally initialized production Auth in the navigation widget test). This exposed a pending SDK timer. Added the same injected test boundary used by existing cloud features; targeted navigation + PIN rerun: 7 passed (`najdtv-pin-navigation-tests.log`). A fresh complete suite is STILL REQUIRED after this fix.
- Analysis after the gate injection exposed one brace-style lint; fixed before saving. Android backup XML was parsed and tested for repeat generation using a representative generated manifest; unrelated backup content retained. iOS entitlements still need configuration/signing verification.
- Proxy-aware source audit completed all 23 independent entries: 10 passed catalog/search/details/container stages, 9 partial, 4 failed. Private evidence: `/workspace/artifacts/najdtv-remaining-source-audit.log` and `/tmp/najd-isolated-audit/beta.json`. This does NOT establish decoded 10-second playback or the requested multiple-film/episode sample matrix. Failure stages include unsafe target, timeouts, empty live catalog and missing/unsupported direct media; retain safeguards.

Next actions in order:
1. Analyze and complete Flutter regression after the gate test-boundary fix; add injected gate widget tests (deep-link hiding, wrong/correct PIN, guest, password recovery), verify real platform secure storage and iOS Keychain generation/signing. Review fail-closed behavior when Auth/storage initialization fails; do not block guest/offline use accidentally.
2. Wire OS-managed background transfers with validated URLs/headers, verified final files, durable startup reconciliation, cleanup cancellation and independent season queue. Existing shared guarded redirect behavior must not be weakened by native automatic redirects. Distinguish OS force-stop limitations, desktop process exit and browser manager support honestly.
3. Implement consent-based recipient sharing and separate personal/shared library; existing legacy library grants delegate the entire owner scope, so avoid mixing progress or overwriting private lists. Supabase CLI now works through `npx --yes supabase@latest`; an empty migration was generated then removed because no schema was written or applied. No database change from this checkpoint.
4. Resolve source failures with guarded observed parsing and continue actual requested video/quality matrix; no WAF bypass or synthetic passes. Then clear the other outstanding acceptance tasks documented above, coordinated version bump and six final builds. Do not interpret this checkpoint as completion of those tasks.

Private artifacts are not committed. Preserve user data/DB containers/fonts. Disk was approximately 121 MB free; only remove explicitly identified generated Flutter test/compiler caches if needed. Freeze functional Dart edits while a full suite is running. Keep final packages and production main unchanged until acceptance gates pass.

## Continued checkpoint — 2026-11-17

Resumed from 2503764. Current review adds recipient work sharing (not library delegation): metadata-only send, durable recipient accept/decline, separate accepted shared-list route, Realtime recipient notifications with foreground polling fallback and account-change guards. No private favorite/history merge. Migration `20261117084940_najd_work_sharing.sql` is applied to roqccichwszxamdpvhli; read-only verification confirmed RLS, no anon SELECT, no authenticated direct INSERT, Realtime publication and exposed SECURITY INVOKER RPCs. Privileged validation lives in mitv_private. Local isolated SQL tests passed consent, account isolation, direct-write denial, replay denial, anonymous send rejection and credential filtering. New objects produced no matching security-advisor finding. Existing unrelated advisories remain unchanged. Note: private owner-scoped library RPCs were ALREADY fixed by the 20261112 migration; do not resurrect the old delegated-owner logic described in older intake.

Device PIN gate widget tests now verify hidden deep links until correct PIN, guest access independent of secure storage, and fail-closed vault failure with password recovery. Cryptographic vectors/rate-limit tests remain in quick_unlock_test.dart. No passwords or raw media credentials are persisted by new sharing/PIN code.

Native OS transfer pipeline is wired to default DownloadService on ANDROID/iOS only, with persisted task records, notification permission at download action, foreground data-sync configuration, bounded OS holding queue, verified MP4 finalization and reconciliation when Downloads is reopened. macOS/Windows/Linux use the existing Dart transfer; despite README wording, the installed plugin declares native plugins only for Android/iOS. Route disposal still preserves active transfer. Global cleanup waits for recovered OS cancellation confirmation; one bad completed file cannot hide other downloads. Simultaneous finalizers share a future (a self-await bug exposed by tests was corrected). This is NOT physical OS-background certification and is NOT an independent durable whole-season queue. Native automatic redirect behavior still needs review against the stricter existing guarded redirect contract before release. No force-stop bypass or desktop/browser-after-process-exit promise.

Verified-media preview is now published before slow remaining probes finish. Player follows explicit in-progress scans, appends newly available choices without restarting or seeking its active decoder, stops polling on lifecycle pause/scan completion and never silently changes source/edition. Existing time/work caps still report partial scans honestly; durable continuation beyond those caps remains unfinished.

Brstej old primary was observed redirecting by HTTPS from brstej1.com to brstej1.site, same branded DOM. Guarded public catalog returned 36 entries in each independent parser family; fixture/legacy-reference tests pass. Applied `20261117091826_najd_brstej_reviewed_primary.sql`: Najd/Beta config now points to brstej1.site while preserving selectors and disabled state. This config can refresh on the existing server without a package build. Parser and first-media code changes remain review-only, not deployed to Render/main.

Validation at this checkpoint:
- Latest full Flutter: 471 passed / 7 environment-dependent skips, no failures. Analysis clean before latest test-only additions.
- Targeted background-source/finalizer/timeline suite: 13 passed. PIN gate: 3 passed; sharing UI/service: 6 passed.
- Node runtime: 352 passed before adding the final browser-preview regression; first-media/browser targeted suite is now 28 passed. npm run check passed, including audited offline fixtures. Native generator repeat/XML/Keychain/identity tests pass. Inventory regenerated and checked.
- Fresh 23-entry live Beta audit BEFORE Brstej repair: 9 passed / 10 partial / 4 failed. This is catalog/search/details/container evidence, NOT the requested two-film/15-episode/ten-second decoded playback matrix. Private logs: /workspace/artifacts/najdtv-20261117-*.log. Do not commit resolved links or raw provider pages.
- Only an isolated local QA database was created and dropped for SQL tests; prior stopped najd-resume-qa container was returned to stopped state. No historical databases/containers/user files were removed. A failed new Docker start ran out of disk; no container was created. Removed only generated Flutter caches/temp compilation files and a duplicate identical npx Supabase CLI cache.

Still REQUIRED before the six final 5.2.0 targets: independent persisted season queue, complete source decode/quality matrix and unresolved source availability/parsers, resumable server continuation, per-provider duration enrichment, source-aware initial-error verification, Asian/adult/anime/foreign classification and shelf freshness audit, verified short-drama category/source, secure revocable quick-watch-link/relay implementation, physical TV/iOS/background checks. No six-platform final build, version bump, main merge or Render deployment was started in this continuation. Continue development; do not report completion of these gates.


## Resume checkpoint, 2026-11-17 — persistent seasons and index continuation

Implemented on the ordinary review branch; final 5.2.0 packages remain gated.

- A separate owner-scoped season queue stores source references and a durable index cursor, never signed media URLs or request headers. It enumerates real episode pages, commits children before advancing the cursor, preserves missing numbers/alternatives, and resumes unfinished jobs on application startup or foreground return. A 151-job regression verifies that a hundred-item UI page is not a queue limit. Switching account stops subsequent jobs without silently moving another owner's library.
- Android/iOS transfers use deterministic task IDs to reattach to their persisted OS transfer; completed MP4s are verified before adoption. Deleting a previously completed file permits a fresh enqueue. The plugin supports these two mobile targets; desktop retains the Dart transfer and Web uses a browser file handoff. Continuing an entire season after process termination still needs native device verification: metadata durability and one OS-owned file are not proof of OS execution of subsequent Dart jobs while closed.
- Download cleanup closes its shared registration gate before cancelling persistent season jobs. A full-suite regression caught an async wrapper breaking concurrent cleanup identity; fixed without weakening the assertion. The targeted cleanup/queue/protocol suite then passed 17 tests. Native force-stop restrictions are not bypassed.
- Source work indexing now persists an expandable page budget and explicitly continues its remaining frontier rather than permanently ending at the first budget. The client follows a physical page cursor even after de-duplicating entries, polls an index that is still growing, and stops/reports terminal partial results. Legacy clients receive completed playback snapshots; only opted-in clients consume early verified media plus background updates.
- Foreign catalog filtering now includes observed non-Arabic languages instead of English alone. Explicit adult rows are excluded. Japanese animation is classified as anime while Western animation remains distinct; anime/Turkish labels survive into library filters without changing canonical movie/TV identity. Broad Asian coverage remains pending.
- Offline Node unified suite: 358 passed; runtime check and continuation scripts passed, including 172 provider fixture assertions with zero network attempts. Flutter analysis is clean. Full Flutter rerun: 484 passed, 7 environment-dependent skips. Fresh debug Web compilation and Chromium MP4, HLS, live switching, MP4 browser handoff, PiP and navigation checks passed with zero page exceptions; see VALIDATION_5.2.0.md.

Short-drama research used guarded public HTTPS requests, not an enabled provider claim: Dragon Shorts' public work page directs playback to its app and contains no browser video; Dramacix was unavailable; Drama Wbas exposes real episode routes and a player whose source is obtained separately. Do not add a playable-source badge from marketing text or episode counts. Private captures stay outside Git.


## Foreground home freshness, 2026-11-18

Home shelves now refresh after ten minutes while visible and foregrounded, or when returning to a stale retained tab. Hidden tabs and background lifecycle states stop the timer. Failed automatic refresh keeps the previous successful cards, and refreshing existing cards does not insert the initial skeleton above them. Upstream popular/trending selections remain observed metadata, not fabricated random changes. This requires a client/Web frontend update, not just a backend deployment.

The new widget regression advances the clock, leaves/re-enters the tab, pauses/resumes the app and simulates an offline refresh; four targeted home/carousel tests passed. Full client suite and fresh Web checks are recorded in VALIDATION_5.2.0.md. A disk-full test attempt is invalid evidence; only the clean rerun counts.

## Explicit release authorization, 2026-11-18

The user now explicitly requests building and publishing the six 5.2.0 clients immediately, postponing server-only work and recording its progress. Physical-device certification is not claimed or treated as completed. This supersedes the earlier all-server-acceptance release hold for this batch. Existing IDs, signing identity, provenance checks, tests and package verification remain required.

Client preparation for deferred server delivery: optional GET `/api/v1/client-features` returns `{status:"success",features:["quick_watch_v1","short_drama_v1"]}` only when actual server implementations are ready. Unknown capabilities and old-server/404/network failures hide actions. Feature readiness is cached for two minutes. Short drama requests normal paginated catalog `catalog:short-drama:all`; the player posts only selected work/episode identity and authenticated bearer to `/api/v1/watch-links`, expecting 201 and an opaque same-server HTTPS `/watch/<random-token>/<name>.m3u8` (or truthful `.mp4`) URL. No media headers or upstream URL are sent by this action. Both actual server implementations remain deferred and must validate ownership, reference safety, limits, expiry/revocation and real media format before advertising readiness.

Release output: native APK/IPA/EXE/DMG assets, with Web as the existing public site. ZIPs remain private CI verification inputs and are not public downloads. Client publication checks the compatible API schema rather than requiring its product version to equal the client version. Verified public compiled files alone are published to main with `[skip render]` and `[skip ci]`; deferred backend source changes are not merged or deployed. Render documents `[skip render]` as suppressing auto-deployment. Source provenance remains the immutable tested review commit, not the generated public-output commit.


## Release completed, 2026-11-21

- Recovered macOS packaging from the observed transient `hdiutil: create failed - Resource busy` by rerunning only failed jobs; the native app itself had built successfully. Both arm64 and x86_64 are present in the published DMG.
- All six targets verified together at source 715b627. The existing production API 4.0.2 passed the client compatibility check; deferred server source was not merged or deployed.
- Publication initially rejected the new public auth-callback files. Added only auth-callback.html/css/js to the main publisher allowlist, with three regressions proving approved callbacks are staged, unexpected files fail before staging and symlinks remain blocked. Reran the aggregate verification/publication using the retained target artifacts, not mixed application builds.
- Release assets are five native installers plus checksums and verification reports; no ZIP download assets. Web is served through the existing Pages URL and its live source manifest was checked. Anonymous HEAD requests to all five native installer URLs returned HTTP 200 with matching asset sizes.
- Normalized the macOS checksum sidecar to use its download basename. A session-token upload limitation required restoring that metadata via a dedicated GitHub Actions maintenance job from the published verified report. The DMG bytes and its verified digest were not changed. Future packaging writes a basename checksum; future verification uploads replace their prior report on retry.
- Server backlog remains: actual short-drama catalog/playback, secure revocable quick-watch relay, broader Asian/provider coverage, full requested live decoder/quality sample matrix, durable continuation of remaining media hosts, and episode metadata enrichment. The 5.2.0 client has the optional versioned actions ready but they remain hidden until server readiness is advertised. Android/iOS force-stop and closed-app season execution have not been certified on physical devices.
