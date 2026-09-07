#!/usr/bin/env python3
"""Složí celou aplikaci do jediného .html souboru.

Použití:  python3 build-single.py [výstup.html]

Hodí se, když chcete appku poslat mailem, otevřít bez serveru nebo
vypublikovat jako jednu stránku. Zdrojem zůstává vždy multi-file verze.
"""
import re, sys, pathlib

root = pathlib.Path(__file__).parent
out  = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else root / "dubec-na-taliri.html")

html   = (root / "index.html").read_text()
css    = (root / "styles.css").read_text()
data   = (root / "data.js").read_text()
app    = (root / "app.js").read_text()

# tělo stránky bez <head> – artefakt / jednosouborová verze si hlavičku nese sama
body = re.search(r"<body>\n(.*)\n</body>", html, re.S).group(1)
body = body.replace('<script src="data.js"></script>\n<script src="app.js"></script>', "")

# service worker a manifest v jednosouborové verzi neexistují
app = re.sub(r'if \("serviceWorker" in navigator.*?\.catch\(\(\) => \{\}\)\);\n', "", app, flags=re.S)

out.write_text(f"""<title>Dubeč na talíři</title>
<style>
{css}
</style>

{body}

<script>
{data}
</script>
<script>
{app}
</script>
""")
print(f"{out}  ({out.stat().st_size // 1024} kB)")
