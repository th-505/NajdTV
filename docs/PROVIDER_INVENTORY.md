# جرد قواشط نجد TV والبيتا من الشفرة

هذا تقرير آلي ساكن؛ لا يرسل أي طلب للمزودين ولا يثبت نجاح التشغيل.

- قواشط نجد: **30**؛ قواشط البيتا: **31**؛ مجموع وحدات التنفيذ المنفصلة: **61**.
- المعروضة افتراضيًا: **27**؛ وحدات التوافق القديمة المخفية: **3**. لا يتم تحويل المراجع القديمة إلى مصدر آخر تلقائيًا.
- وحدات مواقع ذات تعريف PROVIDER_META: **30**؛ المسجل منها: **30**.
- مرآتان مصرح بهما في التعريف: **2**؛ الوحدات غير الموسومة كمرآة: **28**. هذا لا يثبت استقلال مالكي المواقع.
- مصادر الواجهة المستنتجة من الشفرة: **0**؛ وحدات البحث المثبت المربوطة برمجيًا: **28**.
- مصدر قائمة الواجهة مصفوفة ثابتة في index.html.
- بذور فحص بلا وحدة مسجلة: **6**؛ ليست مزودين عاملين.

القدرات أدناه تجمع تصريح metadata ووجود الدالة المصدرة. لا تعني اختبار HTML أو شبكة أو تشغيل فيديو.

| المعرف | مرآة لـ | القدرات المعلنة ولها دالة | الواجهة | البحث المثبت | الملف والدليل |
|---|---|---|---|---|---|
| `3cktv` | — | catalog, search, details, episodes, servers, resolve | — | 3cktv | `server/scrapers/sites/3cktv.mjs:37` |
| `3isk` | — | catalog, search, details, episodes, servers, resolve | — | 3isk | `server/scrapers/sites/3isk.mjs:56` |
| `ahwak` | — | catalog, search, details, episodes, servers, resolve | — | ahwak | `server/scrapers/sites/ahwak.mjs:12` |
| `akwam` | — | catalog, search, details, episodes, servers, resolve | — | akwam, akoam | `server/scrapers/sites/akwam.mjs:34` |
| `alooy` | — | catalog, search, details, episodes, servers, resolve | — | alooy | `server/scrapers/sites/alooy.mjs:53` |
| `anime4up` | — | catalog, search, details, episodes, servers, resolve | — | anime4up | `server/scrapers/sites/anime4up.mjs:50` |
| `anime4up_rest` | anime4up | catalog, search, details, episodes, servers, resolve | — | anime4up_rest | `server/scrapers/sites/anime4up_rest.mjs:21` |
| `animezid` | — | catalog, search, details, episodes, servers, resolve | — | animezid | `server/scrapers/sites/animezid.mjs:3` |
| `arabseed` | — | catalog, search, details, episodes, servers, resolve | — | arabseed | `server/scrapers/sites/arabseed.mjs:34` |
| `atv-tr` | — | catalog, search, details, episodes, servers, resolve | — | atv-tr | `server/scrapers/sites/atv-tr.mjs:10` |
| `brstej` | — | catalog, search, details, episodes, servers, resolve | — | brstej | `server/scrapers/sites/brstej.mjs:13` |
| `cimanow` | — | catalog, search, details, episodes, servers, resolve | — | cimanow | `server/scrapers/sites/cimanow.mjs:32` |
| `egybest` | — | catalog, search, details, episodes, servers, resolve | — | egybest | `server/scrapers/sites/egybest.mjs:3` |
| `egydead` | — | catalog, search, details, episodes, servers, resolve, live | — | egydead | `server/scrapers/sites/egydead.mjs:50` |
| `egydead_live` | — | catalog, details, servers, resolve, live | — | — | `server/scrapers/sites/egydead_live.mjs:37` |
| `fivetv` | — | catalog, search, details, episodes, servers, resolve | — | fivetv | `server/scrapers/sites/fivetv.mjs:18` |
| `fosta` | — | catalog, search, details, episodes, servers, resolve | — | fosta | `server/scrapers/sites/fosta.mjs:15` |
| `ipauniverse` | — | catalog, search, details, servers, resolve | — | ipauniverse | `server/scrapers/sites/ipauniverse.mjs:54` |
| `kanal-d` | — | catalog, search, details, episodes, servers, resolve | — | kanal-d | `server/scrapers/sites/kanal-d.mjs:10` |
| `laroza` | — | catalog, search, details, episodes, servers, resolve | — | laroza | `server/scrapers/sites/laroza.mjs:60` |
| `mewsry` | — | catalog, search, details, servers, resolve, live | — | mewsry | `server/scrapers/sites/mewsry.mjs:51` |
| `movizland` | — | catalog, search, details, episodes, servers, resolve | — | movizland | `server/scrapers/sites/movizland.mjs:3` |
| `moviztime` | — | catalog, search, details, episodes, servers, resolve | — | moviztime | `server/scrapers/sites/moviztime.mjs:32` |
| `mycima` | — | catalog, search, details, episodes, servers, resolve | — | mycima, wecima | `server/scrapers/sites/mycima.mjs:49` |
| `qfilm` | — | catalog, search, details, episodes, servers, resolve | — | qfilm | `server/scrapers/sites/qfilm.mjs:38` |
| `ristoanime` | — | catalog, search, details, episodes, servers, resolve | — | ristoanime | `server/scrapers/sites/ristoanime.mjs:24` |
| `shahid4u` | — | catalog, search, details, episodes, servers, resolve | — | shahid4u | `server/scrapers/sites/shahid4u.mjs:49` |
| `shii4u` | shahid4u | catalog, search, details, episodes, servers, resolve | — | shii4u | `server/scrapers/sites/shii4u.mjs:23` |
| `witanime` | — | catalog, search, details, episodes, servers, resolve | — | witanime | `server/scrapers/sites/witanime.mjs:52` |
| `yallashoot` | — | catalog, details, servers, resolve, live | — | — | `server/scrapers/sites/yallashoot.mjs:30` |

