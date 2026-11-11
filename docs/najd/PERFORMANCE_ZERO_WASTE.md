# NajdTV — zero-waste performance policy

This note records the implementation guardrails for the free/current deployment. It does not authorize a production database migration or a service restart.

## 1. Discovery queue

- The worker now defaults to **on-demand claims**. A global lane sweep is enabled only when `NAJD_HARVEST_SCAN_BACKLOG=1`; unset and `0` both disable it.
- Known durable job keys continue to use `najd_claim_known_jobs` and the `job_key` primary key. Interactive work does not require a global backlog scan.
- Keep the lane limits bounded: search 20, index 1 by default, media 1 by default. Do not increase index/media concurrency without fresh CPU and queue-latency evidence.
- The compatibility `najd_claim_jobs` RPC remains for older workers, but must not be the normal production path.
- The current production database has `najd_claim_jobs_lane` and `najd_claim_known_jobs`, but the supporting `najd_queue_discovery_order` index is absent. A read-only `EXPLAIN` of the current search-lane selector showed a sequential scan (estimated plan cost ~25,532). This is a planner estimate, not measured execution time.
- The repository already contains `supabase/migrations/20261104175430_najd_discovery_lane_queue_index.sql`. The migration history inspected on 2026-11-11 does not contain version `20261104175430`. Review and apply this existing migration in a controlled window before concluding the lane selector is index-backed. Do not create a duplicate index or re-run it blindly.

## 2. Cache policy already present

- Node catalog metadata cache: in-process bounded map (128 entries), at most 16 pending loads, 10-minute refresh TTL, with persisted demand/metadata writes coalesced; storage retry backoff is 30 seconds.
- Cloudflare Edge cache: category/search metadata 300 seconds, details 120 seconds, match/list metadata 15 seconds, playback/resolve responses up to 60 seconds and always bounded by the earliest source expiry minus a safety margin.
- Signed media URLs, authorization material and resolver headers must never enter catalog metadata cache. Do not add Redis or another cache service.
- Do not lengthen playback TTL beyond the source expiry. Metadata TTLs can be tuned only from cache-hit and provider-load measurements.

## 3. Watch-history writes

- Flutter keeps local progress durable and synchronizes cloud records in batches of at most 32 rows.
- Non-history changes are debounced for 3 seconds. Ordinary watch-history writes are now throttled to a 30-second cadence; app lifecycle flushes remain enabled.
- Cloud pull is revision-based (up to 250 rows/page) and the sync loop is bounded. Do not write progress on every playback tick.
- The 30-second cadence is a default; tests may inject a shorter interval. Do not remove lifecycle flush or owner/revision checks.

## 4. Retention — do not reactivate the old hourly job

The existing `najd_hourly_refresh` mixes discovery work with cleanup. It also re-enqueues current favorites and wakes the worker, so it is **not** a safe retention-only scheduler.

The existing cleanup semantics are:
- Discovery jobs: retain at least the last 7 days; only old non-running jobs without a still-valid work-cache row are eligible.
- Episode cache: when playable media expires, clear the media payload and return the row to pending; preserve episode identity/index metadata.
- Work/season cache: expired work metadata may be removed only when the work is not an active favorite; dependent cache rows cascade with it.
- Harvest events: retain 30 days.

Production currently has `pg_cron` installed, but the `najd-favorite-hourly` job is inactive. Keep it inactive: enabling it just to run retention would also trigger discovery enqueue/wake behavior. A separate retention-only function with small `SKIP LOCKED` batches and its own schedule should be introduced as a reviewed migration; do not schedule broad deletes or run `VACUUM FULL`.

## 5. Ads and tracking

No ad SDK, ad network, commercial tracker, or analytics dependency is introduced by this change. Keep the app's content and playback paths free of advertising and commercial tracking.

## Verification checklist

1. Run the Node worker suite, including default on-demand mode and explicit background-sweep opt-in.
2. Run Flutter analysis and `cloud_library_test.dart`, including the 30-second history cadence and lifecycle flush.
3. Before applying the existing queue-index migration, inspect current DB health and migration history; afterward verify the index exists and use `EXPLAIN` (not repeated `EXPLAIN ANALYZE` during saturation).
4. Verify the production worker has backlog scanning disabled and only one active producer is enabled.
5. Keep retention unscheduled until its separate function is reviewed and bounded.
