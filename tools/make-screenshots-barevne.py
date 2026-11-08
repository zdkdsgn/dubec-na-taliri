#!/usr/bin/env python3
"""Složí App Store screenshoty (1320×2868, 6,9") z reálných snímků simulátoru.

    python3 tools/make-screenshots-barevne.py

Vstup:  docs/app-store-screenshots/raw/<n>-<název>.png (snímky iPhone 18 Pro Max, světlý režim, 9:41)
Výstup: docs/app-store-screenshots/<n>-<název>.png
Grafika: zelený přechod z palety appky, kruhy „talíře“ v pozadí, nadpis písmem SF Pro (Heavy) se
zvýrazněným slovem, realistický rám iPhonu a plovoucí „bubliny“ s výhodami. Jména osob se rozostřují.
"""
import math
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "app-store-screenshots" / "raw"
OUT = ROOT / "docs" / "app-store-screenshots" / "barevne"
W, H = 1320, 2868
SF = "/System/Library/Fonts/SFNS.ttf"
ZVYRAZNENI = (255, 214, 92)          # teplá žlutá – kontrast k zelené
MINT = (190, 245, 218)
TMAVA_ZELENA = (14, 84, 58)

# Jména skutečných lidí (vedoucí jídelny/kuchyně, ředitel) se rozostřují: {snímek: [(x0, y0, x1, y1), …]}
ROZMAZAT = {"5-info": [(560, 2190, 1260, 2270), (560, 2326, 1260, 2406), (560, 2462, 1260, 2540)]}

# (soubor, eyebrow, nadpis se {zvýrazněním}, podnadpis, bubliny [(text, ikona, x, y, úhel)])
SLIDY = [
    ("1-den", "", "Co je dnes\nk {obědu}?", "Jídelníček školy nebo školky\nna jednom místě",
     [("Výdej 11:00–14:00", "hodiny", 40, 2470, -4), ("Alergeny u každého jídla", "list", -40, 2640, 3)]),
    ("2-tyden", "TÝDEN", "Celý týden\n{přehledně}", "Rozbalte den a uvidíte\nvšechna jídla",
     [("Po–Pá na jedné obrazovce", "kalendar", 40, 2470, -4), ("Funguje i offline", "ok", -40, 2640, 3)]),
    ("3-obedy", "OBJEDNÁNO", "Vidíte, co má dítě\n{přihlášené}", "Objednané obědy z jidelna.cz\nu každého dítěte",
     [("Přihlášeno · menu 1", "ok", 40, 2470, -4), ("Appka jen čte, nic neodhlašuje", "zamek", -40, 2640, 3)]),
    ("4-alergeny", "ALERGENY", "Hlídejte\n{alergeny}", "Jídla s vaším alergenem\nse hned zvýrazní",
     [("Alergen 6 · soja", "vykricnik", 40, 2470, -4), ("Pro každé dítě zvlášť", "osoba", -40, 2640, 3)]),
    ("5-info", "JÍDELNA", "Vše o jídelně\n{na dosah}", "Kontakty, doby výdeje,\nředitel i číslo účtu",
     [("Doba výdeje", "hodiny", 40, 2470, -4), ("Telefon · e-mail · web", "telefon", -40, 2640, 3)]),
    ("6-alergeny-nastaveni", "NASTAVENÍ", "Nastavte,\nco dítě {nesmí}", "Vlastní alergeny pro každé dítě,\nvšechny na jednom místě",
     [("Profil pro každé dítě", "osoba", 40, 2470, -4), ("Upozornění v 18:00", "zvonek", -40, 2640, 3)]),
]


def pismo(vel, vaha):
    f = ImageFont.truetype(SF, vel)
    f.set_variation_by_name(vaha)
    return f


def rozmazat(im, boxy):
    for b in boxy:
        im.paste(im.crop(b).filter(ImageFilter.GaussianBlur(16)), b[:2])
    return im


