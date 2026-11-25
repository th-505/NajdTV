# External provider sections

The Beta directory lists public section links for all 16 sources. The browser directory API exposes the sections. The external-section API accepts a directory provider and section ID and returns public work or episode links where a listing parser is available. Opening a work delegates playback to the original site. Regional availability, account requirements, and playback resolution are determined there.

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
