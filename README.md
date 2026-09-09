# 🍽️ Dubeč na talíři

Mobilní webová aplikace (PWA) s jídelníčkem **MŠ a ZŠ Dubeč**.
Bez frameworku, bez buildu — čisté HTML/CSS/JS, cca 40 kB. Otevře se okamžitě, funguje i offline.

---

## Spuštění

```bash
cd "/Users/zk/Dubeč Jídelníček" && python3 -m http.server 4173
```

Pak `http://localhost:4173`. (Servírovat přes HTTP je nutné kvůli service workeru — dvojklik na `index.html` funguje taky, jen bez offline režimu.)

## Struktura

| Soubor | Co dělá |
|---|---|
| `index.html` | Kostra – 4 pohledy + tab bar + bottom sheet |
| `styles.css` | Liquid Glass design systém, světlý i tmavý režim |
| `app.js` | Stav, render, gesta, filtr alergenů, sdílení |
| `data.js` | Data jídelníčku — **generovaný soubor, needitovat ručně** |
| `menu/base.json` | Meta, 14 alergenů, typy chodů (ruční) |
| `menu/ms.json` | Jídelníček MŠ (ruční — MŠ ho nikde nepublikuje) |
| `menu/zs.json` | Jídelníček ZŠ (generovaný, slouží jako archiv) — `{"vydej": "11:30–13:45", "chody": [...]}` |
| `tools/update-menu.py` | Stáhne jídelníček ZŠ a přegeneruje `data.js` |
| `.github/workflows/jidelnicek.yml` | Spouští to každé ráno |
| `sw.js` | Offline cache (network-first) |
| `manifest.webmanifest` | Instalace na plochu |

---

## Co aplikace umí

- **MŠ / ZŠ** přepínač — mateřinka má 4 chody (přesnídávka → svačina), základka polévku a dva hlavní chody
- **Den / Týden** — denní osa s časy výdeje, nebo rozbalovací přehled celého týdne
- **Skutečný čas výdeje** — bere se z jídelního lístku (`11:30–13:45`) a během výdeje bliká živá tečka. U MŠ, kde ho jídelna nezveřejňuje, se neukazuje nic — radši žádný údaj než odhad
- **Filtr alergenů rozlišuje, kde alergen je** — když je mléko přímo v jídle, karta zčervená; když je jen v nápoji nebo příloze, zežloutne a odznak řekne „Alergen 7 · nápoj". Rodič tak pozná, kdy jde jídlo vzít a jen vynechat pití
- **Detail jídla** — u každého alergenu stojí, ve které položce je, plus rozpis „co je na talíři" (jídlo, příloha, doplněk, nápoj) s vlastními alergeny
- **Sdílení týdne** — nativní iOS share sheet, text do WhatsApp / třídní skupiny
- **Tmavý režim** — automaticky podle systému, nebo ručně v Info → Vzhled (Automaticky / Světlý / Tmavý). Volba se pamatuje a přebarví i stavový řádek telefonu.
- **Sama se aktualizuje** — service worker je network-first, takže při spuštění vždy sáhne na síť. Navíc po návratu do aplikace (a nejdřív 5 minut od načtení) porovná `meta.updated` v `menu/base.json` s načtenou verzí; když vyšel novější jídelníček, stránku tiše načte znovu. Bez toho by appka probuzená iOSem z paměti ukazovala data z posledního spuštění
- **Offline** — jednou načtený jídelníček zůstane v telefonu
- **Gesta** — swipe doleva/doprava mezi dny, sheet se zavírá stažením dolů, haptická odezva

### Designové principy (iOS 26/27)

Vrstvený **Liquid Glass**: barevné pozadí, nad ním poloprůhledné panely s `backdrop-filter` a vnitřním světelným lemem. Plovoucí tab bar místo přilepené lišty. Pružinové animace (`cubic-bezier(.32,.72,0,1)`). Typografie SF Pro s napjatým `letter-spacing`. Respektuje `prefers-color-scheme` i `prefers-reduced-motion`, `safe-area-inset` pro Dynamic Island a home indicator.

