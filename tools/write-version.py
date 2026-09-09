#!/usr/bin/env python3
"""Přegeneruje version.json podle aktuálního obsahu index.html/styles.css/
app.js/sw.js/manifest.webmanifest.

Spustit po každé ruční úpravě appky (kódu, ne jídelníčku) – teprve pak appka
na telefonech probuzených z paměti pozná, že vyšla nová verze, a sama se
načte znovu. Automatická aktualizace jídelníčku (tools/update-menu.py) totéž
dělá sama za sebe.

    python3 tools/write-version.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _version import zapis_verzi

if __name__ == "__main__":
    verze = zapis_verzi(Path(__file__).resolve().parent.parent)
    print(f"version.json: {verze}")
