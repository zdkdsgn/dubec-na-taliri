# Podklad: aplikace školních jídelen a jak se k nim postavit

Stav k 8. 11. 2026. Zdroj: veřejné vyhledávání App Storu (český obchod) a poslední veřejné recenze.
Čísla jsou malý vzorek, u některých aplikací jen 9–24 hodnocení, a recenze píší převážně nespokojení.
Berte to jako ukazatel nálady, ne jako průzkum.

## 1. Hodnocení aplikací v App Storu (CZ)

| Aplikace | Vydavatel | Hodnocení | Počet hodnocení |
|---|---|---|---|
| Strava.cz | VIS Plzeň | 3,5 | 1 763 |
| iCanteen | Z-WARE | 2,0 | 24 |
| e-Jídelníček | Lukas Wana | 2,6 | 14 |
| eStrava | Ulrich Software | 2,6 | 14 |
| Jídelna.cz pro MŠ, ZŠ, SŠ… | Jan Pejsar | 1,4 | 9 |

Pro srovnání (ne jídelny): Bakaláři OnLine 3,8 (19 769), Škola Online 4,3 (5 685).

## 2. Na co si rodiče stěžují (opakující se témata, parafrázováno)

1. **Odhlašování a objednávání nespolehlivé.** Chyby ve chvíli, kdy je potřeba včas odhlásit; zaškrtnuté obědy se po znovuotevření ztrácejí; dítě pak nemá objednáno. Největší zdroj frustrace, protože za chybu platí rodina.
2. **Přihlášení.** Složité připojení ke škole (URL jídelny), appka si nepamatuje přihlášení, opakované vyplňování jména.
3. **Výpadky a pády** po aktualizacích.
4. **Zastaralý vzhled** a chybějící prvky (widgety, QR kódy, historické přehledy).
5. **Chybějící offline pohled** na to, co je dnes přihlášeno.

## 3. Kde je mezera pro Školu na talíři

- Appka **jen čte** a nic za rodiče neobjednává ani neodhlašuje. Nevytváří tedy problém č. 1, jen ukáže stav a odkáže na web školy.
- Přihlášení probíhá na webu jidelna.cz (appka heslo nevidí), bez nutnosti zadávat URL jídelny.
- Moderní vzhled, widget, hodinky, offline zobrazení, hlídání alergenů s profilem pro každé dítě.
- Jedno místo pro víc škol a víc dětí.

Co **neslibovat:** odhlašování z appky, ani to, že zobrazený stav je právně závazný. Rozhodující je vždy systém jídelny.

## 4. Doporučené formulace (App Store a web)

Veřejný text nepoužívá jména konkurentů (riziko sporu s Apple a se značkami). Říká, co appka umí:

- Podtitul: „Jídelníček školy a školky“
- „Hned vidíte, co je dnes k obědu a které menu má vaše dítě přihlášené.“
- „Funguje i offline. Widget a Apple Watch.“
- „Hlídání alergenů zvlášť pro každé dítě.“
- Pro pravdivost uvést: „Neoficiální přehled. Objednávky a odhlašování řešíte na webu jídelny.“
- Neslibovat „všechny školy“: 668 škol v seznamu, jídelníček má zhruba 244 (viz docs/APP-STORE.md).

## 5. Osnova pro jednání s dodavateli systémů

Cíl: oficiální souhlas a, ideálně, datové rozhraní. Kdo: Barda SW (jidelna.cz), Z-WARE (iCanteen), VIS Plzeň (strava.cz), případně Ulrich Software (eStrava).

1. Kdo jsme: nekomerční aplikace, jen pro čtení, uvádí zdroj a odkazuje zpět na systém jídelny.
2. Co děláme dnes: čteme veřejné jídelníčky (pauza mezi dotazy, identifikace v User-Agent); volitelně rodič nahlíží na vlastní objednávky po přihlášení v okně systému, appka heslo nevidí.
3. Co nabízíme: lepší zobrazení jídelníčku rodičům, bez zátěže pro jejich servery (data se stahují jednou denně, ne při každém otevření appky).
4. Co potřebujeme: (a) souhlas s uvedeným použitím, (b) doporučené oficiální rozhraní nebo export, (c) podmínky (četnost, uvedení zdroje).
5. Co jim přinášíme: méně dotazů rodičů na „co je k obědu“, odkaz zpět do jejich systému, ochotu upravit se podle jejich požadavků.

Dopis pro jidelna.cz je připravený v docs/DOPIS-JIDELNA-CZ.md; ostatním stačí upravit oslovení a bod 1.

## 6. Doplňující zjištění k trhu

- Podíl jednotlivých systémů mezi školami veřejně dostupný není. Doporučený postup: náhodný vzorek ~300 škol z rejstříku MŠMT, určit systém a spočítat podíly (chyba zhruba ±5 p. b.).
- Školy bez jídelníčku na jidelna.cz (424 z 668) většinou jídelní lístek na portál jen neposílají (ověřeno na 40 školách); viz docs/APP-STORE.md.
