import {listExternalSections} from './external-provider-sections.mjs';
export const PROVIDER_GROUPS = Object.freeze({
  arabic:'عربي', foreign:'أجنبي', turkish:'تركي', anime:'أنمي', asian:'آسيوي', indian:'هندي',
});

const mixed = ['arabic','foreign','turkish','asian','indian'];
const groupsById = {
  ahwak:['arabic','foreign','turkish','indian'], brstej:mixed, fosta:['foreign','turkish','asian','indian'],
  mycima:mixed, akwam:mixed, cimanow:mixed, shahid4u:mixed, moviztime:mixed,
  shii4u:mixed, egydead:['arabic','foreign','asian','indian'], ipauniverse:['foreign','asian'],
  '3cktv':['turkish'], '3isk':['turkish'], anime4up:['anime'], anime4up_rest:['anime'],
  qfilm:['arabic','foreign','indian'], ristoanime:['anime'], arabseed:mixed,
  mewsry:['arabic'], witanime:['anime'], egydead_live:[], yallashoot:[],
  alooy:['arabic','turkish'], laroza:['arabic','turkish'], fivetv:['asian'],
  animezid:['anime'], movizland:mixed, egybest:mixed,
  'shoof-live':[...mixed,'anime'],
};
export const providerGroups = id => Object.hasOwn(groupsById,id) ? [...groupsById[id]] : [];

const external = [
  ['mbc-shahid','شاهد المجاني','https://shahid.mbc.net/en/explorefreedrama',['arabic','turkish']],
  ['ad-tv','ADtv','https://adtv.ae/',['arabic']],
  ['roya','رؤيا','https://royatv.com/',['arabic']],
  ['weyyak','وياك','https://weyyak.com/',['arabic','indian','turkish']],
  ['tubi','Tubi','https://tubitv.com/category/watch_in_full_hd',['foreign','anime','asian','indian']],
  ['plex','Plex','https://www.plex.tv/watch-free/',['foreign']],
  ['pluto','Pluto TV','https://pluto.tv/',['foreign','anime']],
  ['roku-channel','The Roku Channel','https://therokuchannel.roku.com/',['foreign']],
  ['turk-dizileri','Türk Dizileri İzle','https://www.youtube.com/channel/UCJgwSnUyW6Nx5Hjg9ymHa4Q',['turkish']],
  ['atv-tr','ATV','https://www.atv.com.tr/kurulus-osman/bolumler',['turkish']],
  ['kanal-d','Kanal D','https://www.kanald.com.tr/kanit/bolumler',['turkish']],
  ['puhutv','puhutv','https://puhutv.com/',['turkish','asian']],
  ['muse-asia','Muse Asia','https://www.youtube.com/@MuseAsia/playlists',['anime']],
  ['ani-one','Ani-One Asia','https://www.youtube.com/@AniOneAsia/playlists',['anime']],
  ['gundaminfo','GundamInfo','https://en.gundam.info/news/video-music/01_12737.html',['anime']],
  ['retrocrush','RetroCrush','https://www.retrocrush.tv/',['anime']],
];
export function externalProviderDirectory() {
  return external.map(([id,name,url,groups]) => ({id,name,url,groups:[...groups],access:'external',sections:listExternalSections(id)}));
}

export async function searchProviderGroup({group,query,providers,search,globalSearch,preferred}) {
  if (!Object.hasOwn(PROVIDER_GROUPS,group) || query.length < 2 || query.length > 120) {
    throw new Error('BROWSER_BAD_QUERY');
  }
  const fallbackAt = Date.now() + 12_000;
  const eligible = providers.filter(source => source.capabilities?.search &&
    source.enabled !== false && providerGroups(source.id).includes(group));
  const preferredSource = eligible.find(source => source.id === preferred);
  if (preferredSource) {
    const rows = await search(preferredSource.id,query).catch(()=>[]);
    if (rows.length) return {items:rows,scope:'beta',fallback:false};
  }
  const others = eligible.filter(source => source !== preferredSource);
  for (let start=0; start<others.length && Date.now()<fallbackAt; start+=4) {
    const results = await Promise.allSettled(others.slice(start,start+4).map(source=>search(source.id,query)));
    const seen = new Set();
    const items = results.flatMap(result=>result.status==='fulfilled' ? result.value : [])
      .filter(item=>item?.ref && !seen.has(item.ref) && seen.add(item.ref));
    if (items.length) return {items,scope:'beta',fallback:false};
  }
  const result = await globalSearch(query);
  return {items:Array.isArray(result?.data)?result.data:[],scope:'najd',fallback:true};
}
