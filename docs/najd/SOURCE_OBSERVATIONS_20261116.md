# Source maintenance observations — 2026-11-16

These are observed parser/network results, not a claim that every source plays.

- Use the execution workspace's configured network proxy for live Node checks (`node --use-env-proxy`). Without it, direct outbound requests timed out collectively. Never change production TLS, SSRF or source protections to accommodate the development network.
- AnimeZid: a focused public catalog returned 181 rows after 5.7 seconds. One watch page's primary action led to an external `/skip` gateway, not a direct player. Report `UNSUPPORTED_CAPABILITY` / `SOURCE_EXTERNAL_WATCH_GATEWAY`; do not label a successful catalog as successful playback, execute gateway scripts or silently broaden host allowlists.
- Ahwak: one sample returned 52 catalog rows; a sampled work exposed 15 episodes with 15 images and no durations on its index, plus 10 server entries. Counts describe that sample, not the site's full catalog. Some durations exist on individual watch pages; metadata enrichment for every indexed episode is still pending.
- Explicit duration labels such as `مدة العرض: ٤٦:٢٠` are supported, including Arabic/Persian digits on the Ahwak watch-page fallback. Unlabelled arbitrary numbers remain unknown.
- The observed HTML resolver previously truncated servers at four entries. It now keeps all observed entries within its bounded request schedule; fixture coverage verifies six hosts in both independent parser families. Completing/resuming every host discovery in the background is a separate unfinished task.
- Catalog diagnostics now allow ten seconds per guarded request because a proven successful catalog exceeded the old five-second budget. A deadline is an availability result, not proof a work is absent.
- After changing provider modules, run `python3 scripts/provider_inventory.py`, review the generated hashes, then `--check`. CI checks the inventory independently of the Node unit suite.

Do not record resolved signed URLs, user searches, session credentials or cookies here. Do not multiply source counts by parser families: active module declarations, explicit mirrors and independently reachable sites are different measurements.
