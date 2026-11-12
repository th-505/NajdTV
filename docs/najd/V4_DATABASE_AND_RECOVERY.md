# Database and recovery operations

Private data lives in owner-protected library/history/favorite rows. RPCs and RLS authorize the authenticated user; handoff grouping never owns private progress. History keys include work and episode identity. See `../PLAYBACK_ISOLATION.md`.

Shared work/season/source/episode catalogs and provider configurations are backend-only. Expiring media is evidence for identity and availability, never a reusable user-session credential. Live playback resolves through an isolated per-open extraction store.

Queue processing uses leases, `SKIP LOCKED`, bounded retries, separate discovery/media lanes and `najd_queue_discovery_order`. The index must be valid/ready before relying on it. `najd-favorite-hourly` runs hourly with a 20-second statement budget and bounded cleanup. Its wake target is `https://najdtv.onrender.com/api/v1/harvest/wake`.

Preserve applied migrations. Compare live schema, function definitions and grants before repairing missing history. Build an existing busy queue index concurrently outside a migration transaction. See `../../supabase/README.md`.

Use rollback SQL tests before changing owner authorization or cron functions. Never infer an overwritten old checkpoint, delete user data to repair migration history, log signed URLs/keys, or enable an unreviewed redirected domain. Laroza now uses the explicitly reviewed https://laroza1.site origin; see ../DOMAIN_REVIEW_2026-11-12.md.
