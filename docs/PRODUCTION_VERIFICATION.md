Production verification — 2026-11-12

Evidence is read-only except the documented public harvest wake (HTTP 202). No migration, cron activation, environment update or deployment was performed.

Render identity and version

- najdtv.onrender.com: workspace tea-dbld41egekts7382lelg, service srv-dbld60s9v7es739mihig.
- matv.onrender.com: workspace tea-db6l0m5g1s2s739p49c0, service srv-db6l1pd9fdbs73b02j40.
- Both services use th-505/NajdTV main and auto-deploy commits. After the owner delegated workspace identification, repository URL plus exact public URL resolved the ambiguity.
- Render reports commit 6ebb30ec36db12ef5fd427a00d2faa262d8e5047 live on both services. This is newer than the requested base 7317d9c86e85770cf4fff6f9da5b69fd3352f9c6.
- Live /health returned version 4.0.2, without source_commit at inspection. The new source_revision response is implemented and locally tested; no claim that it is already deployed.
- readSourceRevision accepts only a full SHA from RENDER_GIT_COMMIT/MITV_SOURCE_COMMIT/GITHUB_SHA, or Git when available; missing/invalid evidence yields null. Local dirty trees are explicit. No secrets are returned.

Supabase and harvest

- Connected project roqccichwszxamdpvhli is NajdTV and ACTIVE_HEALTHY.
- Live /api/v1/harvest/wake returned 202 with configured=true. Runtime harvest configuration is confirmed. Direct Render environment-variable values are not exposed by the available read tools; no secret/config write was used to infer them.
- cron.job and cron.job_run_details exist; najd_hourly_refresh() exists.
- najd-favorite-hourly, job 7: schedule 0 * * * *, active=false, no retained run recorded by the query. Durable hourly scheduling is NOT active through this job. Node setInterval alone is not durable scheduler evidence.
- najd-account-yearly-expiry, job 10: schedule 20 0 * * *, active=true; latest observed run succeeded at 2026-11-12 00:20 UTC.

- Local migrations: 27; recorded production migrations: 28. Fifteen local version timestamps are not exact matches; several names occur with different timestamps. This is history drift, not proof all corresponding DDL is missing.
- najd_beta_catalog, najd_beta_provider_config and najd_set_beta_provider_config exist even though the isolated-beta migration name is absent from recorded history.
- anon SELECT on legacy favorites/history is false, so a missing privilege-hardening filename does not prove the privilege change is absent.
- public.najd_queue_discovery_order index is absent. No production DDL was applied.

Local migration names absent from recorded production names:

- 20261027080555_najd_favorite_harvest
- 20261104175430_najd_discovery_lane_queue_index
- 20261027041930_restrict_legacy_client_privileges
- 20261104193209_najd_isolated_beta_catalog

Laroza

- Production Cloudflare settings confirm a valid gateway LAROZA binding to mitv-extract-laroza, origin https://larooza.beer.
- The exact category source URL /moslslat4.php?page=1 returned 301 to https://larooza.net/moslslat4.php?page=1. This crosses the configured metadata origin.
- Root audits continue through several changing domains; final identity/stability and positive parsing are unverified. Allowlists remain unchanged.
- Code now reports the specific review-required redirect through Edge/Node. Live content recovery and deployment remain uncompleted; no false success or silent source substitution.
