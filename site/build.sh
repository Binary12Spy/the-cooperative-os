#!/usr/bin/env bash
# Render the site's Markdown sources into single, self-contained static HTML
# files: CSS and fonts inlined, no JavaScript, no network at view time.
#
# Requires: pandoc.
#
# Usage:
#   ./build.sh            # writes the-cooperative-os.html
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v pandoc >/dev/null 2>&1; then
  echo "error: pandoc not found. Install pandoc first." >&2
  exit 1
fi

# Render one Markdown file to a self-contained HTML page.
#
# The template renders the title/subtitle/byline in a masthead from metadata, so
# the body must not repeat them. We drop the leading heading block from the
# source: everything up to and including the first blank line after the initial
# H1 (+ optional subtitle/byline) is metadata already shown by the masthead.
#
# Args: <src.md> <out.html> <title> <subtitle> <author-or-empty> <date-or-empty>
render() {
  local src="$1" out="$2" title="$3" subtitle="$4" author="$5" date="$6"

  local body
  body="$(mktemp)"

  # Strip the leading front-matter block. The paper uses a '---' rule after the
  # byline; emit everything after it (the masthead already shows the title,
  # subtitle, and byline from metadata).
  awk 'seen { print } /^---[[:space:]]*$/ && !seen { seen=1 }' "$src" > "$body"

  # --embed-resources inlines the stylesheet and woff fonts as data: URIs.
  # --shift-heading-level-by=1 pushes top-level '#' sections to <h2>, leaving
  # the masthead <h1> as the single document h1.
  local args=(
    "$body"
    --from=gfm
    --to=html5
    --standalone
    --embed-resources
    --shift-heading-level-by=1
    --template="$here/template.html"
    --css="$here/assets/tufte.css"
    --css="$here/assets/paper.css"
    --metadata title="$title"
    --metadata subtitle="$subtitle"
    --metadata lang="en"
    --output="$out"
  )
  [ -n "$author" ] && args+=(--metadata author="$author")
  [ -n "$date" ] && args+=(--metadata date="$date")

  pandoc "${args[@]}"
  rm -f "$body"
  echo "wrote $out ($(wc -c < "$out") bytes, self-contained)"
}

render \
  "$here/../the-cooperative-os.md" \
  "$here/the-cooperative-os.html" \
  "The Cooperative OS" \
  "How trusting your software could make everything faster, and why we stopped." \
  "Ethan Smith" \
  "July 2026"
