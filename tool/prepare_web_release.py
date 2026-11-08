"""Fingerprint the compiled app so returning browsers load the current release."""
from hashlib import sha256
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "build" / "web"
entry = root / "main.dart.js"
assets = root / "assets"
asset_hash = sha256()
for asset in sorted(assets.rglob("*")):
    if asset.is_file():
        asset_hash.update(asset.relative_to(assets).as_posix().encode())
        asset_hash.update(sha256(asset.read_bytes()).digest())
asset_base = f"release-{asset_hash.hexdigest()[:16]}/"
versioned_name = f"main.{sha256(entry.read_bytes()).hexdigest()[:16]}.dart.js"
# Validate both loader copies before modifying the output.
loaders = [root / "index.html", root / "flutter_bootstrap.js"]
contents = [path.read_text() for path in loaders]
for content in contents:
    if '"mainJsPath":"main.dart.js"' not in content:
        raise RuntimeError("Flutter entrypoint configuration changed; inspect the build before publishing")
if any("_flutter.loader.load();" not in content for content in contents):
    raise RuntimeError("Expected the custom Flutter loader before versioning assets")
(root / asset_base).mkdir()
assets.rename(root / asset_base / "assets")
entry.rename(root / versioned_name)
for path, content in zip(loaders, contents):
    content = content.replace('"mainJsPath":"main.dart.js"', f'"mainJsPath":"{versioned_name}"')
    content = content.replace("_flutter.loader.load();", f'_flutter.loader.load({{config: {{assetBase: "{asset_base}"}}}});')
    path.write_text(content)
# Existing installations can still request the old worker URL. Retire it rather
# than returning a 404 that would leave their previous worker active.
(root / "flutter_service_worker.js").write_text(
    "self.addEventListener('install', () => self.skipWaiting());\n"
    "self.addEventListener('activate', event => event.waitUntil(self.registration.unregister()));\n"
)
print(f"Prepared release: {versioned_name}")
