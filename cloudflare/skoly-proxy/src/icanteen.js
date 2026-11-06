/**
 * Čtení veřejného jídelníčku iCanteen (strav.nasejidelna.cz/<číslo>/faces/login.jsp).
 * Port tools/icanteen_client.py – tvar výstupu je stejný jako schools/<id>/days.json.
 */

const ENTITY = { "&nbsp;": " ", "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": '"', "&#39;": "'", "&#039;": "'" };

const text = (html) =>
  html.replace(/<[^>]+>/g, " ")
    .replace(/&(?:nbsp|amp|lt|gt|quot|#0?39);/g, (e) => ENTITY[e])
    .replace(/\s+/g, " ").trim();

const alergeny = (html) => {
  const sub = html.match(/<sub>[\s\S]*?<\/sub>/);
  if (!sub) return [];
  const out = new Set();
  for (const m of sub[0].matchAll(/>\s*(\d{1,2})[a-z]?\s*<\/span>/g)) out.add(Number(m[1]));
  return [...out].sort((a, b) => a - b);
};

const kodChodu = (popisek) => {
  const p = popisek.toLowerCase();
  if (p.startsWith("polév")) return "polevka";
  if (p.startsWith("oběd")) return "obed";
  if (p.startsWith("přesníd")) return "presnidavka";
  if (p.startsWith("svačin") || p.startsWith("odpolední")) return "svacina";
  return null;
};

export function parsujIcanteen(html) {
  const dny = {};
  const dnyRe = /<div id="day-(\d{4}-\d{2}-\d{2})"[^>]*>([\s\S]*?)(?=<div id="day-|$)/g;
  for (const [, iso, blok] of html.matchAll(dnyRe)) {
    const chody = [];
    const videno = new Set();
    let prvniMisto = null;

    for (const [, radek] of blok.matchAll(/<div class="container">([\s\S]*?)(?=<div class="container">|<\/article>|$)/g)) {
      const sloupce = [...radek.matchAll(/<div class="(?:shrinkedColumn|column)[^"]*">([\s\S]*?)<\/div>/g)].map((m) => m[1]);
      if (sloupce.length < 2) continue;
      const kod = kodChodu(text(sloupce[0]));
      if (!kod) continue;

      if (sloupce.length > 2) {                       // víc výdejen: bereme první
        const misto = text(sloupce[1]);
        prvniMisto ??= misto;
        if (misto !== prvniMisto) continue;
      }
      const telo = sloupce[sloupce.length - 1];
      const a = alergeny(telo);
      let t = text(telo.replace(/<sub>[\s\S]*?<\/sub>/g, ""));
      t = t.replace(/\(\s*\d{1,2}[a-z]?(?:\s*,\s*\d{1,2}[a-z]?)*\s*\)?/g, "").replace(/\s+,/g, ",").replace(/^[ ,]+|[ ,]+$/g, "");
      if (!t) continue;

      if (kod !== "obed") { chody.push({ c: kod, n: t, d: "", a }); continue; }
      const klic = t.toLowerCase();
      if (videno.has(klic) || klic.startsWith("nevaří se")) continue;
      videno.add(klic);
      const cast = t.split(",").map((x) => x.trim()).filter(Boolean);
      chody.push({ c: videno.size === 1 ? "obed" : "obed2", n: cast[0], d: cast.slice(1).join(" · "), a, _cast: cast });
    }

    const obedy = chody.filter((c) => c.c === "obed" || c.c === "obed2");
    if (obedy.length && !chody.some((c) => c.c === "polevka")
        && obedy.every((o) => o._cast.length > 1 && o._cast[0] === obedy[0]._cast[0])) {
      chody.unshift({ c: "polevka", n: obedy[0]._cast[0], d: "", a: [] });
      for (const o of obedy) {
        o._cast = o._cast.slice(1);
        o.n = o._cast[0];
        o.d = o._cast.slice(1).join(" · ");
      }
    }
    for (const c of chody) delete c._cast;
    if (chody.length) dny[iso] = { chody };
  }
  return dny;
}
