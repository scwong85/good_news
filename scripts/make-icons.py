#!/usr/bin/env python3
"""Render the Good News sunrise mark to the Android launcher icons and the web icons.

Original artwork, drawn here with Pillow (no third-party images). Re-run after changing the mark:
    python3 scripts/make-icons.py
Writes: Android legacy + adaptive (foreground, monochrome) icons, splash colours, web icons.
"""
import math
import pathlib
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent / "app"
CREAM = (255, 244, 224)
GREEN = (46, 125, 91)
SUN = (240, 154, 44)
SS = 4  # supersampling


def mark(size, fg=True, mono=False, scale=1.0):
    """The sunrise mark on a transparent square. scale<1 leaves room (adaptive safe zone)."""
    n = size * SS
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    sun = (0, 0, 0, 255) if mono else SUN + (255,)
    hill = (0, 0, 0, 255) if mono else GREEN + (255,)
    cx, hy = n / 2, n * (0.5 + 0.18 * scale - 0.18 + 0.18)  # horizon
    s = n * scale
    ox = (n - s) / 2
    oy = (n - s) / 2
    horizon = oy + s * 0.66
    r = s * 0.22
    for i in range(1, 6):
        a = math.pi + i * math.pi / 6
        r1 = r + s * 0.07
        r2 = r + s * (0.21 if i % 2 == 0 else 0.16)
        d.line([(cx + math.cos(a) * r1, horizon + math.sin(a) * r1), (cx + math.cos(a) * r2, horizon + math.sin(a) * r2)], fill=sun, width=int(s * 0.05))
        for r_, in ((r2,),):
            x, y = cx + math.cos(a) * r_, horizon + math.sin(a) * r_
            d.ellipse([x - s * 0.025, y - s * 0.025, x + s * 0.025, y + s * 0.025], fill=sun)
    base = horizon + s * 0.03  # the hill covers the sun's flat base
    d.pieslice([cx - r, base - r, cx + r, base + r], 180, 360, fill=sun)
    def quad(p0, p1, p2, steps=40):
        return [((1 - u) ** 2 * p0[0] + 2 * (1 - u) * u * p1[0] + u * u * p2[0], (1 - u) ** 2 * p0[1] + 2 * (1 - u) * u * p1[1] + u * u * p2[1]) for u in [i / steps for i in range(steps + 1)]]

    x0, x1 = -n * 0.05, n * 1.05
    wide = x1 - x0
    pts = [(x0, n * 1.05)]
    pts += quad((x0, horizon + s * 0.06), (x0 + wide * 0.3, horizon - s * 0.06), (x0 + wide * 0.55, horizon))
    pts += quad((x0 + wide * 0.55, horizon), (x0 + wide * 0.8, horizon + s * 0.06), (x1, horizon + s * 0.02))
    pts += [(x1, n * 1.05)]
    d.polygon(pts, fill=hill)
    return img.resize((size, size), Image.LANCZOS)


def on_background(size, fg_scale, rounded=False, bg=CREAM):
    base = Image.new("RGBA", (size, size), bg + (255,))
    base.alpha_composite(mark(size, scale=fg_scale))
    if rounded:
        m = Image.new("L", (size * SS, size * SS), 0)
        ImageDraw.Draw(m).rounded_rectangle([0, 0, size * SS - 1, size * SS - 1], radius=size * SS * 0.22, fill=255)
        m = m.resize((size, size), Image.LANCZOS)
        out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        out.paste(base, (0, 0), m)
        return out
    return base


res = ROOT / "android/app/src/main/res"
legacy = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
for dpi, px in legacy.items():
    on_background(px, 0.9, rounded=True).save(res / f"mipmap-{dpi}/ic_launcher.png")
    fg = int(px * 108 / 48)
    # Adaptive layers are 108dp; the mark lives inside the central 66dp safe zone.
    mark(fg, scale=0.66).save(res / f"mipmap-{dpi}/ic_launcher_foreground.png")
    mark(fg, mono=True, scale=0.66).save(res / f"mipmap-{dpi}/ic_launcher_monochrome.png")
(res / "mipmap-anydpi-v26").mkdir(exist_ok=True)
(res / "mipmap-anydpi-v26/ic_launcher.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@color/ic_launcher_background"/>\n'
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
    '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>\n'
    "</adaptive-icon>\n"
)
(res / "values/colors.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
    '    <color name="ic_launcher_background">#FFF4E0</color>\n'
    '    <color name="splash_background">#FFFBF3</color>\n'
    "</resources>\n"
)
(res / "values-night").mkdir(exist_ok=True)
(res / "values-night/colors.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
    '    <color name="ic_launcher_background">#FFF4E0</color>\n'
    '    <color name="splash_background">#15191A</color>\n'
    "</resources>\n"
)
# Splash: brand background with the mark centred (shown while Flutter starts).
mark(288, scale=1.0).save(res / "drawable/splash_mark.png")
for name in ("drawable", "drawable-v21"):
    (res / name / "launch_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<layer-list xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <item android:drawable="@color/splash_background" />\n'
        '    <item>\n        <bitmap android:gravity="center" android:src="@drawable/splash_mark" />\n    </item>\n'
        "</layer-list>\n"
    )

web = ROOT / "web"
for px, name, scale, rounded in [(192, "Icon-192.png", 0.9, True), (512, "Icon-512.png", 0.9, True), (192, "Icon-maskable-192.png", 0.66, False), (512, "Icon-maskable-512.png", 0.66, False)]:
    on_background(px, scale, rounded=rounded).save(web / "icons" / name)
on_background(32, 0.95, rounded=True).save(web / "favicon.png")
print("icons written")
