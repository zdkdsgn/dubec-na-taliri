/**
 * Vyhledávací proxy pro appku "Dubeč na talíři" (a její budoucí
 * víceškolní verzi).
 *
 * jidelna.cz nesídlí CORS hlavičky, takže appka v prohlížeči nemůže
 * volat jejich vyhledávání přímo. Tenhle worker to udělá za ni:
 * přeposlaný dotaz → server-side fetch na jidelna.cz → rozparsovaná
 * HTML tabulka výsledků → čistý JSON s CORS hlavičkami pro naši appku.
 *
 * GET /?q=<dotaz>
 *   → { ok: true, vysledky: [{id, nazev}], stav: "ok" | "prazdno" | "prilis_siroke" }
 *
 * Appka sama neví nic o jidelna.cz strukturách – ty zůstávají schované
 * tady, stejně jako v tools/jidelna_client.py (stejná logika, ale
 * appka ji nikdy nestáhne do prohlížeče).
 */

const JIDELNA_HLEDEJ = "https://www.jidelna.cz/vyhledej/jidelny/?q=";

// Kdo smí worker volat z prohlížeče. Appka běží na GitHub Pages;
// localhost je tu kvůli vývoji.
const POVOLENE_PUVODY = new Set([
  "https://zdkdsgn.github.io",
  "http://localhost:4173",
]);

const MIN_DELKA = 4; // stejné pravidlo jako má formulář na jidelna.cz

function corsHlavicky(origin) {
  const povoleno = POVOLENE_PUVODY.has(origin);
  return {
    "Access-Control-Allow-Origin": povoleno ? origin : "null",
    "Access-Control-Allow-Methods": "GET, OPTIONS",
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

export default {
  async fetch(request, env, ctx) {
    const origin = request.headers.get("Origin") || "";
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHlavicky(origin) });
    }
    if (request.method !== "GET") {
      return json({ ok: false, chyba: "jen GET" }, 405, origin);
    }

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
  },
};

function corsSetAll(headers, hlavicky) {
  for (const [k, v] of Object.entries(hlavicky)) headers.set(k, v);
}
