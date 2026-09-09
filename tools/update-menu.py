#!/usr/bin/env python3
"""Stáhne jídelníček ZŠ z jidelna.cz, doplní archiv a vygeneruje data.js.

    python3 tools/update-menu.py              # stáhne a přegeneruje
    python3 tools/update-menu.py --offline    # jen přegeneruje z menu/*.json

Zdroje dat:
    menu/base.json  meta, alergeny, chody         (ruční)
    menu/ms.json    jídelníček mateřské školy      (ruční – MŠ ho nikde nepublikuje)
    menu/zs.json    jídelníček základní školy      (generovaný, slouží zároveň jako archiv)

Výstup:
    data.js         to, co načítá aplikace

Skript nikdy nemaže dny, které už v archivu jsou. Když se stránka jídelny
změní tak, že z ní nic nepřečteme, skončí chybou a data nechá být – lepší
je hlasitá chyba než tiše zastaralý jídelníček.
"""

import json, re, sys, unicodedata, urllib.request
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

ROOT     = Path(__file__).resolve().parent.parent
JIDELNA  = 47
URL      = "https://www.jidelna.cz/jidelni-listek/?jidelna={j}&zacatek={od}&delka=P{dnu}D"
DNY_ZPET, DNY_VPRED = 7, 35

# Kuchyňské zkratky z jídelního lístku → čitelný text.
# Aplikují se po sjednocení mezer, takže "syp ." i "syp." padnou do stejného vzoru.
ZKRATKY = [
    (r"\bm[áa]s\.?\s*maš\.?",   "s máslem, mačkané"),
    (r"\bsyp\.\s*",             "sypané "),
    (r"\bdrožd\.\s*",           "droždovými "),
    (r"\bluštěni\.\s*",         "luštěninovými "),
    (r"\bzelenin\.\s*",         "zeleninový "),
    (r"\bbramb\.\s*",           "bramborový "),
    (r"\bsmet\.\s*",            "smetanový "),
    (r"\bse sýr\b(?!e)",         "se sýrem"),
    (r"\s+sýr\.\s*$",           ", sýr"),
]

MESICE_DNU = 31


# ──────────────────────────────────────────────────────── stažení a parsování

