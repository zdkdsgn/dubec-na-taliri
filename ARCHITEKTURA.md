# Architektura: od appky pro Dubeč k appce pro víc škol

Tenhle dokument popisuje, co je hotové jako **půda pro rozšíření na víc
škol** (a časem případně App Store), co je vědomě odložené, a proč.

Appka pro Dubeč na `zdkdsgn.github.io/dubec-na-taliri` zůstává **beze
změny a plně funkční** – tenhle refaktor běží vedle ní v nových
souborech, nic ze živé appky nepřepisuje.

---

## Co jsme zjistili

**jidelna.cz není vyčerpávající seznam škol.** Je to zákaznický seznam
jedné konkrétní firmy prodávající software jídelnám. Spousta škol tam
prostě není (přesně jako MŠ Dubeč) – appka pro víc škol proto od
začátku počítá s tím, že pokrytí bude děravé, ne úplné.

**Vyhledávání škol musí jít přes server, ne přímo z appky.**
`jidelna.cz` nesídlí `Access-Control-Allow-Origin`, takže `fetch()`
z běžícího webu (kdekoli mimo jejich vlastní doménu) selže na CORS.
Živé hledání "kde je moje škola" tedy nejde postavit jako čistě
statickou stránku na GitHub Pages – buď potřebuje vlastní backend
(server-side proxy), nebo appka pracuje jen s předem staženým registrem
škol (bez hledání na požádání).

## Co je hotové (bezpečné, žádná nová infrastruktura)

| Soubor | Co dělá |
|---|---|
| `tools/jidelna_client.py` | Sdílený klient – stažení jídelníčku i vyhledávání škol na jidelna.cz. Vytažen z `tools/update-menu.py`, který teď jen importuje odsud (ověřeno: výstup identický před/po refaktoru). |
| `tools/search-schools.py` | `python3 tools/search-schools.py "název ulice"` – najde školu na jidelna.cz, `--add` ji zapíše do registru. |
| `tools/fetch-school.py` | Obecná (víceškolní) verze `update-menu.py` – stáhne jídelníček JEDNÉ školy z registru do `schools/<id>/`. `--all` projede celý registr s pauzou mezi školami. |
| `schools/index.json` | Registr škol: `id`, `název`, `zdroj` (`jidelna.cz` / `manual`). Zatím 2 záznamy – ZŠ Dubeč (47) a ručně vedená MŠ Dubeč, jako důkaz, že formát unese oba případy. |
| `schools/<id>/days.json` | Archiv jídelníčku té školy – stejný bohatý formát jako appka pro Dubeč (alergeny po jednotlivých položkách, skutečný výdejní čas). |
| `schools/<id>/base.json` | Meta té školy (kdy naposledy aktualizováno, jaký týden). |

Vyzkoušeno end-to-end na reálné škole (47) – ne jen na Dubči, na kterou
byl původní kód psaný natvrdo.

## Co je vědomě odložené (rozhodnutí, ne opomenutí)

1. **Appka umí vybrat jinou školu – hotovo.** Info → „Vaše škola"
   otevře výběr: rychlé přepnutí na cokoli v `schools/index.json`,
   nebo živé hledání přes `zs-jidelny.zdkdsgn.workers.dev`. Vybraná
   škola se stáhne za běhu (`schools/<id>/{base,days}.json`) a nahradí
   jen `D.days` – `D.courses`/`D.allergens` zůstávají společné pro
   všechny školy. Výchozí appka (bez uložené volby) se chová úplně
   stejně jako dřív, žádný síťový dotaz navíc.

   Jednokuchyňová škola (cokoli mimo Dubeč) se zabalí pod interní
   skupinu `"zs"` a segmentovaný přepínač ZŠ/MŠ se schová – ten zůstává
   jen pro Dubeč, která je jediná appkou podporovaná "spárovaná"
   lokalita (ruční MŠ + reálná ZŠ pod jedním pohledem). Obecnější model
   (víc kuchyní na jednu lokalitu) není zatím potřeba – až přibude druhá
   taková škola, dá se doplnit.

