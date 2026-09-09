#!/usr/bin/env python3
"""Najde jídelnu na jidelna.cz podle názvu/ulice a volitelně ji zapíše
do schools/index.json (registr škol pro víceškolní appku).

    python3 tools/search-schools.py "Starodubečská"
    python3 tools/search-schools.py "Starodubečská" --add

Pozor: jidelna.cz eviduje jen školy, které používají jejich software –
nejde o vyčerpávající seznam všech škol v ČR. Když se nic nenajde nebo je
výsledků moc, dotaz upřesněte (celý název ulice, ne jen město).
"""
import json, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from jidelna_client import hledej

ROOT     = Path(__file__).resolve().parent.parent
REGISTR  = ROOT / "schools" / "index.json"


def nacti_registr() -> list[dict]:
    if REGISTR.exists():
        return json.loads(REGISTR.read_text(encoding="utf-8"))
    return []


def uloz_registr(skoly: list[dict]) -> None:
    REGISTR.parent.mkdir(exist_ok=True)
    REGISTR.write_text(
        json.dumps(skoly, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    pridat = "--add" in sys.argv
    dotaz  = " ".join(a for a in sys.argv[1:] if a != "--add")

    vysledky = hledej(dotaz)
    if not vysledky:
        print("Nic nenalezeno (nebo je výsledků moc – zkuste upřesnit dotaz).")
        return 0

    for s in vysledky:
        print(f"  {s['id']:>6}  {s['nazev']}")

    if pridat:
        registr = nacti_registr()
        znama = {s["id"] for s in registr}
        nove = 0
        for s in vysledky:
            if s["id"] not in znama:
                registr.append({"id": s["id"], "nazev": s["nazev"], "zdroj": "jidelna.cz"})
                nove += 1
        registr.sort(key=lambda s: s["nazev"])
        uloz_registr(registr)
        print(f"\npřidáno {nove} nových, registr má teď {len(registr)} škol")
    return 0


if __name__ == "__main__":
    sys.exit(main())
