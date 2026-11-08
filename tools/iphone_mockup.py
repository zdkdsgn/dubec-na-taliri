"""Fotorealistický mockup iPhonu (titanový rám) vykreslený z vzdálenostního pole (SDF).

    from iphone_mockup import iphone
    obrazek_rgba = iphone(snimek_obrazovky, sirka_obrazovky_px)

Rám se počítá fyzikálně: vzdálenost od okraje zaoblené obdélníkové křivky → zkosená hrana, normála →
odlesk podle směru světla (zleva shora), kartáčovaná struktura titanu, černý rámeček pod sklem,
odraz na skle, Dynamic Island s kamerou, antény a boční tlačítka. Vykresluje se v dvojnásobném
rozlišení a zmenšuje se (hladké hrany).
"""
import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

SS = 2                                    # supersampling


def _smooth(x, a=1.4):
    return np.clip(x / a, 0.0, 1.0)


def _sdf_zaoblene(h, w, r):
    """Záporná vzdálenost od okraje zaobleného obdélníku (uvnitř kladná hloubka)."""
    y, x = np.mgrid[0:h, 0:w].astype("float32")
    px, py = np.abs(x - w / 2 + 0.5), np.abs(y - h / 2 + 0.5)
    qx, qy = px - (w / 2 - r), py - (h / 2 - r)
    venku = np.hypot(np.maximum(qx, 0), np.maximum(qy, 0))
    uvnitr = np.minimum(np.maximum(qx, qy), 0)
    return -(venku + uvnitr - r)         # hloubka: 0 na okraji, >0 uvnitř


def _kartacovany(h, w, sila=0.05, rng=None):
    rng = rng or np.random.default_rng(11)
    sum_ = rng.normal(0, 1, (h, w)).astype("float32")
    im = Image.fromarray(((sum_ * 40) + 128).clip(0, 255).astype("uint8"))
    im = im.filter(ImageFilter.GaussianBlur(radius=0.8)).resize((w, h))
    a = np.asarray(im, "float32")
    a = Image.fromarray(a.astype("uint8")).filter(ImageFilter.BoxBlur(1))
    # protažení vodorovně (kartáčování po délce hrany)
    a = np.asarray(a, "float32")
    k = 9
    pad = np.pad(a, ((0, 0), (k, k)), mode="edge")
    out = sum(pad[:, i:i + a.shape[1]] for i in range(2 * k + 1)) / (2 * k + 1)
    out = (out - out.mean()) / (out.std() + 1e-6)
    return 1.0 + out * sila


def _tlacitko(sw, sh, cistota=0):
    """Boční tlačítko: válcový přechod + horní/dolní odlesk."""
    w, h = sw * SS, sh * SS
    y, x = np.mgrid[0:h, 0:w].astype("float32")
    u = x / (w - 1)
    jas = 0.62 + 0.55 * np.clip(np.sin(np.pi * u), 0, 1) ** 1.5
    v = y / (h - 1)
    jas *= 0.85 + 0.25 * (1 - np.abs(v - 0.2) * 1.2).clip(0, 1)
    barva = np.array((178, 173, 165), "float32")
    rgb = np.clip(barva * jas[..., None], 0, 255)
    im = Image.fromarray(rgb.astype("uint8"), "RGB").convert("RGBA")
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, w - 1, h - 1), min(w, h) // 2 - 1, fill=255)
    im.putalpha(m)
    return im


