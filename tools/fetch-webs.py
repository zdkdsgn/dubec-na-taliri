#!/usr/bin/env python3
"""Projde weby škol (web_url z info.json) a doplní, co chybí: telefon a dobu výdeje obědů.

    python3 tools/fetch-webs.py 47 30          # vybrané školy (ukáže výsledek, nic nezapíše: --zapsat)
    python3 tools/fetch-webs.py --chybejici    # všechny školy s webem, kterým něco chybí
    python3 tools/fetch-webs.py --chybejici --zapsat

Opatrnost: bere jen to, co je jednoznačné.
  • doba výdeje – jen časový rozsah do ~120 znaků za slovem „výdej“ (oběd) a rozumný (6–16 h);
  • telefon – nejdřív číslo hned u slov jídelna/kuchyně/stravování; jinak telefon školy z kontaktu
    (uloží se jako telefon_skola, ne jako telefon jídelny).
Co přišlo z webu, nese značku (telefon_zdroj / vydeje_zdroj = "web"), ať se to dá v appce přiznat.
Stránky se stahují slušně: jeden dotaz za chvíli na jeden server, max. 4 stránky na školu.
"""
import json, re, sys, time, urllib.parse, urllib.request
from concurrent.futures import ThreadPoolExecutor
from html import unescape
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HLAVICKY = {"User-Agent": "skola-na-taliri/1.0 (+https://github.com/zdkdsgn/dubec-na-taliri)"}
MAX_STRANEK = 4
TIMEOUT = 12
MAX_BAJTU = 1_500_000

TEL_RE = re.compile(r"(?<![\d])(?:\+?\s?420[\s.\-]?)?([1-9]\d{2})[\s.\-]?(\d{3})[\s.\-]?(\d{3})(?![\d])")
CAS_RE = re.compile(r"(?<!\d)(\d{1,2})[:.](\d{2})\s*(?:h|hod\.?)?\s*(?:-|–|—|až|do)\s*(\d{1,2})[:.](\d{2})(?!\d)")
ODKAZ_RE = re.compile(r'<a\s[^>]*href=["\']([^"\'#]+)["\'][^>]*>(.*?)</a>', re.S | re.I)
CIL_RE = re.compile(r"kontakt|jídeln|jideln|stravov|stravné|obědy|obed", re.I)


def stahni(url: str) -> str:
    req = urllib.request.Request(url, headers=HLAVICKY)
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        raw = r.read(MAX_BAJTU)
        kodovani = r.headers.get_content_charset() or "utf-8"
    try:
        return raw.decode(kodovani, errors="replace")
    except LookupError:
        return raw.decode("utf-8", errors="replace")


def text(html: str) -> str:
    html = re.sub(r"<(script|style|noscript)\b.*?</\1>", " ", html, flags=re.S | re.I)
    html = re.sub(r"<br\s*/?>|</(p|div|li|tr|h\d)>", "\n", html, flags=re.I)
    t = unescape(re.sub(r"<[^>]+>", " ", html))
    return re.sub(r"[ \t\xa0]+", " ", t)


def stranky(zaklad: str, html: str) -> list[str]:
    host = urllib.parse.urlparse(zaklad).netloc.lower().removeprefix("www.")
    out, videno = [], {zaklad.rstrip("/")}
    for href, popisek in ODKAZ_RE.findall(html):
        cil = urllib.parse.urljoin(zaklad, unescape(href.strip()))
        u = urllib.parse.urlparse(cil)
        if u.scheme not in ("http", "https") or u.netloc.lower().removeprefix("www.") != host:
            continue
        if re.search(r"\.(pdf|docx?|xlsx?|jpe?g|png|zip)$", u.path, re.I):
            continue
        if not CIL_RE.search(re.sub(r"<[^>]+>", " ", popisek) + " " + u.path):
            continue
        k = cil.split("#")[0].rstrip("/")
        if k not in videno:
            videno.add(k); out.append(k)
    # kontakt a jídelna dopředu
    out.sort(key=lambda u: (0 if re.search(r"jídeln|jideln|stravov", u, re.I) else 1 if "kontakt" in u.lower() else 2))
    return out[: MAX_STRANEK - 1]


