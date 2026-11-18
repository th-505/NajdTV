# Najd TV 5.0.1 — release candidate

Build 501. This candidate preserves the original application IDs, installed-user data and one Node server. It does not deploy the abandoned three-service platform or add a paid service.

## Changes

- Real email/password login, account creation and confirmation in Settings. Browsing no longer creates an anonymous account. Existing anonymous owners can upgrade without losing their library; switching accounts isolates local snapshots and pending playback history.
- Eight public IPTV-org feeds: UAE, Saudi Arabia, Egypt, sports, movies, news, kids and entertainment. Search, pagination, deduplication, bounded refresh and independently issued playback sessions run on the existing server. Video travels directly from its source. Unsafe/insecure entries are excluded rather than silently proxied.
- Updated observed Fosta, Brstej, Shahid4u, RistoAnime and QFilm domains; safe relative-reference handling and preservation of old references. MyCima retains its verified primary and adds an observed mirror.
- Explicit replacements: AnimeZid for WitAnime, Movizland for 5TV and EgyBest for CimaNow. Legacy handlers remain accessible for saved references. There are 25 active entries, including two declared mirrors; this is not a claim of 25 independent working streaming services.
- Source-owned season traversal preserves the root work and actual episode numbers. Guarded provider HTML is reused instead of fetched twice. Repeated/foreign pages cannot fabricate additional episodes.
- Home renders local content before optional network metadata; cards decode appropriately sized images; public catalog requests coalesce; optional database reads and counters cannot block the initial catalog indefinitely. Match and channel tabs retain TV navigation.

## Verification and publication status

This is a candidate, not a published release. Deterministic parser fixtures do not certify a live stream. Known-positive public catalogs/search pages were checked; direct playback from the three replacement sites remains unverified or unavailable. Access blocks are reported honestly; no CAPTCHA/login bypass is included.

Email confirmation delivery and a real confirmed-account round trip remain pending. The Supabase project still permits anonymous sign-ins at the service level, although this application no longer requests them. Disable new anonymous sign-ins in Supabase Auth before public rollout; retain existing users and their libraries. Review SMTP delivery and enable leaked-password protection where the project plan supports it. No managed Auth-table workaround or broad RLS grant is introduced.

The six-target CI build, signing verification and artifact validation passed for b20e24349ace974df9b873efaea61eeb75fccbd7. The subsequent server pagination correction requires a fresh CI run before publication. Physical iPhone/Android/TV playback and all channel codecs have not been certified. The unsigned IPA still needs signing; macOS notarization is unchanged.

The release workflow defaults to review artifacts. Explicit publication additionally requires the production single-server API to report the same version as the clients. Do not publish until authentication delivery and representative live/VOD playback are verified.

## Follow-up fixes from the supplied screenshots

- Replaced the remaining gold M favicon, Web/PWA icons and Windows icon with deterministic exports of the approved Najd master. Updated icon cache revisions; active image variants were inspected. Content artwork and source thumbnails are retained.
- Explicit HTTPS confirmation return URL and a minimal callback page that clears auth codes/fragments immediately and contains no analytics. Existing confirmed anonymous upgrades can refresh the same session when returning, without inventing a numeric OTP. Supabase Site URL and redirect allowlist still require dashboard configuration; the connected database tools cannot update them. The reported account is confirmed; the broken localhost return does not mean its email failed confirmation.
- Native iOS PiP is requested on inactive lifecycle while playing; Android retains its native auto-enter path. Browser auto-PiP is requested only through supported browser APIs; Safari/system restrictions still apply. Lifecycle behavior is tested, not certified on every physical device.
- A failed network/media server no longer gets an unrelated software-decoder retry. Confirmed codec failures retain that recovery. A provider-owned work never automatically jumps to a different provider/episode; available servers of its own episode remain selectable.
- Observed per-episode images and exact duration seconds survive normalization, source indexing, private database writes and UI display across Najd/Beta. Missing values remain unknown; metadata-only reindexing cannot erase existing observations. The optional migration is applied with owner/RLS rules unchanged.
- Full observed-server diagnostics distinguish playable, unavailable and unfinished checks, with no signed URLs in the inventory. Only validated direct media is playable. The five-server/two-playable regression is covered; this is not a claim that every remote host works from production.
- Match-only providers are excluded from VOD search and remain under Live. Existing production was still 4.0.2 and returned 404 for new live-feed routes; backend deployment must be verified independently of client builds.