## سجل البيتا المستقل

هذه ملفات تنفيذ مستقلة وليست إعادة تصدير لقواشط نجد. تشترك في أدوات الأمان والنقل العامة فقط، وتظل المراجع المثبتة متوافقة.

| المعرف | مرآة ضمن البيتا لـ | ملف التنفيذ |
|---|---|---|
| `3cktv` | — | `server/browser/providers/sites/3cktv.mjs` |
| `3isk` | — | `server/browser/providers/sites/3isk.mjs` |
| `ahwak` | — | `server/browser/providers/sites/ahwak.mjs` |
| `akwam` | — | `server/browser/providers/sites/akwam.mjs` |
| `alooy` | — | `server/browser/providers/sites/alooy.mjs` |
| `anime4up` | — | `server/browser/providers/sites/anime4up.mjs` |
| `anime4up_rest` | anime4up | `server/browser/providers/sites/anime4up_rest.mjs` |
| `animezid` | — | `server/browser/providers/sites/animezid.mjs` |
| `arabseed` | — | `server/browser/providers/sites/arabseed.mjs` |
| `atv-tr` | — | `server/browser/providers/sites/atv-tr.mjs` |
| `brstej` | — | `server/browser/providers/sites/brstej.mjs` |
| `cimanow` | — | `server/browser/providers/sites/cimanow.mjs` |
| `egybest` | — | `server/browser/providers/sites/egybest.mjs` |
| `egydead` | — | `server/browser/providers/sites/egydead.mjs` |
| `egydead_live` | — | `server/browser/providers/sites/egydead_live.mjs` |
| `fivetv` | — | `server/browser/providers/sites/fivetv.mjs` |
| `fosta` | — | `server/browser/providers/sites/fosta.mjs` |
| `ipauniverse` | — | `server/browser/providers/sites/ipauniverse.mjs` |
| `kanal-d` | — | `server/browser/providers/sites/kanal-d.mjs` |
| `laroza` | — | `server/browser/providers/sites/laroza.mjs` |
| `mewsry` | — | `server/browser/providers/sites/mewsry.mjs` |
| `movizland` | — | `server/browser/providers/sites/movizland.mjs` |
| `moviztime` | — | `server/browser/providers/sites/moviztime.mjs` |
| `mycima` | — | `server/browser/providers/sites/mycima.mjs` |
| `qfilm` | — | `server/browser/providers/sites/qfilm.mjs` |
| `ristoanime` | — | `server/browser/providers/sites/ristoanime.mjs` |
| `shahid4u` | — | `server/browser/providers/sites/shahid4u.mjs` |
| `shii4u` | shahid4u | `server/browser/providers/sites/shii4u.mjs` |
| `shoof-live` | — | `server/browser/providers/sites/shoof-live.mjs` |
| `witanime` | — | `server/browser/providers/sites/witanime.mjs` |
| `yallashoot` | — | `server/browser/providers/sites/yallashoot.mjs` |

