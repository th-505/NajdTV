# v4.0.1 execution ledger

## Player
In progress: per-button glass interiors, clear timeline clocks, bottom toolbar order, half-screen burst seeks, correctly oriented brightness/volume rails, quick tools, three actual quality policies, extended direct video containers with bounded signature probes. No paid conversion service or ad SDK; operating/network costs cannot be promised zero.

## Providers
Observed through the app's guarded HTTP transport: 3ckTV e.3cktv.com, Moviz Time moviz-time.surf, 3iskk.xyz and 5TV (user ho53214qa alias redirects to new61.5tv.lol) return actual content. ww4.3ick.club redirects to 3iskk.xyz and is an alias, not an independent source. WitAnime remains ACCESS_BLOCKED from this environment. Availability in production must be checked separately.

## Database
Applied migration `najd_v4_schema_performance`: two FK indexes, eight owner-policy initPlans, explanatory schema/table comments. Post-change read-only owner isolation check succeeded; performance advisors now report unused indexes only. No users, library rows, table names or compatibility identifiers were deleted/renamed.

Snapshot: ~456k episode rows; ~203k discovery jobs, ~190k queued; one active DB session at observation. This is a snapshot, not a load-test guarantee. Old queue/cache retention and current bounded interactive workers must be assessed independently; no arbitrary purge.

## Remaining before release
Finish provider parsers and actual/sanitized fixtures; complete carousel/shelves/person filters; validate responsive UI, all tests, all six builds, published web and API version; publish v4.0.1 with explicit platform/source limits. Do not mark device PiP or blocked sources as certified by a build.
