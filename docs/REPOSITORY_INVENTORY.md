Repository cleanup inventory — no deletions

Base: `3f37377d1eb9279c36b10c5dcd0ff4bad6570292`. Files scanned: 1531. Scope includes both registered families, legacy providers, source seed config, tests, CI, package scripts and literal filesystem/native references.

This is a conservative static inventory, not a proof that unreferenced code is unused. Dynamic expressions, convention-loaded skills, native entry points and manually invoked tools remain blockers. All approved-deletion lists are empty. No cleanup commit is permitted before owner approval.

Code and configuration inventory

| File | Reachability | Evidence / decision |
|---|---|---|
|`server/browser/configuration.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/app.mjs|
|`server/browser/episode-index.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/source-graph.mjs, tests/provider-recovery-observed.test.mjs, tests/scraper-family-isolation.test.mjs|
|`server/browser/providers/edge/laroza.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/sites/laroza.mjs|
|`server/browser/providers/legacy/3isk-playback/contract.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/legacy/3isk-playback/miravd.mjs, server/browser/providers/legacy/3isk-playback/router.mjs, server/browser/providers/legacy/3isk-playback/ukrcdn.mjs, server/browser/providers/legacy/3isk.mjs|
|`server/browser/providers/legacy/3isk-playback/miravd.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/legacy/3isk-playback/router.mjs, server/browser/providers/legacy/3isk.mjs|
|`server/browser/providers/legacy/3isk-playback/router.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/legacy/3isk.mjs|
|`server/browser/providers/legacy/3isk-playback/ukrcdn.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/legacy/3isk-playback/router.mjs|
|`server/browser/providers/legacy/3isk.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/sites/3isk.mjs|
|`server/browser/providers/legacy/alooy.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/sites/alooy.mjs|
|`server/browser/providers/legacy/laroza.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/sites/laroza.mjs|
|`server/browser/providers/sites/3cktv.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/3isk.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/ahwak-categories.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/sites/ahwak.mjs|
|`server/browser/providers/sites/ahwak.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/akwam.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, tests/akwam-server-discovery.test.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/alooy.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/anime4up.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/sites/anime4up_rest.mjs, server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/anime4up_rest.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/arabseed.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/brstej-categories.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/sites/brstej.mjs|
|`server/browser/providers/sites/brstej.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/cimanow.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/egydead.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/egydead_live.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/fivetv.mjs`|True|KEEP: reachable from runtime/tests/CI; users: scripts/fivetv_capture_audit.mjs, server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/fosta-categories.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/sites/fosta.mjs|
|`server/browser/providers/sites/fosta.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/ipauniverse.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/sites/specialized-portals.mjs, server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/laroza.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/mewsry.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/sites/specialized-portals.mjs, server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/moviztime.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/mycima.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/qfilm.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/sites/specialized-portals.mjs, server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/ristoanime.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/sites/specialized-portals.mjs, server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/shahid4u.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/sites/shii4u.mjs, server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/shii4u.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/specialized-portals.mjs`|False|KEEP: references remain; no deletion proof; users: |
|`server/browser/providers/sites/witanime.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/providers/sites/yallashoot.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/registry.mjs, مهام/تقارير/المصادر.json|
|`server/browser/references.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/service.mjs, tests/scraper-family-isolation.test.mjs|
|`server/browser/registry.mjs`|True|KEEP: reachable from runtime/tests/CI; users: scripts/provider_inventory.py, scripts/providers_unit_and_integration_test.mjs, server/app.mjs, server/browser/configuration.mjs, server/browser/references.mjs|
|`server/browser/service.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/local_load_profiles.mjs, server/app.mjs, tests/browser-isolation.test.mjs|
|`server/browser/source-graph.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/browser/service.mjs, tests/browser-isolation.test.mjs, tests/fivetv-provider.test.mjs|
|`server/browser/store.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/browser/configuration.mjs, server/browser/service.mjs|
|`server/browser/traffic.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/app.mjs, server/browser/configuration.mjs, server/browser/registry.mjs, server/browser/service.mjs|
|`server/providers/3isk-playback/contract.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/providers/3isk-playback/miravd.mjs, server/providers/3isk-playback/router.mjs, server/providers/3isk-playback/ukrcdn.mjs, server/providers/3isk.mjs|
|`server/providers/3isk-playback/miravd.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/providers/3isk-playback/router.mjs, server/providers/3isk.mjs, server/providers/akoam.mjs, supabase/functions/matv-miravd-metadata/index.mjs|
|`server/providers/3isk-playback/router.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/3isk_provider_test.mjs, server/providers/3isk.mjs, مهام/تقارير/المصادر.json|
|`server/providers/3isk-playback/ukrcdn.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/providers/3isk-playback/router.mjs, مهام/تقارير/المصادر.json|
|`server/providers/3isk.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/3isk_dual_engine_live.mjs, scripts/3isk_http_test.mjs, scripts/3isk_provider_test.mjs, scripts/3isk_runtime_test.mjs|
|`server/providers/akoam.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, package.json, scripts/hls_manifest_proxy_test.mjs, scripts/phase2_provider_test.mjs, server/app.mjs|
|`server/providers/alooy.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/alooy_provider_test.mjs, server/app.mjs, server/browser/providers/sites/alooy.mjs, server/scrapers/sites/alooy.mjs|
|`server/providers/laroza.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, package.json, scripts/laroza_runtime_test.mjs, server/app.mjs, server/browser/providers/sites/laroza.mjs|
|`server/scrapers/anti-ban.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, package.json, server/browser/providers/sites/3cktv.mjs, server/browser/providers/sites/arabseed.mjs, server/browser/providers/sites/cimanow.mjs|
|`server/scrapers/configurable-provider.mjs`|True|KEEP: reachable from runtime/tests/CI; users: .github/workflows/provider-health-audit.yml, docs/najd/assets/javascript-functions.json, server/browser/registry.mjs, server/scrapers/registry.mjs|
|`server/scrapers/content-discovery.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/app.mjs, server/browser/episode-index.mjs, server/browser/service.mjs, server/browser/source-graph.mjs|
|`server/scrapers/content-scope.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/najd_provider_forms.mjs, server/harvest/pipeline.mjs, server/scrapers/content-discovery.mjs, server/scrapers/source-registry.mjs|
|`server/scrapers/index.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, package.json, scripts/app_path_e2e_verification.mjs, scripts/episode_identity_browser_test.mjs, scripts/provider_inventory.py|
|`server/scrapers/provider-browser.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/app.mjs, tests/fivetv-provider.test.mjs, tests/interactive-discovery.test.mjs, tests/provider-browser.test.mjs|
|`server/scrapers/providers-registry.json`|True|KEEP: reachable from runtime/tests/CI; users: scripts/provider_inventory.py|
|`server/scrapers/registry.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/audit_provider_media_2_beta.mjs, scripts/audit_source_searches.mjs, scripts/najd_provider_forms.mjs, scripts/najd_provider_report_registry.mjs|
|`server/scrapers/shared/catalog-decision.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/harvest/pipeline.mjs, server/harvest/source-work.mjs, server/scrapers/shared/normalize.mjs, tests/source-work-policy.test.mjs|
|`server/scrapers/shared/concurrency.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/browser/service.mjs, server/diagnostics/service-checks.mjs, server/discovery-audit.mjs, server/scrapers/content-discovery.mjs|
|`server/scrapers/shared/direct-candidate.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/browser/providers/sites/fivetv.mjs, server/scrapers/content-discovery.mjs, server/scrapers/shared/provider-media.mjs, server/scrapers/sites/fivetv.mjs|
|`server/scrapers/shared/errors.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/providers/3cktv.fixture.test.mjs, scripts/providers/3cktv.live.test.mjs, scripts/providers/3isk.fixture.test.mjs, scripts/providers/akwam.fixture.test.mjs|
|`server/scrapers/shared/http.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scratch/test_shahid.mjs, scripts/najd_provider_forms.mjs, scripts/providers/anime4up.live.test.mjs, scripts/providers/egydead.live.test.mjs|
|`server/scrapers/shared/normalize.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/browser/providers/sites/3cktv.mjs, server/browser/providers/sites/3isk.mjs, server/browser/providers/sites/ahwak.mjs, server/browser/providers/sites/akwam.mjs|
|`server/scrapers/shared/provider-config.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/app.mjs, server/browser/configuration.mjs, server/browser/providers/sites/3cktv.mjs, server/browser/providers/sites/brstej.mjs|
|`server/scrapers/shared/provider-media.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/browser/service.mjs, server/diagnostics/service-checks.mjs, server/harvest/pipeline.mjs, server/scrapers/content-discovery.mjs|
|`server/scrapers/shared/source-episode-evidence.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/browser/service.mjs, server/harvest/pipeline.mjs, tests/source-parent-episode-evidence.test.mjs|
|`server/scrapers/shared/work-title.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/browser/providers/sites/moviztime.mjs, server/scrapers/sites/moviztime.mjs|
|`server/scrapers/sites/3cktv.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/providers/3cktv.fixture.test.mjs, scripts/providers/3cktv.live.test.mjs, server/scrapers/index.mjs, server/scrapers/registry.mjs|
|`server/scrapers/sites/3isk.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/providers/3isk.fixture.test.mjs, scripts/providers/3isk.live.test.mjs, server/scrapers/index.mjs, server/scrapers/registry.mjs|
|`server/scrapers/sites/ahwak-categories.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/scrapers/sites/ahwak.mjs, مهام/تقارير/المصادر.json|
|`server/scrapers/sites/ahwak.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/scrapers/registry.mjs, tests/ahwak.test.mjs, مهام/تقارير/المصادر.json|
|`server/scrapers/sites/akwam.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/providers/akwam.fixture.test.mjs, scripts/providers/akwam.live.test.mjs, server/scrapers/index.mjs, server/scrapers/registry.mjs|
|`server/scrapers/sites/alooy.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/app_path_e2e_verification.mjs, scripts/providers/alooy.fixture.test.mjs, scripts/providers/alooy.live.test.mjs, server/scrapers/index.mjs|
|`server/scrapers/sites/anime4up.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/providers/anime4up.fixture.test.mjs, scripts/providers/anime4up.live.test.mjs, server/scrapers/index.mjs, server/scrapers/registry.mjs|
|`server/scrapers/sites/anime4up_rest.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/scrapers/registry.mjs, server/scrapers/supervisor5-arabseed.mjs, مهام/تقارير/المصادر.json|
|`server/scrapers/sites/arabseed.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/providers/arabseed.fixture.test.mjs, scripts/providers/arabseed.live.test.mjs, server/scrapers/index.mjs, server/scrapers/registry.mjs|
|`server/scrapers/sites/brstej-categories.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/scrapers/sites/brstej.mjs, مهام/تقارير/المصادر.json|
|`server/scrapers/sites/brstej.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/scrapers/registry.mjs, tests/brstej.test.mjs, مهام/تقارير/المصادر.json|
|`server/scrapers/sites/cimanow.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/providers/cimanow.fixture.test.mjs, scripts/providers/cimanow.live.test.mjs, server/scrapers/index.mjs, server/scrapers/registry.mjs|
|`server/scrapers/sites/egydead.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/providers/egydead.fixture.test.mjs, scripts/providers/egydead.live.test.mjs, server/scrapers/index.mjs, server/scrapers/registry.mjs|
|`server/scrapers/sites/egydead_live.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/scrapers/registry.mjs, server/scrapers/supervisor6-witanime-live.mjs, مهام/تقارير/المصادر.json|
|`server/scrapers/sites/fivetv.mjs`|True|KEEP: reachable from runtime/tests/CI; users: scripts/fivetv_capture_audit.mjs, server/scrapers/registry.mjs, tests/fivetv-provider.test.mjs, مهام/تقارير/المصادر.json|
|`server/scrapers/sites/fosta-categories.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/scrapers/sites/fosta.mjs, مهام/تقارير/المصادر.json|
|`server/scrapers/sites/fosta.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/scrapers/registry.mjs, tests/fosta.test.mjs, مهام/تقارير/المصادر.json|
|`server/scrapers/sites/ipauniverse.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/providers/ipauniverse.fixture.test.mjs, scripts/providers/ipauniverse.live.test.mjs, server/scrapers/registry.mjs, server/scrapers/sites/specialized-portals.mjs|
|`server/scrapers/sites/laroza.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/providers/laroza.fixture.test.mjs, scripts/providers/laroza.live.test.mjs, server/scrapers/index.mjs, server/scrapers/registry.mjs|
|`server/scrapers/sites/mewsry.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/providers/mewsry.fixture.test.mjs, scripts/providers/mewsry.live.test.mjs, server/scrapers/registry.mjs, server/scrapers/sites/specialized-portals.mjs|
|`server/scrapers/sites/moviztime.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/app_path_e2e_verification.mjs, scripts/providers/moviztime.fixture.test.mjs, scripts/providers/moviztime.live.test.mjs, server/scrapers/index.mjs|
|`server/scrapers/sites/mycima.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/providers/mycima.fixture.test.mjs, scripts/providers/mycima.live.test.mjs, server/scrapers/index.mjs, server/scrapers/registry.mjs|
|`server/scrapers/sites/qfilm.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/providers/qfilm.fixture.test.mjs, scripts/providers/qfilm.live.test.mjs, server/scrapers/registry.mjs, server/scrapers/sites/specialized-portals.mjs|
|`server/scrapers/sites/ristoanime.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/app_path_e2e_verification.mjs, scripts/providers/ristoanime.fixture.test.mjs, scripts/providers/ristoanime.live.test.mjs, server/scrapers/registry.mjs|
|`server/scrapers/sites/shahid4u.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/episode_identity_browser_test.mjs, scripts/providers/shahid4u.fixture.test.mjs, scripts/providers/shahid4u.live.test.mjs, server/scrapers/index.mjs|
|`server/scrapers/sites/shii4u.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/scrapers/registry.mjs, server/scrapers/supervisor2-shahid-moviz.mjs, مهام/تقارير/المصادر.json|
|`server/scrapers/sites/specialized-portals.mjs`|True|KEEP: reachable from runtime/tests/CI; users: server/scrapers/index.mjs, مهام/تقارير/المصادر.json|
|`server/scrapers/sites/witanime.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/providers/witanime.fixture.test.mjs, scripts/providers/witanime.live.test.mjs, server/scrapers/index.mjs, server/scrapers/registry.mjs|
|`server/scrapers/sites/yallashoot.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/app_path_e2e_verification.mjs, scripts/providers/yallashoot.fixture.test.mjs, scripts/providers/yallashoot.live.test.mjs, scripts/yalla_script_and_hash_test.mjs|
|`server/scrapers/source-manifest.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, server/app.mjs, tests/source-manifest.test.mjs|
|`server/scrapers/source-registry.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/audit_source_searches.mjs, scripts/najd_provider_report_registry.mjs, scripts/pinned_source_test.mjs, scripts/provider_inventory.py|
|`server/scrapers/stream-unwrapper.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, scripts/audit_provider_media_2_beta.mjs, scripts/yalla_script_and_hash_test.mjs, server/app.mjs, server/browser/providers/sites/3cktv.mjs|
|`server/scrapers/supervisor1-mycima.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, package.json, مهام/تقارير/المصادر.json|
|`server/scrapers/supervisor2-shahid-moviz.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, package.json, مهام/تقارير/المصادر.json|
|`server/scrapers/supervisor3-egydead-ipa.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, package.json, مهام/تقارير/المصادر.json|
|`server/scrapers/supervisor4-anime4up.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, package.json, مهام/تقارير/المصادر.json|
|`server/scrapers/supervisor5-arabseed.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, package.json, مهام/تقارير/المصادر.json|
|`server/scrapers/supervisor6-witanime-live.mjs`|True|KEEP: reachable from runtime/tests/CI; users: docs/najd/assets/javascript-functions.json, package.json, server/scrapers/index.mjs, مهام/تقارير/المصادر.json|

Markdown inventory — every file

| File | Classification | Evidence / reason |
|---|---|---|
|`.agents/skills/api-and-interface-design/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/browser-testing-with-devtools/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/ci-cd-and-automation/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/code-review-and-quality/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/code-simplification/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/constraint-driven-development/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/context-engineering/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/debugging-and-error-recovery/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/deprecation-and-migration/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/documentation-and-adrs/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/doubt-driven-development/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/frontend-ui-engineering/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/git-workflow-and-versioning/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/graphify/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3, scripts/repository_inventory.py:75|
|`.agents/skills/graphify/references/add-watch.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:723|
|`.agents/skills/graphify/references/exports.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:577|
|`.agents/skills/graphify/references/extraction-spec.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231|
|`.agents/skills/graphify/references/github-and-merge.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:63|
|`.agents/skills/graphify/references/hooks.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:729|
|`.agents/skills/graphify/references/query.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:717|
|`.agents/skills/graphify/references/transcribe.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:157, .agents/skills/graphify/references/update.md:77|
|`.agents/skills/graphify/references/update.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:705|
|`.agents/skills/hermes-codebase-inspection/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/hermes-dogfood/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/hermes-github/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/hermes-inspecting-hermes-desktop-dom/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/hermes-node-inspect-debugger/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/hermes-python-debugpy/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/hermes-requesting-code-review/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/hermes-spike/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/hermes-systematic-debugging/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/hermes-test-driven-development/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/idea-refine/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/incremental-implementation/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/interview-me/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/matv-master-blueprint/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/najd-brand/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/najd-scraper-maintenance/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/observability-and-instrumentation/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/performance-optimization/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/planning-and-task-breakdown/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/rea-analysis-optimization/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/rea-changelog-update/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/rea-ci-tests-audit/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/rea-tool-design/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/reverse-engineer-anything/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/security-and-hardening/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/shipping-and-launch/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/source-driven-development/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/spec-driven-development/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, AGENTS.md:3, scripts/repository_inventory.py:75|
|`.agents/skills/test-driven-development/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`.agents/skills/using-agent-skills/SKILL.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/SKILL.md:231, .agents/skills/spec-driven-development/SKILL.md:214, AGENTS.md:3|
|`AGENTS.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/constraint-driven-development/SKILL.md:53, .agents/skills/context-engineering/SKILL.md:78, .agents/skills/graphify/SKILL.md:727|
|`FEATURE_QUEUE.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; PROJECT_STATE.md:42, docs/retired-workflows/ai_agent_loop.yml:166, scripts/repository_inventory.py:56|
|`FEATURE_REGISTRY.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; PROJECT_STATE.md:42, scripts/repository_inventory.py:56|
|`FEEDBACK.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; FEATURE_REGISTRY.md:43, PROJECT_STATE.md:12, docs/retired-workflows/ai_agent_loop.yml:170|
|`PROJECT_STATE.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .github/scripts/agent_reviewer.py:23, docs/AUTONOMOUS_REVIEW_RULES.md:5, scripts/repository_inventory.py:56|
|`README.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/references/extraction-spec.md:61, .agents/skills/hermes-spike/SKILL.md:85, app/assets/NOTICES:23561|
|`REVIEW_REPORT.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .github/scripts/agent_reviewer.py:22, FEEDBACK.md:16, PROJECT_STATE.md:86|
|`SPRINT_V2_9_DELIVERY_LOG.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`design/najd-ui/README.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/references/extraction-spec.md:61, .agents/skills/hermes-spike/SKILL.md:85, README.md:20|
|`design/najd-ui/planning/PLAN.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`design/najd-ui/ui/shared/fonts/NOTICE.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; scripts/repository_inventory.py:56|
|`docs/3ISK_DUAL_ENGINE.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`docs/ARCHITECTURE_ATTACHMENT_REVIEW.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/najd-scraper-maintenance/SKILL.md:7|
|`docs/AUTONOMOUS_AGENT_ARCHITECTURE.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`docs/AUTONOMOUS_DEVELOPMENT_STATE.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; FEATURE_REGISTRY.md:42, PROJECT_STATE.md:39, docs/AUTONOMOUS_AGENT_ARCHITECTURE.md:25|
|`docs/AUTONOMOUS_REVIEW_RULES.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/BATCH1_IOS_PHYSICAL_HARDENING.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/BATCH1_LOCAL_STORAGE_GATES.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/CONTENT_RUNTIME_1.0.1.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; scripts/repository_inventory.py:80|
|`docs/DOMAIN_REVIEW_2026-11-12.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/EXECUTION_REPORT_AR.md:42, scripts/repository_inventory.py:56|
|`docs/EDGE_RESOLVER_1.0.41.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/EDGE_RESOLVER_1.0.42.md:3|
|`docs/EDGE_RESOLVER_1.0.42.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`docs/EXECUTION_REPORT_AR.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/EXPLORATION_STORE_INTEGRATION.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; مهام/تقارير/تنفيذ-2026-10-24.md:38, مهام/فرعية/05.01.md:31|
|`docs/HLS_FALLBACK_GAP_AUDIT.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/IDENTITY_V1_0_13.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; scripts/repository_inventory.py:80|
|`docs/IDENTITY_V1_0_17.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; scripts/repository_inventory.py:80|
|`docs/KOYEB_DEPLOYMENT.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`docs/MA_TV_V8_5_AUDIT.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/MITV_1.0.43.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`docs/PHASE1_3ISK_REBUILD.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/PHASE1_3ISK_VALIDATION.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/PHASE2_3ISK_INTEGRATION.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/PHASE1_3ISK_VALIDATION.md:5|
|`docs/PHASE2_PLAYER_AND_AKOAM.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/PHASE3_7_1.0.40.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/PLATFORM_PARITY.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; مهام/README.md:55|
|`docs/PRODUCTION_VERIFICATION.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/EXECUTION_REPORT_AR.md:42|
|`docs/PROVIDER_CONTRACT.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/EXECUTION_REPORT_AR.md:49, scripts/repository_inventory.py:56|
|`docs/PROVIDER_FIXTURE_REVIEW.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/EXECUTION_REPORT_AR.md:50, scripts/repository_inventory.py:56|
|`docs/PROVIDER_INVENTORY.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`docs/RENDER_DEPLOYMENT.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/KOYEB_DEPLOYMENT.md:3|
|`docs/SEARCH_DIAGNOSTICS.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/najd-scraper-maintenance/SKILL.md:7|
|`docs/SECURITY_EPISODE_REVIEW_1.1.2.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/najd-scraper-maintenance/SKILL.md:7|
|`docs/TV_DETAILS_FOCUS_PARITY.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`docs/najd/BUILD_AND_CODE_REFERENCE.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .github/workflows/promote-reviewed-release.yml:81, docs/najd/RUNTIME_AND_FLOW_MAP.md:57|
|`docs/najd/DAILY_REPORTS.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/najd/DATABASE_INCIDENT_2026-11-04.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/najd/DYNAMIC_SOURCES.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; README.md:22, docs/najd/IMPLEMENTATION_2_BETA.md:52|
|`docs/najd/FIVETV_PROVIDER.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`docs/najd/IDENTITY_RENAME_NAJDTV.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; README.md:22|
|`docs/najd/IMPLEMENTATION_1.1.3.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/najd-scraper-maintenance/SKILL.md:7|
|`docs/najd/IMPLEMENTATION_1.1.5.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/najd-brand/SKILL.md:7, AGENTS.md:5|
|`docs/najd/IMPLEMENTATION_2_BETA.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/najd/PLAN_2_BETA.md:24|
|`docs/najd/KEYED_DISCOVERY_2.0.2.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`docs/najd/LOGO_CONCEPTS_1.1.5.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/najd/MAINTENANCE_KNOWLEDGE.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; scripts/najd_daily_report.py:73|
|`docs/najd/NATIVE_UI_BUILD_108.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/najd/NATIVE_UI_BUILD_109.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/najd/PHOTO_REVIEW_4.0.2.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/najd/BUILD_AND_CODE_REFERENCE.md:1, docs/najd/RUNTIME_AND_FLOW_MAP.md:1|
|`docs/najd/PLAN_2_BETA.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`docs/najd/PLAYBACK_1.1.6.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`docs/najd/PLAYER_SETTINGS_NEXT.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`docs/najd/PROVIDER_BROWSER_DIAGNOSTICS_2.0.1.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`docs/najd/PROVIDER_RECOVERY_2026_11_07.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/najd/RELEASE_3.0.2.md:7|
|`docs/najd/RELEASE_2.0.3.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/najd/RELEASE_2.0.4.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/najd/BUILD_AND_CODE_REFERENCE.md:33|
|`docs/najd/RELEASE_3.0.0.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/najd/RELEASE_3.0.1.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/najd/BUILD_AND_CODE_REFERENCE.md:27, docs/najd/RUNTIME_AND_FLOW_MAP.md:51|
|`docs/najd/RELEASE_3.0.2.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/najd/RELEASE_3.0.3.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/najd/PLAYER_SETTINGS_NEXT.md:3|
|`docs/najd/RELEASE_4.0.1.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/najd/BUILD_AND_CODE_REFERENCE.md:5, docs/najd/V4_DATABASE_AND_RECOVERY.md:58, docs/najd/V4_EXECUTION.md:9|
|`docs/najd/RELEASE_4.0.2.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/najd/BUILD_AND_CODE_REFERENCE.md:1, docs/najd/RUNTIME_AND_FLOW_MAP.md:1|
|`docs/najd/REVIEW_AFTER_3.0.0.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/najd/BUILD_AND_CODE_REFERENCE.md:23, docs/najd/RUNTIME_AND_FLOW_MAP.md:47|
|`docs/najd/RUNTIME_AND_FLOW_MAP.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .github/workflows/promote-reviewed-release.yml:81, docs/najd/BUILD_AND_CODE_REFERENCE.md:33|
|`docs/najd/SCRAPER_FAMILIES.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/najd/BUILD_AND_CODE_REFERENCE.md:25, docs/najd/FIVETV_PROVIDER.md:51, docs/najd/RUNTIME_AND_FLOW_MAP.md:49|
|`docs/najd/SECURITY_1.1.5.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/najd/SOURCE_AUDIT_2_BETA.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/najd/IMPLEMENTATION_2_BETA.md:32|
|`docs/najd/SOURCE_POLICY_1.1.7.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; scripts/repository_inventory.py:56|
|`docs/najd/TASKS_2.0.1.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`docs/najd/TASKS_2.0.2.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`docs/najd/TASKS_2.0.3.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`docs/najd/UI_81_HANDOFF.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/najd/V4_DATABASE_AND_RECOVERY.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/najd/BUILD_AND_CODE_REFERENCE.md:5, docs/najd/V4_EXECUTION.md:4|
|`docs/najd/V4_EXECUTION.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`docs/najd/WORK_2.0.5.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/najd/WORK_3.0.0.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`docs/retired-workflows/README.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/references/extraction-spec.md:61, .agents/skills/hermes-spike/SKILL.md:85, README.md:20|
|`docs/sprints/MITV-v2.9-phase3.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; SPRINT_V2_9_DELIVERY_LOG.md:12|
|`docs/sprints/MITV-v2.9-phase4.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; SPRINT_V2_9_DELIVERY_LOG.md:12|
|`flutter_app/README.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/references/extraction-spec.md:61, .agents/skills/hermes-spike/SKILL.md:85, README.md:20|
|`flutter_app/RELEASE_POLICY.md`|KEEP_HISTORY|retained historical evidence; age does not prove obsolescence; |
|`flutter_app/assets/fallback/README.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/references/extraction-spec.md:61, .agents/skills/hermes-spike/SKILL.md:85, README.md:20|
|`مهام/01.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; مهام/README.md:6|
|`مهام/02.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/03.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; مهام/README.md:13|
|`مهام/04.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/05.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/06.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/07.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/najd/RELEASE_3.0.2.md:7|
|`مهام/08.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/09.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/10.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/11.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/12.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/EXECUTION_REPORT_AR.md:42, scripts/repository_inventory.py:56, مهام/README.md:6|
|`مهام/README.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; .agents/skills/graphify/references/extraction-spec.md:61, .agents/skills/hermes-spike/SKILL.md:85, README.md:20|
|`مهام/الثوابت.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; design/najd-ui/planning/PLAN.md:11, مهام/README.md:49|
|`مهام/تقارير/المصادر.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; scripts/provider_inventory.py:18, مهام/README.md:39, مهام/تقارير/تنفيذ-2026-10-24.md:6|
|`مهام/تقارير/تنفيذ-2026-10-24.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; مهام/README.md:50|
|`مهام/تقارير/توحيد-1.1.0.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; مهام/README.md:55|
|`مهام/تقارير/نشر-Render-2026-10-24.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/رئيسية/01.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; مهام/README.md:6|
|`مهام/رئيسية/02.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/رئيسية/03.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; مهام/README.md:13|
|`مهام/رئيسية/04.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/رئيسية/05.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/رئيسية/06.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/رئيسية/07.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/najd/RELEASE_3.0.2.md:7|
|`مهام/رئيسية/08.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/رئيسية/09.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/رئيسية/10.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/رئيسية/11.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/رئيسية/12.md`|KEEP_REFERENCE|convention-loaded instruction/current reference or referenced document; docs/EXECUTION_REPORT_AR.md:42, scripts/repository_inventory.py:56, مهام/README.md:6|
|`مهام/فرعية/01.01.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/01.02.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/01.03.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/02.01.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/02.02.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/02.03.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/03.01.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/03.02.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/03.03.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/03.04.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/04.01.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/04.02.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/05.01.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/05.02.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/06.01.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/06.02.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/06.03.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/07.01.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/07.02.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/08.01.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/08.02.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/09.01.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/09.02.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/09.03.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/09.04.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/09.05.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/09.06.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/10.01.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/10.02.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/10.03.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/11.01.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/11.02.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/11.03.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/12.01.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/12.02.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |
|`مهام/فرعية/12.03.md`|MERGE_REVIEW|unreferenced standalone documentation; review and consolidate, do not delete without content comparison; |

