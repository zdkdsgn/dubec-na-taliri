#!/usr/bin/env python3
"""Projde čísla jídelen iCanteen (strav.nasejidelna.cz/<číslo>) a zapíše ty,
které mají veřejný jídelníček, do menu/icanteen-kandidati.json. Stáhne i jejich
logo (název školy je na stránce jen jako obrázek) – podle něj se pak ručně
doplní "nazev" a kandidát se přidá do registru (tools/pridej-icanteen.py).

    python3 tools/scan-icanteen.py 1 800 [složka_na_loga]
"""
import json, sys, time, urllib.error, urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from icanteen_client import HLAVICKY, parsuj, stahni

ROOT  = Path(__file__).resolve().parent.parent
SOUBOR = ROOT / "menu" / "icanteen-kandidati.json"
PAUZA = 0.4


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__); return 1
    od, do = int(sys.argv[1]), int(sys.argv[2])
    loga = Path(sys.argv[3]) if len(sys.argv) > 3 else None
    data = json.loads(SOUBOR.read_text(encoding="utf-8")) if SOUBOR.exists() else {"hotovo": [], "kandidati": {}}
    hotovo = set(data["hotovo"])

    for i in range(od, do + 1):
        cislo = f"{i:04d}"
        if cislo in hotovo:
            continue
        try:
            dny = parsuj(stahni(cislo))
        except urllib.error.HTTPError as e:
            dny = {}
            if e.code != 404:
                print(f"[{cislo}] HTTP {e.code}", file=sys.stderr)
        except Exception as e:
            print(f"[{cislo}] chyba: {e}", file=sys.stderr); time.sleep(2); continue
        if dny:
            data["kandidati"][cislo] = {"dni": len(dny), "nazev": None}
            if loga:
                try:
                    req = urllib.request.Request(f"https://strav.nasejidelna.cz/{cislo}/img/logo.png", headers=HLAVICKY)
                    (loga / f"{cislo}.png").write_bytes(urllib.request.urlopen(req, timeout=30).read())
                except Exception:
                    pass
            print(f"[{cislo}] jídelníček ({len(dny)} dní)")
        hotovo.add(cislo)
        data["hotovo"] = sorted(hotovo)
        if i % 20 == 0:
            SOUBOR.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        time.sleep(PAUZA)

    SOUBOR.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"HOTOVO {od}–{do}: kandidátů {len(data['kandidati'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
