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
|laroza|laroza.buzz → laroza1.click → laroza-tv.cfd → laroza1.shop → laroza1.site (then homepage path redirects)|Adopted the directly reviewed origin https://laroza1.site; never auto-follow this chain or raise redirect budgets.|
|fivetv|https://ho26374qa.5ivtv.in [302] → https://ce73291ro.5ivtv.in/ [302] → https://new61.5tv.lol/ [200]|new61.5tv.lol already exists in the source allowlist; intermediary changed since prior audit. No expansion.|
|laroza-worker-origin|Old larooza.beer traverses many legacy aliases before the same domain|Replace the configured metadata origin with the reviewed direct origin; retain exact-origin redirect checks.|

Current Laroza verification

The old worker origin redirected outside its exact metadata origin; the gateway and service binding themselves existed. Direct review of `https://laroza1.site` established the source identity before admitting it: two series-category GETs returned the same 40 parsed works; an actual series page returned eight numbered episodes with unknown seasons left null; the matching watch page linked the existing allowed host `mp4plus.org`; that player produced two MP4 candidates under the already allowed `*.cdnz.quest`, both returning HEAD 200 and video/mp4. A known-positive keyword search returned 11 parsed results including the selected work.

Node, Beta and Edge now use this exact origin, with a regression fixture made from sanitized observed catalog/episode fragments. The metadata origin is replaced rather than permitting arbitrary redirected hosts. Media allowlists and redirect/DNS/private-address protections are unchanged; new hosts observed in other players are not admitted. A media HEAD check is availability evidence, not a certification of full playback on physical devices. An explicit operational disable remains available.
