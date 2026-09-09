#!/usr/bin/env python3
"""Najde jídelnu na jidelna.cz podle názvu/ulice a volitelně ji zapíše
do schools/index.json (registr škol pro víceškolní appku).

    python3 tools/search-schools.py "Starodubečská"
    python3 tools/search-schools.py "Starodubečská" --add
    python3 tools/search-schools.py "Starodubečská" --add --kratky "ZŠ Dubeč"

Bez --kratky appka v hlavičce zobrazí celý oficiální název (zalomí se
na 2 řádky) – funguje to, jen "ZŠ Dubeč" vypadá v hlavičce líp než
"Základní škola, Starodubečská 413, Praha 10 - Dubeč".

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


def zpracuj_argumenty(argv):
    """--add a --kratky "text" se vyloučí ze slov dotazu, ať se do
    vyhledávání na jidelna.cz neprotáhnou omylem."""
    pridat, kratky, slova = False, None, []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--add":
            pridat = True
        elif a == "--kratky":
            i += 1
            kratky = argv[i] if i < len(argv) else None
        else:
            slova.append(a)
        i += 1
    return pridat, kratky, " ".join(slova)


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    pridat, kratky, dotaz = zpracuj_argumenty(sys.argv[1:])

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
                zaznam = {"id": s["id"], "nazev": s["nazev"], "zdroj": "jidelna.cz", "skutecna_data": True}
                if kratky:
                    zaznam["kratky"] = kratky
                registr.append(zaznam)
                nove += 1
        registr.sort(key=lambda s: s["nazev"])
        uloz_registr(registr)
        print(f"\npřidáno {nove} nových, registr má teď {len(registr)} škol")
    return 0


if __name__ == "__main__":
    sys.exit(main())
