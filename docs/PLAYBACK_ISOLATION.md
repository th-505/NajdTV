# Private state and playback credentials

`najd_upsert_library`, `najd_pull_library`, `najd_history_checkpoint` and favorite
refresh authorize private rows with `auth.uid()`. Library identity remains
`(user_id, kind, item_key)`; history `item_key` includes the stable work and episode
identity. A handoff grant authorizes sending a request between accounts; it does
not transfer ownership of favorites, history or progress. Shared catalog/index
refreshes never write user progress. Existing overwritten positions cannot be
reconstructed reliably and must not be guessed.

Flutter stores one atomic snapshot per owner. A legacy snapshot is claimed once
by its saved account; changing owners saves/restores separate snapshots and
pending changes. Supabase session-owner checks still reject a changed Auth user.

Playback requests extract fresh credentials. Catalog/episode caches provide
identity evidence, not reusable viewer tokens. The session extraction adapter
reuses the guarded provider parser and media probe through an isolated store;
it cannot invalidate or overwrite the shared episode row. The legacy 3isk and
Alooy HTTP playback paths also bypass shared token/HTML pending requests.

Flutter creates a random 128-bit capability for each playback open and reuses it
only while polling that extraction. Server memory isolates jobs by capability,
work, episode and platform, with bounded concurrency/queue/entries and expiration
before the media token. Reopening or renewing creates a new capability. These
IDs authorize no library operations. Responses use `Cache-Control: no-store`. The Edge gateway also bypasses legacy
shared Cache API media entries and never writes new playback responses, including
live-match playback. Metadata caching and extraction rate limits remain active.

Media expiry is bounded by declared and URL token expiry. Player failure recovery
can force extraction again. Request isolation prevents application cache reuse;
it cannot force a CDN to mint different URLs, remove an upstream IP/session limit,
or establish physical-device buffering performance. Video bodies travel directly
between the player and source; retired server video proxies return 410. Shared
HTTP concurrency limits apply to extraction/probing, not ongoing video transfer.

Verification: `tests/playback-session-isolation.test.mjs`, Flutter
`cloud_library_test.dart`, and the rollback SQL `scripts/qa_najd_library_link.sql`.
The SQL test creates temporary Auth identities, tests both consented link modes,
and proves A=900000ms and B=30000ms remain separate after writes/revocation.
