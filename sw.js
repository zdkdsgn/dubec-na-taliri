/* Network-first pro vlastní soubory: online rodič vidí vždy čerstvý
   jídelníček, offline se servíruje poslední uložená verze. */
const CACHE = "dubec-na-taliri-v3";
const ASSETS = [
  "./", "./index.html", "./styles.css", "./app.js", "./data.js",
  "./manifest.webmanifest", "./assets/icon.png",
  "./assets/icon-180.png", "./assets/icon-192.png", "./assets/icon-512.png"
];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(caches.keys()
    .then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

/* ── Push notifikace ("nový jídelníček je venku") ──────────────────
   Payload posílá worker jako JSON {title, body, schoolId} – viz
   cloudflare/skoly-proxy/src/worker.js. Klik na notifikaci appku buď
   přivede do popředí (už otevřenou kartu), nebo otevře novou. */
self.addEventListener("push", e => {
  let data = { title: "Škola na talíři", body: "Nový jídelníček je venku." };
  try { if (e.data) data = { ...data, ...e.data.json() }; } catch {}
  e.waitUntil(self.registration.showNotification(data.title, {
    body: data.body,
    icon: "./assets/icon-192.png",
    badge: "./assets/icon-192.png",
    /* Tag podle školy (ne napevno) – jinak by si notifikace pro různé
       školy tiše přepisovaly jedna druhou. renotify ať i tak vždy
       upozorní, kdyby náhodou stejná škola dostala dvě zprávy rychle
       po sobě (dřív tohle chybělo, takže druhá appka jen tiše
       nahradila první beze zvuku/vibrace). */
    tag: data.schoolId ? `skola-${data.schoolId}` : "novy-jidelnicek",
    renotify: true,
    data: { schoolId: data.schoolId },
  }));
});

self.addEventListener("notificationclick", e => {
  e.notification.close();
  const schoolId = e.notification.data?.schoolId;
  e.waitUntil((async () => {
    const clientList = await self.clients.matchAll({ type: "window", includeUncontrolled: true });
    for (const c of clientList) {
      if ("focus" in c) {
        await c.focus();
        // appka už běží – řekneme jí přes postMessage, na kterou školu
        // přepnout, ať to nemusí řešit přes URL parametr při startu.
        if (schoolId) c.postMessage({ type: "otevrit-skolu", schoolId });
        return;
      }
    }
    if (self.clients.openWindow) {
      return self.clients.openWindow(schoolId ? `./?push=${encodeURIComponent(schoolId)}` : "./");
    }
  })());
});

self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET" || new URL(req.url).origin !== location.origin) return;

  e.respondWith(
    /* cache:"no-store" je tu klíčové – bez něj prohlížeč klidně vrátí
       vlastní HTTP cache (GitHub Pages posílá Cache-Control: max-age=600)
       a "network-first" fetch se ve skutečnosti sítě vůbec nezeptá. */
    fetch(req, { cache: "no-store" })
      .then(res => {
        if (res.ok) { const copy = res.clone(); caches.open(CACHE).then(c => c.put(req, copy)); }
        return res;
      })
      .catch(() => caches.match(req).then(hit => hit || caches.match("./index.html")))
  );
});
