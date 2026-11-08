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
ROZMAZAT = {"5-info": [(560, 2190, 1260, 2270), (560, 2326, 1260, 2406), (560, 2462, 1260, 2540)]}


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


def kov(w, h, r, svetly=(226, 228, 230), tmavy=(128, 132, 135)):
    """Titanový rám: vodorovný kovový přechod se světlým středem."""
    g = Image.new("RGBA", (w, h))
    px = g.load()
    for x in range(w):
        t = abs((x / (w - 1)) - 0.5) * 2          # 0 uprostřed, 1 na okrajích
        c = tuple(int(svetly[i] + (tmavy[i] - svetly[i]) * (t ** 1.6)) for i in range(3))
        for y in range(h):
            px[x, y] = c + (255,)
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, w, h), r, fill=255)
    g.putalpha(m)
    return g


def iphone(shot, sw):
    """Obrázek obrazovky → realistický iPhone (rám, tlačítka, Dynamic Island). Vrací (obrázek, (x, y0))."""
    sh = round(shot.size[1] * sw / shot.size[0])
    shot = shot.resize((sw, sh), Image.LANCZOS)
    obrazovka_r = 112
    cerny, kovovy = 20, 14
    ob = cerny + kovovy
    w, h = sw + 2 * ob, sh + 2 * ob
    vnejsi_r = obrazovka_r + ob
    tlacitko = 9
    pl = Image.new("RGBA", (w + 2 * tlacitko, h), (0, 0, 0, 0))
    ox = tlacitko
    # boční tlačítka (vystupují z rámu)
    d = ImageDraw.Draw(pl)
    for y, v in ((250, 70), (410, 150), (590, 150)):
        d.rounded_rectangle((ox - tlacitko, y, ox + 14, y + v), 5, fill=(150, 154, 157, 255))
    d.rounded_rectangle((ox + w - 14, 470, ox + w + tlacitko, 470 + 230), 5, fill=(150, 154, 157, 255))
    # kovový rám a černý okraj
    pl.alpha_composite(kov(w, h, vnejsi_r), (ox, 0))
    cerna = Image.new("RGBA", (w - 2 * kovovy, h - 2 * kovovy), (0, 0, 0, 0))
    ImageDraw.Draw(cerna).rounded_rectangle((0, 0, cerna.size[0], cerna.size[1]), vnejsi_r - kovovy, fill=(6, 8, 7, 255))
    pl.alpha_composite(cerna, (ox + kovovy, kovovy))
    # obrazovka
    m = Image.new("L", shot.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, sw, sh), obrazovka_r, fill=255)
    scr = shot.convert("RGBA"); scr.putalpha(m)
    pl.alpha_composite(scr, (ox + ob, ob))
    # Dynamic Island
    iw, ih = round(290 * sw / 1320 * 0.97), round(107 * sw / 1320 * 0.97)
    d = ImageDraw.Draw(pl)
    ix = ox + ob + (sw - iw) // 2
    iy = ob + round(43 * sw / 1320)
    d.rounded_rectangle((ix, iy, ix + iw, iy + ih), ih // 2, fill=(0, 0, 0, 255))
    x = (W - pl.size[0]) // 2
    return pl, (x, 700)


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
    telefon, (x, y0) = iphone(shot, 940)
    stin = Image.new("RGBA", pl.size, (0, 0, 0, 0))
    ImageDraw.Draw(stin).rounded_rectangle((x + 10, y0 + 40, x + telefon.size[0] - 10, y0 + 40 + telefon.size[1]), 150, fill=(0, 0, 0, 150))
    pl = Image.alpha_composite(pl, stin.filter(ImageFilter.GaussianBlur(46)))
    pl.alpha_composite(telefon, (x, y0))
    pl.convert("RGB").save(OUT / f"{jmeno}.png", optimize=True)


if __name__ == "__main__":
    for j, n, p in SLIDY:
        slide(j, n, p); print("hotovo", j)
