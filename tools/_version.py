"""Sdílená logika pro version.json – otisk appky, podle kterého klient
pozná, že vyšla nová verze, i když se nezměnila žádná data jídelníčku.

Hash počítáme jen ze souborů, které appku vizuálně nebo funkčně mění.
menu/*.json a data.js záměrně vynechané – ty appka hlídá zvlášť podle
meta.updated, hash appky by se jinak měnil při každé aktualizaci
jídelníčku a appka by se zbytečně restartovala kvůli obyčejným datům.
"""
import hashlib, json
from datetime import datetime, timedelta, timezone
from pathlib import Path

SOUBORY = ["index.html", "styles.css", "app.js", "sw.js", "manifest.webmanifest"]


def zapis_verzi(root: Path) -> str:
    h = hashlib.sha256()
    for jmeno in SOUBORY:
        h.update((root / jmeno).read_bytes())
    verze = h.hexdigest()[:12]

    (root / "version.json").write_text(
        json.dumps(
            {
                "v": verze,
                "generated": datetime.now(timezone(timedelta(hours=2))).isoformat(timespec="seconds"),
            },
            ensure_ascii=False, indent=2,
        ) + "\n",
        encoding="utf-8",
    )
    return verze