# ── pozadí ─────────────────────────────────────────────────────────────

_PANO = None


def panorama(n):
    """Jedno souvislé pozadí přes všechny snímky: přechod, záře, kruhy přecházející z jednoho snímku do dalšího."""
    import numpy as np
    pw = W * n
    yy, xx = np.mgrid[0:H, 0:pw].astype("float32")
    t = np.clip(0.55 * (xx / pw) + 0.45 * (yy / H), 0, 1)
    stops = [(0.0, (52, 184, 130)), (0.45, (26, 134, 94)), (1.0, (7, 52, 37))]
    out = np.zeros((H, pw, 3), "float32")
    for (t0, c0), (t1, c1) in zip(stops, stops[1:]):
        m = (t >= t0) & (t <= t1)
        k = ((t - t0) / (t1 - t0))[..., None]
        seg = np.array(c0, "float32") + (np.array(c1, "float32") - np.array(c0, "float32")) * k
        out = np.where(m[..., None], seg, out)
    base = Image.fromarray(out.clip(0, 255).astype("uint8"), "RGB").convert("RGBA")
    glow = Image.new("RGBA", (pw, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(glow)
    for i in range(n):
        cx = i * W + W // 2
        d.ellipse((cx - 560, 1180, cx + 560, 2300), fill=(180, 255, 220, 90))      # záře za telefonem
        d.ellipse((cx - 700, -420, cx + 500, 700), fill=(120, 240, 185, 55))        # záře za nadpisem
    glow = glow.filter(ImageFilter.GaussianBlur(170))
    base = Image.alpha_composite(base, glow)
    ring = Image.new("RGBA", (pw, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(ring)
    for i in range(1, n):                       # velké kruhy přes hrany – spojují sousední snímky
        cx = i * W
        for r, al, wd in ((520, 34, 5), (760, 24, 4), (1020, 16, 4)):
            d.ellipse((cx - r, 1650 - r, cx + r, 1650 + r), outline=(255, 255, 255, al), width=wd)
    for i in range(n):                           # kruhy „talíře“ za každým telefonem
        cx = i * W + W // 2
        for r, al in ((640, 24), (840, 16), (1060, 10)):
            d.ellipse((cx - r, 1800 - r, cx + r, 1800 + r), outline=(255, 255, 255, al), width=4)
    base = Image.alpha_composite(base, ring)
    # jemné zrno proti pruhování přechodů
    rng = np.random.default_rng(7)
    zrno = rng.normal(0, 2.2, (H, pw, 1)).astype("float32")
    arr = np.asarray(base.convert("RGB"), "float32") + zrno
    return Image.fromarray(arr.clip(0, 255).astype("uint8"), "RGB").convert("RGBA")


def pozadi(i, n):
    global _PANO
    if _PANO is None:
        _PANO = panorama(n)
    return _PANO.crop((i * W, 0, (i + 1) * W, H))


# ── text ──────────────────────────────────────────────────────────────

def sirka(d, txt, f, track=0):
    return d.textlength(txt, font=f) + track * max(len(txt) - 1, 0)


def kresli(d, x, y, txt, f, fill, track=0):
    if not track:
        d.text((x, y), txt, font=f, fill=fill)
        return x + d.textlength(txt, font=f)
    for ch in txt:
        d.text((x, y), ch, font=f, fill=fill)
        x += d.textlength(ch, font=f) + track
    return x


def nadpis_radek(d, y, radek, f, stin=False):
    """Řádek s {zvýrazněním}: bílý text + žluté slovo, vystředěno."""
    casti, i = [], 0
    while i < len(radek):
        if radek[i] == "{":
            j = radek.index("}", i)
            casti.append((radek[i + 1:j], ZVYRAZNENI)); i = j + 1
        else:
            j = radek.find("{", i); j = len(radek) if j < 0 else j
            casti.append((radek[i:j], (255, 255, 255))); i = j
    celkem = sum(d.textlength(t, font=f) for t, _ in casti)
    x = (W - celkem) / 2
    for t, c in casti:
        x = kresli(d, x, y, t, f, (0, 24, 14, 120) if stin else c + (255,))


# ── bubliny ───────────────────────────────────────────────────────────

def ikona(d, kind, cx, cy, r, kruh, b):
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=kruh)
    lw = max(r // 6, 4)
    if kind == "ok":
        d.line([(cx - r * .42, cy + r * .02), (cx - r * .1, cy + r * .34), (cx + r * .48, cy - r * .34)], fill=b, width=lw, joint="curve")
    elif kind == "vykricnik":
        d.line([(cx, cy - r * .5), (cx, cy + r * .12)], fill=b, width=lw)
        d.ellipse((cx - lw * .7, cy + r * .36, cx + lw * .7, cy + r * .36 + lw * 1.4), fill=b)
    elif kind == "hodiny":
        d.ellipse((cx - r * .55, cy - r * .55, cx + r * .55, cy + r * .55), outline=b, width=lw)
        d.line([(cx, cy), (cx, cy - r * .35)], fill=b, width=lw); d.line([(cx, cy), (cx + r * .28, cy + r * .12)], fill=b, width=lw)
    elif kind == "kalendar":
        d.rounded_rectangle((cx - r * .5, cy - r * .42, cx + r * .5, cy + r * .5), r * .12, outline=b, width=lw)
        d.line([(cx - r * .5, cy - r * .1), (cx + r * .5, cy - r * .1)], fill=b, width=lw)
    elif kind == "zamek":
        d.rounded_rectangle((cx - r * .42, cy - r * .05, cx + r * .42, cy + r * .5), r * .1, fill=b)
        d.arc((cx - r * .28, cy - r * .55, cx + r * .28, cy + r * .12), 180, 360, fill=b, width=lw)
    elif kind == "osoba":
        d.ellipse((cx - r * .22, cy - r * .5, cx + r * .22, cy - r * .06), fill=b)
        d.pieslice((cx - r * .5, cy + r * .02, cx + r * .5, cy + r * .9), 180, 360, fill=b)
    elif kind == "telefon":
        d.rounded_rectangle((cx - r * .28, cy - r * .5, cx + r * .28, cy + r * .5), r * .1, outline=b, width=lw)
    elif kind == "zvonek":
        d.pieslice((cx - r * .42, cy - r * .5, cx + r * .42, cy + r * .4), 180, 360, fill=b)
        d.rectangle((cx - r * .42, cy - r * .05, cx + r * .42, cy + r * .32), fill=b)
        d.ellipse((cx - r * .14, cy + r * .3, cx + r * .14, cy + r * .56), fill=b)
    elif kind == "list":
        d.pieslice((cx - r * .5, cy - r * .5, cx + r * .5, cy + r * .5), 20, 200, fill=b)


def bublina(text, kind, uhel, pozadi_pod=None):
    """Bublina z tmavě zeleného mléčného skla; pozadi_pod = výřez obrazu pod ní (rozostří se)."""
    f = pismo(52, "Semibold")
    dm = ImageDraw.Draw(Image.new("RGBA", (10, 10)))
    tw = dm.textlength(text, font=f)
    r = 38
    w, h = int(tw + 2 * 40 + 2 * r + 22), 116
    pad = 100
    im = Image.new("RGBA", (w + 2 * pad, h + 2 * pad), (0, 0, 0, 0))
    stin = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(stin).rounded_rectangle((pad, pad + 26, pad + w, pad + h + 26), h // 2, fill=(0, 22, 14, 170))
    im = Image.alpha_composite(im, stin.filter(ImageFilter.GaussianBlur(30)))
    maska = Image.new("L", im.size, 0)
    ImageDraw.Draw(maska).rounded_rectangle((pad, pad, pad + w, pad + h), h // 2, fill=255)
    if pozadi_pod is not None:
        rozost = pozadi_pod.filter(ImageFilter.GaussianBlur(30)).convert("RGBA")
        im.paste(rozost, (0, 0), maska)
    sklo = Image.new("RGBA", im.size, (9, 84, 58, 222))
    im.paste(Image.alpha_composite(im, sklo), (0, 0), maska)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((pad, pad, pad + w, pad + h), h // 2, outline=(255, 255, 255, 120), width=3)
    ikona(d, kind, pad + 30 + r, pad + h // 2, r, (255, 255, 255, 255), (222, 64, 88, 255) if kind == "vykricnik" else (22, 122, 84, 255))
    d.text((pad + 34 + 2 * r + 22, pad + h // 2 - 33), text, font=f, fill=(255, 255, 255, 255))
    return im.rotate(uhel, resample=Image.BICUBIC, expand=True)


# ── telefon ───────────────────────────────────────────────────────────

def kov(w, h, r, svetly=(226, 228, 230), tmavy=(128, 132, 135)):
    g = Image.new("RGBA", (w, h))
    px = g.load()
    for x in range(w):
        t = abs((x / (w - 1)) - 0.5) * 2
        c = tuple(int(svetly[i] + (tmavy[i] - svetly[i]) * (t ** 1.6)) for i in range(3))
        for y in range(h):
            px[x, y] = c + (255,)
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, w, h), r, fill=255)
    g.putalpha(m)
    return g


def iphone(shot, sw):
    sh = round(shot.size[1] * sw / shot.size[0])
    shot = shot.resize((sw, sh), Image.LANCZOS)
    obrazovka_r = round(112 * sw / 940)
    cerny, kovovy = 20, 14
    ob = cerny + kovovy
    w, h = sw + 2 * ob, sh + 2 * ob
    vnejsi_r = obrazovka_r + ob
    tl = 9
    pl = Image.new("RGBA", (w + 2 * tl, h), (0, 0, 0, 0))
    ox = tl
    d = ImageDraw.Draw(pl)
    for y, v in ((250, 70), (410, 150), (590, 150)):
        d.rounded_rectangle((ox - tl, y, ox + 14, y + v), 5, fill=(150, 154, 157, 255))
    d.rounded_rectangle((ox + w - 14, 470, ox + w + tl, 700), 5, fill=(150, 154, 157, 255))
    pl.alpha_composite(kov(w, h, vnejsi_r), (ox, 0))
    cerna = Image.new("RGBA", (w - 2 * kovovy, h - 2 * kovovy), (0, 0, 0, 0))
    ImageDraw.Draw(cerna).rounded_rectangle((0, 0, cerna.size[0], cerna.size[1]), vnejsi_r - kovovy, fill=(6, 8, 7, 255))
    pl.alpha_composite(cerna, (ox + kovovy, kovovy))
    m = Image.new("L", shot.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, sw, sh), obrazovka_r, fill=255)
    scr = shot.convert("RGBA"); scr.putalpha(m)
    pl.alpha_composite(scr, (ox + ob, ob))
    # jemný diagonální odlesk skla
    og = Image.linear_gradient("L").rotate(55, expand=True).resize((sw, sh)).point(lambda v: int(max(0, 90 - v) * 0.55))
    odlesk = Image.new("RGBA", (sw, sh), (255, 255, 255, 0)); odlesk.putalpha(ImageChops.multiply(og, m))
    pl.alpha_composite(odlesk, (ox + ob, ob))
    iw, ih = round(290 * sw / 1320 * 0.97), round(107 * sw / 1320 * 0.97)
    ix, iy = ox + ob + (sw - iw) // 2, ob + round(43 * sw / 1320)
    ImageDraw.Draw(pl).rounded_rectangle((ix, iy, ix + iw, iy + ih), ih // 2, fill=(0, 0, 0, 255))
    return pl


# ── slide ─────────────────────────────────────────────────────────────

def logo_hlavicka(pl):
    """Slide 1: ikona appky + název místo eyebrow."""
    ic = Image.open(ROOT / "assets" / "icon-512.png").convert("RGB").resize((168, 168), Image.LANCZOS)
    m = Image.new("L", ic.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, 168, 168), 40, fill=255)
    ic = ic.convert("RGBA"); ic.putalpha(m)
    d = ImageDraw.Draw(pl)
    f = pismo(60, "Bold")
    nazev = "Škola na talíři"
    tw = d.textlength(nazev, font=f)
    x = (W - (168 + 28 + tw)) / 2
    pl.alpha_composite(ic, (int(x), 120))
    d.text((x + 168 + 28, 120 + 168 / 2 - 36), nazev, font=f, fill=(255, 255, 255, 255))


def slide(idx, n, jmeno, eyebrow, nadpis, podnadpis, bubliny):
    pl = pozadi(idx, n)
    d = ImageDraw.Draw(pl)
    if jmeno == "1-den":
        logo_hlavicka(pl); y = 360
    else:
        f = pismo(46, "Bold")
        tw = sirka(d, eyebrow, f, 9)
        kresli(d, (W - tw) / 2, 150, eyebrow, f, MINT + (255,), track=9)
        y = 250
    vel = 160
    plain = [r.replace("{", "").replace("}", "") for r in nadpis.split("\n")]
    while max(d.textlength(r, font=pismo(vel, "Heavy")) for r in plain) > W - 150:
        vel -= 4
    fn = pismo(vel, "Heavy")
    stin_t = Image.new("RGBA", pl.size, (0, 0, 0, 0))
    ys = y
    for radek in nadpis.split("\n"):
        nadpis_radek(ImageDraw.Draw(stin_t), ys + 8, radek, fn, stin=True)
        ys += round(vel * 1.05)
    pl = Image.alpha_composite(pl, stin_t.filter(ImageFilter.GaussianBlur(14)))
    d = ImageDraw.Draw(pl)
    for radek in nadpis.split("\n"):
        nadpis_radek(d, y, radek, fn)
        y += round(vel * 1.05)
    fp = pismo(60, "Medium")
    y += 22
    for radek in podnadpis.split("\n"):
        tw = d.textlength(radek, font=fp)
        d.text(((W - tw) / 2, y), radek, font=fp, fill=(226, 247, 236, 235))
        y += 78

    shot = rozmazat(Image.open(RAW / f"{jmeno}.png").convert("RGB"), ROZMAZAT.get(jmeno, []))
    tel = iphone(shot, 1000)
    x, y0 = (W - tel.size[0]) // 2, (930 if jmeno == "1-den" else 820)
    stin = Image.new("RGBA", pl.size, (0, 0, 0, 0))
    ImageDraw.Draw(stin).rounded_rectangle((x + 20, y0 + 60, x + tel.size[0] - 20, y0 + tel.size[1]), 160, fill=(0, 20, 12, 170))
    pl = Image.alpha_composite(pl, stin.filter(ImageFilter.GaussianBlur(56)))
    pl.alpha_composite(tel, (x, y0))
    for txt, kind, bx, by, uhel in bubliny:
        probe = bublina(txt, kind, 0)
        pw_, ph_ = probe.size
        px = bx - 100 if bx >= 0 else W + bx + 100 - pw_
        py = by - 100
        pod = pl.crop((max(px, 0), py, max(px, 0) + pw_, py + ph_)).convert("RGBA")
        if pod.size != (pw_, ph_):
            pod = pod.resize((pw_, ph_))
        b = bublina(txt, kind, uhel, pod)
        pl.alpha_composite(b, (px - (b.size[0] - pw_) // 2, py - (b.size[1] - ph_) // 2))
    pl.convert("RGB").save(OUT / f"{jmeno}.png", optimize=True)


if __name__ == "__main__":
    for i, sl in enumerate(SLIDY):
        slide(i, len(SLIDY), *sl); print("hotovo", sl[0])