---

## Jak to provozovat — doporučení

### 0. Stav dat (k 7. 9. 2026)

| Škola | Data | Zdroj |
|---|---|---|
| **ZŠ** | ✅ skutečný jídelníček, 1.–11. 9. 2026 (týdny 36 a 37) | [jidelna.cz, jídelna 47](https://www.jidelna.cz/jidelni-listek/?jidelna=47) |
| **MŠ** | ⚠️ ukázková | [msdubec.cz](https://www.msdubec.cz/stranka-jidelnicek-45) má vyvěšený stále červenec 2026 |

**MŠ nemá jídelníček nikde veřejně.** Prověřeno: vlastní web (jen červenec), jeho sekce Aktuality ze školní kuchyně, rejstřík jídelen na jidelna.cz (je tam jen ZŠ, jídelna 47), strava.cz i facebooková stránka školky (za přihlášením). Jediná cesta je domluva s vedoucí jídelny — jidelna@msdubec.cz, 734 463 835.

Aplikace to nezakrývá: `data.js → meta.real` říká, která skupina je skutečná, a nad ukázkovým jídelníčkem se zobrazí žlutá poznámka. Až MŠ zveřejní září, stačí přepsat `days[…].ms` a přehodit `real.ms` na `true`.

**Užitečný nález:** URL jidelna.cz přijímá parametry rozsahu, takže se nedá stáhnout jen aktuální týden, ale celé období:

```
https://www.jidelna.cz/jidelni-listek/?jidelna=47&zacatek=2026-09&delka=P1M
```

`zacatek` bere `RRRR-MM` i konkrétní datum, `delka` je ISO 8601 doba (`P1M`, `P7D`). Tohle je hotová cesta pro automatický odběr — jedno stažení měsíčně místo denního hlídání. Do budoucna se vyplatí publikované týdny archivovat, dopředu jídelna vypisuje jen pár dní.

### 1. Automatická aktualizace (ZŠ — hotovo)

Každý všední den v 6:10 se spustí GitHub Action, která stáhne jídelní lístek ZŠ, porovná ho s archivem a při změně commitne. Push na `main` rovnou přesadí Pages, takže se rodičům nový jídelníček objeví sám.

Ručně kdykoli:

```bash
python3 tools/update-menu.py            # stáhne a přegeneruje
python3 tools/update-menu.py --offline  # jen přegeneruje z menu/*.json
```

Skript **nikdy nemaže** dny, které už v `menu/zs.json` jsou — archiv tak roste sám, i když jidelna.cz zveřejňuje jen několik týdnů dopředu. Když se z lístku nepodaří přečíst ani jeden den (typicky po změně HTML na jidelna.cz), skončí chybou a data nechá být. Action zčervená a přijde vám e-mail — lepší hlasitá chyba než tiše zastaralý jídelníček.

Parsuje se ze struktury `div.den` → `div.menu` → `popiskaJidla` / `textJidla` / `alergeny`, z hlavičky dne se bere výdejní okno. Polévka se bere jen z prvního chodu (u druhého se opakuje). Příloha, doplněk a nápoj se skládají do popisku odděleného tečkou, ale **zůstávají i rozepsané v poli `p`** i s vlastními alergeny — právě díky tomu umí aplikace říct, že mléko je jen v nápoji. Kuchyňské zkratky (`más. maš`, `syp.`, `drožd.`) rozepisuje tabulka `ZKRATKY` na začátku skriptu — když narazíte na další, přidejte řádek.

### 2. Jídelníček MŠ (ruční)

Mateřská škola jídelníček nikde nepublikuje, takže se do `menu/ms.json` píše ručně. Formát je stejný jako u ZŠ:

```json
"2026-09-21": [
  {"c": "presnidavka", "n": "Ovocný jogurt", "d": "Rohlík, hroznové víno", "a": [1, 7]}
]
```

`c` je typ chodu (`presnidavka`, `polevka`, `obed`, `obed2`, `svacina`), `d` doplněk a `a` čísla alergenů. Volitelně jde přidat `p` s rozpisem položek (`[{"l": "Jídlo", "n": "…", "a": [1]}]`) — aplikace pak i u MŠ pozná, ve které položce alergen je. Bez `p` se chová jako dosud. Po úpravě spusťte `python3 tools/update-menu.py --offline` a commitněte. Až MŠ začne jídelníček zveřejňovat, přehoďte v `menu/base.json` `meta.real.ms` na `true` — zmizí tím žlutá poznámka o ukázkových datech.

### 3. Kdyby to jednou přestalo stačit

Další varianty, od nejlevnější:

**A. Ruční (nejjednodušší start)**
Hospodářka jednou týdně přepíše jídelníček do `data.js` a nahraje soubor. Zvládne to kdokoli, kdo umí kopírovat text — struktura je jeden řádek na jídlo.

**B. Tabulka jako redakční systém (doporučuji)**
Google Sheet se sloupci `datum | skupina | chod | název | doplněk | alergeny`. Kuchyně píše do tabulky, kterou už zná. Malý skript (GitHub Action jednou denně) tabulku stáhne, převede na `menu.json` a nasadí. Nulové náklady, žádná administrace, verzování zdarma.

**C. Automatický odběr z jidelna.cz** — už běží, viz bod 1.

> Ať zvolíte cokoli, `app.js` se nemění. Stačí `data.js` nahradit za `fetch('menu.json')` — struktura je totožná.

### 2. Kde to hostovat

**GitHub Pages, Netlify nebo Cloudflare Pages** — zdarma, HTTPS automaticky, nasazení = `git push`. PWA vyžaduje HTTPS, takže tohle je nutná podmínka pro „přidat na plochu". Doména typu `jidelnicek.dubec.cz` jako CNAME.

### 3. Notifikace (druhá fáze)

Nejžádanější funkce u rodičů bývá **„zítra je rybí filé, syn to nejí"**. Web Push funguje na iOS 16.4+ pouze pro aplikaci přidanou na plochu. Realizace: rodič si v Nastavení zvolí čas (např. 17:00) a případně alergeny; server pošle push jen tehdy, když se v zítřejším jídelníčku alergen objeví. Do té doby je levnější a spolehlivější **odběr kalendáře (.ics)** — jídelníček se zobrazí přímo v iOS Kalendáři, nula infrastruktury.

### 4. Co dál stojí za zvážení

| Funkce | Proč | Náročnost |
|---|---|---|
| Odkaz na odhlášení oběda | Nejčastější úkon rodiče vůbec | Nízká (deeplink do Strava.cz) |
| Widget na plochu / zamykací obrazovku | „Co je dneska" bez otevírání appky | Vysoká (vyžaduje nativní app) |
| Fotky jídel od kuchařek | Děti si vybírají očima, buduje důvěru | Střední |
| Profily dětí (Anička = bez mléka) | Filtr alergenů per dítě | Střední |
| Statistika „jak dětem chutnalo" | Zpětná vazba pro jídelnu, data už sbíráme lokálně | Střední (nutný backend) |

### 5. Než to pustíte mezi rodiče

- Domluvit se školou, že jde o **neoficiální přehled** (aplikace to uvádí v patičce i v Info)
- Ověřit, kdo odpovídá za správnost alergenů — to je jediné právně citlivé místo
- Krátký návod „Sdílet → Přidat na plochu" do třídních skupin; bez toho většina rodičů PWA neinstaluje

---

## Nasazení

GitHub Pages z větve `main`, složka `/`. Adresa: **https://zdkdsgn.github.io/dubec-na-taliri/**

Aby mohl automat commitovat, musí být v **Settings → Actions → General → Workflow permissions** zapnuto **Read and write permissions**. Bez toho Action doběhne, ale push selže.
