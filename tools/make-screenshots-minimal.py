#!/usr/bin/env python3
"""App Store screenshoty v minimalistickém stylu (1320×2868, 6,9"): světlá a tmavá varianta.

    python3 tools/make-screenshots-minimal.py

Vstup:  docs/app-store-screenshots/raw/<n>-<název>.png (snímky simulátoru, jména osob se rozostřují)
Výstup: docs/app-store-screenshots/<n>-<název>.png          (světlá)
        docs/app-store-screenshots/tmave/<n>-<název>.png     (tmavá)
Barevná varianta s bublinami: tools/make-screenshots.py (docs/app-store-screenshots/barevne/).

Styl: hodně prázdného místa, velký nadpis SF Pro (Semibold, těsné řádkování), jedno slovo v zeleném
přechodu, podnadpis šedě, telefon se stínem – bez bublin, kruhů a dalších ozdob.
"""
import importlib.util
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("barevne", ROOT / "tools" / "make-screenshots.py")
bar = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bar)           # znovu použijeme rám iPhonu, rozostření jmen a písmo

W, H = bar.W, bar.H
RAW = bar.RAW
OUT_SVETLE = ROOT / "docs" / "app-store-screenshots" / "minimal-svetle"
OUT_TMAVE = ROOT / "docs" / "app-store-screenshots" / "minimal-tmave"

STYLY = {
    "svetle": dict(
        out=OUT_SVETLE,
        horni=(253, 253, 254), dolni=(234, 240, 236),
        nadpis=(29, 29, 31), podnadpis=(110, 110, 115), eyebrow=(30, 122, 85),
        grad=((22, 122, 84), (62, 196, 138)),
        stin=(0, 0, 0, 70), zare=(120, 220, 170, 38),
    ),
    "tmave": dict(
        out=OUT_TMAVE,
        horni=(12, 13, 13), dolni=(0, 0, 0),
        nadpis=(245, 245, 247), podnadpis=(152, 152, 158), eyebrow=(98, 214, 160),
        grad=((79, 203, 142), (164, 245, 206)),
        stin=(40, 200, 130, 70), zare=(40, 170, 110, 70),
    ),
}

# (soubor, eyebrow, nadpis se {zvýrazněním}, podnadpis)
SLIDY = [
    ("1-den", "", "Co je dnes\nk {obědu}?", "Jídelníček školy nebo školky\nna jednom místě."),
    ("2-tyden", "TÝDEN", "Celý týden.\n{Přehledně.}", "Rozbalte den a uvidíte\nvšechna jídla."),
    ("3-obedy", "OBJEDNÁNO", "Co má dítě\n{přihlášené.}", "Objednané obědy z jidelna.cz\nu každého dítěte."),
    ("4-alergeny", "ALERGENY", "Hlídejte\n{alergeny.}", "Jídla s vaším alergenem\nse hned zvýrazní."),
    ("5-info", "JÍDELNA", "Vše o jídelně.\n{Na dosah.}", "Kontakty, doby výdeje,\nředitel i číslo účtu."),
    ("6-alergeny-nastaveni", "NASTAVENÍ", "Co dítě\n{nesmí.}", "Vlastní alergeny pro každé dítě,\nvšechny na jednom místě."),
]


def pozadi(st):
    import numpy as np
    y = np.linspace(0, 1, H, dtype="float32")[:, None, None]
    a, b = np.array(st["horni"], "float32"), np.array(st["dolni"], "float32")
    plocha = np.broadcast_to(a + (b - a) * y, (H, W, 3))
    rng = np.random.default_rng(3)
    plocha = plocha + rng.normal(0, 1.2, (H, W, 1))
    im = Image.fromarray(plocha.clip(0, 255).astype("uint8"), "RGB").convert("RGBA")
    zare = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(zare).ellipse((140, 1500, 1180, 2700), fill=st["zare"])         # velmi jemná záře u telefonu
    return Image.alpha_composite(im, zare.filter(ImageFilter.GaussianBlur(220)))


def sirka_radku(radek, f, track):
    dm = ImageDraw.Draw(Image.new("RGBA", (10, 10)))
    return sum(dm.textlength(ch, font=f) + track for ch in radek) - track


