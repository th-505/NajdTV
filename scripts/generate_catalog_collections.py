import json
from pathlib import Path
rows=[]
def add(group,key,title,kind='movie',params=None,window=None):
 rows.append(dict(id=f'catalog:collection:{group}-{key}',group=group,title=title,type=kind,params=params or {},**({'window':window} if window else {})))
for group,kind,label in [('movie','movie','أفلام'),('series','tv','مسلسلات')]:
 for key,title,params,window in [
  ('top','أفضل عشرة '+label,{'sort_by':'vote_average.desc','vote_count.gte':'300' if kind=='movie' else '100'},None),
  ('popular','الأكثر رواجًا',{'sort_by':'popularity.desc'},None),
  ('year','الأعلى تقييمًا هذا العام',{'sort_by':'vote_average.desc','vote_count.gte':'50'},'year'),
  ('recent','أحدث '+label,{'sort_by':'primary_release_date.desc' if kind=='movie' else 'first_air_date.desc'},'past'),
  ('classic','كلاسيكيات تستحق المشاهدة',{'sort_by':'vote_average.desc','vote_count.gte':'300','primary_release_date.lte' if kind=='movie' else 'first_air_date.lte':'1999-12-31'},None),
  ('arabic','مكتبة عربية',{'with_original_language':'ar'},None)]:add(group,key,title,kind,params,window)
 movie=[(28,'أكشن'),(12,'مغامرات'),(16,'رسوم متحركة'),(35,'كوميديا'),(80,'جريمة'),(99,'وثائقي'),(18,'دراما'),(10751,'عائلي'),(14,'فانتازيا'),(36,'تاريخ'),(27,'رعب'),(10402,'موسيقى'),(9648,'غموض'),(10749,'رومانسي'),(878,'خيال علمي'),(53,'تشويق')]
 tv=[(10759,'أكشن ومغامرات'),(16,'رسوم متحركة'),(35,'كوميديا'),(80,'جريمة'),(99,'وثائقي'),(18,'دراما'),(10751,'عائلي'),(10762,'للأطفال'),(9648,'غموض'),(10765,'خيال علمي وفانتازيا'),(10768,'حروب وسياسة'),(10766,'دراما يومية'),(37,'ويسترن'),(10764,'واقع')]
 for genre,name in movie if kind=='movie' else tv:add(group,str(genre),name,kind,{'with_genres':str(genre)})
for key,title,kind,params,window in [
 ('top','أفضل عشرة أنمي','tv',{'sort_by':'vote_average.desc','vote_count.gte':'100'},None),('popular','أنمي رائج','tv',{},None),('movies','أفلام أنمي','movie',{},None),('week','حلقات أنمي هذا الأسبوع','tv',{},'week'),('upcoming','الأنمي الأسبوع القادم','tv',{},'upcoming'),('adventure','أنمي أكشن ومغامرات','tv',{'with_genres':'16,10759'},None)]:add('anime',key,title,kind,{'with_original_language':'ja','with_genres':'16',**params},window)
for key,title,params,window in [('top','أفضل عشرة مسلسلات تركية',{'sort_by':'vote_average.desc','vote_count.gte':'50'},None),('popular','التركي الرائج',{},None),('week','حلقات تركية هذا الأسبوع',{},'week'),('upcoming','التركي الأسبوع القادم',{},'upcoming'),('drama','دراما تركية',{'with_genres':'18'},None),('comedy','كوميديا تركية',{'with_genres':'35'},None)]:add('turkish',key,title,'tv',{'with_original_language':'tr',**params},window)
# Distinct TMDB filter policies, not a claimed list of hundreds of official genres.
for group,kind,label in [('movie','movie','أفلام'),('series','tv','مسلسلات')]:
 add(group,'daily','اختيارات اليوم',kind,{},None)
