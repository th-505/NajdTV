# External provider sections

The Beta directory lists 14 external sources, with ATV and Kanal D available separately through both integrated provider registries. The browser directory API exposes the sections. The external-section API accepts a directory provider and section ID and returns public work or episode links where a listing parser is available. Opening a work delegates playback to the original site. Regional availability, account requirements, and playback resolution are determined there.

| Source | Public sections | Inspection outcome |
| --- | --- | --- |
| MBC Shahid | Free drama, Saudi shows, series, movies, Turkish | The free drama and series landing pages returned 200. Series and movie catalogs can include paid titles. |
| ADtv | Abu Dhabi library | The original URL redirected to STARZPLAY and the destination returned 403 from the inspection network. |
| Roya | Shows and series | Origin produced a 526 TLS error from the inspection network. |
| Weyyak | Main catalog | Origin returned 503 from the inspection network. |
| Tubi | Full HD, exclusives | The Full HD URL redirected to the regional information page in the inspection network. |
| Plex | On demand, free A24 selection, live TV | The public navigation exposed all three. Discovery pages can include availability at other services. |
| Pluto TV | Movies, shows, live TV | Movies and shows list item links. These sections use the US catalog and remain region-dependent. |
| The Roku Channel | Main channel catalog | The channel URL redirected to the Roku app landing page in the inspection network. |
| Türk Dizileri İzle | Playlists and videos | Public channel URLs. The inspection network denied the YouTube connection. |
| ATV | Current shows, archive, Kuruluş Osman episodes | The public HTML showed episode links with source numbers. |
| Kanal D | Series, D-Shorts, Kanıt episodes | The public HTML showed episodes and season controls. |
| puhutv | Turkish series, originals, East Asian titles | Public navigation linked all three, including East Asian shows. |
| Muse Asia | Playlists and videos | Public channel URLs. The inspection network denied the YouTube connection. |
| Ani-One Asia | Playlists and videos | Public channel URLs. The inspection network denied the YouTube connection. |
| GundamInfo | Official playlists, Build Metaverse | The official release page moved to gundam-official.com and returned 200. |
| RetroCrush | Classic anime catalog, free-viewing details | The home page returned 200. Access can vary by title. |

The Pluto, ATV and Kanal D HTML extractors use HTTPS-only hosts, site-specific path patterns, bounded HTML, and duplicate suppression. There is always a link to open the provider's section if the work listing is empty or the upstream is unreachable. The directory does not claim that a listing is a direct stream or that its available quality has been verified.

## Follow-up verification

Temporary network timeouts and HTTP 408/502/503/504 get one retry on the same approved URL. HTTP 403, access challenges and unsafe redirects retain their original failure path.

The guarded live fetch returned 13 ATV episodes, 30 Kanal D episodes and 18 Kanal D series. ATV's current/archive index timed out through the guarded path. Pluto's guarded listing was empty despite featured shelves appearing in the captured public HTML. Weyyak returned 503 twice, ADtv redirected to an access-denied page, Tubi redirected to its regional information page, and Roku redirected to its app landing page. The three inspected YouTube channel connections remained unavailable on the inspection network. A candidate 1080p MP4 found on an ATV episode returned redirects without a verified media response. The Kanal D sample did not expose a direct media URL in its public HTML.

These are directory and catalog results. None of the 16 sources has passed independent end-to-end playback certification in both Core and Beta.

The next inspection found 100 signed-out Plex VOD cards in the public on-demand HTML. Najd now exposes distinct movie and series previews, matching Plex's own VOD card marker and excluding discovery cards for other services. Parsing the captured response yielded 60 movie preview entries and 21 series entries. The guarded live request to Plex timed out in this run. Pluto's public navigation exposed dedicated US anime movies and anime series sections, which are available as official links in the directory.

## ATV integration

ATV now has separate Core and Beta modules. Live guarded tests of both modules returned three current series, a result for Hamal, and thirteen observed Kuruluş Osman episodes including episode 187. Both modules resolved the published MP4 for episode 187 and verified the CDN response using a bounded 1024-byte range request. The CDN returned HTTP 206 with an MP4 file signature. The observed URL carries a 1080p label. This check does not confirm playback on every Najd client or availability outside the tested network.

The separate Kanal D work sample exposed an embed link but no direct media response was verified.

## Release acceptance

Run the strict audit independently for Core and Beta using the audit script with scope najd or beta and the strict flag. To focus a diagnostic run on one provider, pass its ID using the provider option. The nine recorded stages verify specialization, one declared catalog section, catalog, positive and negative search, work name, image response, direct media container, complete server inventory, and quality metadata per playable server. Image and media probes read a bounded prefix. A probe is distinct from playback on a physical device.

The release flag checks that both families expose 39 active, independent providers with a catalog before starting the strict audit for the selected scope. Run it once per family. Any missing or failed stage causes a nonzero exit. Fixture passes are separate from live verification.

## Kanal D integration and audit snapshot

Kanal D has separate Core and Beta adapters. The current-series index returned 18 titles and the archive check returned 24 titles. The Kanıt index exposed 30 episode links on the sampled page. Older and newer episode URL formats preserve source numbering. For Kanıt, the public embed declares a relative HLS path and the CDN to resolve it against. For Daha 17, episode metadata directly publishes an HTTPS HLS manifest. Both paths are restricted to the observed CDN and checked for a valid manifest.

The 2026-11-25 strict audit checked 24 previous Core and 25 previous Beta entries. Nine per family passed all seven stages. The new Kanal D adapters then passed all seven stages in separate live runs in each family, bringing the observed pass count to ten per family. These are server-side checks on representative samples.

The playback response keeps provider, server identity and quality metadata separate. The server picker groups the available files on the same server, and the quality picker selects levels from that server. Web HLS uses its automatic level selection, and native HLS automatic mode makes a selection using the available bandwidth estimate. Fixed-file labels are published metadata and do not establish decoded pixel size.

### New acceptance run, 2026-11-25

With the server inventory and per-server quality checks enabled, the full live audit completed for 25 Core entries and 26 Beta entries. The same five IDs passed all nine checks in both families: 3cktv, qfilm, ristoanime, atv-tr and kanal-d. The most frequent failure was unconfirmed server quality metadata, with 13 Core and 14 Beta failures. These results supersede the earlier seven-stage pass counts for release qualification.
