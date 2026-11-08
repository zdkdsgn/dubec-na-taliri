#!/usr/bin/env python3
"""Doplní do schools/<id>/info.json údaje z rejstříku škol a školských zařízení MŠMT
(otevřená data, zdroj: MŠMT): jméno ředitele/ky a – když jídelna e-mail nezveřejnila – e-mail školy.
Páruje se přes IČO (z info.json). Nic jiného nepřepisuje.

    python3 tools/merge-rejstrik.py              # stáhne nejnovější celostátní soubor
    python3 tools/merge-rejstrik.py soubor.jsonld

Soubor se vydává čtvrtletně; adresu nejnovějšího dohledá v katalogu data.gov.cz (SPARQL).
"""
import json, re, sys, urllib.parse, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HLAVICKY = {"User-Agent": "skola-na-taliri/1.0 (+https://github.com/zdkdsgn/dubec-na-taliri)"}
SPARQL = "https://data.gov.cz/sparql"
EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[a-z]{2,}$", re.I)


def nejnovejsi_url() -> str:
    q = ('PREFIX dcat: <http://www.w3.org/ns/dcat#> PREFIX dcterms: <http://purl.org/dc/terms/> '
         'SELECT ?u WHERE { ?d a dcat:Dataset ; dcterms:title ?t ; dcat:distribution ?x . ?x dcat:downloadURL ?u . '
         'FILTER(CONTAINS(LCASE(STR(?t)),"rejstřík škol") && CONTAINS(LCASE(STR(?t)),"celá čr") && CONTAINS(STR(?u),"rssz-cela-cr-")) }')
    req = urllib.request.Request(SPARQL + "?" + urllib.parse.urlencode({"query": q}),
                                 headers={**HLAVICKY, "Accept": "application/sparql-results+json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        urls = [b["u"]["value"] for b in json.load(r)["results"]["bindings"]]
    datum = lambda u: (re.search(r"(\d{4}-\d{2}-\d{2})\.jsonld$", u) or [None, ""])[1]
    return max(urls, key=datum)


def nacti(zdroj: str) -> list:
    if Path(zdroj).exists():
        return json.loads(Path(zdroj).read_text(encoding="utf-8"))["list"]
    req = urllib.request.Request(zdroj, headers=HLAVICKY)
    with urllib.request.urlopen(req, timeout=300) as r:
        return json.loads(r.read().decode("utf-8"))["list"]


def main():
    zdroj = sys.argv[1] if len(sys.argv) > 1 else nejnovejsi_url()
    print("Zdroj:", zdroj)
    podle_ico = {x["ico"].zfill(8): x for x in nacti(zdroj) if x.get("ico")}
    registr = json.loads((ROOT / "schools" / "index.json").read_text(encoding="utf-8"))
    zmen = {"reditel": 0, "email": 0}
    for s in registr:
        p = ROOT / "schools" / s["id"] / "info.json"
        if not p.exists():
            continue
        info = json.loads(p.read_text(encoding="utf-8"))
        ico = re.sub(r"\D", "", info.get("ico", ""))
        r = podle_ico.get(ico.zfill(8)) if ico else None
        if not r:
            continue
        puvodni = dict(info)
        jmeno = ((r.get("reditel") or {}).get("nazevOsoby") or "").strip()
        if jmeno:
            info["reditel"] = jmeno
        if not info.get("email") or info.get("email_zdroj") == "rejstrik":
            emaily = [e.strip() for e in r.get("emaily") or [] if EMAIL_RE.match(e.strip())]
            if emaily:
                info["email"], info["email_zdroj"] = emaily[0], "rejstrik"
        if info != puvodni:
            zmen["reditel"] += "reditel" in info and info.get("reditel") != puvodni.get("reditel")
            zmen["email"] += info.get("email") != puvodni.get("email")
            p.write_text(json.dumps(info, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Doplněno:", zmen)


if __name__ == "__main__":
    main()