Instructions and skills

- `.agents/skills/api-and-interface-design/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/browser-testing-with-devtools/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/ci-cd-and-automation/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/code-review-and-quality/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/code-simplification/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/constraint-driven-development/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/context-engineering/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/debugging-and-error-recovery/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/deprecation-and-migration/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/documentation-and-adrs/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/doubt-driven-development/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/frontend-ui-engineering/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/git-workflow-and-versioning/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/graphify/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/graphify/references/add-watch.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/graphify/references/exports.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/graphify/references/extraction-spec.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/graphify/references/github-and-merge.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/graphify/references/hooks.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/graphify/references/query.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/graphify/references/transcribe.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/graphify/references/update.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/hermes-codebase-inspection/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/hermes-dogfood/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/hermes-github/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/hermes-inspecting-hermes-desktop-dom/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/hermes-node-inspect-debugger/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/hermes-python-debugpy/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/hermes-requesting-code-review/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/hermes-spike/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/hermes-systematic-debugging/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/hermes-test-driven-development/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/idea-refine/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/incremental-implementation/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/interview-me/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/matv-master-blueprint/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/najd-brand/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/najd-scraper-maintenance/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/observability-and-instrumentation/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/performance-optimization/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/planning-and-task-breakdown/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/rea-analysis-optimization/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/rea-changelog-update/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/rea-ci-tests-audit/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/rea-tool-design/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/reverse-engineer-anything/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/security-and-hardening/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/shipping-and-launch/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/source-driven-development/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/spec-driven-development/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/test-driven-development/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `.agents/skills/using-agent-skills/SKILL.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.
- `AGENTS.md`: keep/update; AGENTS and skills load by convention; zero imports cannot prove disuse.

