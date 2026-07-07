#!/usr/bin/env bash
# Bundle the rendered paper into a static-hosting zip.
#
# The paper is the whole site, so it is served as the root index.html. Deploying
# the zip's contents at the site root yields:
#
#   /   ->  index.html   (the paper)
#
# The page is fully self-contained (CSS and fonts inlined), so there are no
# sibling assets to carry.
#
# Requires: the rendered HTML to exist (run ./build.sh first). Uses the `zip`
# CLI when available, otherwise falls back to python3's zipfile module.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
html="$here/the-cooperative-os.html"
dist="$here/dist"
zip_out="$here/the-cooperative-os-site.zip"

if [ ! -f "$html" ]; then
  echo "error: $html not found. Run ./build.sh first." >&2
  exit 1
fi

# Serve the paper as the site root.
rm -rf "$dist" "$zip_out"
mkdir -p "$dist"
cp "$html" "$dist/index.html"

# Zip the CONTENTS of dist/ so the archive root is the site root, not dist/.
if command -v zip >/dev/null 2>&1; then
  ( cd "$dist" && zip -r -q "$zip_out" . )
else
  ( cd "$dist" && python3 -c 'import os,sys,zipfile
out=sys.argv[1]
with zipfile.ZipFile(out,"w",zipfile.ZIP_DEFLATED) as z:
    for root,_,files in os.walk("."):
        for name in files:
            p=os.path.join(root,name)
            z.write(p, os.path.relpath(p,"."))' "$zip_out" )
fi

echo "wrote $zip_out"
echo "contents:"
python3 -c 'import sys,zipfile
for n in zipfile.ZipFile(sys.argv[1]).namelist(): print("  "+n)' "$zip_out"
