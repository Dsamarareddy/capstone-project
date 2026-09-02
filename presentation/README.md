# Presentation

`capstone-presentation.md` is a [Marp](https://marp.app/) slide deck (plain Markdown with a `marp: true`
front-matter block). Marp CLI was used to export it to `.pptx`/`.pdf` for submission — those exported files
are gitignored (see root `.gitignore`) since they're generated output, not source.

## Re-export after editing the deck

```powershell
npx --yes @marp-team/marp-cli@latest capstone-presentation.md --pptx --allow-local-files -o capstone-presentation.pptx
npx --yes @marp-team/marp-cli@latest capstone-presentation.md --pdf --allow-local-files -o capstone-presentation.pdf
```

The first run downloads a headless Chrome via Puppeteer (requires internet access once); subsequent runs
reuse the cached browser.

## If `npx`/Chrome isn't available

Open `capstone-presentation.md` directly — any Markdown viewer renders it as readable slide-shaped sections,
or paste each `---`-delimited section into PowerPoint manually as one slide per section.
