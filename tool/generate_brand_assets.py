#!/usr/bin/env python3
"""Generate Relay's app icons, splash marks, and store artwork.

The mark is a pair of paper pages with a terracotta relay arrow. It is drawn
from the same geometry for Android, iOS, macOS, Windows, web, and the Play
listing. Requires Pillow (``python -m pip install pillow``).

Run from the repository root:

    python tool/generate_brand_assets.py
"""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]

# Relay palette. Keep these in sync with lib/app/theme/app_colors.dart.
FOREST_INK = "#242820"
WARM_PAPER = "#F4F0E6"
TERRACOTTA = "#D96C4F"
SAGE = "#D8E0CF"
OLIVE_GRAY = "#79796F"
DEEP_OLIVE = "#3B4036"

SUPERSAMPLE = 2
SOURCE_SIZE = 2048 * SUPERSAMPLE  # 4096 px working canvas
ICON_SIZE = 1024
MARK_WIDTH = 0.72  # fraction of the source canvas occupied by the mark
MARK_BOUNDS = (0.20, 0.21, 0.90, 0.79)  # x0, y0, x1, y1 in unit space


def hex_rgba(value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = value.lstrip("#")
    return (
        int(value[0:2], 16),
        int(value[2:4], 16),
        int(value[4:6], 16),
        alpha,
    )


def page_layer(
    size: int,
    center: tuple[float, float],
    width: float,
    height: float,
    angle: float,
    fill: tuple[int, int, int, int],
    lines: list[tuple[float, float, float, float]] | None = None,
    line_color: tuple[int, int, int, int] | None = None,
) -> Image.Image:
    """Draw one rotated page and return it as a transparent layer."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = center[0] * size, center[1] * size
    w, h = width * size, height * size
    left, top = cx - w / 2, cy - h / 2
    radius = int(min(w, h) * 0.09)
    draw.rounded_rectangle(
        (left, top, left + w, top + h),
        radius=radius,
        fill=fill,
    )
    if lines and line_color:
        for x0, y0, x1, y1 in lines:
            draw.rounded_rectangle(
                (
                    cx + x0 * size,
                    cy + y0 * size,
                    cx + x1 * size,
                    cy + y1 * size,
                ),
                radius=max(1, int((y1 - y0) * size / 2)),
                fill=line_color,
            )
    return layer.rotate(
        angle,
        resample=Image.Resampling.BICUBIC,
        center=(cx, cy),
    )


def bezier_points(
    p0: tuple[float, float],
    p1: tuple[float, float],
    p2: tuple[float, float],
    p3: tuple[float, float],
    steps: int = 120,
) -> list[tuple[float, float]]:
    points = []
    for index in range(steps + 1):
        t = index / steps
        mt = 1.0 - t
        x = (
            mt**3 * p0[0]
            + 3 * mt**2 * t * p1[0]
            + 3 * mt * t**2 * p2[0]
            + t**3 * p3[0]
        )
        y = (
            mt**3 * p0[1]
            + 3 * mt**2 * t * p1[1]
            + 3 * mt * t**2 * p2[1]
            + t**3 * p3[1]
        )
        points.append((x, y))
    return points


def draw_arrow(
    draw: ImageDraw.ImageDraw,
    size: int,
    points: list[tuple[float, float]],
    color: tuple[int, int, int, int],
    width: float,
    tip_length: float,
    barb_width: float,
) -> None:
    scaled = [(x * size, y * size) for x, y in points]
    stroke = max(2, int(width * size))
    draw.line(scaled, fill=color, width=stroke, joint="curve")
    # Round the tail.
    tail_x, tail_y = scaled[0]
    draw.ellipse(
        (
            tail_x - stroke / 2,
            tail_y - stroke / 2,
            tail_x + stroke / 2,
            tail_y + stroke / 2,
        ),
        fill=color,
    )
    # Arrowhead aligned with the final tangent.
    (x0, y0), (x1, y1) = scaled[-2], scaled[-1]
    dx, dy = x1 - x0, y1 - y0
    length = math.hypot(dx, dy) or 1.0
    dx, dy = dx / length, dy / length
    px, py = -dy, dx
    tip = (x1 + dx * tip_length * size, y1 + dy * tip_length * size)
    base = (x1 - dx * tip_length * size * 0.15, y1 - dy * tip_length * size * 0.15)
    half = barb_width * size
    draw.polygon(
        [
            tip,
            (base[0] + px * half, base[1] + py * half),
            (base[0] - px * half, base[1] - py * half),
        ],
        fill=color,
    )


def render_mark(
    page_front: tuple[int, int, int, int],
    page_back: tuple[int, int, int, int],
    text_color: tuple[int, int, int, int],
    arrow_color: tuple[int, int, int, int],
    *,
    monochrome: bool = False,
) -> Image.Image:
    size = SOURCE_SIZE
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # Back page, then front page with two quiet text rules.
    image.alpha_composite(
        page_layer(
            size,
            center=(0.38, 0.50),
            width=0.36,
            height=0.54,
            angle=-14,
            fill=page_back,
        )
    )
    front_lines = [
        (-0.12, -0.10, 0.02, -0.082),
        (-0.12, -0.03, 0.05, -0.012),
        (-0.12, 0.04, -0.01, 0.058),
    ]
    image.alpha_composite(
        page_layer(
            size,
            center=(0.50, 0.50),
            width=0.38,
            height=0.56,
            angle=-6,
            fill=page_front,
            lines=None if monochrome else front_lines,
            line_color=text_color,
        )
    )

    draw = ImageDraw.Draw(image)
    if monochrome:
        # A separate arrow keeps the single-colour glyph legible.
        draw_arrow(
            draw,
            size,
            [(0.68, 0.58), (0.73, 0.58), (0.79, 0.58), (0.86, 0.58)],
            color=arrow_color,
            width=0.052,
            tip_length=0.055,
            barb_width=0.050,
        )
    else:
        draw_arrow(
            draw,
            size,
            bezier_points(
                (0.43, 0.67),
                (0.51, 0.55),
                (0.67, 0.38),
                (0.86, 0.38),
            ),
            color=arrow_color,
            width=0.050,
            tip_length=0.055,
            barb_width=0.050,
        )

    # Rescale the mark so its bounding box is the requested width and its
    # visual centre is the canvas centre.
    x0, y0, x1, y1 = (value * size for value in MARK_BOUNDS)
    mark_width = x1 - x0
    mark_height = y1 - y0
    target_width = MARK_WIDTH * size
    scale = target_width / mark_width
    target_height = mark_height * scale

    cropped = image.crop((int(x0), int(y0), int(x1), int(y1)))
    cropped = cropped.resize(
        (max(1, int(target_width)), max(1, int(target_height))),
        Image.Resampling.LANCZOS,
    )
    result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    result.alpha_composite(
        cropped,
        (
            int((size - cropped.width) / 2),
            int((size - cropped.height) / 2),
        ),
    )
    return result


def resize(image: Image.Image, size: int) -> Image.Image:
    return image.resize((size, size), Image.Resampling.LANCZOS)


def full_icon(mark: Image.Image, size: int) -> Image.Image:
    background = Image.new("RGBA", (size, size), hex_rgba(FOREST_INK))
    background.alpha_composite(mark.resize((size, size), Image.Resampling.LANCZOS))
    return background


def rounded_icon(mark: Image.Image, size: int, radius_fraction: float = 0.22) -> Image.Image:
    icon = full_icon(mark, size)
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    radius = int(size * radius_fraction)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    result.paste(icon, (0, 0), mask)
    return result


def save(image: Image.Image, path: Path, *, rgb: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if rgb:
        image.convert("RGB").save(path, "PNG", optimize=True)
    else:
        image.save(path, "PNG", optimize=True)


def scaled_mark(mark: Image.Image, width_fraction: float) -> Image.Image:
    """Return a square canvas with the mark scaled to width_fraction."""
    factor = width_fraction / MARK_WIDTH
    target = int(round(SOURCE_SIZE * factor))
    resized = mark.resize((target, target), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (SOURCE_SIZE, SOURCE_SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(
        resized,
        (
            int((SOURCE_SIZE - target) / 2),
            int((SOURCE_SIZE - target) / 2),
        ),
    )
    return canvas


def main() -> None:
    store = ROOT / "store"
    brand = store / "brand"
    brand.mkdir(parents=True, exist_ok=True)

    # Light pages on the dark app background: launcher, Play, feature graphic.
    icon_mark = render_mark(
        page_front=hex_rgba(WARM_PAPER),
        page_back=hex_rgba(SAGE),
        text_color=hex_rgba(OLIVE_GRAY, 180),
        arrow_color=hex_rgba(TERRACOTTA),
    )
    # Dark pages for the light splash background.
    light_splash_mark = render_mark(
        page_front=hex_rgba(FOREST_INK),
        page_back=hex_rgba(DEEP_OLIVE),
        text_color=hex_rgba(WARM_PAPER, 180),
        arrow_color=hex_rgba(TERRACOTTA),
    )
    # Dark-mode splash uses the same light pages as the app icon.
    dark_splash_mark = icon_mark
    mono_mark = render_mark(
        page_front=hex_rgba("#FFFFFF"),
        page_back=hex_rgba("#FFFFFF"),
        text_color=hex_rgba("#FFFFFF"),
        arrow_color=hex_rgba("#FFFFFF"),
        monochrome=True,
    )

    # Source files for future editing and store uploads.
    save(full_icon(icon_mark, ICON_SIZE), brand / "relay-icon-1024.png", rgb=True)
    save(icon_mark.resize((ICON_SIZE, ICON_SIZE), Image.Resampling.LANCZOS), brand / "relay-mark-light-1024.png")
    save(light_splash_mark.resize((ICON_SIZE, ICON_SIZE), Image.Resampling.LANCZOS), brand / "relay-mark-dark-1024.png")
    save(full_icon(icon_mark, 512), store / "icon-512.png", rgb=True)

    # Android legacy icons.
    for density, size in {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }.items():
        save(rounded_icon(icon_mark, size), ROOT / "android/app/src/main/res" / f"mipmap-{density}" / "ic_launcher.png")
        save(rounded_icon(icon_mark, size, 0.50), ROOT / "android/app/src/main/res" / f"mipmap-{density}" / "ic_launcher_round.png")

    # Adaptive foreground and monochrome layers. The 0.60 width keeps the
    # visible mark inside the adaptive-icon safe zone.
    adaptive_mark = scaled_mark(icon_mark, 0.60)
    adaptive_mono = scaled_mark(mono_mark, 0.60)
    for density, size in {
        "mdpi": 108,
        "hdpi": 162,
        "xhdpi": 216,
        "xxhdpi": 324,
        "xxxhdpi": 432,
    }.items():
        drawable = ROOT / "android/app/src/main/res" / f"drawable-{density}"
        save(adaptive_mark.resize((size, size), Image.Resampling.LANCZOS), drawable / "ic_launcher_foreground.png")
        save(adaptive_mono.resize((size, size), Image.Resampling.LANCZOS), drawable / "ic_launcher_monochrome.png")

    # Splash marks: pre-Android 12 uses a larger mark; Android 12+ uses a
    # smaller mark because the system applies its own circular mask.
    splash_mark = scaled_mark(light_splash_mark, 0.78)
    splash_icon = scaled_mark(light_splash_mark, 0.58)
    night_splash_mark = scaled_mark(dark_splash_mark, 0.78)
    night_splash_icon = scaled_mark(dark_splash_mark, 0.58)
    for density, size in {
        "mdpi": 256,
        "hdpi": 384,
        "xhdpi": 512,
        "xxhdpi": 768,
        "xxxhdpi": 1024,
    }.items():
        light_dir = ROOT / "android/app/src/main/res" / f"drawable-{density}"
        night_dir = ROOT / "android/app/src/main/res" / f"drawable-night-{density}"
        save(splash_mark.resize((size, size), Image.Resampling.LANCZOS), light_dir / "splash_mark.png")
        save(splash_icon.resize((size, size), Image.Resampling.LANCZOS), light_dir / "splash_icon.png")
        save(night_splash_mark.resize((size, size), Image.Resampling.LANCZOS), night_dir / "splash_mark.png")
        save(night_splash_icon.resize((size, size), Image.Resampling.LANCZOS), night_dir / "splash_icon.png")

    # Web icons and favicon.
    web_icons = ROOT / "web/icons"
    save(rounded_icon(icon_mark, 32, 0.22), ROOT / "web/favicon.png")
    save(full_icon(icon_mark, 192), web_icons / "Icon-192.png", rgb=True)
    save(full_icon(icon_mark, 512), web_icons / "Icon-512.png", rgb=True)
    save(full_icon(scaled_mark(icon_mark, 0.55), 192), web_icons / "Icon-maskable-192.png", rgb=True)
    save(full_icon(scaled_mark(icon_mark, 0.55), 512), web_icons / "Icon-maskable-512.png", rgb=True)

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
        save(full_icon(icon_mark, size), ios_dir / filename, rgb=True)

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
        save(rounded_icon(icon_mark, size, 0.22), macos_dir / filename)

    # Windows .ico with the standard sizes.
    ico_sizes = [16, 24, 32, 48, 64, 128, 256]
    ico_base = rounded_icon(icon_mark, 1024, 0.22)
    ico_base.save(
        ROOT / "windows/runner/resources/app_icon.ico",
        format="ICO",
        sizes=[(size, size) for size in ico_sizes],
    )

    # iOS launch image. The storyboard background is warm paper.
    launch_dir = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    for filename, (width, height) in {
        "LaunchImage.png": (168, 185),
        "LaunchImage@2x.png": (336, 370),
        "LaunchImage@3x.png": (504, 555),
    }.items():
        canvas = Image.new("RGBA", (width, height), hex_rgba(WARM_PAPER))
        mark_size = int(width * 0.72)
        mark = scaled_mark(light_splash_mark, 0.78).resize(
            (mark_size, mark_size), Image.Resampling.LANCZOS
        )
        canvas.alpha_composite(
            mark,
            ((width - mark_size) // 2, (height - mark_size) // 2),
        )
        save(canvas, launch_dir / filename, rgb=True)

    # Play feature graphic: 1024 x 500, opaque, no unsupported claims.
    feature = Image.new("RGBA", (2048, 1000), hex_rgba(FOREST_INK))
    feature_draw = ImageDraw.Draw(feature, "RGBA")
    feature_draw.ellipse(
        (1450, -260, 2300, 590),
        outline=hex_rgba(TERRACOTTA, 34),
        width=3,
    )
    feature_draw.ellipse(
        (1600, -110, 2150, 440),
        outline=hex_rgba(WARM_PAPER, 26),
        width=2,
    )
    feature_draw.line((120, 890, 1928, 890), fill=hex_rgba(TERRACOTTA, 80), width=2)

    feature_mark = scaled_mark(icon_mark, 0.72).resize((720, 720), Image.Resampling.LANCZOS)
    feature.alpha_composite(feature_mark, (130, 140))

    georgia_path = Path(r"C:\Windows\Fonts\georgiab.ttf")
    segoe_path = Path(r"C:\Windows\Fonts\segoeui.ttf")
    segoe_bold_path = Path(r"C:\Windows\Fonts\segoeuib.ttf")
    try:
        title_font = ImageFont.truetype(str(georgia_path), 220)
        body_font = ImageFont.truetype(str(segoe_path), 66)
        label_font = ImageFont.truetype(str(segoe_bold_path), 34)
    except OSError:
        title_font = ImageFont.load_default()
        body_font = ImageFont.load_default()
        label_font = ImageFont.load_default()

    feature_draw.text((920, 210), "Relay", font=title_font, fill=hex_rgba(WARM_PAPER))
    feature_draw.line((930, 500, 1080, 500), fill=hex_rgba(TERRACOTTA), width=8)
    feature_draw.text(
        (920, 570),
        "Read offline. Share nearby.",
        font=body_font,
        fill=hex_rgba(SAGE),
    )
    feature_draw.text(
        (925, 690),
        "PDF & EPUB   /   OFFLINE READING   /   DIRECT NEARBY SHARING",
        font=label_font,
        fill=hex_rgba(TERRACOTTA),
    )
    save(feature.resize((1024, 500), Image.Resampling.LANCZOS), store / "feature-graphic-1024x500.png", rgb=True)

    # A short manifest for reviewers and future automation.
    manifest = {
        "generated_by": "tool/generate_brand_assets.py",
        "palette": {
            "forest_ink": FOREST_INK,
            "warm_paper": WARM_PAPER,
            "terracotta": TERRACOTTA,
            "sage": SAGE,
            "olive_gray": OLIVE_GRAY,
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
    (store / "brand-assets.json").write_text(
        json.dumps(manifest, indent=2) + "\n",
        encoding="utf-8",
    )

    print("Generated Relay brand assets.")
    print(f"  source: {brand / 'relay-icon-1024.png'}")
    print(f"  play icon: {store / 'icon-512.png'}")
    print(f"  feature: {store / 'feature-graphic-1024x500.png'}")


if __name__ == "__main__":
    main()
