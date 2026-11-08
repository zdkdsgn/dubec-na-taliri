#!/usr/bin/env python3
"""Složí App Store screenshoty (1320×2868, 6,9") z reálných snímků simulátoru + nadpisů.

    python3 tools/make-screenshots.py

Vstup:  docs/app-store-screenshots/raw/<n>-<název>.png (snímky iPhone 18 Pro Max, světlý režim, 9:41)
Výstup: docs/app-store-screenshots/<n>-<název>.png
Písmo: SF Pro (systémové, macOS). Barvy z palety appky.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "app-store-screenshots" / "raw"
OUT = ROOT / "docs" / "app-store-screenshots"
W, H = 1320, 2868
SF = "/System/Library/Fonts/SFNS.ttf"

SLIDY = [
    ("1-den", "Co je dnes\nk obědu?", "Jídelníček vaší školy nebo školky\nna jednom místě"),
    ("2-tyden", "Celý týden\npřehledně", "Rozbalte den a uvidíte\nvšechna jídla"),
    ("3-obedy", "Vidíte, co má dítě\npřihlášené", "Objednané obědy z jidelna.cz\nu každého dítěte"),
    ("4-alergeny", "Hlídejte\nalergeny", "Jídla s vaším alergenem\nse hned zvýrazní"),
    ("5-info", "Vše o jídelně\nna dosah", "Kontakty, doby výdeje,\nředitel i číslo účtu"),
    ("6-alergeny-nastaveni", "Nastavte,\nco dítě nesmí", "Vlastní alergeny pro každé dítě,\nvšechny na jednom místě"),
]


# Jména skutečných lidí (vedoucí jídelny/kuchyně, ředitel) se v reklamních snímcích rozostřují: {snímek: [(x0, y0, x1, y1), …]}
ROZMAZAT = {"5-info": [(700, 2125, 1260, 2200), (700, 2262, 1260, 2337), (700, 2398, 1260, 2473)]}


def rozmazat(im, boxy):
    for b in boxy:
        oblast = im.crop(b).filter(ImageFilter.GaussianBlur(16))
        im.paste(oblast, b[:2])
    return im


def pismo(vel, vaha):
    f = ImageFont.truetype(SF, vel)
    f.set_variation_by_name(vaha)
    return f


def pozadi():
    # svislý přechod z palety appky + dvě rozostřené záře
    g = Image.new("RGB", (W, H))
    px = g.load()
    horni, dolni = (31, 133, 92), (11, 62, 43)
    for y in range(H):
        t = y / (H - 1)
        c = tuple(int(horni[i] + (dolni[i] - horni[i]) * t) for i in range(3))
        for x in range(W):
            px[x, y] = c
    z = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(z)
    d.ellipse((-300, -200, 900, 800), fill=(120, 230, 180, 70))
    d.ellipse((700, 1500, 1700, 2500), fill=(70, 200, 140, 55))
    z = z.filter(ImageFilter.GaussianBlur(160))
    return Image.alpha_composite(g.convert("RGBA"), z)


def zaoblit(im, r):
    m = Image.new("L", im.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, im.size[0], im.size[1]), r, fill=255)
    out = im.convert("RGBA"); out.putalpha(m)
    return out


def text_stred(d, y, text, font, fill, mezera):
    for radek in text.split("\n"):
        w = d.textlength(radek, font=font)
        d.text(((W - w) / 2, y), radek, font=font, fill=fill)
        y += mezera
    return y


def slide(jmeno, nadpis, podnadpis):
    pl = pozadi()
    d = ImageDraw.Draw(pl)
    y = text_stred(d, 150, nadpis, pismo(136, "Bold"), (255, 255, 255, 255), 150)
    text_stred(d, y + 26, podnadpis, pismo(58, "Medium"), (226, 245, 236, 235), 76)

    shot = Image.open(RAW / f"{jmeno}.png").convert("RGB")
    shot = rozmazat(shot, ROZMAZAT.get(jmeno, []))
    sirka = 1010
    vyska = round(shot.size[1] * sirka / shot.size[0])
    shot = shot.resize((sirka, vyska), Image.LANCZOS)
    r_vnitrni = 96
    telefon = zaoblit(shot, r_vnitrni)
    ram = 16
    ram_im = Image.new("RGBA", (sirka + 2 * ram, vyska + 2 * ram), (0, 0, 0, 0))
    ImageDraw.Draw(ram_im).rounded_rectangle((0, 0, ram_im.size[0], ram_im.size[1]), r_vnitrni + ram, fill=(9, 16, 12, 255))
    ram_im.alpha_composite(telefon, (ram, ram))

    x = (W - ram_im.size[0]) // 2
    y0 = 700
    stin = Image.new("RGBA", pl.size, (0, 0, 0, 0))
    ImageDraw.Draw(stin).rounded_rectangle((x, y0 + 30, x + ram_im.size[0], y0 + 30 + ram_im.size[1]), r_vnitrni + ram, fill=(0, 0, 0, 120))
    pl = Image.alpha_composite(pl, stin.filter(ImageFilter.GaussianBlur(40)))
    pl.alpha_composite(ram_im, (x, y0))
    pl.convert("RGB").save(OUT / f"{jmeno}.png", optimize=True)


if __name__ == "__main__":
    for j, n, p in SLIDY:
        slide(j, n, p); print("hotovo", j)
