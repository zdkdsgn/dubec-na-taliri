"""Sdílený klient pro jidelna.cz – používá jak jednoškolní update-menu.py,
tak nástroje pro víc škol (fetch-school.py, search-schools.py).

Jídelníček:
    stahni(jidelna_id, od, dnu) -> HTML
    parsuj(html) -> {ISO datum: {"vydej": "11:30–13:45", "chody": [...]}}

Vyhledávání škol (server-side – jidelna.cz nesídlí CORS hlavičky, takže
tohle NEJDE volat přímo z appky v prohlížeči, jen odsud nebo z GitHub
Actions):
    hledej(dotaz) -> [{"id": "47", "nazev": "..."}]
"""
import re
import unicodedata
import urllib.parse
import urllib.request
from datetime import date
from typing import Optional

JIDELNI_LISTEK_URL = "https://www.jidelna.cz/jidelni-listek/?jidelna={j}&zacatek={od}&delka=P{dnu}D"
HLEDEJ_URL          = "https://www.jidelna.cz/vyhledej/jidelny/?q={q}"
HLAVICKY            = {"User-Agent": "dubec-na-taliri/1.0 (+https://github.com/zdkdsgn/dubec-na-taliri)"}


def _stahni_url(url: str) -> str:
    req = urllib.request.Request(url, headers=HLAVICKY)
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read().decode("utf-8", "replace")


def stahni(jidelna_id: int, od: date, dnu: int) -> str:
    """Stáhne HTML jídelního lístku jedné jídelny za dané období."""
    return _stahni_url(JIDELNI_LISTEK_URL.format(j=jidelna_id, od=od.isoformat(), dnu=dnu))


def hledej(dotaz: str) -> list[dict]:
    """Vyhledá jídelny podle názvu/ulice. Vrátí seznam nalezených škol –
    prázdný, když nic nesedí, i když je toho moc (jidelna.cz pak jen řekne
    "upřesněte vyhledávání", což pro nás znamená totéž jako "nic použitelného").

    Pozor: jidelna.cz eviduje jen školy, které používají jejich software –
    nejde o vyčerpávající seznam všech škol v ČR, jen jejich zákazníky.
    """
    html = _stahni_url(HLEDEJ_URL.format(q=urllib.parse.quote(dotaz)))
    return [
        {"id": jidelna_id, "nazev": cisty_text(nazev)}
        for jidelna_id, nazev in re.findall(
            r'<a href="/jidelni-listek/\?jidelna=(\d+)">([^<]+)</a>', html
        )
    ]


# ──────────────────────────────────────────────────────── čištění textu

# Kuchyňské zkratky z jídelního lístku → čitelný text.
# Aplikují se po sjednocení mezer, takže "syp ." i "syp." padnou do stejného vzoru.
ZKRATKY = [
    (r"\bm[áa]s\.?\s*maš\.?", "s máslem, mačkané"),
    (r"\bsyp\.\s*",           "sypané "),
    (r"\bdrožd\.\s*",         "droždovými "),
    (r"\bluštěni\.\s*",       "luštěninovými "),
    (r"\bzelenin\.\s*",       "zeleninový "),
    (r"\bbramb\.\s*",         "bramborový "),
    (r"\bsmet\.\s*",          "smetanový "),
    (r"\bse sýr\b(?!e)",      "se sýrem"),
    (r"\s+sýr\.\s*$",         ", sýr"),
]


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
    text = re.sub(r"\s+([.,])", r"\1", text)            # "syp ." → "syp."
    text = re.sub(r"/\s*([^/]+?)\s*/", r"(\1)", text)   # "ryba / hejk /" → "ryba (hejk)"
    for vzor, nahrada in ZKRATKY:
        text = re.sub(vzor, nahrada, text, flags=re.I)
    text = re.sub(r",(?=\S)", ", ", text)
    text = re.sub(r"\s-\s", " – ", text)                # "Zelenina - dresink" → pomlčka
    text = re.sub(r"\s+", " ", text).strip(" ,")
    return text[:1].upper() + text[1:] if text else text


