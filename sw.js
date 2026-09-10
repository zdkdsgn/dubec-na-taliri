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
