import * as cheerio from 'cheerio';
import {fetchProviderHtml, resolveSafeUrl} from '../scrapers/shared/http.mjs';

// Public pages discovered in provider navigation or official release notes.
const entries = {
  'mbc-shahid':[
    ['free-drama','دراما مجانية','https://shahid.mbc.net/en/explorefreedrama'],
    ['saudi','أعمال سعودية','https://shahid.mbc.net/en/landingpages/sba'],
    ['series','دليل المسلسلات','https://shahid.mbc.net/en/series'],
    ['movies','دليل الأفلام','https://shahid.mbc.net/en/movies'],
    ['turkish','أعمال تركية','https://shahid.mbc.net/en/meta/genres/Turkish/49923065123937'],
  ],
  'ad-tv':[['catalog','مكتبة أبوظبي','https://adtv.ae/']],
  roya:[['catalog','البرامج والمسلسلات','https://royatv.com/']],
  weyyak:[['catalog','دليل وياك','https://weyyak.com/']],
  tubi:[
    ['full-hd','أعمال Full HD','https://tubitv.com/category/watch_in_full_hd'],
    ['exclusives','أعمال Tubi الحصرية','https://tubitv.com/category/tubi_exclusive'],
  ],
  plex:[
    ['on-demand','أفلام ومسلسلات عند الطلب','https://watch.plex.tv/on-demand'],
    ['a24','أفلام A24 المجانية','https://www.plex.tv/a24-movies/'],
    ['live','قنوات Plex','https://watch.plex.tv/live-tv'],
  ],
  pluto:[
    ['movies','أفلام','https://pluto.tv/us/movies/', /^\/us\/movies\/[a-f0-9]{24}\/?$/],
    ['shows','مسلسلات','https://pluto.tv/us/shows/', /^\/us\/shows\/[\w-]+\/?$/],
    ['live','قنوات مباشرة','https://pluto.tv/us/watch/live-tv/'],
  ],
  'roku-channel':[['catalog','دليل Roku','https://therokuchannel.roku.com/']],
  'turk-dizileri':[
    ['playlists','قوائم المسلسلات','https://www.youtube.com/channel/UCJgwSnUyW6Nx5Hjg9ymHa4Q/playlists'],
    ['videos','أحدث الفيديوهات','https://www.youtube.com/channel/UCJgwSnUyW6Nx5Hjg9ymHa4Q/videos'],
  ],
  'atv-tr':[
    ['series','المسلسلات الحالية','https://www.atv.com.tr/diziler'],
    ['archive','أرشيف المسلسلات','https://www.atv.com.tr/eski-diziler'],
    ['osman','حلقات المؤسس عثمان','https://www.atv.com.tr/kurulus-osman/bolumler', /^\/kurulus-osman\/\d+-bolum(?:\/izle)?\/?$/],
  ],
  'kanal-d':[
    ['series','المسلسلات','https://www.kanald.com.tr/diziler'],
    ['shorts','الدراما القصيرة','https://www.kanald.com.tr/d-shorts-diziler/'],
    ['kanit','حلقات مسلسل Kanıt','https://www.kanald.com.tr/kanit/bolumler', /^\/kanit\/bolumler\/\d+-bolum(?:-izle)?\/?$/],
  ],
  puhutv:[
    ['series','المسلسلات التركية','https://puhutv.com/yerli-diziler'],
    ['originals','إنتاجات puhutv','https://puhutv.com/puhutv-orijinal'],
    ['asian','أعمال شرق آسيا','https://puhutv.com/uzak-dogu-ruzgari'],
  ],
  'muse-asia':[
    ['playlists','قوائم الأنمي','https://www.youtube.com/@MuseAsia/playlists'],
    ['videos','أحدث الفيديوهات','https://www.youtube.com/@MuseAsia/videos'],
  ],
  'ani-one':[
    ['playlists','قوائم الأنمي','https://www.youtube.com/@AniOneAsia/playlists'],
    ['videos','أحدث الفيديوهات','https://www.youtube.com/@AniOneAsia/videos'],
  ],
  gundaminfo:[
    ['playlists','قوائم Gundam الرسمية','https://www.youtube.com/user/GundamInfo/playlists'],
    ['metaverse','إصدار Gundam Build Metaverse','https://en.gundam-official.com/news/i/news/video-music/01_12737'],
  ],
  retrocrush:[
    ['catalog','كتالوج الأنمي الكلاسيكي','https://www.retrocrush.tv/'],
    ['availability','تفاصيل المشاهدة المجانية','https://support.retrocrush.tv/portal/en/kb/articles/how-much-does-retro-crush-cost'],
  ],
};

export function listExternalSections(provider) {
  if (!Object.hasOwn(entries,provider)) return [];
  return entries[provider].map(([id,label,url,matcher])=>({id,label,url,browse:Boolean(matcher)}));
}

export async function loadExternalSection(provider,id,options={}) {
  const definition = Object.hasOwn(entries,provider) && entries[provider].find(row=>row[0]===id);
  if (!definition?.[3]) throw Error('EXTERNAL_SECTION_UNSUPPORTED');
  const [, , url, matcher] = definition;
  // Pluto's public home embeds the featured shelves, while its section pages load them on the client.
  const listingUrl = provider === 'pluto' ? new URL('/',url).href : url;
  const origin = new URL(url).origin;
  const allowedHosts = [new URL(url).hostname];
  const result = await fetchProviderHtml(listingUrl,{...options,
    allowHttp:false, allowedHosts, timeoutMs:6500, maxRetries:0, maxBytes:2*1024*1024});
  if (!result.ok) throw Error('EXTERNAL_SECTION_UNAVAILABLE');
  const $ = cheerio.load(result.html);
  const items = new Map();
  $('a[href]').each((_, node) => {
    const anchor = $(node);
    const raw = resolveSafeUrl(anchor.attr('href'),result.url,{allowHttp:false,allowedHosts});
    if (!raw) return;
    const target = new URL(raw);
    if (target.origin !== origin || !matcher.test(target.pathname)) return;
    let title = [anchor.attr('title'),anchor.find('img').first().attr('alt'),anchor.attr('aria-label'),anchor.text()]
      .map(value=>String(value||'').replace(/\s+/g,' ').trim()).find(Boolean);
    if (!title || title.length > 180) return;
    const episode = target.pathname.match(/\/(\d+)-bolum(?:-izle|\/izle)?\/?$/)?.[1];
    if (episode && !new RegExp('(?:^|\\D)'+episode+'(?:\\D|$)').test(title)) {
      title += ' · الحلقة '+episode;
    }
    const link = origin+target.pathname;
    if (!items.has(link)) items.set(link,{title,url:link});
  });
  return [...items.values()].slice(0,60);
}