2. **Živé vyhledávání škol z appky – nasazeno.**
   `cloudflare/skoly-proxy/` je Cloudflare Worker, který dotaz přepošle
   na jidelna.cz a vrátí JSON s CORS hlavičkami. Appka samotná zůstává
   na GitHub Pages, worker se volá jen při hledání školy. Běží na
   **https://zs-jidelny.zdkdsgn.workers.dev** – appka na něj zatím
   nikam neodkazuje, čeká se na výběr školy v UI (bod 1 výše).

3. **Hromadné doplňování registru.** `search-schools.py` umí najít
   školu podle přesného názvu/ulice, ale nejde "vylistovat všechny
   školy v ČR" – jidelna.cz žádné takové API nemá. Registr poroste
   postupně (buď ručně přes `search-schools.py --add`, nebo časem přes
   formulář v appce, kde si škola/rodič sami najdou a přidají svou
   jídelnu).

4. **App Store.** Tenhle refaktor dělá appku *architektonicky*
   připravenou (data oddělená od jedné konkrétní školy), ale
   nezakládá Apple Developer účet ani nebalí appku přes Capacitor/
   Cordova do nativního obalu – to je krok až na konci, ne teď.

## Parser umí i vícestopé školy (spojené ZŠ+MŠ)

Původní parser počítal jen s jedním "castDne" blokem na den (tak to
má ZŠ Dubeč). Spojené instituce (typicky ZŠ+MŠ na jedné stránce)
ale mají na jeden den víc "castDne" bloků, každý s vlastním podnadpisem
("Oběd ZŠ (11:00-14:00)", "Přesnídávka MŠ (8:00-8:30)"…) – bez toho
si appka pletla přesnídávku s obědem a duplikovala jídla mezi
skupinami.

`tools/jidelna_client.py` teď podnadpisy čte a rozdělí den na skupiny
(`zs`/`ms`) přesně jako appka odjakživa dělá pro Dubeč – taková škola
pak v appce dostane stejný ZŠ/MŠ přepínač. Jednostopé školy (drtivá
většina) se tímhle nezměnily, `parsuj()` pro ně vrací identický tvar
jako dřív.

**Pořád neumí:** školy s víc než 2 číslovanými obědovými variantami
v jedné skupině (např. běžný oběd + bezlepková dieta jako chod 3) –
`tools/fetch-school.py` na to při stahování hlasitě upozorní
("N obědových položek"), ale nezastaví se. Jedna taková škola (ZŠ Na
Líše, Praha 4) je zatím z registru vyřazená kvůli tomuhle.

## Plošné procházení celého ID prostoru (2026-09)

jidelna.cz nemá "vypiš mi všechno" API, jen vyhledávání podle názvu –
jediná cesta k opravdu úplnému seznamu je projet ID prostor sekvenčně.
`tools/scan-all-schools.py <od> <do>` to dělá: pro každé ID jeden
požadavek (stejná stránka, ze které appka číst jídelníček), 200 = platná
škola, 302 = neplatné ID. robots.txt cestu `/jidelni-listek/` nezakazuje.

Rozsah 1–4200 (hustě obsazená část prostoru, ověřeno vzorkováním až do
20000) proběhl s 0,5s pauzou mezi požadavky – ~35 minut, běželo na
pozadí. Výsledek: **179 nových škol**, **17 vyřazeno** (stejná pravidla
jako u ručních importů – 3+ obědové položky na skupinu). Registr má
teď **207 škol** napříč ~44 městy a okresy, ne jen Prahou a Brnem.

Průběh a přehled nalezených/vyřazených škol je v `menu/sken-prubeh.json`
– slouží jako log, appka ho sama nečte.

## Rozumný další krok

Až budete chtít pokračovat, navrhuju v tomhle pořadí:

1. Probrat UX výběru školy (hledání vs. výběr ze seznamu, jak appka
   pozná "moji školu" napříč zařízeními).
2. Přepsat `app.js`/`index.html`, aby uměly načíst kteroukoli školu
   z `schools/<id>/` za běhu, ne jen vestavěný `data.js` pro Dubeč.
3. Teprve pak řešit vyhledávací proxy a růst registru – to už je
   otázka škálování, ne architektury.
