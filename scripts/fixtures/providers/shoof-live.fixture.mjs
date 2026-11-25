export const FIXTURE_META = {
  providerId:'shoof-live',
  provenance:'Synthetic markup based on public search DOM observed 2026-11-24',
  urls:{search:'https://m1.shooflive.buzz/?s=اسد'},
};

export const SEARCH_HTML = `<main id="shooflive-smart-search"><div class="slv2-grid">
  <a class="slv2-card" href="/movies/film/">
    <span class="slv2-name">فيلم أسد 2026</span>
    <div class="slv2-poster"><img data-src="/fixture.webp" src="placeholder.gif"></div>
    <span class="slv2-badge">فيلم</span>
  </a></div></main>`;

export const CATALOG_HTML = `<main>
  <div class="block-post"><a href="/movies/film/"><div class="title">فيلم أسد 2026</div></a></div>
  <div class="block-post"><a href="/series/show/"><img alt="مسلسل" data-src="/show.webp"></a></div>
  <div class="block-post"><a href="/episode/show-988/"><div class="title">الحلقة 988</div></a></div>
</main>`;