for group,language,label in [('anime','ja','أنمي'),('turkish','tr','تركية')]:
 for key,title,params,window in [
  ('daily','اختيارات اليوم',{},'year'),('year','الأعلى تقييمًا هذا العام',{'sort_by':'vote_average.desc','vote_count.gte':'30'},'year'),
  ('recent','أحدث الأعمال',{'sort_by':'first_air_date.desc'},'past'),('classic','كلاسيكيات',{'first_air_date.lte':'1999-12-31','sort_by':'vote_average.desc','vote_count.gte':'30'},None),
  ('mystery','غموض',{'with_genres':'9648'},None),('crime','جريمة',{'with_genres':'80'},None),('family','عائلي',{'with_genres':'10751'},None),
  ('fantasy','خيال علمي وفانتازيا',{'with_genres':'10765'},None),('history','حروب وسياسة',{'with_genres':'10768'},None),
  ('votes','الأكثر تصويتًا',{'sort_by':'vote_count.desc','vote_count.gte':'30'},None),('nineties','من التسعينيات',{'first_air_date.gte':'1990-01-01','first_air_date.lte':'1999-12-31'},None),
  ('millennium','من الألفينات',{'first_air_date.gte':'2000-01-01','first_air_date.lte':'2009-12-31'},None),
  ('last-decade','من العقد الماضي',{'first_air_date.gte':'2010-01-01','first_air_date.lte':'2019-12-31'},None),('modern','أعمال حديثة',{'first_air_date.gte':'2020-01-01'},None),
  ('rated','الأعلى تقييمًا بمشاركة الجمهور',{'sort_by':'vote_average.desc','vote_count.gte':'300'},None),
  ('latest-year','إصدارات هذا العام',{'sort_by':'first_air_date.desc'},'year'),
 ]:
  base={'with_original_language':language}
  if group=='anime':base['with_genres']='16'+(','+params['with_genres'] if params.get('with_genres') else '')
  add(group,key,title,'tv',{**base,**{k:v for k,v in params.items() if k!='with_genres' or group!='anime'}},window)
for key,title,kind,params,window in [
 ('top','أفضل عشرة أفلام','movie',{'sort_by':'vote_average.desc','vote_count.gte':'300'},None),
 ('daily','ما ينصح به اليوم','movie',{},None),('series-top','أفضل عشرة مسلسلات','tv',{'sort_by':'vote_average.desc','vote_count.gte':'100'},None),
 ('movie-popular','الأفلام الرائجة','movie',{'sort_by':'popularity.desc'},None),('series-popular','المسلسلات الرائجة','tv',{'sort_by':'popularity.desc'},None),
 ('movie-year','أفضل أفلام العام','movie',{'sort_by':'vote_average.desc','vote_count.gte':'50'},'year'),('series-year','أفضل مسلسلات العام','tv',{'sort_by':'vote_average.desc','vote_count.gte':'50'},'year'),
 ('movie-action','أفلام أكشن','movie',{'with_genres':'28'},None),('movie-comedy','أفلام كوميدية','movie',{'with_genres':'35'},None),('movie-drama','أفلام درامية','movie',{'with_genres':'18'},None),
 ('movie-mystery','غموض وتشويق','movie',{'with_genres':'9648'},None),('movie-family','أفلام عائلية','movie',{'with_genres':'10751'},None),
 ('series-arabic','مسلسلات عربية','tv',{'with_original_language':'ar'},None),('movie-arabic','أفلام عربية','movie',{'with_original_language':'ar'},None),
 ('turkish','التركي الرائج','tv',{'with_original_language':'tr'},None),('anime','عالم الأنمي','tv',{'with_original_language':'ja','with_genres':'16'},None),
 ('korean','دراما كورية','tv',{'with_original_language':'ko','with_genres':'18'},None),('indian','أفلام هندية','movie',{'with_original_language':'hi'},None),
 ('movie-classic','كلاسيكيات السينما','movie',{'primary_release_date.lte':'1999-12-31','vote_count.gte':'300','sort_by':'vote_average.desc'},None),
 ('documentary','أفلام وثائقية','movie',{'with_genres':'99'},None),
]:add('home',key,title,kind,params,window)
for row in rows:
 if row['id'] in ('catalog:collection:home-daily','catalog:collection:movie-daily','catalog:collection:series-daily'):
  row['path']='/trending/'+row['type']+'/day'
Path('shared/catalog-collections.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
# Source-controlled generated client definitions contain no service credentials.
Path('flutter_app/lib/src/catalog_collection_defs.dart').write_text('// Generated from shared/catalog-collections.json.\nconst najdCatalogCollections = <Map<String, String>>[\n'+''.join("  {'id': "+json.dumps(r['id'])+", 'group': "+json.dumps(r['group'])+", 'title': "+json.dumps(r['title'],ensure_ascii=False)+"},\n" for r in rows)+'];\n')
print(len(rows),'observed-data collection policies')