المجموع يحصي وحدات القشط في المسارين؛ لا يعني خمسين موقعًا مختلفًا. تعديل قارئ مصدر في مسار لا يعدل الملف المقابل في المسار الآخر.

## الأسماء البديلة والطبقات

- `akoam` في الواجهة وطبقة server/providers يقابل `akwam` في وحدات القشط.
- `wecima` اسم واجهة للمصدر `mycima`؛ ليس ملف موقع مستقلًا.
- `shii4u` مرآة معلنة لـ `shahid4u` و`anime4up_rest` مرآة معلنة لـ `anime4up`.
- طبقة server/providers: `server/providers/3isk.mjs`، `server/providers/akoam.mjs`، `server/providers/alooy.mjs`، `server/providers/laroza.mjs`.
- واجهات التنسيق (ليست مزودين جددًا): `server/scrapers/supervisor1-mycima.mjs`، `server/scrapers/supervisor2-shahid-moviz.mjs`، `server/scrapers/supervisor3-egydead-ipa.mjs`، `server/scrapers/supervisor4-anime4up.mjs`، `server/scrapers/supervisor5-arabseed.mjs`، `server/scrapers/supervisor6-witanime-live.mjs`.
- ملفات استخراج المشغل المساعدة (لا تعد مواقع مستقلة): `server/providers/3isk-playback/contract.mjs`، `server/providers/3isk-playback/miravd.mjs`، `server/providers/3isk-playback/router.mjs`، `server/providers/3isk-playback/ukrcdn.mjs`.
- واجهات التوافق: `server/basri-source.mjs`، `server/match-production.mjs`.
- ملفات Edge: `edge/config/3isk.jsonc`، `edge/config/akoam.jsonc`، `edge/config/alooy.jsonc`، `edge/config/laroza.jsonc`، `edge/config/matches.jsonc`، `edge/config/providers.json`.
- وحدات التجميع التي لا تعد مواقع جديدة: `server/scrapers/sites/ahwak-categories.mjs`، `server/scrapers/sites/brstej-categories.mjs`، `server/scrapers/sites/fosta-categories.mjs`، `server/scrapers/sites/specialized-portals.mjs`.

## بذور بلا وحدة مسجلة

`faselhd`، `cima4u`، `fushaar`، `cinemana`، `tukif`، `kooralive`

## تعارض الرموز

- `AP` مشترك بين anime4up, anime4up_rest؛ لا يصلح الرمز وحده معرفًا فريدًا.

## إعادة الإنتاج وحدود الإغلاق

`python3 scripts/provider_inventory.py` يولد التقرير وJSON، و`--check` يكشف تقادم النتائج.

هذا جرد حالي لتوصيلات الشفرة، وليس إثباتًا لعمل المواقع الحية. راجع الاختبارات وحالة المصدر لتقييم توفره.
