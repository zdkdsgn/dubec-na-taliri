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

import json, re, sys
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _version import zapis_verzi
from jidelna_client import stahni, parsuj

ROOT     = Path(__file__).resolve().parent.parent
JIDELNA  = 47
DNY_ZPET, DNY_VPRED = 7, 35


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
    def rozbal(zaznam):
        """Přijme starý tvar (pole chodů) i nový ({"vydej":…, "chody":[…]})."""
        if isinstance(zaznam, list):
            return None, zaznam
        return zaznam.get("vydej"), zaznam.get("chody", [])

    dny = {}
    for iso in sorted(set(ms) | set(zs)):
        z, vydej = {}, {}
        for skupina, zdroj in (("zs", zs), ("ms", ms)):
            if iso in zdroj:
                cas, chody = rozbal(zdroj[iso])
                z[skupina] = chody
                if cas:
                    vydej[skupina] = cas
        if vydej:
            z["vydej"] = vydej
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



def main() -> int:
    offline = "--offline" in sys.argv
    nacti   = lambda p: json.loads((ROOT / p).read_text(encoding="utf-8"))
    base, ms, zs = nacti("menu/base.json"), nacti("menu/ms.json"), nacti("menu/zs.json")
    pred = len(zs)

    if not offline:
        od = date.today() - timedelta(days=DNY_ZPET)
        html = stahni(JIDELNA, od, DNY_ZPET + DNY_VPRED)
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
            print(f"  • {d}: " + " / ".join(c["n"] for c in nove[d]["chody"]))

        base["meta"]["updated"] = datetime.now(timezone(timedelta(hours=2))).isoformat(timespec="seconds")
        if zs:
            base["meta"]["week"] = f"{min(zs)} – {max(zs)}"
        (ROOT / "menu/base.json").write_text(
            json.dumps(base, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    (ROOT / "data.js").write_text(generuj_data_js(base, ms, zs), encoding="utf-8")
    print(f"data.js: {len(set(ms) | set(zs))} dní (ZŠ {len(zs)}, MŠ {len(ms)})")

    verze = zapis_verzi(ROOT)
    print(f"version.json: {verze}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
