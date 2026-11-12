# Current Najd requirements and acceptance contract

The application is Najd TV / نجد, with a shared Flutter client, Node API, independent Najd/Beta source families and guarded Edge extractors. Keep installed application IDs, source references, library export/import, current build inputs, licenses and applied migrations compatible.

- Branding: `shared/najd-brand.json`, `ui_contract.dart` and `web/core/ui-contract.js` define current identity and adaptive RTL themes. Fonts supplied privately remain local; redistribute only approved fallback assets and licenses.
- Sources: preserve observed provider/edition/season/episode identity. Missing evidence remains unknown. Catalog pagination is explicit; blocked/time-out/changed structures are typed availability errors. Never broaden SSRF allowlists just to follow a redirect.
- Playback: extract direct media through guarded HTTP and bounded probes. Do not execute source scripts or install a video relay. A source/container check is not physical-device certification. Session extraction follows `docs/PLAYBACK_ISOLATION.md`.
- Accounts: private favorites, library, history and checkpoints belong to the authenticated user. Consent-based handoff linking does not merge progress. Shared catalog refreshes never overwrite user state. Local snapshots and pending writes stay owner-scoped.
- Harvesting: durable jobs use claims, leases, bounded retries and bounded hourly cleanup. Applied migration history, the discovery ordering index and cron are described in `supabase/README.md`.
- Verification: run the six npm suites, guarded provider fixtures, Flutter analysis/tests and repository health checks. Native signing, device playback and release promotion require their actual release gates; do not infer them from a passing source test.

Build inputs: `BUILD_AND_CODE_REFERENCE.md`. Current behavior: `RUNTIME_AND_FLOW_MAP.md`. Keep current operational guidance concise; obsolete reports, archived workflows and duplicate generic agent rules do not belong in the source tree.
