#!/usr/bin/env python3
"""Stáhne kontakty a doby výdejů škol z jidelna.cz (stránka /kontakty/) do
schools/<id>/info.json. Appka je ukazuje v sekci „O jídelně“.

    python3 tools/fetch-info.py 10 47       # vybrané školy
    python3 tools/fetch-info.py --all       # celý registr (jidelna.cz)

Soubor se přepíše jen když se obsah změnil, ať v gitu nevznikají zbytečné commity.
"""
import json, re, sys, time
from html import unescape
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from jidelna_client import _stahni_url

ROOT = Path(__file__).resolve().parent.parent
URL = "https://www.jidelna.cz/kontakty/?jidelna={j}"
PAUZA = 0.5

POLE = {            # popisek na stránce → klíč v info.json
    "Adresa": "adresa", "PSČ": "psc", "Kraj": "kraj", "IČO": "ico",
    "Telefon": "telefon", "Vedoucí jídelny": "vedouci_jidelny",
    "Vedoucí kuchyně": "vedouci_kuchyne", "Bankovní spojení": "ucet",
    "WWW": "web", "E-mail": "email",
}


def _text(html: str) -> str:
    html = re.sub(r"<br\s*/?>", ", ", html)
    t = re.sub(r"\s+", " ", unescape(re.sub(r"<[^>]+>", " ", html))).strip(" ,")
    return re.sub(r"\s+,", ",", t)


def _dvojice(blok: str) -> list[tuple[str, str]]:
    return [(_text(a), d) for a, d in re.findall(r"<dt>(.*?)</dt>\s*<dd>(.*?)</dd>", blok, re.S)]


def parsuj(html: str) -> dict:
    info = {}
    m = re.search(r"<h4>Kontakty</h4>\s*<dl[^>]*>(.*?)</dl>", html, re.S)
    for popisek, hodnota in (_dvojice(m.group(1)) if m else []):
        klic = POLE.get(popisek)
        text = _text(hodnota)
        if klic == "telefon" and re.fullmatch(r"\d{9}", text):
            text = f"{text[:3]} {text[3:6]} {text[6:]}"
        if klic and text:
            info[klic] = text
    if "web" in info and not info["web"].startswith("http"):
        info["web_url"] = "https://" + info["web"]
    elif "web" in info:
        info["web_url"] = info["web"]
    m = re.search(r"<h4>Doby výdejů</h4>\s*<dl[^>]*>(.*?)</dl>", html, re.S)
    vydeje = [{"chod": p, "cas": _text(h)} for p, h in (_dvojice(m.group(1)) if m else []) if _text(h)]
    if vydeje:
        info["vydeje"] = vydeje
    return info


def stahni_info(skola_id: str) -> bool:
    try:
        info = parsuj(_stahni_url(URL.format(j=skola_id)))
    except Exception as e:                      # síť/server – staré info nech být
        print(f"[{skola_id}] chyba: {e}", file=sys.stderr)
        return False
    if not info:
        return True
    soubor = ROOT / "schools" / skola_id / "info.json"
    soubor.parent.mkdir(parents=True, exist_ok=True)
    novy = json.dumps(info, ensure_ascii=False, indent=2) + "\n"
    if not soubor.exists() or soubor.read_text(encoding="utf-8") != novy:
        soubor.write_text(novy, encoding="utf-8")
        print(f"[{skola_id}] info aktualizováno")
    return True


def main():
    args = sys.argv[1:]
    if args == ["--all"]:
        registr = json.loads((ROOT / "schools" / "index.json").read_text(encoding="utf-8"))
        ids = [s["id"] for s in registr if s.get("zdroj") == "jidelna.cz"]
    else:
        ids = args
    chyby = 0
    for i, sid in enumerate(ids):
        if i:
            time.sleep(PAUZA)
        chyby += not stahni_info(sid)
    print(f"Hotovo: {len(ids)} škol, chyb {chyby}")


if __name__ == "__main__":
    main()
