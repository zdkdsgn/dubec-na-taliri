/* Network-first pro vlastní soubory: online rodič vidí vždy čerstvý
   jídelníček, offline se servíruje poslední uložená verze. */
const CACHE = "dubec-na-taliri-v2";
const ASSETS = [
  "./", "./index.html", "./styles.css", "./app.js", "./data.js",
  "./manifest.webmanifest", "./assets/icon.svg",
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

self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET" || new URL(req.url).origin !== location.origin) return;

  e.respondWith(
    fetch(req)
      .then(res => {
        if (res.ok) { const copy = res.clone(); caches.open(CACHE).then(c => c.put(req, copy)); }
        return res;
      })
      .catch(() => caches.match(req).then(hit => hit || caches.match("./index.html")))
  );
});
