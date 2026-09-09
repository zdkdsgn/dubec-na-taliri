#!/usr/bin/env python3
"""Stáhne jídelníček JEDNÉ školy z registru (schools/index.json) do
schools/<id>/days.json – archiv, který se dny nikdy nemažou, jen doplňují.

    python3 tools/fetch-school.py 47
    python3 tools/fetch-school.py --all      # projede celý registr

Tohle je obecná, víceškolní verze tools/update-menu.py (ten zůstává beze
změny a dál obsluhuje jen appku pro Dubeč – tenhle skript je příprava na
appku, která si školu vybere sama, viz ARCHITEKTURA.md).

Funguje jen pro školy se zdrojem "jidelna.cz" – "manual" školy (jako MŠ
Dubeč) se editují ručně přímo v jejich schools/<id>/days.json.
"""
import json, sys, time
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from jidelna_client import parsuj, stahni

ROOT = Path(__file__).resolve().parent.parent
DNY_ZPET, DNY_VPRED = 7, 35
PAUZA_MEZI_SKOLAMI = 1.5   # sekund – slušnost k jidelna.cz při --all


def nacti_registr() -> list[dict]:
    return json.loads((ROOT / "schools" / "index.json").read_text(encoding="utf-8"))


def stahni_skolu(skola_id: str) -> bool:
    """True = úspěch (i beze změny), False = chyba (data se nechala být)."""
    slozka = ROOT / "schools" / skola_id
    dny_soubor = slozka / "days.json"
    dny = json.loads(dny_soubor.read_text(encoding="utf-8")) if dny_soubor.exists() else {}
    pred = len(dny)

    try:
        od   = date.today() - timedelta(days=DNY_ZPET)
        html = stahni(int(skola_id), od, DNY_ZPET + DNY_VPRED)
        nove = parsuj(html)
    except Exception as e:
        print(f"  [{skola_id}] CHYBA: {e} – data nechávám beze změny", file=sys.stderr)
        return False

    if not nove:
        print(f"  [{skola_id}] nic se nepodařilo přečíst – data nechávám beze změny", file=sys.stderr)
        return False

    # Parser počítá s max. 2 "chody" na oběd (polévka + 1–2 hlavní jídla).
    # Některé školy (typicky spojená ZŠ+MŠ na jedné stránce, nebo MŠ
    # s vlastním počtem chodů) mají na jeden den víc – appka by pak
    # klidně ukázala zdvojené nebo popletené jídlo. Radši nahlas
    # varovat, ať si to někdo ověří ručně, než to tiše propašovat dál.
    for den, zaznam in nove.items():
        chody = zaznam.get("chody", [])
        obedu = sum(1 for c in chody if c["c"] in ("obed", "obed2"))
        nazvy = [c["n"] for c in chody]
        if obedu > 2 or len(nazvy) != len(set(nazvy)):
            print(f"  [{skola_id}] POZOR {den}: {len(chody)} chodů, {obedu} obědových položek – "
                  f"tahle škola možná nesedí do dvouchodového modelu, zkontrolujte ručně", file=sys.stderr)

    dny.update(nove)
    dny = {d: dny[d] for d in sorted(dny)}

    slozka.mkdir(parents=True, exist_ok=True)
    dny_soubor.write_text(json.dumps(dny, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    base_soubor = slozka / "base.json"
    base = json.loads(base_soubor.read_text(encoding="utf-8")) if base_soubor.exists() else {}
    base["updated"] = datetime.now(timezone(timedelta(hours=2))).isoformat(timespec="seconds")
    if dny:
        base["week"] = f"{min(dny)} – {max(dny)}"
    base_soubor.write_text(json.dumps(base, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(f"  [{skola_id}] archiv {pred} → {len(dny)} dní")
    return True


def main() -> int:
    registr = nacti_registr()
    cilove = [s for s in registr if s["zdroj"] == "jidelna.cz"]

    if "--all" in sys.argv:
        vybrane = cilove
    else:
        pozadovane = {a for a in sys.argv[1:] if not a.startswith("--")}
        if not pozadovane:
            print(__doc__)
            return 1
        vybrane = [s for s in cilove if s["id"] in pozadovane]
        chybejici = pozadovane - {s["id"] for s in vybrane}
        for cid in chybejici:
            print(f"  [{cid}] není v registru se zdrojem jidelna.cz – přeskakuji", file=sys.stderr)

    if not vybrane:
        print("Nic ke stažení.")
        return 1

    ok = True
    for i, s in enumerate(vybrane):
        if i:
            time.sleep(PAUZA_MEZI_SKOLAMI)
        ok = stahni_skolu(s["id"]) and ok

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