Instruction findings: AGENTS.md correctly routes provider work to scraper maintenance and UI work to brand guidance. The scraper skill explicitly covers both legacy and current safety/identity invariants; no contradictory deletion instruction was found. Its knowledge-index links can be updated to include PROVIDER_CONTRACT.md and this review. Brand skills concern a separate UI scope and are not dead because this task did not invoke them. `matv-master-blueprint/SKILL.md` still says 21 scrapers, while the registry check proves 25 entries per family (23 non-mirror + 2 mirrors): propose updating counts and linking the live registry. Generic graphify and Hermes tool skills assume optional tools not declared by package.json; scope them to their own tools instead of deleting them. `test-driven-development`/`hermes-test-driven-development` and generic/Hermes debugging/review skills overlap: propose a single routing index, not unproven deletion.

Backup-name candidates

- `flutter_app/lib/src/library_backup_control.dart`: name match only; references flutter_app/lib/src/account_settings.dart:2; not approved for deletion.
- `flutter_app/lib/src/library_backup_export_native.dart`: name match only; references flutter_app/lib/src/library_backup_control.dart:7; not approved for deletion.
- `flutter_app/lib/src/library_backup_export_web.dart`: name match only; references flutter_app/lib/src/library_backup_control.dart:8; not approved for deletion.
- `flutter_app/test/library_backup_test.dart`: name match only; references docs/EXECUTION_REPORT_AR.md:28; not approved for deletion.

