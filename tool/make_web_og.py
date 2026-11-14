from PIL import Image
from pathlib import Path

src = Image.open(r"store/brand/relay-icon.png").convert("RGBA")
out = Path(r"website/public/assets/brand")
for size in (128, 512, 1024):
    im = src.resize((size, size), Image.LANCZOS)
    im.save(out / f"icon-{size}.png", optimize=True)

og = Image.new("RGBA", (1200, 630), (14, 14, 16, 255))
fg = Image.open(r"store/feature-graphic-1024x500.png").convert("RGBA")
w = 1136
h = round(fg.height * w / fg.width)
fg = fg.resize((w, h), Image.LANCZOS)
og.alpha_composite(fg, ((1200 - w) // 2, (630 - h) // 2))
og.convert("RGB").save(out / "og.png", optimize=True)

print("icon-128", (out / "icon-128.png").stat().st_size)
print("og", (out / "og.png").size, (out / "og.png").stat().st_size)
