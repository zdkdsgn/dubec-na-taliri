#!/usr/bin/env python3
"""Týdenní kontrola stavu dat: kolik škol má čerstvý jídelníček.

    python3 tools/kontrola-dat.py            # vypíše shrnutí (markdown), zapíše menu/stav.json
    python3 tools/kontrola-dat.py --github   # navíc nastaví výstupy pro GitHub Actions

Za „zastaralou“ se počítá škola s jídelníčkem, jejíž nejnovější den je starší než 21 dní.
Problém = víc než 25 % škol zastaralých, nebo některá ze sledovaných škol (ZŠ/MŠ Dubeč) starší než 10 dní.
Prázdniny hlásí hodně škol zastaralých naráz – proto jen upozornění, ne chyba.
"""
import json, os, sys
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SLEDOVANE = {"47": "ZŠ Dubeč", "ms-dubec": "MŠ Dubeč"}
LIMIT_SKOLA, LIMIT_SLEDOVANA, PODIL = 21, 10, 0.25


def nejnovejsi_den(sid: str):
    p = ROOT / "schools" / sid / "days.json"
    try:
        dny = json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return None
    return max(dny) if dny else None


def main():
    dnes = date.today()
    registr = json.loads((ROOT / "schools" / "index.json").read_text(encoding="utf-8"))
    s_menu = [s for s in registr if not s.get("bez_listku")]
    zastarale, bez_dat = [], []
    for s in s_menu:
        d = nejnovejsi_den(s["id"])
        if not d:
            bez_dat.append(s["id"]); continue
        if date.fromisoformat(d) < dnes - timedelta(days=LIMIT_SKOLA):
            zastarale.append((s["id"], s.get("kratky") or s["nazev"], d))
    podil = (len(zastarale) + len(bez_dat)) / max(len(s_menu), 1)

    sledovane = []
    for sid, jmeno in SLEDOVANE.items():
        d = nejnovejsi_den(sid)
        if not d or date.fromisoformat(d) < dnes - timedelta(days=LIMIT_SLEDOVANA):
            sledovane.append(f"{jmeno} (poslední den: {d or 'žádný'})")

    problem = podil > PODIL or bool(sledovane)
    radky = [f"## Stav dat k {dnes.strftime('%-d. %-m. %Y')}", "",
             f"- Škol v registru: **{len(registr)}** (s jídelníčkem {len(s_menu)}, zatím bez {len(registr) - len(s_menu)})",
             f"- Zastaralých (nejnovější den starší než {LIMIT_SKOLA} dní): **{len(zastarale)}** ({podil:.0%})",
             f"- Bez jediného dne: {len(bez_dat)}"]
    if sledovane:
        radky += ["", "**Sledované školy bez čerstvých dat:** " + ", ".join(sledovane)]
    if zastarale:
        radky += ["", "Příklady zastaralých:"] + [f"- `{i}` {n} – {d}" for i, n, d in zastarale[:15]]
    radky += ["", "Pozor: o prázdninách je zastaralých škol víc, to samo o sobě chyba nemusí být."]
    zprava = "\n".join(radky)
    print(zprava)

    (ROOT / "menu").mkdir(exist_ok=True)
    (ROOT / "menu" / "stav.json").write_text(json.dumps({
        "datum": dnes.isoformat(), "skol": len(registr), "s_jidelnickem": len(s_menu),
        "zastarale": len(zastarale), "podil_zastaralych": round(podil, 3), "problem": problem,
        "sledovane_problem": sledovane}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if "--github" in sys.argv:
        with open(os.environ["GITHUB_OUTPUT"], "a") as f:
            f.write(f"problem={'true' if problem else 'false'}\n")
        Path("/tmp/stav.md").write_text(zprava, encoding="utf-8")
        if os.environ.get("GITHUB_STEP_SUMMARY"):
            Path(os.environ["GITHUB_STEP_SUMMARY"]).write_text(zprava, encoding="utf-8")


if __name__ == "__main__":
    main()
