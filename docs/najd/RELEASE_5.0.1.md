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

Native packages require the existing six-target CI build, signing verification and artifact validation. Physical iPhone/Android/TV playback and all channel codecs have not been certified. The unsigned IPA still needs signing; macOS notarization is unchanged.

The release workflow defaults to review artifacts. Explicit publication additionally requires the production single-server API to report the same version as the clients. Do not publish until authentication delivery and representative live/VOD playback are verified.
