#!/usr/bin/env python3
"""Neděle večer pošle push souhrn hlavních jídel na příští týden ("tenhle
týden vás čeká…") – nezávisle na denním /push/notify z update-menu.py,
který hlásí jen "nový jídelníček je venku". Spouští ho samostatný cron
v .github/workflows/tydenni-souhrn.yml.

Worker sám notifikaci nikam nepošle, pokud pro danou školu nikdo nemá
zapnutý odběr (viz /push/notify) – klidně tedy projedeme celý registr,
zbytečná volání jsou levná a bez efektu.

Vyžaduje NOTIFY_SECRET v prostředí (stejně jako notify-push.py).
"""
import json, os, sys
from datetime import date, timedelta
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

ROOT = Path(__file__).resolve().parent.parent
WORKER = "https://zs-jidelny.zdkdsgn.workers.dev/push/notify"
DOW_ZKR = ["Po", "Út", "St", "Čt", "Pá"]
MAX_DELKA_JIDLA = 22


def priste_pondeli() -> date:
    dnes = date.today()
    posun = (7 - dnes.weekday()) % 7
    return dnes + timedelta(days=posun or 7)


def zkrat(text: str, n: int = MAX_DELKA_JIDLA) -> str:
    text = text.strip()
    return text if len(text) <= n else text[: n - 1].rstrip() + "…"


def chody_pro_den(zaznam):
    """Sjednotí tři možné podoby jednoho dne v schools/<id>/days.json
    (viz stahniSkolu() v app.js – appka řeší totéž na klientovi)."""
    if zaznam is None:
        return []
    if isinstance(zaznam, list):
        return zaznam
    if "skupiny" in zaznam:
        skupina = zaznam["skupiny"].get("zs") or next(iter(zaznam["skupiny"].values()), {})
        return skupina.get("chody", [])
    return zaznam.get("chody", [])


def sestav_souhrn(dny_json: dict, tyden: list[date]) -> str:
    casti = []
    for i, den in enumerate(tyden):
        chody = chody_pro_den(dny_json.get(den.isoformat()))
        obed = next((c for c in chody if c.get("c") == "obed"), None)
        if obed and obed.get("n"):
            casti.append(f"{DOW_ZKR[i]}: {zkrat(obed['n'])}")
    return " · ".join(casti)


def main():
    tajemstvi = os.environ.get("NOTIFY_SECRET", "")
    if not tajemstvi:
        print("weekly-digest: chybí NOTIFY_SECRET, přeskakuji", file=sys.stderr)
        return

    tyden = [priste_pondeli() + timedelta(days=i) for i in range(5)]
    nadpis_tyden = f"{tyden[0].day}. {tyden[0].month}. – {tyden[-1].day}. {tyden[-1].month}."

    registr = json.loads((ROOT / "schools" / "index.json").read_text(encoding="utf-8"))
    schools = []
    for polozka in registr:
        soubor = ROOT / "schools" / polozka["id"] / "days.json"
        if not soubor.exists():
            continue
        dny = json.loads(soubor.read_text(encoding="utf-8"))
        souhrn = sestav_souhrn(dny, tyden)
        if not souhrn:
            continue
        schools.append({
            "id": polozka["id"],
            "nazev": polozka.get("kratky") or polozka["nazev"],
            "title": f"Škola na talíři · týden {nadpis_tyden}",
            "body": souhrn,
        })

    if not schools:
        print("weekly-digest: žádná škola nemá data na příští týden, nic neposílám")
        return

    body = json.dumps({"schools": schools}).encode("utf-8")
    req = Request(WORKER, data=body, method="POST", headers={
        "Content-Type": "application/json",
        "X-Notify-Secret": tajemstvi,
        "User-Agent": "dubec-na-taliri-github-action/1.0",
    })
    try:
        with urlopen(req, timeout=25) as r:
            print("weekly-digest:", r.read().decode("utf-8"))
    except (URLError, HTTPError) as e:
        # Souhrn není kritická část provozu – chyba tu appku nemá zastavit.
        print(f"weekly-digest: worker se nepodařilo zavolat ({e}) – necháno být", file=sys.stderr)


if __name__ == "__main__":
    main()
