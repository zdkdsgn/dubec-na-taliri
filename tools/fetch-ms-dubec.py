#!/usr/bin/env python3
"""Stáhne jídelníček MŠ Dubeč z jejího vlastního webu (msdubec.cz) –
jediná škola v registru, co není na jidelna.cz, takže ji fetch-school.py
přeskakuje (zdroj "msdubec.cz", ne "jidelna.cz").

    python3 tools/fetch-ms-dubec.py

Stejná konvence jako fetch-school.py: nikdy nemaže dny, co v archivu
už jsou, jen doplňuje/přepisuje ty nově přečtené.

Web nemá žádné API ani strukturovaný export – text jídelníčku je
narváný v <strong>/<br> značkách bez tříd nebo id, na které by šlo
spolehlivě zacílit. Takže: postáhnout celou stránku, servrolovat
značky pryč a hledat vzor "Pondělí 7.9.2026" + "Přesnídávka: … (A …)"
v čistém textu. Křehčí než jidelna_client.py – když MŠ web předělají,
tenhle skript přestane něco najít a skončí chybou (radši nahlas, než
tiše nic nezapsat)."""
import html as htmllib
import json
import re
import sys
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKOLA_ID = "ms-dubec"
URL = "https://www.msdubec.cz/stranka-jidelnicek-45"
HLAVICKA = {"User-Agent": "dubec-na-taliri/1.0 (+https://github.com/zdkdsgn/dubec-na-taliri)"}

CHODY = [("Přesnídávka", "presnidavka"), ("Polévka", "polevka"),
         ("Hlavní chod", "obed"), ("Svačina", "svacina")]


def stahni_text() -> str:
    req = urllib.request.Request(URL, headers=HLAVICKA)
    with urllib.request.urlopen(req, timeout=30) as r:
        raw = r.read().decode("utf-8", "replace")
    text = re.sub(r"<[^>]+>", " ", raw)
    text = htmllib.unescape(text)
    return re.sub(r"\s+", " ", text).strip()


def rozeber_chod(text_chodu: str) -> dict:
    """'Kaiserka,pomazánka Budapešť,banán,čaj (A 1,7)' → {n, d, a}."""
    m = re.search(r"\(A\s*([\d,\s]*)\)", text_chodu)
    alergeny = sorted({int(x) for x in re.findall(r"\d+", m.group(1))}) if m else []
    obsah = text_chodu[: m.start()].strip() if m else text_chodu.strip()
    casti = [c.strip() for c in obsah.split(",") if c.strip()]
    nazev = casti[0] if casti else obsah
    popis = ", ".join(casti[1:])
    return {"n": nazev, "d": popis, "a": alergeny}


def parsuj(text: str) -> dict:
    hlavicky = list(re.finditer(
        r"(Pondělí|Úterý|Středa|Čtvrtek|Pátek)\s+(\d{1,2})\.(\d{1,2})\.(\d{4})", text))
    if not hlavicky:
        raise RuntimeError("na stránce nejde najít žádný den (Pondělí DD.MM.RRRR …) – web se asi změnil")

    dny = {}
    for i, m in enumerate(hlavicky):
        d, mes, rok = int(m.group(2)), int(m.group(3)), int(m.group(4))
        konec = hlavicky[i + 1].start() if i + 1 < len(hlavicky) else len(text)
        blok = text[m.end():konec]

        # Rozdělíme blok dne podle labelů chodů – jednodušší a spolehlivější
        # než počítat pozice ručně.
        chody = []
        vzor = "|".join(re.escape(l) for l, _ in CHODY)
        kusy = re.split(f"(?:{vzor}):", blok)
        nalezene_labely = re.findall(f"(?:{vzor}):", blok)
        for label_s_dvojteckou, obsah in zip(nalezene_labely, kusy[1:]):
            label = label_s_dvojteckou[:-1]
            kod = dict(CHODY)[label]
            chody.append({"c": kod, **rozeber_chod(obsah)})

        iso = f"{rok:04d}-{mes:02d}-{d:02d}"
        dny[iso] = chody
    return dny


def main() -> int:
    try:
        text = stahni_text()
        nove = parsuj(text)
    except Exception as e:
        print(f"  [{SKOLA_ID}] CHYBA: {e} – data nechávám beze změny", file=sys.stderr)
        return 1

    slozka = ROOT / "schools" / SKOLA_ID
    dny_soubor = slozka / "days.json"
    dny = json.loads(dny_soubor.read_text(encoding="utf-8")) if dny_soubor.exists() else {}
    pred = len(dny)
    dny.update(nove)
    dny = {d: dny[d] for d in sorted(dny)}

    slozka.mkdir(parents=True, exist_ok=True)
    dny_soubor.write_text(json.dumps(dny, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    base_soubor = slozka / "base.json"
    base = json.loads(base_soubor.read_text(encoding="utf-8")) if base_soubor.exists() else {}
    base["updated"] = datetime.now(timezone(timedelta(hours=2))).isoformat(timespec="seconds")
    if nove:
        base["week"] = f"{min(nove)} – {max(nove)}"
    base_soubor.write_text(json.dumps(base, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(f"  [{SKOLA_ID}] archiv {pred} → {len(dny)} dní ({len(nove)} nově přečteno)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
