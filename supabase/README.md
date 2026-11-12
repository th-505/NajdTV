# Production migration and scheduler operations

Migration filenames use the versions actually recorded by Supabase. Four existing
production migrations were missing locally; equivalent local migrations also had
different generated versions. Their SQL was compared before restoring filenames
and the missing files. The guarded legacy-cleanup function is intentionally safe
on installations without that retired RPC.

Three previously unrecorded effects (legacy client privilege restrictions,
discovery lane index/function and Beta catalog) are recorded by the reconciliation
migration after inspecting their live schema and grants. It restores the lane
function but never replays table creation or drops user data. Do not blindly run
`migration repair` or mark a migration applied based only on a matching name.

For an existing busy queue, build `najd_queue_discovery_order` separately with
`CREATE INDEX CONCURRENTLY IF NOT EXISTS`, outside a transaction; verify
`pg_index.indisvalid` and `indisready` before recording its effect. Transactional
migration runners cannot build a concurrent index. New installations may use the
ordinary indexed migration before accepting traffic.

`najd-favorite-hourly` runs at `0 * * * *`. Cleanup batches are bounded and use
`SKIP LOCKED`; an advisory transaction lock prevents overlapping runs. The cron
command limits execution to 20 seconds. Wake requests target the NajdTV service.
Inspect `cron.job_run_details` after enabling or modifying the job. Never log keys,
signed URLs, user metadata or raw request cookies in an operational report.
