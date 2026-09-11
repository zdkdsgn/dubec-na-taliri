/**
 * Worker appky "Škola na talíři" – dvě samostatné věci pod jednou střechou:
 *
 * 1) Vyhledávací proxy (GET /?q=…) – beze změny, viz historie souboru.
 *
 * 2) Push notifikace ("nový jídelníček je venku"):
 *      POST /push/subscribe    {subscription, schoolId}   – appka: zapnout
 *      POST /push/unsubscribe  {endpoint, schoolId}        – appka: vypnout
 *      POST /push/notify       {schools:[{id,nazev}, …]}   – GitHub Action
 *        (jen s hlavičkou X-Notify-Secret, viz env.NOTIFY_SECRET)
 *
 *    Odběry se ukládají do KV pod klíčem "sub:<schoolId>:<hash endpointu>",
 *    ať appka umí při /notify rychle vyjmenovat všechny odběratele jedné
 *    školy (KV neumí dotaz "najdi podle hodnoty", jen podle klíče/prefixu).
 */

import webpush from "web-push";

const JIDELNA_HLEDEJ = "https://www.jidelna.cz/vyhledej/jidelny/?q=";

// Kdo smí worker volat z prohlížeče. Appka běží na GitHub Pages;
// localhost je tu kvůli vývoji.
const POVOLENE_PUVODY = new Set([
  "https://zdkdsgn.github.io",
  "http://localhost:4173",
  "http://localhost:8934",
]);

const MIN_DELKA = 4; // stejné pravidlo jako má formulář na jidelna.cz

function corsHlavicky(origin) {
  const povoleno = POVOLENE_PUVODY.has(origin);
  return {
    "Access-Control-Allow-Origin": povoleno ? origin : "null",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Vary": "Origin",
  };
}

function json(data, status, origin) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "public, max-age=300", // 5 min – ať appka i CDN šetří jidelna.cz
      ...corsHlavicky(origin),
    },
  });
}

function rozparsuj(html) {
  if (html.includes("Nalezeno příliš mnoho jídelen")) {
    return { vysledky: [], stav: "prilis_siroke" };
  }
  if (html.includes("Nenalezeno žádné zařízení")) {
    return { vysledky: [], stav: "prazdno" };
  }
  const vysledky = [];
  const re = /<a href="\/jidelni-listek\/\?jidelna=(\d+)">([^<]+)<\/a>/g;
  let m;
  while ((m = re.exec(html))) {
    vysledky.push({ id: m[1], nazev: dekoduj(m[2]).trim() });
  }
  return { vysledky, stav: vysledky.length ? "ok" : "prazdno" };
}

function dekoduj(text) {
  return text
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#0?39;/g, "'");
}

function corsSetAll(headers, hlavicky) {
  for (const [k, v] of Object.entries(hlavicky)) headers.set(k, v);
}

async function hledejSkolu(request, env, origin, ctx) {
  const url = new URL(request.url);
  const dotaz = (url.searchParams.get("q") || "").trim();
  if (dotaz.length < MIN_DELKA) {
    return json(
      { ok: false, chyba: `dotaz musí mít aspoň ${MIN_DELKA} znaky` },
      400,
      origin
    );
  }

  // Cloudflare Cache API – stejný dotaz z víc appek/zařízení sdílí
  // odpověď, jidelna.cz se ptáme jen jednou za cache okno.
  const cacheKey = new Request(url.toString(), request);
  const cache = caches.default;
  const zCache = await cache.match(cacheKey);
  if (zCache) {
    const odpoved = new Response(zCache.body, zCache);
    corsSetAll(odpoved.headers, corsHlavicky(origin));
    return odpoved;
  }

  let html;
  try {
    const r = await fetch(JIDELNA_HLEDEJ + encodeURIComponent(dotaz), {
      headers: { "User-Agent": "dubec-na-taliri-proxy/1.0" },
      cf: { cacheTtl: 300, cacheEverything: true },
    });
    html = await r.text();
  } catch (e) {
    return json({ ok: false, chyba: "jidelna.cz nedostupná" }, 502, origin);
  }

  const { vysledky, stav } = rozparsuj(html);
  const odpoved = json({ ok: true, vysledky, stav }, 200, origin);
  ctx.waitUntil(cache.put(cacheKey, odpoved.clone()));
  return odpoved;
}

