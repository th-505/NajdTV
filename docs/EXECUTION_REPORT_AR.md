تقرير تنفيذ NajdTV — 12 نوفمبر 2026

المرجع المطلوب: 7317d9c86e85770cf4fff6f9da5b69fd3352f9c6.
أُنجزت الإصلاحات على فرع fix/najdtv-provider-hardening، مع الحفاظ على تغييرات main الأحدث عند 6ebb30ec36db12ef5fd427a00d2faa262d8e5047.

الحالة الفعلية

- إصلاح أكوام: حفظ 1216 و1217؛ المعرف /episode/91/ ليس رقم عرض؛ الغموض null؛ لا إعادة ترقيم بحسب المصفوفة؛ بدائل الحلقة لا تختفي بسبب تطابق الرقم.
- Laroza: حدود 60/200 تعلن partial وnext_offset/next_cursor، والمتابعة تمر من Node وGateway إلى المصدر نفسه؛ دفعات Harvest ذات 100 لم تتغير.
- عقد إضافي موحد مع إبقاء التوافق، وحالات queued/running/partial/unavailable ورموز أخطاء مستقلة عن الفراغ. JSON غير صالح وHTML غير معروف لا يتحولان إلى EMPTY_RESULT في المحولات القديمة التي عولجت.
- المحولات القديمة الأربعة تستخدم عميل HTTP المشترك؛ اختبارات DNS/SSRF والمهل والأحجام وجلسة المصدر مستمرة. لم تتوسع allowlists.
- راجعت تحويلات المصادر العشرة، ولم أعتمد نطاقًا من التحويل وحده.
- أصلحت فقدان سبب فشل Laroza بين Edge وNode. استعادة المحتوى الحي لم تثبت: المصدر يوجّه خارج origin المسموح عبر سلسلة غير مستقرة. لم أتجاوز الحماية ولم أستبدل المصدر.
- صُححت الاختبارات الستة وأُضيفت إلى npm run check بحارس يمنع الشبكة الحية.
- أُضيف source_commit إلى /health مع تحقق صارم وnull عند غياب الدليل، إضافة إلى مؤشرات Harvest آمنة. لم يُزعم أنه منشور في الإنتاج.

الاختبارات

الحزم الست المطلوبة شُغلت قبل التعديل وبعد كل مرحلة. النتائج المفصلة والأزمنة في verification-results.json.
قبل الإصلاح على المرجع الأصلي: الحزم الست ناجحة؛ مجموعة fixtures المنفصلة 12/18 ناجحة و6 فاشلة.
بعد المرحلة الخامسة: مجموعة fixtures المنفصلة 18/18 ناجحة، والحزم الست ناجحة.
التشغيل النهائي بعد دمج main الأحدث موثق في نتائج المرحلة السابعة، ولا يعادل شهادة بناء Flutter أو أجهزة فعلية أو تشغيل الفيديوهات الحية.

تنظيف الملفات

لم يُحذف أي ملف. تقرير REPOSITORY_INVENTORY.md وجرد repository-inventory.json يشملان الملفات البرمجية المطلوبة وملفات Markdown والتعليمات وأنماط backup والمطابقات الثنائية.
لم تثبت ملفات برمجية غير مرتبطة ضمن العائلات المطلوبة؛ لا يوجد ملف معتمد للحذف.
ملفات library_backup_* وlibrary_backup_test.dart تخص ميزة مستخدم فعلية، وليست مخلفات.
الوثائق IDENTITY_V1_0_13 وIDENTITY_V1_0_17 تتضمن هويتين تاريخيتين متعاقبتين؛ المقترح أرشفتهما وربطهما بالهوية الحالية، لا حذف التاريخ.
CONTENT_RUNTIME_1.0.1 يسجل انتقال Basri قديمًا؛ المقترح توضيح صفته التاريخية وربطه بالعقد الجديد.
matv-master-blueprint يذكر 21 scraper بينما الجرد يثبت 25 مدخلًا لكل عائلة؛ المقترح تحديث العدد والفهرس.
مهارات Hermes/graphify تفترض أدوات اختيارية مختلفة؛ المقترح تقييد نطاقها وتوحيد فهرس التوجيه، دون حذف غير مثبت.
تبقى SOURCE_POLICY_1.1.7 وإشعارات تراخيص الخطوط ومراجع الاختبارات والتوافق.

الإنتاج — مثبت وغير مثبت