Exact byte duplicates — not deletion proof

- `albasri-cinema.html`, `matv-cinema.html`; retain pending path/runtime/asset compatibility review.
- `app/assets/NOTICES`, `internal_web/assets/NOTICES`; retain pending path/runtime/asset compatibility review.
- `app/assets/fonts/fallback/Roboto-Regular.ttf`, `assets/fonts/fallback/Roboto-Regular.ttf`, `internal_web/assets/fonts/fallback/Roboto-Regular.ttf`; retain pending path/runtime/asset compatibility review.
- `app/assets/packages/media_kit/assets/web/hls1.4.10.js`, `assets/packages/media_kit/assets/web/hls1.4.10.js`, `internal_web/assets/packages/media_kit/assets/web/hls1.4.10.js`; retain pending path/runtime/asset compatibility review.
- `app/assets/packages/wakelock_plus/assets/no_sleep.js`, `assets/packages/wakelock_plus/assets/no_sleep.js`, `internal_web/assets/packages/wakelock_plus/assets/no_sleep.js`; retain pending path/runtime/asset compatibility review.
- `app/assets/shaders/ink_sparkle.frag`, `assets/shaders/ink_sparkle.frag`, `internal_web/assets/shaders/ink_sparkle.frag`; retain pending path/runtime/asset compatibility review.
- `app/assets/shaders/stretch_effect.frag`, `assets/shaders/stretch_effect.frag`, `internal_web/assets/shaders/stretch_effect.frag`; retain pending path/runtime/asset compatibility review.
- `app/canvaskit/canvaskit.js`, `canvaskit/canvaskit.js`, `internal_web/canvaskit/canvaskit.js`; retain pending path/runtime/asset compatibility review.
- `app/canvaskit/canvaskit.wasm`, `canvaskit/canvaskit.wasm`, `internal_web/canvaskit/canvaskit.wasm`; retain pending path/runtime/asset compatibility review.
- `app/canvaskit/chromium/canvaskit.js`, `canvaskit/chromium/canvaskit.js`, `internal_web/canvaskit/chromium/canvaskit.js`; retain pending path/runtime/asset compatibility review.
- `app/canvaskit/chromium/canvaskit.wasm`, `canvaskit/chromium/canvaskit.wasm`, `internal_web/canvaskit/chromium/canvaskit.wasm`; retain pending path/runtime/asset compatibility review.
- `app/canvaskit/skwasm.js`, `canvaskit/skwasm.js`, `internal_web/canvaskit/skwasm.js`; retain pending path/runtime/asset compatibility review.
- `app/canvaskit/skwasm.wasm`, `canvaskit/skwasm.wasm`, `internal_web/canvaskit/skwasm.wasm`; retain pending path/runtime/asset compatibility review.
- `app/canvaskit/skwasm_heavy.js`, `canvaskit/skwasm_heavy.js`, `internal_web/canvaskit/skwasm_heavy.js`; retain pending path/runtime/asset compatibility review.
- `app/canvaskit/skwasm_heavy.wasm`, `canvaskit/skwasm_heavy.wasm`, `internal_web/canvaskit/skwasm_heavy.wasm`; retain pending path/runtime/asset compatibility review.
- `app/canvaskit/webparagraph/canvaskit.js`, `canvaskit/webparagraph/canvaskit.js`, `internal_web/canvaskit/webparagraph/canvaskit.js`; retain pending path/runtime/asset compatibility review.
- `app/canvaskit/webparagraph/canvaskit.wasm`, `canvaskit/webparagraph/canvaskit.wasm`, `internal_web/canvaskit/webparagraph/canvaskit.wasm`; retain pending path/runtime/asset compatibility review.
- `app/canvaskit/wimp.js`, `canvaskit/wimp.js`, `internal_web/canvaskit/wimp.js`; retain pending path/runtime/asset compatibility review.
- `app/canvaskit/wimp.wasm`, `canvaskit/wimp.wasm`, `internal_web/canvaskit/wimp.wasm`; retain pending path/runtime/asset compatibility review.
- `app/favicon.png`, `favicon.png`, `flutter_app/web/favicon.png`; retain pending path/runtime/asset compatibility review.
- `app/flutter.js`, `flutter.js`, `internal_web/flutter.js`; retain pending path/runtime/asset compatibility review.
- `app/icons/Icon-192.png`, `app/icons/Icon-maskable-192.png`, `flutter_app/web/icons/Icon-192.png`, `flutter_app/web/icons/Icon-maskable-192.png`, `icons/Icon-192.png`, `icons/Icon-maskable-192.png`; retain pending path/runtime/asset compatibility review.
- `app/icons/Icon-512.png`, `app/icons/Icon-maskable-512.png`, `flutter_app/web/icons/Icon-512.png`, `flutter_app/web/icons/Icon-maskable-512.png`, `icons/Icon-512.png`, `icons/Icon-maskable-512.png`; retain pending path/runtime/asset compatibility review.
- `assets/assets/fallback/NotoSansArabic.ttf`, `design/najd-ui/ui/shared/fonts/NotoSansArabic.ttf`, `flutter_app/assets/fallback/NotoSansArabic.ttf`, `internal_web/assets/assets/fallback/NotoSansArabic.ttf`; retain pending path/runtime/asset compatibility review.
- `assets/assets/fallback/OFL.txt`, `flutter_app/assets/fallback/OFL.txt`, `internal_web/assets/assets/fallback/OFL.txt`; retain pending path/runtime/asset compatibility review.
- `assets/assets/najd/mark.png`, `assets/brand/najd-mark.png`, `flutter_app/assets/najd/mark.png`, `internal_web/assets/assets/najd/mark.png`; retain pending path/runtime/asset compatibility review.
- `flutter_app/web/icons/Najd-Apple-180.png`, `icons/Najd-Apple-180.png`; retain pending path/runtime/asset compatibility review.
- `flutter_app/web/manifest.json`, `manifest.json`; retain pending path/runtime/asset compatibility review.
- `flutter_app/web/najd-install.js`, `najd-install.js`; retain pending path/runtime/asset compatibility review.
- `flutter_app/web/najd-video.js`, `najd-video.js`; retain pending path/runtime/asset compatibility review.
- `flutter_bootstrap.js`, `internal_web/flutter_bootstrap.js`; retain pending path/runtime/asset compatibility review.
- `flutter_service_worker.js`, `internal_web/flutter_service_worker.js`; retain pending path/runtime/asset compatibility review.
- `internal_web/icons/Icon-192.png`, `internal_web/icons/Icon-maskable-192.png`; retain pending path/runtime/asset compatibility review.
- `internal_web/icons/Icon-512.png`, `internal_web/icons/Icon-maskable-512.png`; retain pending path/runtime/asset compatibility review.

Concrete documentation consolidation: docs/IDENTITY_V1_0_13.md describes the superseded black/gold Qaf identity; docs/IDENTITY_V1_0_17.md explicitly supersedes it with a Q mark. Both are historical relative to current Najd branding: propose archival labels plus a link to current brand rules, not removal of history. docs/CONTENT_RUNTIME_1.0.1.md explicitly records an intended old Basri migration: archive its status and link PROVIDER_CONTRACT.md. Retain SOURCE_POLICY_1.1.7.md as current source-identity authority and font NOTICE.md as licensing evidence.

Deletion proposal: NONE APPROVED. MERGE_REVIEW documents and REVIEW_ONLY code are review candidates, not proven dead files. The JSON inventory contains full line-reference evidence. Existing generated platform artifacts and duplicated Najd/Beta source implementations must not be removed merely for hash/import similarity.

Validation: rerun the six requested suites after inventory generation. No application behavior is changed by this inventory.
