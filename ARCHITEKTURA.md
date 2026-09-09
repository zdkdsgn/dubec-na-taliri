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

1. **Appka samotná (index.html/app.js) víc škol zatím neumí.** Pořád
   umí jen Dubeč, přesně jako dneska. Přepnutí na "appka si školu
   vybere sama" je samostatný kus práce – hlavně UI pro výběr/hledání
   školy a runtime načítání `schools/<id>/…` místo vestavěného
   `data.js`. Chce to nejdřív probrat UX (textové hledání? mapa?
   "poblíž mě"?), než se do toho pustím naslepo.

2. **Živé vyhledávání škol z appky.** Kvůli CORS to jde jen přes
   server. Nejlevnější a nejmíň závazná varianta je malá serverless
   funkce (např. Cloudflare Worker, zdarma), která jen přeposílá dotaz
   na jidelna.cz a vrátí JSON – appka samotná zůstává na GitHub Pages.
   Vyžaduje to ale nový účet/službu navíc, proto to nezakládám bez
   potvrzení.

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

## Rozumný další krok

Až budete chtít pokračovat, navrhuju v tomhle pořadí:

1. Probrat UX výběru školy (hledání vs. výběr ze seznamu, jak appka
   pozná "moji školu" napříč zařízeními).
2. Přepsat `app.js`/`index.html`, aby uměly načíst kteroukoli školu
   z `schools/<id>/` za běhu, ne jen vestavěný `data.js` pro Dubeč.
3. Teprve pak řešit vyhledávací proxy a růst registru – to už je
   otázka škálování, ne architektury.