- Render: خدمتا najdtv وmatv تعملان بالإصدار 4.0.2 وSHA 6ebb30e… حسب سجلات النشر المتصلة.
- Supabase: المشروع ACTIVE_HEALTHY؛ Harvest أعاد configured=true.
- مهمة najd-favorite-hourly معطلة: active=false. لم أفعّلها لأن المرحلة تطلب التحقق، ولم أغيّر إعدادات إنتاج.
- سجل migrations غير متطابق حرفيًا: 27 محليًا مقابل 28 مسجلة بالإنتاج، مع اختلاف أختام زمنية وأسماء. جداول Beta وصلاحيات منع anon موجودة فعلًا؛ فهرس najd_queue_discovery_order غير موجود. لم أطبق migrations عمياء.
- قيمة NAJD_HARVEST_ENABLED النصية لم تقرأ مباشرة من Render؛ تشغيل Harvest موثق من الاستجابة الفعلية، دون كشف أسرار.
- التفاصيل والموارد والأدلة في PRODUCTION_VERIFICATION.md وDOMAIN_REVIEW_2026-11-12.md.

ملفات التنفيذ وأسباب تعديلها

- `docs/DOMAIN_REVIEW_2026-11-12.md`: توثيق العقد أو الأدلة أو جرد التنظيف أو نتائج التحقق.
- `docs/EXECUTION_REPORT_AR.md`: توثيق العقد أو الأدلة أو جرد التنظيف أو نتائج التحقق.
- `docs/PRODUCTION_VERIFICATION.md`: توثيق العقد أو الأدلة أو جرد التنظيف أو نتائج التحقق.
- `docs/PROVIDER_CONTRACT.md`: توثيق العقد أو الأدلة أو جرد التنظيف أو نتائج التحقق.
- `docs/PROVIDER_FIXTURE_REVIEW.md`: توثيق العقد أو الأدلة أو جرد التنظيف أو نتائج التحقق.
- `docs/REPOSITORY_INVENTORY.md`: توثيق العقد أو الأدلة أو جرد التنظيف أو نتائج التحقق.
- `docs/repository-inventory.json`: توثيق العقد أو الأدلة أو جرد التنظيف أو نتائج التحقق.
- `docs/verification-results.json`: توثيق العقد أو الأدلة أو جرد التنظيف أو نتائج التحقق.
- `edge/src/laroza.mjs`: متابعة قوائم الكتالوج والحلقات، والعقد وتصنيف تحويل المصدر غير المعتمد.
- `edge/src/router.mjs`: التحقق من offset وتمريره وإدخاله في مفتاح الطلب والكاش.
- `package.json`: تشغيل الاختبارات الستة المصححة ضمن check.
- `scripts/provider-fixture-network-guard.mjs`: فشل الاختبارات عند أي محاولة شبكة حية غير مقصودة.
- `scripts/provider_fixture_suite.mjs`: تشغيل الاختبارات الستة المصححة في CI.
- `scripts/providers/3isk.fixture.test.mjs`: تصحيح توقع قديم مثبت دون إزالة فحوص الحماية أو تبديل المصدر.
- `scripts/providers/arabseed.fixture.test.mjs`: تصحيح توقع قديم مثبت دون إزالة فحوص الحماية أو تبديل المصدر.
- `scripts/providers/cimanow.fixture.test.mjs`: تصحيح توقع قديم مثبت دون إزالة فحوص الحماية أو تبديل المصدر.
- `scripts/providers/laroza.fixture.test.mjs`: تصحيح توقع قديم مثبت دون إزالة فحوص الحماية أو تبديل المصدر.
- `scripts/providers/mycima.fixture.test.mjs`: تصحيح توقع قديم مثبت دون إزالة فحوص الحماية أو تبديل المصدر.
- `scripts/providers/qfilm.fixture.test.mjs`: تصحيح توقع قديم مثبت دون إزالة فحوص الحماية أو تبديل المصدر.
- `scripts/repository_inventory.py`: جرد قابل لإعادة الإنتاج للاستيرادات والمراجع وCI والوثائق والتكرار، بلا حذف.
- `server/app.mjs`: تمرير offset وحالة المصدر والأخطاء الجزئية، وإضافة SHA إلى health.
- `server/catalog-metadata-cache.mjs`: حفظ حقول الجزئية والمتابعة أثناء تنقية metadata.
- `server/content-runtime-service.mjs`: حفظ إخفاقات المصادر والنتائج الجزئية في الكاش والاستجابات.
- `server/content-runtime.mjs`: حقول الحالة والجزئية في envelope العام.
- `server/index-runtime.mjs`: إضافة عقد المصدر إلى حدود JSON دون تغيير المسارات.
- `server/index.mjs`: إضافة عقد المصدر إلى حدود JSON دون تغيير المسارات.
- `server/providers/3isk.mjs`: العميل المحمي، عقد المصدر، والفصل بين HTML غير المعروف والنتيجة الفارغة.
- `server/providers/akoam.mjs`: حفظ هوية الحلقة ورقمها، وإزالة الترقيم الموضعي، والعميل المحمي.
- `server/providers/alooy.mjs`: العميل المحمي والتحقق البنيوي من JSON والعقد.
- `server/providers/laroza.mjs`: المتابعة والعميل المحمي ونقل السبب الحقيقي لفشل Gateway.
- `server/scrapers/configurable-provider.mjs`: تطبيق العقد على محولات Najd وBeta المسجلة.
- `server/scrapers/shared/errors.mjs`: رمز خطأ وحالة صريحة مع إبقاء رموز التوافق.
- `server/scrapers/shared/http.mjs`: واجهة محمية للمحولات القديمة مع حدود الرد والتحويل والهوية.
- `server/source-revision.mjs`: مصدر SHA موثوق مع تمييز العمل المحلي غير المحفوظ.
- `shared/provider-contract.js`: التطبيع الإضافي والهوية والحالات وتصنيف الأخطاء.
- `shared/provider-pagination.js`: متابعة رقمية مقيدة لنفس صفحة المصدر.
- `tests/laroza-source-review.test.mjs`: اختبارات انحدار للسلوك المطلوب وحدود HTTP والعقد والهوية والمتابعة.
- `tests/legacy-provider-http.test.mjs`: اختبارات انحدار للسلوك المطلوب وحدود HTTP والعقد والهوية والمتابعة.
- `tests/provider-contract.test.mjs`: اختبارات انحدار للسلوك المطلوب وحدود HTTP والعقد والهوية والمتابعة.
- `tests/provider-numbering-pagination.test.mjs`: اختبارات انحدار للسلوك المطلوب وحدود HTTP والعقد والهوية والمتابعة.
- `tests/source-revision.test.mjs`: اختبارات انحدار للسلوك المطلوب وحدود HTTP والعقد والهوية والمتابعة.

