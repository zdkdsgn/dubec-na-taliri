# Podklady pro App Store (návrh)

## Základní údaje
- **Název:** Škola na talíři
- **Podtitul (30 znaků):** Jídelníček školy a školky
- **Kategorie:** Jídlo a pití (alternativně Životní styl)
- **Věk:** 4+
- **Zásady ochrany soukromí (URL):** https://zdkdsgn.github.io/dubec-na-taliri/soukromi.html
- **Podpora (URL):** https://github.com/zdkdsgn/dubec-na-taliri/issues

## Popis
Co je dnes k obědu? Jídelníček vaší školy nebo školky na jednom místě – bez hesel a bez hledání ve složitých webech.

• Stovky škol a školek z celé republiky (jidelna.cz, iCanteen)
• Den i celý týden přehledně, včetně doby výdeje
• Hlídání alergenů – jídla s nimi se zvýrazní, u víc dětí má každé svůj profil
• Přihlášené obědy z jidelna.cz (beta): hned vidíte, které menu má dítě objednané
• Upozornění na nový jídelníček a večerní upozornění na alergeny
• Widget a Apple Watch
• Kontakty a doby výdejů jídelny

Neoficiální přehled. Před rozhodnutím ověřte údaje u školy.

## Klíčová slova (100 znaků)
jídelníček,škola,školka,obědy,jídelna,alergeny,stravování,školní jídelna,oběd

## Poznámka k formulaci
Veřejný text nesrovnává se jmény konkurentů, říká jen, co appka umí; neslibuje odhlašování ani „všechny školy“. Důvody a podklady: docs/PODKLAD-KONKURENCE.md.

## Co je nového (příklad)
Úvod při prvním spuštění, výběr školy bez předvybrané, karta „O jídelně“, přihlášené obědy z jidelna.cz (beta), profil alergenů pro každé dítě, večerní upozornění, nová ikona.

## App Privacy („nutrition labels“) – návrh odpovědí
| Otázka | Odpověď |
|---|---|
| Sbíráte data? | Ano, minimálně |
| **Identifikátory zařízení** (push token APNs) | Ano – jen pro upozornění, nepropojeno s identitou, nepoužito ke sledování |
| Kontaktní údaje, polohu, zdraví, finance, historii prohlížení | Ne |
| Uživatelský obsah (hodnocení jídel, filtr alergenů) | Ne – zůstává jen v zařízení |
| Sledování (tracking) | Ne |
| Analytika, reklamy třetích stran | Ne |

Poznámky: přihlašovací údaje k jidelna.cz zadává uživatel na webu jidelna.cz v okně WKWebView, appka je nevidí. Objednávky (jména dětí) se čtou a ukládají jen lokálně.

## Poznámky k review
- Funkce „Přihlášené obědy“ je volitelná, pro test stačí běžné použití bez přihlášení (výběr školy a jídelníček).
- Zkušební účet k jidelna.cz nemáme k dispozici; popište, že přihlášení je nepovinné.
- Appka je neoficiální a odkazuje na zdroje dat; před vydáním je vhodné mít odpověď provozovatele jidelna.cz (viz docs/DOPIS-JIDELNA-CZ.md).

## Před vydáním
1. Odeslat dopis provozovateli jidelna.cz a vyčkat na odpověď.
2. Doplnit v souboru soukromi.html a v dopise jméno/kontakt provozovatele.
3. Screenshoty (6,9" a 6,3" iPhone, volitelně Watch) z čisté instalace s několika školami.
4. Vyplnit App Privacy podle tabulky výše.