def kresli_radek(pl, y, radek, f, st, track=-4):
    """Vystředěný řádek; {slovo} je vyplněné zeleným přechodem."""
    casti, i = [], 0
    while i < len(radek):
        if radek[i] == "{":
            j = radek.index("}", i); casti.append((radek[i + 1:j], True)); i = j + 1
        else:
            j = radek.find("{", i); j = len(radek) if j < 0 else j
            casti.append((radek[i:j], False)); i = j
    celkem = sum(sirka_radku(t, f, track) + track for t, _ in casti) - track
    x = (W - celkem) / 2
    d = ImageDraw.Draw(pl)
    for t, zvyr in casti:
        sw = sirka_radku(t, f, track)
        if not zvyr:
            for ch in t:
                d.text((x, y), ch, font=f, fill=st["nadpis"] + (255,))
                x += d.textlength(ch, font=f) + track
        else:
            maska = Image.new("L", (int(sw) + 60, int(f.size * 1.4)), 0)
            md = ImageDraw.Draw(maska); mx = 20
            for ch in t:
                md.text((mx, 0), ch, font=f, fill=255)
                mx += md.textlength(ch, font=f) + track
            g = Image.linear_gradient("L").rotate(90).resize(maska.size)
            c0, c1 = st["grad"]
            barva = Image.composite(Image.new("RGB", maska.size, c1), Image.new("RGB", maska.size, c0), g).convert("RGBA")
            barva.putalpha(maska)
            pl.alpha_composite(barva, (int(x) - 20, int(y)))
            x += sw + track
    return pl


def slide(st, jmeno, eyebrow, nadpis, podnadpis, tmave):
    pl = pozadi(st)
    d = ImageDraw.Draw(pl)
    y = 190
    if jmeno == "1-den":
        ic = Image.open(ROOT / "assets" / "icon-512.png").convert("RGB").resize((176, 176), Image.LANCZOS)
        m = Image.new("L", ic.size, 0)
        ImageDraw.Draw(m).rounded_rectangle((0, 0, 176, 176), 42, fill=255)
        ic = ic.convert("RGBA"); ic.putalpha(m)
        stin = Image.new("RGBA", pl.size, (0, 0, 0, 0))
        ImageDraw.Draw(stin).rounded_rectangle(((W - 176) // 2, 150, (W + 176) // 2, 150 + 176), 42, fill=(0, 0, 0, 90 if not tmave else 0))
        pl = Image.alpha_composite(pl, stin.filter(ImageFilter.GaussianBlur(22)))
        pl.alpha_composite(ic, ((W - 176) // 2, 130))
        y = 400
    else:
        f = bar.pismo(44, "Semibold")
        w_ = sirka_radku(eyebrow, f, 8)
        x = (W - w_) / 2
        d = ImageDraw.Draw(pl)
        for ch in eyebrow:
            d.text((x, 170), ch, font=f, fill=st["eyebrow"] + (255,)); x += d.textlength(ch, font=f) + 8
        y = 270
    fn = bar.pismo(152, "Semibold")
    for radek in nadpis.split("\n"):
        pl = kresli_radek(pl, y, radek, fn, st)
        y += 160
    d = ImageDraw.Draw(pl)
    fp = bar.pismo(56, "Regular")
    y += 20
    for radek in podnadpis.split("\n"):
        tw = d.textlength(radek, font=fp)
        d.text(((W - tw) / 2, y), radek, font=fp, fill=st["podnadpis"] + (255,))
        y += 76

    shot = bar.rozmazat(Image.open(RAW / f"{jmeno}.png").convert("RGB"), bar.ROZMAZAT.get(jmeno, []))
    tel = bar.iphone(shot, 960)
    x, y0 = (W - tel.size[0]) // 2, (1010 if jmeno == "1-den" else 930)
    stin = Image.new("RGBA", pl.size, (0, 0, 0, 0))
    ImageDraw.Draw(stin).rounded_rectangle((x + 30, y0 + 70, x + tel.size[0] - 30, y0 + tel.size[1]), 160, fill=st["stin"])
    pl = Image.alpha_composite(pl, stin.filter(ImageFilter.GaussianBlur(70)))
    pl.alpha_composite(tel, (x, y0))
    st["out"].mkdir(parents=True, exist_ok=True)
    pl.convert("RGB").save(st["out"] / f"{jmeno}.png", optimize=True)


if __name__ == "__main__":
    for nazev, st in STYLY.items():
        for jm, ey, nad, pod in SLIDY:
            slide(st, jm, ey, nad, pod, nazev == "tmave"); print("hotovo", nazev, jm)