# ──────────────────────────────────────────────────────────── parsování

DEN_RE     = re.compile(r'<div class="den container-fluid">(.*?)(?=<div class="den container-fluid">|<div class="oddelovacTydnu">|</main>)', re.S)
DATUM_RE   = re.compile(r'<div class="datum[^"]*">\s*\w+\s+(\d{1,2})\.\s*(\d{1,2})\.\s*(\d{4})', re.S)
VYDEJ_RE   = re.compile(r'<div class="datum[^"]*">.*?\(\s*(\d{1,2}:\d{2})\s*(?:-|–|&nbsp;-&nbsp;)\s*(\d{1,2}:\d{2})\s*\)', re.S)
CASTDNE_RE = re.compile(r'<div class="castDne row">(.*?)(?=<div class="castDne row">|<div class="oddelovacTydnu">|</main>|\Z)', re.S)
NADPIS_RE  = re.compile(r'<div class="hlavicka row">\s*([^<]+?)\s*</div>', re.S)
NADPIS_CAS_RE = re.compile(r'\((\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})\)')
MENU_RE    = re.compile(r'<div class="menu row">(.*?)(?=<div class="menu row">|\Z)', re.S)
CISLO_RE   = re.compile(r'nazevJidla[^>]*>\s*<p>\s*(\d+)\s*</p>', re.S)
RADEK_RE = re.compile(
    r'popiskaJidla">\s*(?P<popiska>[^<]+?)\s*</div>.*?'
    r'textJidla">(?P<text>.*?)</div>'
    r'(?:\s*<div[^>]*alergeny">(?P<alergeny>.*?)</div>)?', re.S)

# Text před závorkou s časem, ať jde poznat "Oběd"/"Přesnídávka"/"Svačina"
# i s libovolnou skupinou za ním (MŠ/ZŠ/nic).
KURZ_RE = {
    "presnidavka": re.compile(r'^Přesnídávka', re.I),
    "svacina":     re.compile(r'^(Odpolední\s+)?Svačina', re.I),
    "obed":        re.compile(r'^Oběd', re.I),
}


def _skupina_z_nadpisu(text: str) -> Optional[str]:
    """'Oběd ZŠ (11:00 - 14:00)' → 'zs'; 'Přesnídávka MŠ (...)' → 'ms';
    bez skupiny (jednostopá škola jako ZŠ Dubeč) → None."""
    if re.search(r'\bMŠ\b', text): return "ms"
    if re.search(r'\bZŠ\b', text): return "zs"
    return None


def _alergeny_z_odkazu(html: str) -> list[int]:
    """'1' i jemnější 'obiloviny' varianty typu '1a'/'1d' (pšenice/oves) –
    appka zná jen základních 14 čísel, písmenko se zahodí a čísla ať se
    sečtou do stejné množiny."""
    return sorted({int(re.match(r'\d{1,2}', x).group()) for x in
                   re.findall(r'>\s*(\d{1,2}[a-z]?)\s*</a>', html)})