def cislo(m) -> str:
    return f"{m.group(1)} {m.group(2)} {m.group(3)}"


def hledej_vydej(t: str):
    for m in re.finditer(r"výdej", t, re.I):
        okno = t[m.end(): m.end() + 120]
        if re.search(r"přesníd|svačin|večeř", okno[:60], re.I) and "oběd" not in okno[:60].lower():
            continue
        c = CAS_RE.search(okno)
        if not c:
            continue
        h1, m1, h2, m2 = map(int, c.groups())
        if 6 <= h1 <= 15 and 7 <= h2 <= 16 and m1 < 60 and m2 < 60 and (h1, m1) < (h2, m2) and (h2 - h1) <= 4:
            return f"{h1}:{m1:02d} - {h2}:{m2:02d}"
    return None


def hledej_telefon(t: str):
    jidelna = skola = None
    for m in TEL_RE.finditer(t):
        pred = t[max(0, m.start() - 60): m.start()].lower()
        if re.search(r"jídeln|jideln|kuchyn|stravov|vedoucí školní", pred):
            jidelna = jidelna or cislo(m)
        elif re.search(r"tel|mobil|fax", pred) and "fax" not in pred[-12:]:
            skola = skola or cislo(m)
    return jidelna, skola


PORTALY = ("jidelna.cz", "barda.cz")     # „web“ je u části škol jen přihlašovací portál dodavatele


def jeSkolniWeb(url: str) -> bool:
    host = urllib.parse.urlparse(url).netloc.lower().removeprefix("www.")
    return not any(host == p or host.endswith("." + p) for p in PORTALY)


def zpracuj(sid: str):
    p = ROOT / "schools" / sid / "info.json"
    info = json.loads(p.read_text(encoding="utf-8"))
    zaklad = info.get("web_url")
    nalez, chyba = {}, None
    try:
        html = stahni(zaklad)
        sebrano = [text(html)]
        for u in stranky(zaklad, html):
            time.sleep(0.8)
            try:
                sebrano.append(text(stahni(u)))
            except Exception:
                pass
        t = "\n".join(sebrano)
        if not info.get("vydeje"):
            v = hledej_vydej(t)
            if v:
                nalez["vydeje"] = [{"chod": "Oběd", "cas": v}]
        if not info.get("telefon"):
            j, s = hledej_telefon(t)
            if j:
                nalez["telefon"] = j
            elif s and not info.get("telefon_skola"):
                nalez["telefon_skola"] = s
    except Exception as e:
        chyba = str(e)[:80]
    return sid, info, nalez, chyba


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    zapsat = "--zapsat" in sys.argv
    if "--chybejici" in sys.argv:
        ids = []
        for p in sorted((ROOT / "schools").glob("*/info.json")):
            d = json.loads(p.read_text(encoding="utf-8"))
            if d.get("web_url") and jeSkolniWeb(d["web_url"]) and (not d.get("telefon") or not d.get("vydeje")):
                ids.append(p.parent.name)
    else:
        ids = args
    souhrn = {"vydeje": 0, "telefon": 0, "telefon_skola": 0, "chyb": 0}
    with ThreadPoolExecutor(max_workers=8) as pool:
        for sid, info, nalez, chyba in pool.map(zpracuj, ids):
            if chyba:
                souhrn["chyb"] += 1
            for k in nalez:
                souhrn[k] += 1
            if nalez:
                print(sid, info.get("web"), "→", json.dumps(nalez, ensure_ascii=False))
                if zapsat:
                    info.update(nalez)
                    if "vydeje" in nalez: info["vydeje_zdroj"] = "web"
                    if "telefon" in nalez: info["telefon_zdroj"] = "web"
                    (ROOT / "schools" / sid / "info.json").write_text(
                        json.dumps(info, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Hotovo: {len(ids)} škol", souhrn)


if __name__ == "__main__":
    main()
