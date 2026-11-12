Domain review — 2026-11-12

Public HTTPS probes; no cookies/authentication, JavaScript execution or application allowlist changes. DNS public-address checks passed for recorded hops. A 200/title/logo marker is not sufficient proof of source identity or a working extractor. No domain was adopted automatically.

| Source | Observed chain | Decision |
|---|---|---|
|brstej|https://brstej.garden [301] → https://prstej.lat/ [301] → https://prstej.lat/home03 [200]|Not adopted: positive parser/identity and repeated stability evidence incomplete.|
|mycima|https://mycima.gdn [301] → https://mycima.house/ [403]|Not adopted: terminal 403 challenge.|
|cimanow|https://cimanow.info [301] → https://myseed.name/ [200]|Not adopted: destination brands itself MySeed, not evidence of CimaNow identity.|
|shahid4u|https://shahidfu.cam [301] → https://shahidfu.live/ [200]|Not adopted: positive parser/identity and repeated stability evidence incomplete.|
|egydead|https://a1.egydead.media [301] → https://egydead.life/ [403]|Not adopted: terminal 403 challenge.|
|ristoanime|https://ristoanime.me [301] → https://ristoanime.cc/ [200]|Not adopted: positive parser/identity and repeated stability evidence incomplete.|
|egydead_live|https://tv10.egydead.live [301] → https://a1.egydead.media/ [301] → https://egydead.life/ [403]|Not adopted: terminal 403 challenge.|
|yallashoot|https://yalla-shootz.cc [301] → https://www.yalla-shoat.today/ [200]|Not adopted: positive parser/identity and repeated stability evidence incomplete.|
|laroza|https://laroza.buzz [301] → https://laroza1.click/ [301] → https://laroza-tv.cfd/ [301] → https://laroza1.shop/ [301] → https://laroza1.site/ [302]|Not adopted: chain exceeded the five-hop audit budget; final identity/stability unproven.|
|fivetv|https://ho26374qa.5ivtv.in [302] → https://ce73291ro.5ivtv.in/ [302] → https://new61.5tv.lol/ [200]|new61.5tv.lol already exists in the source allowlist; intermediary changed since prior audit. No expansion.|
|laroza-worker-origin|https://larooza.beer [301] → https://larooza.net/ [301] → https://laroza.garden/ [301] → https://laroza1.cyou/ [301] → https://laroza1.surf/ [301]|Not adopted: chain exceeded the five-hop audit budget; final identity/stability unproven.|

Laroza gateway diagnosis

Connected Cloudflare read confirmed `matv-edge-resolver` has a LAROZA service binding to `mitv-extract-laroza`; its PROVIDER_CONFIG.origin is `https://larooza.beer`. Thus the /v1/laroza/category route and binding exist. The configured source redirects outside the exact metadata origin. The previous category aggregation hid this cause behind LAROZA_CATALOG_UNAVAILABLE.

Code now preserves the bounded failure as upstream_reason=LAROZA_SOURCE_REDIRECT_REQUIRES_REVIEW, error_code=ACCESS_BLOCKED, state=unavailable, through Edge and Node. Deterministic regression verifies that the unreviewed destination receives zero requests. This repairs diagnosis/propagation, not source availability. Live recovery remains blocked until source identity and positive extraction are verified; no production deployment or unsafe domain expansion is claimed.

Checklist before future adoption: two stable final-origin probes; matching branding/logo and work URLs; known-positive search parsed by that source adapter; current public DNS and HTTPS/redirect tests; sanitized fixture and compatibility/reference tests in both Najd and Beta.