def iphone(shot, sw, barva=(176, 171, 163)):
    """shot = obrázek obrazovky; sw = šířka obrazovky v px (výstup). Vrací RGBA včetně bočních tlačítek."""
    sh = round(shot.size[1] * sw / shot.size[0])
    side, bezel = 13, 16                                  # tloušťka kovu a černého rámečku (1×)
    ob = side + bezel
    w1, h1 = sw + 2 * ob, sh + 2 * ob
    r1 = round(112 * sw / 940) + ob
    w, h, r = w1 * SS, h1 * SS, r1 * SS
    side_s, bez_s = side * SS, bezel * SS

    depth = _sdf_zaoblene(h, w, r)
    gy, gx = np.gradient(-depth)                          # směr ven (rostoucí vzdálenost od středu)
    nrm = np.hypot(gx, gy) + 1e-6
    nx, ny = gx / nrm, gy / nrm
    lx, ly = -0.55, -0.83                                 # světlo zleva shora
    ndl = nx * lx + ny * ly

    # ── kovový rám ────────────────────────────────────────────────────
    kart = _kartacovany(h, w, 0.045)
    zaklad = np.array(barva, "float32")
    jas = 0.58 + 0.78 * np.clip(ndl, 0, 1) ** 1.35 - 0.20 * np.clip(-ndl, 0, 1)
    vert = 1.0 + 0.16 * (1 - np.linspace(0, 1, h, dtype="float32"))[:, None]    # nahoře o něco světlejší
    jas = jas * vert * kart
    # zkosená hrana: ostrá světlá linka u samého okraje + stín pod ní
    rim = np.exp(-((depth - 1.6 * SS) / (1.2 * SS)) ** 2)
    skos = np.exp(-((depth - (side_s - 2.2 * SS)) / (1.5 * SS)) ** 2)
    kov = zaklad * jas[..., None]
    kov += (rim * (70 + 120 * np.clip(ndl, 0, 1)))[..., None]
    kov -= (skos * 38)[..., None]
    kov = np.clip(kov, 0, 255)

    # ── černý rámeček pod sklem ───────────────────────────────────────
    t = ((depth - side_s) / bez_s).clip(0, 1)
    cerna = np.stack([4 + 14 * np.clip(ndl, 0, 1) * (1 - t) ** 3 + 0 * t] * 3, axis=-1)
    cerna = np.clip(cerna + (np.exp(-((depth - side_s - 1.2 * SS) / (1.0 * SS)) ** 2) * 55)[..., None], 0, 255)

    # ── skládání vrstev podle hloubky ─────────────────────────────────
    m_ven = _smooth(depth, 1.4 * SS)                                      # tvar těla
    m_rám = _smooth(side_s - depth, 1.2 * SS)                             # kov nad hloubkou side
    m_bez = _smooth(depth - side_s + 0.6 * SS, 1.0 * SS) * _smooth(side_s + bez_s - depth, 1.2 * SS)
    m_scr = _smooth(depth - (side_s + bez_s) + 0.4 * SS, 1.0 * SS)
    rgb = kov * m_rám[..., None] + cerna * (1 - m_rám)[..., None]
    alfa = m_ven

    # ── obrazovka ─────────────────────────────────────────────────────
    sw2, sh2 = sw * SS, sh * SS
    scr = shot.convert("RGB").resize((sw2, sh2), Image.LANCZOS)
    scr_pl = np.zeros((h, w, 3), "float32")
    scr_pl[ob * SS:ob * SS + sh2, ob * SS:ob * SS + sw2] = np.asarray(scr, "float32")
    # vnitřní stín u okraje skla a odraz (diagonální pruh světla)
    hl = np.clip((depth - (side_s + bez_s)) / (26 * SS), 0, 1)
    scr_pl *= (0.80 + 0.20 * hl)[..., None]
    y, x = np.mgrid[0:h, 0:w].astype("float32")
    diag = (x / w) * 0.75 + (y / h) * 0.55
    odraz = np.clip(1 - np.abs(diag - 0.45) / 0.34, 0, 1) ** 2 * 0.075 + np.clip(0.42 - diag, 0, 1) * 0.07
    scr_pl = np.clip(scr_pl + 255 * odraz[..., None], 0, 255)
    rgb = rgb * (1 - m_scr[..., None]) + scr_pl * m_scr[..., None]

    # ── antény: tenké tmavé linky přes kov na bocích ──────────────────
    im = Image.fromarray(np.clip(rgb, 0, 255).astype("uint8"), "RGB").convert("RGBA")
    im.putalpha(Image.fromarray((np.clip(alfa, 0, 1) * 255).astype("uint8"), "L"))
    d = ImageDraw.Draw(im)
    for yy in (0.115, 0.885):
        y0 = int(h * yy)
        d.rectangle((0, y0 - 2 * SS, side_s + 2 * SS, y0 + 2 * SS), fill=(26, 26, 28, 230))
        d.rectangle((w - side_s - 2 * SS, y0 - 2 * SS, w, y0 + 2 * SS), fill=(26, 26, 28, 230))
    # Dynamic Island + kamera
    iw, ih = round(290 * sw / 1320 * 0.97) * SS, round(107 * sw / 1320 * 0.97) * SS
    ix, iy = ob * SS + (sw2 - iw) // 2, ob * SS + round(43 * sw / 1320) * SS
    d.rounded_rectangle((ix, iy, ix + iw, iy + ih), ih // 2, fill=(0, 0, 0, 255))
    d.rounded_rectangle((ix + 3 * SS, iy + 3 * SS, ix + iw - 3 * SS, iy + ih - 3 * SS), ih // 2 - 3 * SS, outline=(22, 24, 26, 255), width=2 * SS)
    cx, cy, cr = ix + iw - ih // 2 - 6 * SS, iy + ih // 2, ih // 5
    d.ellipse((cx - cr, cy - cr, cx + cr, cy + cr), fill=(14, 16, 28, 255))
    d.ellipse((cx - cr * .62, cy - cr * .62, cx + cr * .62, cy + cr * .62), fill=(30, 36, 70, 255))
    d.ellipse((cx - cr * .32, cy - cr * .35, cx + cr * .02, cy - cr * .02), fill=(150, 170, 230, 255))

    # ── boční tlačítka ────────────────────────────────────────────────
    tl = 9
    plocha = Image.new("RGBA", (w + 2 * tl * SS, h), (0, 0, 0, 0))
    plocha.alpha_composite(im, (tl * SS, 0))
    for y0, v in ((int(h1 * 0.105), 62), (int(h1 * 0.175), 118), (int(h1 * 0.262), 118)):     # akce + hlasitost
        b = _tlacitko(tl + 6, v)
        plocha.alpha_composite(b, (0, y0 * SS))
    b = _tlacitko(tl + 6, 205)                                                              # boční
    plocha.alpha_composite(b, (w + 2 * tl * SS - (tl + 6) * SS, int(h1 * 0.205) * SS))
    vyst = plocha.resize((plocha.size[0] // SS, plocha.size[1] // SS), Image.LANCZOS)
    return vyst