def _zpracuj_menu_bloky(usek_html: str, kurz: str) -> list[dict]:
    """Rozparsuje 'menu row' bloky v jednom úseku (jeden chod dne pro jednu
    skupinu). U oběda může být víc číslovaných chodů (1, 2 – jídlo A/B),
    u přesnídávky/svačiny bývá jen jeden."""
    chody, polevka_hotova = [], False
    for menu_html in MENU_RE.findall(usek_html):
        cislo_m = CISLO_RE.search(menu_html)
        cislo   = int(cislo_m.group(1)) if cislo_m else 1

        jidlo, polozky = None, []
        for r in RADEK_RE.finditer(menu_html):
            popiska = cisty_text(r.group("popiska"))
            text    = uprav(cisty_text(r.group("text")))
            cisla   = _alergeny_z_odkazu(r.group("alergeny") or "")
            if not text:
                continue

            if popiska.startswith("Polév") and kurz == "obed":
                if not polevka_hotova:                    # u druhého chodu je stejná
                    chody.append({"c": "polevka", "n": text, "d": "", "a": cisla})
                    polevka_hotova = True
            elif popiska.startswith("Jídlo"):
                jidlo = {"l": "Jídlo", "n": text, "a": cisla}
            else:                                          # Příloha, Doplněk, Nápoj
                polozky.append({"l": popiska, "n": text, "a": cisla})

        if jidlo:
            vsechny = [jidlo] + polozky
            kod = kurz if kurz != "obed" else ("obed" if cislo == 1 else "obed2")
            chody.append({
                "c": kod,
                "n": jidlo["n"],
                "d": " · ".join(p["n"] for p in polozky),
                "a": sorted({a for p in vsechny for a in p["a"]}),
                "p": vsechny,
            })
    return chody


def parsuj(html: str) -> dict:
    """HTML jídelního lístku → {ISO datum: záznam dne}.

    Jednostopá škola (ZŠ Dubeč a většina ostatních – jeden "castDne" bez
    vlastního podnadpisu): {"vydej": "11:30–13:45", "chody": [...]}
    – přesně dosavadní tvar, appka pro Dubeč se tímhle nemění.

    Vícestopá škola (spojená ZŠ+MŠ na jedné stránce, kde "castDne" bloky
    mají vlastní podnadpisy "Oběd ZŠ (11:00-14:00)", "Přesnídávka MŠ (…)"
    apod.): {"skupiny": {"zs": {"vydej":…, "chody":[…]}, "ms": {…}}}
    – appka pak pro takovou školu umí ukázat stejný ZŠ/MŠ přepínač jako
    u Dubče, místo aby přesnídávku a oběd popletla dohromady.

    U hlavního chodu si necháváme položky rozepsané (jídlo, příloha, doplněk,
    nápoj) i s jejich vlastními alergeny – appka pak v detailu umí říct, jestli
    je mléko v jídle, nebo jen v nápoji, který se dá vynechat.
    """
    dny = {}
    for blok in DEN_RE.findall(html):
        m = DATUM_RE.search(blok)
        if not m:
            continue
        d, mes, rok = (int(x) for x in m.groups())
        iso = date(rok, mes, d).isoformat()

        v = VYDEJ_RE.search(blok)
        vydej_dne = f"{v.group(1)}–{v.group(2)}" if v else None

        skupiny = {}   # type: dict[str, dict]
        for usek in CASTDNE_RE.findall(blok):
            nadpis_m = NADPIS_RE.search(usek)
            nadpis   = nadpis_m.group(1) if nadpis_m else ""

            kurz = next((k for k, vzor in KURZ_RE.items() if vzor.match(nadpis)), "obed")
            skupina = _skupina_z_nadpisu(nadpis) or "zs"

            cas_m = NADPIS_CAS_RE.search(nadpis)
            vydej_useku = f"{cas_m.group(1)}–{cas_m.group(2)}" if cas_m else vydej_dne

            nove_chody = _zpracuj_menu_bloky(usek, kurz)
            if not nove_chody:
                continue

            zaznam = skupiny.setdefault(skupina, {"vydej": None, "chody": []})
            zaznam["chody"].extend(nove_chody)
            if kurz == "obed":       # "Výdej" v appce vždy znamená oběd, ne přesnídávku/svačinu
                zaznam["vydej"] = vydej_useku

        if not skupiny:
            continue

        if list(skupiny) == ["zs"]:                     # jednostopá škola – starý tvar
            zaznam = skupiny["zs"]
            dny[iso] = {"vydej": zaznam["vydej"], "chody": zaznam["chody"]} if zaznam["vydej"] \
                       else {"chody": zaznam["chody"]}
        else:                                            # víc skupin na stránce
            dny[iso] = {"skupiny": skupiny}
    return dny
