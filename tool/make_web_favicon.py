from PIL import Image
from pathlib import Path

src = Image.open(r"store/brand/relay-icon.png").convert("RGBA")
out = Path(r"website/public")

# Browsers request /favicon.ico by default even when icons are declared.
src.resize((48, 48), Image.LANCZOS).save(
    out / "favicon.ico",
    sizes=[(16, 16), (32, 32), (48, 48)],
)
print("favicon", (out / "favicon.ico").stat().st_size)
