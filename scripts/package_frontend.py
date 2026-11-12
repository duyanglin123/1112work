"""Create a deployable static frontend with the public API URL baked into config.js."""
from pathlib import Path
import argparse
import shutil

parser = argparse.ArgumentParser()
parser.add_argument("--api-url", required=True, help="Public API base URL, e.g. https://api.example.com")
parser.add_argument("--out", default="dist", help="Output directory")
args = parser.parse_args()

root = Path(__file__).resolve().parents[1]
src = root / "frontend"
out = root / args.out
out.mkdir(parents=True, exist_ok=True)
for name in ("index.html", "app.js", "styles.css"):
    shutil.copy2(src / name, out / name)
api_url = args.api_url.rstrip("/").replace("\\", "\\\\").replace('"', '\\"')
(out / "config.js").write_text(f'window.APP_CONFIG = {{ API_BASE: "{api_url}" }};\n', encoding="utf-8")
print(f"Wrote {out} with API_BASE={args.api_url.rstrip('/')}")
