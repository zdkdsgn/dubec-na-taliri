#!/usr/bin/env python3
"""Odhad podílu systémů školních jídelníčků: náhodný vzorek MŠ a ZŠ z rejstříku MŠMT.

    python3 tools/vzorek-systemu.py rssz.jsonld [počet=300] [seed=1]

Web školy se odhadne z domény e-mailu (bez freemailů), stáhne se úvodní stránka a až 3 podstránky
s „jídeln/stravov/kontakt“ a hledají se značky systémů (odkazy, názvy). Výstup: tabulka podílů a
seznam do tools/../menu/vzorek-systemu.json. Slušné dotazy (pauza, User-Agent), nic se nezapisuje do registru.
"""
import json, random, re, sys, time, urllib.parse, urllib.request
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HLAV = {"User-Agent": "skola-na-taliri/1.0 (+https://github.com/zdkdsgn/dubec-na-taliri)"}
FREEMAIL = {"seznam.cz","email.cz","centrum.cz","gmail.com","volny.cz","post.cz","atlas.cz","tiscali.cz","quick.cz","icloud.com","outlook.com","hotmail.com","yahoo.com","najdi.to","iol.cz","c-box.cz"}
SYSTEMY = [
    ("jidelna.cz", r"jidelna\.cz|objednavky\.jidelna|jídelna\.cz"),
    ("strava.cz", r"strava\.cz"),
    ("iCanteen", r"nasejidelna\.cz|icanteen|i-canteen"),
    ("eStrava/Ulrich", r"estrava|ulrich"),
    ("jiný systém (dobrajidelna, e-jidelna…)", r"dobrajidelna|e-jidelna|webjidelna|stravovani\.eu|jidelnicek\.eu"),
]


def stahni(u, t=12):
    r = urllib.request.Request(u, headers=HLAV)
    with urllib.request.urlopen(r, timeout=t) as x:
        return x.read(900_000).decode(x.headers.get_content_charset() or "utf-8", "replace")


def web(email):
    d = email.split("@")[-1].lower()
    return None if d in FREEMAIL else d


def zkus(x):
    host = x["web"]; texty = []
    for pre in ("https://www.", "https://", "http://www."):
        try:
            h = stahni(pre + host); base = pre + host; texty.append(h); break
        except Exception:
            h = None
    if not texty:
        return {**x, "stav": "web_nedostupny", "systemy": []}
    odk = re.findall(r'href=["\']([^"\'#]+)["\']', texty[0])
    cile = [urllib.parse.urljoin(base + "/", a) for a in odk if re.search(r"jideln|stravov|jidelnic|obedy|kontakt", a, re.I)]
    for u in list(dict.fromkeys(cile))[:5]:
        if host.split(".")[0] in u:
            try: time.sleep(0.5); texty.append(stahni(u))
            except Exception: pass
    t = "\n".join(texty).lower()
    nalez = [n for n, rx in SYSTEMY if re.search(rx, t)]
    vlastni = bool(re.search(r"jídeln[íi]č|jidelnic", t)) and not nalez
    return {**x, "stav": "ok", "systemy": nalez, "vlastni_jidelnicek": vlastni}


def main():
    zdroj = sys.argv[1]; n = int(sys.argv[2]) if len(sys.argv) > 2 else 300
    random.seed(int(sys.argv[3]) if len(sys.argv) > 3 else 1)
    data = json.loads(Path(zdroj).read_text(encoding="utf-8"))["list"]
    kand = []
    for s in data:
        druhy = {z["druh"] for z in s["skolyAZarizeni"]}
        if not druhy & {"A00", "B00"}: continue
        w = next((web(e) for e in s.get("emaily") or [] if web(e)), None)
        kand.append({"ico": s["ico"], "nazev": s["zkracenyNazev"], "web": w, "kraj": s["kraj"]})
    vz = random.sample(kand, min(n, len(kand)))
    s_webem = [x for x in vz if x["web"]]
    print(f"Vzorek {len(vz)} MŠ/ZŠ, z nich {len(s_webem)} s odhadnutým webem (zbytek: freemail/bez e-mailu)")
    with ThreadPoolExecutor(max_workers=10) as p:
        vys = list(p.map(zkus, s_webem))
    ok = [v for v in vys if v["stav"] == "ok"]
    c = Counter()
    for v in ok:
        if v["systemy"]:
            for s in v["systemy"]: c[s] += 1
        elif v["vlastni_jidelnicek"]: c["vlastní web (jídelníček na webu školy)"] += 1
        else: c["nenalezeno"] += 1
    print(f"Web odpověděl u {len(ok)}, nedostupný u {len(vys) - len(ok)}")
    for k, v in c.most_common(): print(f"  {k:44} {v:4}  {v / len(ok):5.0%}")
    (ROOT / "menu").mkdir(exist_ok=True)
    (ROOT / "menu" / "vzorek-systemu.json").write_text(json.dumps(
        {"vzorek": len(vz), "s_webem": len(s_webem), "odpovedelo": len(ok), "podily": dict(c), "skoly": vys},
        ensure_ascii=False, indent=1), encoding="utf-8")


if __name__ == "__main__":
    main()