// ── Push notifikace ──────────────────────────────────────────────────

async function sha256hex(text) {
  const data = new TextEncoder().encode(text);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return [...new Uint8Array(digest)].map(b => b.toString(16).padStart(2, "0")).join("");
}

async function podepsatSubscribe(request, env, origin) {
  let body;
  try { body = await request.json(); } catch { return json({ ok: false, chyba: "špatný JSON" }, 400, origin); }
  const { subscription, schoolId } = body || {};
  if (!subscription?.endpoint || !subscription?.keys?.p256dh || !subscription?.keys?.auth || !schoolId) {
    return json({ ok: false, chyba: "chybí subscription nebo schoolId" }, 400, origin);
  }
  const klic = `sub:${schoolId}:${await sha256hex(subscription.endpoint)}`;
  await env.PUSH_SUBS.put(klic, JSON.stringify(subscription));
  return json({ ok: true }, 200, origin);
}

async function podepsatUnsubscribe(request, env, origin) {
  let body;
  try { body = await request.json(); } catch { return json({ ok: false, chyba: "špatný JSON" }, 400, origin); }
  const { endpoint, schoolId } = body || {};
  if (!endpoint || !schoolId) return json({ ok: false, chyba: "chybí endpoint nebo schoolId" }, 400, origin);
  const klic = `sub:${schoolId}:${await sha256hex(endpoint)}`;
  await env.PUSH_SUBS.delete(klic);
  return json({ ok: true }, 200, origin);
}

async function poslatNotifikace(request, env, origin) {
  const tajemstvi = request.headers.get("X-Notify-Secret") || "";
  if (!env.NOTIFY_SECRET || tajemstvi !== env.NOTIFY_SECRET) {
    return json({ ok: false, chyba: "neautorizováno" }, 401, origin);
  }
  let body;
  try { body = await request.json(); } catch { return json({ ok: false, chyba: "špatný JSON" }, 400, origin); }
  const schools = Array.isArray(body?.schools) ? body.schools : [];
  if (!schools.length) return json({ ok: true, posláno: 0, smazáno: 0 }, 200, origin);

  webpush.setVapidDetails("mailto:zdeko.design@gmail.com", env.VAPID_PUBLIC_KEY, env.VAPID_PRIVATE_KEY);

  let posláno = 0, smazáno = 0;
  for (const { id, nazev } of schools) {
    const prefix = `sub:${id}:`;
    let cursor, seznam;
    do {
      seznam = await env.PUSH_SUBS.list({ prefix, cursor });
      cursor = seznam.cursor;
      for (const { name } of seznam.keys) {
        const syrove = await env.PUSH_SUBS.get(name);
        if (!syrove) continue;
        const subscription = JSON.parse(syrove);
        const payload = JSON.stringify({
          title: "Škola na talíři",
          body: `Nový jídelníček pro ${nazev} je venku.`,
          schoolId: id,
        });
        try {
          await webpush.sendNotification(subscription, payload);
          posláno++;
        } catch (e) {
          if (e.statusCode === 404 || e.statusCode === 410) {
            await env.PUSH_SUBS.delete(name);
            smazáno++;
          }
          // ostatní chyby (dočasný výpadek push serveru) necháme být,
          // odběr zůstává, zkusí se to znovu při dalším /notify
        }
      }
    } while (!seznam.list_complete);
  }
  return json({ ok: true, posláno, smazáno }, 200, origin);
}

export default {
  async fetch(request, env, ctx) {
    const origin = request.headers.get("Origin") || "";
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHlavicky(origin) });
    }

    if (url.pathname === "/push/subscribe" && request.method === "POST")
      return podepsatSubscribe(request, env, origin);
    if (url.pathname === "/push/unsubscribe" && request.method === "POST")
      return podepsatUnsubscribe(request, env, origin);
    if (url.pathname === "/push/notify" && request.method === "POST")
      return poslatNotifikace(request, env, origin);

    if (request.method !== "GET") {
      return json({ ok: false, chyba: "jen GET" }, 405, origin);
    }
    return hledejSkolu(request, env, origin, ctx);
  },
};