ملاحظة التكامل مع main الأحدث: اختبار Akwam المنفصل كان يفترض MP4 فقط، بينما العينة نفسها تتضمن HLS وإصلاح main يحفظه الآن. صُحح الاختبار ليثبت المسارات الستة الفعلية وصيغها وترتيب الجودات، وأُضيف كاختبار سابع إلى حزمة fixtures المحمية من الشبكة.
- `scripts/providers/akwam.fixture.test.mjs`: تثبيت جميع بدائل العينة الفعلية بعد دمج إصلاح main، دون إسقاط HLS أو تخفيف فحص المصدر.

فحوص إضافية في التسليم: مهلة مستقلة لـDNS قبل طلب HTTP، والحفاظ على رسائل HTTP القديمة المنقحة دون إعادة قيم query إلى سجلات الفشل، وتصنيف HTTP 500 كتعذر upstream بدل ادعاء انتهاء مهلة.

نتيجة القبول النهائية: الحزم الست ناجحة؛ 301 اختبار Node موحد ناجح، و18/18 ملف fixtures ناجح.

| المرحلة | check | continuation | unified | 3isk | phase2 | alooy |
|---|---|---|---|---|---|---|
|baseline|PASS|PASS|PASS|PASS|PASS|PASS|
|stage1|PASS|PASS|PASS|PASS|PASS|PASS|
|stage2|PASS|PASS|PASS|PASS|PASS|PASS|
|stage3|PASS|PASS|PASS|PASS|PASS|PASS|
|stage4|PASS|PASS|PASS|PASS|PASS|PASS|
|stage5|PASS|PASS|PASS|PASS|PASS|PASS|
|stage6|PASS|PASS|PASS|PASS|PASS|PASS|
|stage7|PASS|PASS|PASS|PASS|PASS|PASS|

لا توجد قائمة حذف معتمدة؛ أي حذف لاحق يحتاج إثباتًا وموافقة وCommit مستقل، وفق طلب المستخدم.

- `.github/workflows/content-runtime.yml`: تشغيل مجموعة fixtures المصححة صراحة في CI لكل Pull Request، إضافة إلى دمجها في npm run check.
