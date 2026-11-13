#!/usr/bin/env python3
"""Derive every Relay brand asset from the official icon.

The single source of truth is ``store/brand/relay-icon.png``. Nothing in this
script invents a mark: it crops, keys, and rescales the official artwork for
Android, iOS, macOS, Windows, web, the splash screen, and the Play listing.

Requires Pillow (``python -m pip install pillow``).

Run from the repository root:

    python tool/generate_brand_assets.py
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
STORE = ROOT / "store"
BRAND = STORE / "brand"
SOURCE = BRAND / "relay-icon.png"

# Play palette. Values are sampled from the official icon; keep in sync with
# lib/app/theme/app_colors.dart where they overlap.
FOREST_INK = "#0F0F11"  # official icon background
WARM_PAPER = "#F4F0E6"
TERRACOTTA = "#D96C4F"
SAGE = "#D8E0CF"
LIME = "#C2F050"

ICON_BG = (15, 15, 17)
CORNER_RADIUS = 0.225  # matches the official rounded-square silhouette
ICON_SIZE = 1024


def hex_rgba(value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = value.lstrip("#")
    return (
        int(value[0:2], 16),
        int(value[2:4], 16),
        int(value[4:6], 16),
        alpha,
    )


def load_source() -> Image.Image:
    if not SOURCE.exists():
        raise SystemExit(f"Missing official brand source: {SOURCE}")
    return Image.open(SOURCE).convert("RGB")


def squared(image: Image.Image) -> Image.Image:
    """Fill the transparent/black outer corners with the icon background.

    The official artwork is a rounded square flattened onto black. Play and the
    legacy launcher icons need an opaque square, so the outer corners become the
    icon background instead of black.
    """
    luma = image.convert("L")
    keep = luma.point(lambda value: 255 if value > 3 else 0)
    background = Image.new("RGB", image.size, ICON_BG)
    return Image.composite(image, background, keep)


def extract_mark(image: Image.Image) -> Image.Image:
    """Return the official R mark on a transparent canvas."""
    background = Image.new("RGB", image.size, ICON_BG)
    difference = ImageChops.difference(image, background).convert("L")
    # Pixels close to the icon background are fully transparent; the ramp keeps
    # the anti-aliased edge of the official artwork. The 18 threshold also
    # removes the faint rounded-square outline left by the flattened source.
    alpha = difference.point(
        lambda value: 0 if value <= 18 else min(255, int((value - 18) * 255 / 140))
    )
    mark = image.convert("RGBA")
    mark.putalpha(alpha)
    return mark


def fit_mark(
    mark: Image.Image,
    canvas: int,
    height_fraction: float,
) -> Image.Image:
    """Scale a transparent mark to a fraction of the canvas height and centre it."""
    bounds = mark.getbbox()
    if bounds is None:
        raise SystemExit("The official icon has no visible mark to extract.")
    cropped = mark.crop(bounds)
    target_height = max(1, int(round(canvas * height_fraction)))
    target_width = max(1, int(round(cropped.width * target_height / cropped.height)))
    resized = cropped.resize((target_width, target_height), Image.Resampling.LANCZOS)
    result = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    result.alpha_composite(
        resized,
        ((canvas - target_width) // 2, (canvas - target_height) // 2),
    )
    return result


def rounded(image: Image.Image, size: int, radius_fraction: float = CORNER_RADIUS) -> Image.Image:
    icon = image.resize((size, size), Image.Resampling.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size - 1, size - 1),
        radius=int(size * radius_fraction),
        fill=255,
    )
    result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    result.paste(icon, (0, 0), mask)
    return result


def circle(image: Image.Image, size: int) -> Image.Image:
    icon = image.resize((size, size), Image.Resampling.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)
    result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    result.paste(icon, (0, 0), mask)
    return result


def save(image: Image.Image, path: Path, *, rgb: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if rgb:
        image.convert("RGB").save(path, "PNG", optimize=True)
    else:
        image.save(path, "PNG", optimize=True)


def font_or_default(path: str, size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


def main() -> None:
    source = load_source()
    square = squared(source)
    mark = extract_mark(source)

    # Canonical derivatives kept next to the source for future tooling.
    save(square.resize((ICON_SIZE, ICON_SIZE), Image.Resampling.LANCZOS), BRAND / "relay-icon-1024.png", rgb=True)
    save(
        square.resize((512, 512), Image.Resampling.LANCZOS),
        BRAND / "relay-icon-512.png",
        rgb=True,
    )
    for stale in ("relay-mark-light-1024.png", "relay-mark-dark-1024.png"):
        (BRAND / stale).unlink(missing_ok=True)

    # Android legacy launcher icons. Adaptive icons are used on Android 8+.
    densities = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }
    res = ROOT / "android/app/src/main/res"
    for density, size in densities.items():
        save(rounded(square, size), res / f"mipmap-{density}" / "ic_launcher.png")
        save(circle(square, size), res / f"mipmap-{density}" / "ic_launcher_round.png")

    # Adaptive foreground: the transparent official mark inside the 66/108 safe
    # zone, over the official background colour declared in colors.xml.
    adaptive_sizes = {
        "mdpi": 108,
        "hdpi": 162,
        "xhdpi": 216,
        "xxhdpi": 324,
        "xxxhdpi": 432,
    }
    for density, size in adaptive_sizes.items():
        drawable = res / f"drawable-{density}"
        save(fit_mark(mark, size, 0.58), drawable / "ic_launcher_foreground.png")
        silhouette = Image.new("RGBA", mark.size, (255, 255, 255, 0))
        silhouette.putalpha(mark.getchannel("A"))
        save(fit_mark(silhouette, size, 0.58), drawable / "ic_launcher_monochrome.png")

    # Splash. Both themes use the official icon on warm paper so the dark mark
    # is always legible; the night overlay keeps the same background on purpose.
    splash_sizes = {
        "mdpi": 256,
        "hdpi": 384,
        "xhdpi": 512,
        "xxhdpi": 768,
        "xxxhdpi": 1024,
    }
    for density, size in splash_sizes.items():
        light_dir = res / f"drawable-{density}"
        night_dir = res / f"drawable-night-{density}"
        icon = rounded(square, size)
        inset = fit_mark(mark, size, 0.58)
        save(icon, light_dir / "splash_mark.png")
        save(icon, night_dir / "splash_mark.png")
        save(inset, light_dir / "splash_icon.png")
        save(inset, night_dir / "splash_icon.png")

    # Web icons and favicon.
    save(rounded(square, 32), ROOT / "web/favicon.png")
    web_icons = ROOT / "web/icons"
    save(
        square.resize((192, 192), Image.Resampling.LANCZOS),
        web_icons / "Icon-192.png",
        rgb=True,
    )
    save(
        square.resize((512, 512), Image.Resampling.LANCZOS),
        web_icons / "Icon-512.png",
        rgb=True,
    )
    maskable = Image.new("RGBA", (512, 512), hex_rgba(FOREST_INK))
    maskable.alpha_composite(fit_mark(mark, 512, 0.56))
    save(maskable, web_icons / "Icon-maskable-512.png", rgb=True)
    save(
        maskable.resize((192, 192), Image.Resampling.LANCZOS),
        web_icons / "Icon-maskable-192.png",
        rgb=True,
    )

    # iOS app icons are full square and opaque; iOS applies the mask.
    ios_dir = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    ios_specs = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for filename, size in ios_specs.items():
        save(
            square.resize((size, size), Image.Resampling.LANCZOS),
            ios_dir / filename,
            rgb=True,
        )

    # macOS uses a rounded, transparent icon.
    macos_dir = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for filename, size in {
        "app_icon_16.png": 16,
        "app_icon_32.png": 32,
        "app_icon_64.png": 64,
        "app_icon_128.png": 128,
        "app_icon_256.png": 256,
        "app_icon_512.png": 512,
        "app_icon_1024.png": 1024,
    }.items():
        save(rounded(square, size), macos_dir / filename)

    # Windows .ico with the standard sizes.
    ico_base = rounded(square, 1024)
    ico_base.save(
        ROOT / "windows/runner/resources/app_icon.ico",
        format="ICO",
        sizes=[(size, size) for size in (16, 24, 32, 48, 64, 128, 256)],
    )

    # iOS launch image. The storyboard background is warm paper.
    launch_dir = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    for filename, (width, height) in {
        "LaunchImage.png": (168, 185),
        "LaunchImage@2x.png": (336, 370),
        "LaunchImage@3x.png": (504, 555),
    }.items():
        canvas = Image.new("RGBA", (width, height), hex_rgba(WARM_PAPER))
        icon_size = int(min(width, height) * 0.72)
        canvas.alpha_composite(rounded(square, icon_size), ((width - icon_size) // 2, (height - icon_size) // 2))
        save(canvas, launch_dir / filename, rgb=True)

    # Play Store icon: 512 x 512, opaque, square.
    save(square.resize((512, 512), Image.Resampling.LANCZOS), STORE / "icon-512.png", rgb=True)

    # Play feature graphic: 1024 x 500, opaque. Copy stays product-accurate.
    feature = Image.new("RGBA", (2048, 1000), hex_rgba(FOREST_INK))
    draw = ImageDraw.Draw(feature, "RGBA")
    draw.ellipse((1420, -300, 2320, 600), outline=hex_rgba(LIME, 36), width=3)
    draw.ellipse((1580, -140, 2160, 440), outline=hex_rgba(WARM_PAPER, 28), width=2)
    draw.line((120, 880, 1928, 880), fill=hex_rgba(LIME, 90), width=2)
    feature.alpha_composite(rounded(square, 700), (140, 150))

    title_font = font_or_default(r"C:\Windows\Fonts\georgiab.ttf", 210)
    body_font = font_or_default(r"C:\Windows\Fonts\segoeui.ttf", 62)
    label_font = font_or_default(r"C:\Windows\Fonts\segoeuib.ttf", 32)
    draw.text((960, 230), "Relay", font=title_font, fill=hex_rgba(WARM_PAPER))
    draw.line((970, 500, 1120, 500), fill=hex_rgba(LIME), width=8)
    draw.text(
        (960, 560),
        "Read offline. Share by QR code.",
        font=body_font,
        fill=hex_rgba(SAGE),
    )
    draw.text(
        (965, 680),
        "PDF & EPUB   /   OFFLINE READING   /   DIRECT DEVICE SHARING",
        font=label_font,
        fill=hex_rgba(LIME),
    )
    save(feature.resize((1024, 500), Image.Resampling.LANCZOS), STORE / "feature-graphic-1024x500.png", rgb=True)

    # Provenance for reviewers and future automation.
    digest = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    manifest = {
        "generated_by": "tool/generate_brand_assets.py",
        "source": {
            "path": "store/brand/relay-icon.png",
            "size": list(source.size),
            "sha256": digest,
        },
        "palette": {
            "forest_ink": FOREST_INK,
            "warm_paper": WARM_PAPER,
            "terracotta": TERRACOTTA,
            "sage": SAGE,
            "lime": LIME,
        },
        "play_store": {
            "icon": "store/icon-512.png",
            "feature_graphic": "store/feature-graphic-1024x500.png",
        },
        "android": {
            "legacy_icons": "android/app/src/main/res/mipmap-*",
            "adaptive_icons": "android/app/src/main/res/mipmap-anydpi-v26 and -v33",
            "splash": "android/app/src/main/res/drawable-* and drawable-night-*",
        },
        "sizes": {
            "icon": [1024, 1024],
            "play_icon": [512, 512],
            "feature_graphic": [1024, 500],
        },
    }
    (STORE / "brand-assets.json").write_text(
        json.dumps(manifest, indent=2) + "\n",
        encoding="utf-8",
    )

    print("Generated Relay brand assets from store/brand/relay-icon.png.")
    print(f"  sha256: {digest}")
    print(f"  play icon: {STORE / 'icon-512.png'}")
    print(f"  feature: {STORE / 'feature-graphic-1024x500.png'}")


if __name__ == "__main__":
    main()
