import assert from "node:assert/strict";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { chromium } from "playwright-core";
const dir = path.resolve("flutter_app/build/web");
const format = process.argv[2] === "hls" ? "hls" : "mp4";
const liveMode = process.env.NAJD_TEST_LIVE === '1';
const liveRows = ['a','b'].map((id,index) => ({id:id.repeat(24),ref:`live:iptv-org:sa:${id.repeat(24)}`,title:`قناة الاختبار ${index+1}`,poster:'',type:'live'}));
const mime = {
  ".js": "application/javascript",
  ".wasm": "application/wasm",
  ".html": "text/html",
  ".json": "application/json",
  ".png": "image/png",
  ".m3u8": "application/vnd.apple.mpegurl",
  ".ts": "video/mp2t",
  ".mp4": "video/mp4",
};
const server = http.createServer((req, res) => {
  const file = path.join(
    dir,
    new URL(req.url, "http://local").pathname.replace(/^\/internal\//, ""),
  );
  if (
    !file.startsWith(dir + "/") ||
    !fs.existsSync(file) ||
    !fs.statSync(file).isFile()
  ) {
    res.writeHead(404);
    res.end();
    return;
  }
  res.setHeader(
    "Content-Type",
    mime[path.extname(file)] || "application/octet-stream",
  );
  fs.createReadStream(file).pipe(res);
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const browser = await chromium.launch({
  headless: true,
  executablePath: process.env.CHROMIUM_BIN || "/usr/bin/chromium",
  args: ["--no-sandbox", "--autoplay-policy=no-user-gesture-required"],
});
const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, serviceWorkers: "block" });
const errors = [];
page.on("pageerror", (e) => errors.push(e.stack || e.message));
const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, HEAD, POST, OPTIONS",
  "access-control-allow-headers": "*",
};
// Auth and library requests are fixtures too: never create real users from CI.
const fixtureUser = {id:'00000000-0000-4000-8000-000000000121',aud:'authenticated',role:'authenticated',is_anonymous:true,created_at:new Date().toISOString(),app_metadata:{provider:'anonymous',providers:['anonymous']},user_metadata:{}};
const jwt = [Buffer.from(JSON.stringify({alg:'HS256',typ:'JWT'})).toString('base64url'),Buffer.from(JSON.stringify({sub:fixtureUser.id,role:'authenticated',is_anonymous:true,exp:Math.floor(Date.now()/1000)+3600})).toString('base64url'),'fixture-signature'].join('.');
await page.route('https://roqccichwszxamdpvhli.supabase.co/**',async route=>{
  if(route.request().method()==='OPTIONS') return route.fulfill({status:204,headers:corsHeaders});
  const u=new URL(route.request().url());
  const body=u.pathname.startsWith('/auth/')?{access_token:jwt,refresh_token:'fixture-refresh',expires_in:3600,expires_at:Math.floor(Date.now()/1000)+3600,token_type:'bearer',user:fixtureUser}:[];
  return route.fulfill({status:200,headers:{...corsHeaders,'content-type':'application/json'},body:JSON.stringify(body)});
});
await page.route("https://najdtv.onrender.com/**", async (route) => {
  if (route.request().method() === "OPTIONS") {
    await route.fulfill({ status: 204, headers: corsHeaders });
    return;
  }
  const u = new URL(route.request().url());
  if (u.pathname.endsWith(".ts")) {
    await route.fulfill({
      status: 200,
      headers: { ...corsHeaders, "content-type": "video/mp2t" },
      body: fs.readFileSync(
        "/tmp/matv-codec-fixtures/" + path.basename(u.pathname),
      ),
    });
    return;
  }
  if (u.pathname.includes("/media")) {
    const file =
      u.searchParams.get("format") === "m3u8" ? "master.m3u8" : "sample.mp4";
    await route.fulfill({
      status: 200,
      headers: {
        ...corsHeaders,
        "content-type": mime[path.extname(file)] || "application/octet-stream",
      },
      body: fs.readFileSync("/tmp/matv-codec-fixtures/" + file),
    });
    return;
  }
  let data = { status: "success", data: [] };
  if (u.pathname === '/api/v1/live/catalog') {
    return route.fulfill({status:200,headers:{...corsHeaders,'content-type':'application/json'},body:JSON.stringify({status:'success',data:liveRows,pagination:{has_more:false}})});
  }
  if (u.pathname === '/api/v1/live/playback') {
    const url='https://media.fixture.example/sample.mp4', expiry=new Date(Date.now()+120000).toISOString();
    return route.fulfill({status:200,headers:{...corsHeaders,'content-type':'application/json'},body:JSON.stringify({status:'success',data:{media_path:url,media_type:'video/mp4',playback_mode:'direct',expires_at:expiry,media_sources:[{url,media_type:'video/mp4',playback_mode:'direct',expires_at:expiry,headers:{}}]}})});
  }

  if (u.pathname === "/api/cinema/details")
    data = {
      status: "success",
      movie_title: "Web playback fixture",
      poster: "",
      playback_unavailable: true,
      playback_reason: "EDGE_DIRECT_RESOLUTION_REQUIRED",
      download_available: false,
    };
  await route.fulfill({
    status: 200,
    headers: { ...corsHeaders, "content-type": "application/json" },
    body: JSON.stringify(data),
  });
});
await page.route(
  "https://matv-edge-resolver.dada1000100.workers.dev/**",
  async (route) => {
    if (route.request().method() === "OPTIONS") {
      await route.fulfill({ status: 204, headers: corsHeaders });
      return;
    }
    await route.fulfill({
      status: 200,
      headers: {
        ...corsHeaders,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        status: "success",
        schema_version: 1,
        episode_id: "web-fixture",
        sources: [
          {
            provider_id: "alooy",
            provider: "Fixture",
            format,
            quality: "test",
            url: `https://media.fixture.example/${format === "hls" ? "master.m3u8" : "sample.mp4"}`,
            playback_mode: "edge_direct",
            web_playable: true,
            expires_at: new Date(Date.now() + 120000).toISOString(),
            headers: {},
          },
        ],
      }),
    });
  },
);
await page.route("https://media.fixture.example/**", async (route) => {
  if (route.request().method() === "OPTIONS") {
    await route.fulfill({ status: 204, headers: corsHeaders });
    return;
  }
  const u = new URL(route.request().url());
  const name = path.basename(u.pathname);
  await route.fulfill({
    status: 200,
    headers: {
      ...corsHeaders,
      "content-type": mime[path.extname(name)] || "application/octet-stream",
    },
    body: fs.readFileSync("/tmp/matv-codec-fixtures/" + name),
  });
});
try {
  await page.goto(
    liveMode ? `http://127.0.0.1:${server.address().port}/internal/index.html#/player?ref=${encodeURIComponent(liveRows[0].ref)}&source=${encodeURIComponent(liveRows[0].ref)}&type=live`
      : `http://127.0.0.1:${server.address().port}/internal/index.html?ref=alooy:fixture`,
  );
  await page.locator("flutter-view").waitFor({ timeout: 60000 });
  const placeholder = page.locator("flt-semantics-placeholder");
  await placeholder.waitFor();
  await placeholder.evaluate((el) => el.click());
  if (!liveMode) {
    const watch = page.getByText("مشاهدة", { exact: true });
    await watch.waitFor({timeout: 20000});
    await watch.click({timeout: 10000});
  }
  await page.waitForFunction(
    () =>
      [...document.querySelectorAll("video")].some(
        (v) => v.videoWidth > 0 && v.currentTime > 0.2,
      ),
    null,
    { timeout: 25000 },
  );
  if (liveMode) {
    await page.getByText('القنوات والتصنيفات',{exact:true}).evaluate(el=>el.click());
    await page.getByText(liveRows[0].title,{exact:true}).last().evaluate(el=>el.click());
    await page.waitForFunction(()=>[...document.querySelectorAll('video')].some(v=>!v.paused && v.videoWidth>0 && v.currentTime>.2));
    await page.getByRole('button',{name:'القناة التالية',exact:true}).evaluate(el=>el.click());
    await page.waitForFunction(expected => new URL(location.hash.slice(1), location.origin).searchParams.get('ref') === expected, liveRows[1].ref);
    assert(new URL(page.url()).hash.includes('type=live'));
    await page.waitForFunction(()=>[...document.querySelectorAll('video')].some(v=>!v.paused && v.videoWidth>0 && v.currentTime>.2));
    assert(!await page.getByRole('button',{name:'تقديم 10 ثانية',exact:true}).count());
  }
  if (process.env.NAJD_TEST_PIP === '1') {
    await page.locator('video').evaluate(v => { v.loop = true; });
    await page.waitForTimeout(1500);
    // Reveal hidden controls through the video surface; do not toggle visible ones off.
    const more = page.getByRole('button', {name: 'المزيد', exact: true});
    if (await more.count() === 0) await page.mouse.click(640, 160);
    await more.evaluate(el => el.click());
    await page.getByText('صورة داخل صورة', {exact: true}).evaluate(el => el.click());
    await page.waitForFunction(() => document.pictureInPictureElement != null, null, {timeout: 10000});
    await page.evaluate(() => document.exitPictureInPicture());
    await page.waitForFunction(() => document.pictureInPictureElement == null);
  }
  if (process.env.NAJD_TEST_DOWNLOAD === '1' && format === 'mp4' && !liveMode) {
    await page.evaluate(() => {
      window.__najdDownloadFixture = null;
      const original = HTMLAnchorElement.prototype.click;
      HTMLAnchorElement.prototype.click = function() {
        if (this.hostname === 'media.fixture.example') {
          window.__najdDownloadFixture = {path:this.pathname, name:this.download, rel:this.rel};
          return;
        }
        return original.call(this);
      };
    });
    const more = page.getByRole('button', {name:'المزيد',exact:true});
    if (await more.count() === 0) await page.mouse.click(640,160);
    await more.evaluate(el => el.click());
    await page.getByText('تحميل الفيديو',{exact:true}).evaluate(el => el.click());
    await page.waitForFunction(() => window.__najdDownloadFixture != null);
    const handoff = await page.evaluate(() => window.__najdDownloadFixture);
    assert.equal(handoff.path, '/sample.mp4');
    assert(handoff.name.endsWith('.mp4'));
    assert(handoff.rel.includes('noopener'));
    assert(!await page.getByText('اكتمل تنزيل MP4. الملف متاح في مكتبتك.',{exact:true}).count());
  }
  const video = await page.locator("video").evaluateAll(videos => {
    const v=videos.find(v=>!v.paused && v.videoWidth>0) || videos.find(v=>v.videoWidth>0);
    return {width:v?.videoWidth||0,height:v?.videoHeight||0,time:v?.currentTime||0};
  });
  assert(video.width > 0);
  assert.equal(errors.length, 0, errors.join("\n"));
  await page.screenshot({
    path: path.join(
      process.env.MATV_WEB_SCREENSHOT_DIR || os.tmpdir(),
      `matv-web-${format}.png`,
    ),
  });
  console.log(
    JSON.stringify({
      browser: "Chromium",
      format,
      app_booted: true,
    live_channel_switch: liveMode,
    browser_download_handoff: process.env.NAJD_TEST_DOWNLOAD === '1' && !liveMode,
      video_decoded: true,
      system_pip_entered_and_exited: process.env.NAJD_TEST_PIP === '1',
      ...video,
      exceptions: errors.length,
      fixture: true,
      physical_device_tested: false,
    }),
  );
} catch (error) {
  if (liveMode) console.log(JSON.stringify({fixture_hash:new URL(page.url()).hash}));
  await page.screenshot({
    path: path.join(
      process.env.MATV_WEB_SCREENSHOT_DIR || os.tmpdir(),
      "matv-web-error.png",
    ),
  });
  console.log((await page.locator("body").innerText()).slice(0, 1500));
  console.log(errors);
  throw error;
} finally {
  await browser.close();
  server.closeAllConnections();
  await new Promise((r) => server.close(r));
}
