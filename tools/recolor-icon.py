#!/usr/bin/env python3
"""Přebarví hlavní ikonu (oranžová) do zelené palety appky a vygeneruje všechny velikosti.

    python3 tools/recolor-icon.py <zdrojová-1024.png>

Paleta: tmavá #1E7A55 → světlá #4FCB8E (T.accent světlý/tmavý režim), talíř v barvě pozadí appky.
"""
import sys
from pathlib import Path
from PIL import Image
import colorsys

DARK  = (0x14, 0x6B, 0x47)
LIGHT = (0x5F, 0xD6, 0x9B)
MINT  = (246, 250, 247)    # T.bg světlý

def lerp(a, b, t): return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))

def recolor(src: Image.Image) -> Image.Image:
    im = src.convert("RGB"); px = im.load(); w, h = im.size
    out = Image.new("RGB", im.size); op = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            hh, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            a = min(1.0, max(0.0, (s - 0.05) / 0.45))          # kolik je pixel „barva“ (pozadí/dům) vs. talíř
            lum = 0.299 * r + 0.587 * g + 0.114 * b
            t = min(1.0, max(0.0, 1 - (lum - 120) / 120))        # žlutá (světlá) → světlá zelená, oranžová → tmavá
            green = lerp(LIGHT, DARK, t ** 0.9)
            plate = lerp((r, g, b), MINT, 0.85)                  # talíř: jemný stín zůstane, tón do mátové
            op[x, y] = tuple(int(round(plate[i] * (1 - a) + green[i] * a)) for i in range(3))
    return out

if __name__ == "__main__":
    src = Image.open(sys.argv[1]); big = recolor(src)
    root = Path(__file__).resolve().parent.parent
    big.save(root / "mobile/native/SkolaNaTaliri/Assets.xcassets/AppIcon.appiconset/icon-1024.png")
    big.save(root / "mobile/native/Watch/Assets.xcassets/AppIcon.appiconset/icon-1024.png")
    big.save(root / "mobile/ios-wrapper/ios/App/App/Assets.xcassets/AppIcon.appiconset/AppIcon-512@2x.png")
    for name, size in [("icon.png", 512), ("icon-512.png", 512), ("icon-192.png", 192), ("icon-180.png", 180)]:
        big.resize((size, size), Image.LANCZOS).save(root / "assets" / name)
    big.resize((512, 512), Image.LANCZOS).save(root / "mobile/native/SkolaNaTaliri/Assets.xcassets/SplashIcon.imageset/splash.png")
    print("hotovo")
