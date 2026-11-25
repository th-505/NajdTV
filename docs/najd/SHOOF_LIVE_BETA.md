# ShoofLive Beta

The adapter lives in `server/browser/providers/sites/shoof-live.mjs` and is registered only in the Beta browser registry. It implements search, work details, source episode indexing, server discovery and direct media extraction. It uses guarded HTTPS requests and parses published HTML and inline media literals. It does not run the site's JavaScript, forward browser sessions or proxy video. The Beta browser lists this provider through its latest catalog, sourced from the public homepage. No live-channel capability is advertised.

## Routes observed on 2026-11-24

- The working search host for these probes was `m1.shooflive.buzz`. The document's canonical pointed to `shooflive.watch`. Search starts with `/?s=...` and subsequent results use `/search/{term}/?sp=N`. “اسد” returned two cards. “مسلسل” returned 24 cards on each of the first two pages, and the adapter reported page three as the next page.
- Two film detail pages exposed AlbaPlayer iframes. The tested film and episode exposed the same AlbaPlayer reference on their ordinary page and their corresponding `/servers/` page. No AJAX trigger was needed for those responses.
- The tested series exposed eight episode cards for its fourth season. An episode exposed six AlbaPlayer menu entries, including Cdnplus and an independently advertised host for VidSpeed. The tested film exposed five. Server positions are obtained from the published anchors and processed in displayed order with bounded request concurrency.
- The tested film's five menu entries led to AnaFast, MP4Plus, VidSpeed, VK and Voe. The AnaFast embed returned a literal HLS URL. A bounded request from the inspection environment obtained a media playlist with HTTP 200. MP4Plus returned literal MP4 URLs and a small byte-range request returned HTTP 206. VidSpeed responded with a redirect, the inspection environment's tunnel denied VK, and Voe returned HTTP 404. These observations do not certify playback in Najd clients.
- The guarded Node path required the inspection environment's standard `NODE_USE_ENV_PROXY=1` transport setting. With it, the adapter ran live search and resolved two films and two episodes. The VidSpeed host `vidspeeds.org` was independently observed in the episode menu and returned an HLS URL. Cdnplus redirected to an unapproved host. Repeat playback checks in the deployed Beta runtime and Najd clients before promoting.

## Configuration and diagnosis

Use the existing Beta provider configuration for the site's `primary_domain`. Add exact verified hostnames in comma-separated `SHOOF_LIVE_PLAYER_HOSTS` or `SHOOF_LIVE_EMBED_HOSTS` when the published player changes hosts. Hostnames seen in redirects are not added automatically. Direct media uses the actual embed as its Referer. The adapter discards an expired URL when a signed link carries a recognizable Unix timestamp in `s` and a duration in `e`. A fresh resolution reads the published embed again.

The adapter exposes process-local diagnostic snapshots through `getShoofDiagnostics()`. Rows cover attempts, successful extractions, average elapsed milliseconds and the last failure category, keyed by approved host. The snapshots omit full URLs, query text, token values and cookies. There is no public metrics endpoint for this adapter.
