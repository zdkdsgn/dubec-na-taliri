# Vyhledávací proxy škol

Malý Cloudflare Worker – jediný jeho úkol je obejít to, že `jidelna.cz`
nesídlí CORS hlavičky, takže appka v prohlížeči nemůže jejich vyhledávání
škol zavolat přímo. Worker dotaz přepošle, výsledek rozparsuje na JSON
a vrátí appce s CORS hlavičkami. Appka samotná zůstává na GitHub Pages –
tenhle worker se volá jen při hledání/přidávání školy, ne při běžném
prohlížení jídelníčku.

## Nasazení (jednorázově)

```bash
cd cloudflare/skoly-proxy
npx wrangler login      # otevře prohlížeč, přihlásíte se / založíte účet zdarma
npx wrangler deploy
```

Vypíše se adresa tvaru `https://dubec-skoly-proxy.<váš-subdomain>.workers.dev`
– tu si poznamenejte, appka ji bude potřebovat, až se postaví výběr
školy.

Zdarma stačí (Workers free plán: 100 000 požadavků/den, bez platební
karty) – worker se volá jen při hledání školy, ne při běžném provozu.

## Vývoj a testování

```bash
npm install
npm run dev        # http://localhost:8787, žádné přihlášení nepotřeba
```

```bash
curl "http://localhost:8787/?q=Starodubečská" -H "Origin: http://localhost:4173"
```

## Rozhraní

`GET /?q=<dotaz>` (dotaz musí mít aspoň 4 znaky, stejně jako na jidelna.cz)

```json
{
  "ok": true,
  "vysledky": [{ "id": "47", "nazev": "Základní škola, Starodubečská 413, Praha 10 - Dubeč" }],
  "stav": "ok"
}
```

`stav`: `"ok"` (výsledky), `"prazdno"` (nic nenalezeno), `"prilis_siroke"`
(moc obecný dotaz, jidelna.cz odmítla vypsat seznam).

CORS je omezené na `POVOLENE_PUVODY` v `src/worker.js` – zatím GitHub
Pages appka a localhost pro vývoj. Přidat další doménu = jeden řádek.
