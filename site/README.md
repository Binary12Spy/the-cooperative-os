# Paper site

A static, self-contained HTML rendering of
[`../the-cooperative-os.md`](../the-cooperative-os.md), typeset with
[Tufte CSS](https://edwardtufte.github.io/tufte-css/).

The output is a single file with the stylesheet and fonts inlined as `data:`
URIs. It has **no scripts, makes no network requests, and needs no runtime** -
it renders itself from plain markup. You can open it straight off disk
(`file://`), email it, or archive it, and it will look the same years from now.

## Building

With `pandoc` installed:

```sh
site/build.sh
```

This writes `the-cooperative-os.html`. Re-run it whenever the Markdown changes;
the committed HTML is a convenience copy so the page can be published without a
build step.

## Files

- `build.sh` - pandoc invocation that produces the static HTML.
- `template.html` - pandoc HTML template (masthead + colophon).
- `assets/tufte.css` - Tufte CSS v1.8.0, trimmed to reference only the `.woff`
  fonts (vendored, unminified so it stays inspectable).
- `assets/paper.css` - small additive styles for code blocks and tables.
- `assets/et-book/` - the ET Book web fonts (vendored, `.woff`).
- `the-cooperative-os.html` - generated, self-contained output.

## Publishing

Serving `site/the-cooperative-os.html` is enough - it depends on nothing else.

To publish, `./package.sh` bundles the rendered paper into
`the-cooperative-os-site.zip` as the site root:

```
index.html   # the paper
```

Deploying the zip's contents at the site root serves the paper (currently live
via Cloudflare) at
[the-cooperative-os.project802.io](https://the-cooperative-os.project802.io/).

The zip and its `dist/` staging directory are build artifacts (git-ignored);
regenerate them any time with `./build.sh && ./package.sh`.
