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
  – žádný den nemá víc než MAX_OBEDU obědových položek v rámci jedné skupiny
    (jinak jde o typ školy, který parser zatím neumí – viz ARCHITEKTURA.md)

Průběh se průběžně zapisuje do menu/sken-prubeh.json, aby šlo sledovat
odkudkoli a v klidu pokračovat po přerušení – při dalším spuštění stejného
rozsahu přeskočí ID, která už byla zpracovaná.

Školy s platnou stránkou, ale zrovna bez jídelníčku (prázdniny, nepravidelné
zveřejňování), se zapíšou do registru s příznakem "bez_listku": true a
prázdným days.json – appka je pak umí vybrat a jídelníček se doplní, jakmile
se objeví (viz tools/obnov-skoly.py, spouští ho týdenní workflow).

    python3 tools/scan-all-schools.py 1 4200 --znovu   # znovu projde už hotová ID
    python3 tools/scan-all-schools.py 4300 4450 --nove # vždy znovu zkusí celý rozsah (týdenní workflow)

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
MAX_OBEDU = 4         # víc různých obědů v jedné skupině = jiný typ jídelny (catering, dietní řady)


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
    # neplatné ID vrací úvodní stránku jidelna.cz s tímhle obecným titulkem
    if not nazev or nazev.startswith("Jídelní lístky škol a školek"):
        return None
    return nazev


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


def zapis_bez_listku(registr, znama_id, progres, sid, nazev):
    zaznam = {"id": sid, "nazev": nazev, "zdroj": "jidelna.cz", "skutecna_data": True, "bez_listku": True}
    registr.append(zaznam)
    znama_id.add(sid)
    progres.setdefault("bez_listku", []).append(zaznam)
    slozka = ROOT / "schools" / sid
    slozka.mkdir(parents=True, exist_ok=True)
    uloz_json(slozka / "days.json", {})
    uloz_json(slozka / "base.json", {"updated": datetime.now(timezone(timedelta(hours=2))).isoformat(timespec="seconds")})


def main() -> int:
    argumenty = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(argumenty) != 2:
        print(__doc__)
        return 1
    znovu = "--znovu" in sys.argv
    nove  = "--nove" in sys.argv         # vždy znovu zkusit všechna ID v rozsahu (týdenní objevování)
    od, do = int(argumenty[0]), int(argumenty[1])

    registr = nacti_json(ROOT / "schools" / "index.json", [])
    znama_id = {s["id"] for s in registr}
    progres  = nacti_json(PROGRES, {"hotovo": [], "najdeno": [], "vyrazeno": []})
    klic_hotovo = "znovu_hotovo" if znovu else "hotovo"
    hotovo   = set() if nove else set(progres.get(klic_hotovo, []))
    vyrazena_id = {v["id"] for v in progres["vyrazeno"]}

    zacatek_obdobi = date.today() - timedelta(days=DNY_ZPET)
    delka = DNY_ZPET + DNY_VPRED

    for i in range(od, do + 1):
        sid = str(i)
        if sid in hotovo or sid in znama_id or sid in vyrazena_id:
            continue
        try:
            html = stahni(i, zacatek_obdobi, delka)
        except Exception as e:
            print(f"[{i}] síťová chyba: {e}", file=sys.stderr)
            time.sleep(2)
            continue

        nazev = cisty_nazev(html)
        dny = parsuj(html) if nazev else {}

        if not nazev:
            pass  # neplatné ID
        elif not dny:
            zapis_bez_listku(registr, znama_id, progres, sid, nazev)
            print(f"[{i}] BEZ JÍDELNÍČKU: {nazev}")
        elif max_obedu_v_ramci_skupiny(dny) > MAX_OBEDU:
            progres["vyrazeno"].append({"id": sid, "nazev": nazev, "duvod": f"{MAX_OBEDU + 1}+ obědových položek"})
            print(f"[{i}] VYŘAZENO (moc obědů): {nazev}")
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
        progres[klic_hotovo] = sorted(hotovo, key=int)
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
