#!/usr/bin/env python3
"""Pošle worker.js pokyn k rozeslání push notifikací ("nový jídelníček
je venku") pro školy, jejichž schools/<id>/ se v tomhle běhu GitHub
Actions opravdu změnilo.

    python3 tools/notify-push.py 47 304 ms-dubec

ID škol dostává jako argumenty (typicky z `git diff --name-only`).
Vyžaduje proměnnou prostředí NOTIFY_SECRET – stejnou hodnotu, jakou má
worker jako secret (`wrangler secret put NOTIFY_SECRET`). Bez ní, nebo
bez zadaných ID, skript jen tiše skončí – notifikace nejsou kritická
část nasazení, appka funguje i bez nich.
"""
import json, os, sys
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

ROOT = Path(__file__).resolve().parent.parent
WORKER = "https://zs-jidelny.zdkdsgn.workers.dev/push/notify"


def main():
    ids = sys.argv[1:]
    if not ids:
        print("notify-push: žádné změněné školy, nic neposílám")
        return

    tajemstvi = os.environ.get("NOTIFY_SECRET", "")
    if not tajemstvi:
        print("notify-push: chybí NOTIFY_SECRET, přeskakuji", file=sys.stderr)
        return

    registr = {s["id"]: s for s in json.loads((ROOT / "schools" / "index.json").read_text(encoding="utf-8"))}
    schools = []
    for sid in ids:
        polozka = registr.get(sid)
        if not polozka:
            continue
        schools.append({"id": sid, "nazev": polozka.get("kratky") or polozka["nazev"]})

    if not schools:
        print("notify-push: žádné ze změněných ID není v registru, nic neposílám")
        return

    body = json.dumps({"schools": schools}).encode("utf-8")
    req = Request(WORKER, data=body, method="POST", headers={
        "Content-Type": "application/json",
        "X-Notify-Secret": tajemstvi,
        # Bez vlastního User-Agentu blokuje Cloudflare výchozí
        # "Python-urllib/…" hlavičku ještě předtím, než dotaz vůbec
        # dorazí do workeru (403 rovnou z edge, ne z naší logiky).
        "User-Agent": "dubec-na-taliri-github-action/1.0",
    })
    try:
        with urlopen(req, timeout=20) as r:
            print("notify-push:", r.read().decode("utf-8"))
    except (URLError, HTTPError) as e:
        # Notifikace nejsou kritická část nasazení – chyba tu appku nemá zastavit.
        print(f"notify-push: worker se nepodařilo zavolat ({e}) – necháno být", file=sys.stderr)


if __name__ == "__main__":
    main()