def stahni(od: date, dnu: int) -> str:
    url = URL.format(j=JIDELNA, od=od.isoformat(), dnu=dnu)
    req = urllib.request.Request(url, headers={"User-Agent": "dubec-na-taliri/1.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read().decode("utf-8", "replace")


def cisty_text(html: str) -> str:
    """HTML fragment → holý text."""
    t = re.sub(r"<[^>]+>", " ", html)
    t = (t.replace("&nbsp;", " ").replace("&amp;", "&")
          .replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", '"'))
    t = unicodedata.normalize("NFC", t)
    t = re.sub(r"\s+", " ", t).strip()
    return re.sub(r"\s+,", ",", t)


def uprav(text: str) -> str:
    """Zkratky, závorky místo lomítek, mezery, velké písmeno na začátku."""
    text = re.sub(r"\s+([.,])", r"\1", text)          # "syp ." → "syp."
    text = re.sub(r"/\s*([^/]+?)\s*/", r"(\1)", text)  # "ryba / hejk /" → "ryba (hejk)"
    for vzor, nahrada in ZKRATKY:
        text = re.sub(vzor, nahrada, text, flags=re.I)
    text = re.sub(r",(?=\S)", ", ", text)
    text = re.sub(r"\s-\s", " – ", text)          # "Zelenina - dresink" → pomlčka
    text = re.sub(r"\s+", " ", text).strip(" ,")
    return text[:1].upper() + text[1:] if text else text


DEN_RE   = re.compile(r'<div class="den container-fluid">(.*?)(?=<div class="den container-fluid">|<div class="oddelovacTydnu">|</main>)', re.S)
DATUM_RE = re.compile(r'<div class="datum[^"]*">\s*\w+\s+(\d{1,2})\.\s*(\d{1,2})\.\s*(\d{4})', re.S)
MENU_RE  = re.compile(r'<div class="menu row">(.*?)(?=<div class="menu row">|\Z)', re.S)
CISLO_RE = re.compile(r'nazevJidla[^>]*>\s*<p>\s*(\d+)\s*</p>', re.S)
RADEK_RE = re.compile(
    r'popiskaJidla">\s*(?P<popiska>[^<]+?)\s*</div>.*?'
    r'textJidla">(?P<text>.*?)</div>'
    r'(?:\s*<div[^>]*alergeny">(?P<alergeny>.*?)</div>)?', re.S)


def parsuj(html: str) -> dict:
    """HTML jídelního lístku → {ISO datum: [chod, ...]}"""
    dny = {}
    for blok in DEN_RE.findall(html):
        m = DATUM_RE.search(blok)
        if not m:
            continue
        d, mes, rok = (int(x) for x in m.groups())
        iso = date(rok, mes, d).isoformat()

        chody, polevka_hotova = [], False
        for menu_html in MENU_RE.findall(blok):
            cislo_m = CISLO_RE.search(menu_html)
            cislo   = int(cislo_m.group(1)) if cislo_m else 1

            jidlo, doplnky, alergeny = None, [], set()
            for r in RADEK_RE.finditer(menu_html):
                popiska = cisty_text(r.group("popiska"))
                text    = uprav(cisty_text(r.group("text")))
                cisla   = {int(x) for x in re.findall(r">\s*(\d{1,2})\s*</a>", r.group("alergeny") or "")}
                if not text:
                    continue

                if popiska.startswith("Polév"):
                    if not polevka_hotova:                    # u chodu 2 je stejná
                        chody.append({"c": "polevka", "n": text, "d": "", "a": sorted(cisla)})
                        polevka_hotova = True
                elif popiska.startswith("Jídlo"):
                    jidlo = text
                    alergeny |= cisla
                else:                                          # Příloha, Doplněk, Nápoj
                    doplnky.append(text)
                    alergeny |= cisla

            if jidlo:
                chody.append({
                    "c": "obed" if cislo == 1 else "obed2",
                    "n": jidlo,
                    "d": " · ".join(doplnky),   # příloha · doplněk · nápoj
                    "a": sorted(alergeny),
                })

        if chody:
            dny[iso] = chody
    return dny


# ────────────────────────────────────────────────────────────────── generátor

def js_hodnota(v, odsazeni=0):
    """JSON → čitelný JS (klíče bez uvozovek, pole chodů na jednom řádku)."""
    mezera = "  " * odsazeni
    if isinstance(v, dict):
        if not v:
            return "{}"
        radky = []
        for k, val in v.items():
            klic = k if re.fullmatch(r"[A-Za-z_]\w*", str(k)) else f'"{k}"'
            radky.append(f"{mezera}  {klic}: {js_hodnota(val, odsazeni + 1)}")
        return "{\n" + ",\n".join(radky) + f"\n{mezera}}}"
    if isinstance(v, list):
        if v and all(isinstance(x, dict) for x in v):
            return "[\n" + ",\n".join(
                f"{mezera}    {json.dumps(x, ensure_ascii=False)}" for x in v
            ) + f"\n{mezera}  ]"
        return json.dumps(v, ensure_ascii=False)
    return json.dumps(v, ensure_ascii=False)


def generuj_data_js(base, ms, zs) -> str:
    dny = {}
    for iso in sorted(set(ms) | set(zs)):
        z = {}
        if iso in zs: z["zs"] = zs[iso]
        if iso in ms: z["ms"] = ms[iso]
        dny[iso] = z

    obsah = {"meta": base["meta"], "allergens": base["allergens"],
             "courses": base["courses"], "days": dny}
    return (
        "/* ------------------------------------------------------------------\n"
        "   Dubeč na talíři — datová vrstva\n\n"
        "   GENEROVANÝ SOUBOR – needitujte ho ručně.\n"
        "   Zdroj: menu/base.json, menu/ms.json, menu/zs.json\n"
        "   Přegeneruje ho: python3 tools/update-menu.py\n"
        "------------------------------------------------------------------ */\n\n"
        "window.MENU_DATA = " + js_hodnota(obsah) + ";\n"
    )


# ─────────────────────────────────────────────────────────────────────── běh

def main() -> int:
    offline = "--offline" in sys.argv
    nacti   = lambda p: json.loads((ROOT / p).read_text(encoding="utf-8"))
    base, ms, zs = nacti("menu/base.json"), nacti("menu/ms.json"), nacti("menu/zs.json")
    pred = len(zs)

    if not offline:
        od = date.today() - timedelta(days=DNY_ZPET)
        html = stahni(od, DNY_ZPET + DNY_VPRED)
        nove = parsuj(html)
        if not nove:
            print("CHYBA: z jídelního lístku se nepodařilo přečíst žádný den.\n"
                  "       Stránka jidelna.cz nejspíš změnila strukturu – data nechávám beze změny.",
                  file=sys.stderr)
            return 1
        zmenene = [d for d, ch in nove.items() if zs.get(d) != ch]
        zs.update(nove)
        zs = {d: zs[d] for d in sorted(zs)}
        (ROOT / "menu/zs.json").write_text(
            json.dumps(zs, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"staženo {len(nove)} dní, změněno {len(zmenene)}, archiv {pred} → {len(zs)}")
        for d in zmenene:
            print(f"  • {d}: " + " / ".join(c["n"] for c in nove[d]))

        base["meta"]["updated"] = datetime.now(timezone(timedelta(hours=2))).isoformat(timespec="seconds")
        if zs:
            base["meta"]["week"] = f"{min(zs)} – {max(zs)}"
        (ROOT / "menu/base.json").write_text(
            json.dumps(base, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    (ROOT / "data.js").write_text(generuj_data_js(base, ms, zs), encoding="utf-8")
    print(f"data.js: {len(set(ms) | set(zs))} dní (ZŠ {len(zs)}, MŠ {len(ms)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
