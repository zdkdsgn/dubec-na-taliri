"""Klient pro iCanteen (Z-WARE) – veřejný jídelníček z přihlašovací stránky.

iCanteen nemá API, ale jídelníček je veřejně vidět přímo na přihlašovací
stránce jídelny, bez účtu:

    https://strav.nasejidelna.cz/<čtyřmístné číslo>/faces/login.jsp

Stejné rozhraní jako jidelna_client.py: stahni() → HTML, parsuj() → {ISO datum:
{"chody": [...]}} ve stejném tvaru, který appka už zná. Na stránce není
název školy (jen obrázek loga), ten se doplňuje ručně v schools/index.json.

ID škol z iCanteen mají v registru předponu "ic" ("ic0003"), ať se nepletou
s čísly z jidelna.cz.
"""
import re
import urllib.request
from datetime import date
from html import unescape
from typing import Optional

URL      = "https://strav.nasejidelna.cz/{n}/faces/login.jsp"
HLAVICKY = {"User-Agent": "skola-na-taliri/1.0 (+https://github.com/zdkdsgn/dubec-na-taliri)"}

DEN_RE     = re.compile(r'<div id="day-(\d{4}-\d{2}-\d{2})"[^>]*>(.*?)(?=<div id="day-|\Z)', re.S)
RADEK_RE   = re.compile(r'<div class="container">(.*?)(?=<div class="container">|</article>|\Z)', re.S)
SLOUPEC_RE = re.compile(r'<div class="(?:shrinkedColumn|column)[^"]*">(.*?)</div>', re.S)
ALERGEN_RE = re.compile(r'<sub>.*?</sub>', re.S)
CISLA_V_ZAVORCE_RE = re.compile(r'\(\s*\d{1,2}[a-z]?(?:\s*,\s*\d{1,2}[a-z]?)*\s*\)?')


def _stahni_url(url: str) -> str:
    req = urllib.request.Request(url, headers=HLAVICKY)
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read().decode("utf-8", errors="replace")


def stahni(cislo: str) -> str:
    return _stahni_url(URL.format(n=cislo))


def _text(html: str) -> str:
    return re.sub(r"\s+", " ", unescape(re.sub(r"<[^>]+>", " ", html))).strip()


def _alergeny(html: str) -> list[int]:
    sub = ALERGEN_RE.search(html)
    cisla = re.findall(r">\s*(\d{1,2})[a-z]?\s*</span>", sub.group()) if sub else []
    return sorted({int(c) for c in cisla})


def _kod_chodu(popisek: str) -> Optional[str]:
    p = popisek.lower()
    if p.startswith("polév"):       return "polevka"
    if p.startswith("oběd"):        return "obed"
    if p.startswith("přesníd"):     return "presnidavka"
    if p.startswith("svačin") or p.startswith("odpolední"): return "svacina"
    return None                     # večeře, nápoje… appka nezná


def parsuj(html: str) -> dict:
    dny = {}
    for iso, blok in DEN_RE.findall(html):
        try:
            date.fromisoformat(iso)
        except ValueError:
            continue
        chody, videno_obedu, prvni_misto = [], set(), None
        for radek in RADEK_RE.findall(blok):
            sloupce = SLOUPEC_RE.findall(radek)
            if len(sloupce) < 2:
                continue
            kod = _kod_chodu(_text(sloupce[0]))
            if not kod:
                continue
            # víc výdejen v jednom lístku (Sokolská/Štěpánská…): bereme první
            misto = _text(sloupce[1]) if len(sloupce) > 2 else None
            if misto:
                prvni_misto = prvni_misto or misto
                if misto != prvni_misto:
                    continue
            telo = sloupce[-1]
            cisla = _alergeny(telo)
            text = _text(ALERGEN_RE.sub("", telo))
            text = CISLA_V_ZAVORCE_RE.sub("", text)
            text = re.sub(r"\s+,", ",", text).strip(" ,")
            if not text:
                continue
            if kod != "obed":
                chody.append({"c": kod, "n": text, "d": "", "a": cisla})
                continue
            klic = text.lower()
            if klic in videno_obedu or klic.startswith("nevaří se"):
                continue
            videno_obedu.add(klic)
            cast = [c.strip() for c in text.split(",") if c.strip()]
            chody.append({"c": "obed" if len(videno_obedu) == 1 else "obed2",
                          "n": cast[0], "d": " · ".join(cast[1:]), "a": cisla, "_cast": cast})

        # Polévka na řádku oběda: když lístek nemá samostatný řádek Polévka a
        # všechny obědy začínají stejným kouskem, je to společná polévka.
        obedy = [c for c in chody if c["c"] in ("obed", "obed2")]
        if obedy and not any(c["c"] == "polevka" for c in chody) \
                and all(len(o["_cast"]) > 1 and o["_cast"][0] == obedy[0]["_cast"][0] for o in obedy):
            chody.insert(0, {"c": "polevka", "n": obedy[0]["_cast"][0], "d": "", "a": []})
            for o in obedy:
                o["_cast"] = o["_cast"][1:]
                o["n"], o["d"] = o["_cast"][0], " · ".join(o["_cast"][1:])
        for c in chody:
            c.pop("_cast", None)
        if chody:
            dny[iso] = {"chody": chody}
    return dny
