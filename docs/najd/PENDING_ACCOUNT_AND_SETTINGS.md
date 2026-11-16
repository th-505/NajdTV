# Current release work: 5.2.0

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
