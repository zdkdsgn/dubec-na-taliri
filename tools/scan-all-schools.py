#!/usr/bin/env python3
"""Projde ID prostor jidelna.cz a najde VŠECHNY reálné jídelny s aktuálním
jídelníčkem – jidelna.cz nemá žádné "vypiš mi všechno" API, jen vyhledávání
podle názvu, takže tohle je jediná cesta k opravdu úplnému seznamu.

    python3 tools/scan-all-schools.py 1 4200        # rozsah <od> <do>, včetně

Pro každé ID udělá JEDEN požadavek (stejnou stránku, ze které appka beztak
čte jídelníček), takže objevení a stažení je jeden krok, ne dva zvlášť.
Škola se do registru zapíše, jen když:
  – stránka vrátí 200 (ne přesměrování na hlavní stránku = neplatné ID)
  – jde z ní přečíst aspoň jeden den s jídlem
  – žádný den nemá víc než 2 obědové položky v rámci jedné skupiny
    (jinak jde o typ školy, který parser zatím neumí – viz ARCHITEKTURA.md)

Průběh se průběžně zapisuje do menu/sken-prubeh.json, aby šlo sledovat
odkudkoli a v klidu pokračovat po přerušení – při dalším spuštění stejného
rozsahu přeskočí ID, která už byla zpracovaná.

Bezohledně neútočí na jidelna.cz: mezi požadavky čeká, viz PAUZA níž.
robots.txt cestu /jidelni-listek/ nezakazuje.
"""
import json, sys, time
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from jidelna_client import parsuj, stahni

ROOT   = Path(__file__).resolve().parent.parent
PROGRES = ROOT / "menu" / "sken-prubeh.json"
PAUZA  = 0.5          # sekund mezi požadavky – slušnost k jidelna.cz
DNY_ZPET, DNY_VPRED = 7, 21


def nacti_json(cesta, vychozi):
    return json.loads(cesta.read_text(encoding="utf-8")) if cesta.exists() else vychozi


def uloz_json(cesta, data):
    cesta.parent.mkdir(parents=True, exist_ok=True)
    cesta.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def cisty_nazev(html):
    i, j = html.find("<title>"), html.find("</title>")
    if i < 0 or j < 0:
        return None
    nazev = html[i + 7:j].replace(" - Jídelní lístek", "").strip()
    return nazev or None


def max_obedu_v_ramci_skupiny(dny):
    """Kolik obědových položek má nejnabitější den v rámci JEDNÉ skupiny –
    spojené ZŠ+MŠ školy mají 2 skupiny a to je v pořádku, tohle počítá
    zvlášť pro každou."""
    nejvic = 0
    for zaznam in dny.values():
        skupiny = zaznam.get("skupiny") or {"_": zaznam}
        for zaz in skupiny.values():
            n = sum(1 for c in zaz.get("chody", []) if c["c"] in ("obed", "obed2"))
            nejvic = max(nejvic, n)
    return nejvic


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 1
    od, do = int(sys.argv[1]), int(sys.argv[2])

    registr = nacti_json(ROOT / "schools" / "index.json", [])
    znama_id = {s["id"] for s in registr}
    progres  = nacti_json(PROGRES, {"hotovo": [], "najdeno": [], "vyrazeno": []})
    hotovo   = set(progres["hotovo"])

    zacatek_obdobi = date.today() - timedelta(days=DNY_ZPET)
    delka = DNY_ZPET + DNY_VPRED

    for i in range(od, do + 1):
        sid = str(i)
        if sid in hotovo or sid in znama_id:
            continue
        try:
            html = stahni(i, zacatek_obdobi, delka)
        except Exception as e:
            print(f"[{i}] síťová chyba: {e}", file=sys.stderr)
            time.sleep(2)
            continue

        nazev = cisty_nazev(html)
        dny = parsuj(html) if nazev else {}

        if not nazev or not dny:
            pass  # neplatné ID nebo škola bez aktuálního jídelníčku – přeskočit
        elif max_obedu_v_ramci_skupiny(dny) > 2:
            progres["vyrazeno"].append({"id": sid, "nazev": nazev, "duvod": "3+ obědové položky"})
            print(f"[{i}] VYŘAZENO (3+ obědů): {nazev}")
        else:
            zdroj = "manual" if False else "jidelna.cz"
            skutecna = True
            zaznam = {"id": sid, "nazev": nazev, "zdroj": zdroj, "skutecna_data": skutecna}
            registr.append(zaznam)
            znama_id.add(sid)
            progres["najdeno"].append(zaznam)

            slozka = ROOT / "schools" / sid
            slozka.mkdir(parents=True, exist_ok=True)
            uloz_json(slozka / "days.json", dny)
            uloz_json(slozka / "base.json", {
                "updated": datetime.now(timezone(timedelta(hours=2))).isoformat(timespec="seconds"),
                "week": f"{min(dny)} – {max(dny)}",
            })
            print(f"[{i}] NALEZENO: {nazev}  ({len(dny)} dní)")

        hotovo.add(sid)
        progres["hotovo"] = sorted(hotovo, key=int)
        if i % 20 == 0:                      # průběžné ukládání, ne po každém ID
            uloz_json(PROGRES, progres)
            uloz_json(ROOT / "schools" / "index.json", registr)
        time.sleep(PAUZA)

    uloz_json(PROGRES, progres)
    uloz_json(ROOT / "schools" / "index.json", registr)
    print(f"\nHOTOVO {od}–{do}: nalezeno {len(progres['najdeno'])}, vyřazeno {len(progres['vyrazeno'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
