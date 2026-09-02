# Presentation

`capstone-presentation.md` is a [Marp](https://marp.app/) slide deck (plain Markdown with a `marp: true`
front-matter block). Its 8-slide structure (Title → Problem Statement → Solution → CI/CD Pipeline diagram →
AWS Architecture diagram → Security table → Validation table → Thank You) mirrors the format of a reference
submission (`Group21_Foundation.pptx`) another group produced, restyled with this platform's own content and
the real validation results/logs captured during this build (see the Validation slide).

Exported files are gitignored (see root `.gitignore`) since they're generated output, not source. The
current submission copy is exported directly to Downloads, not into this folder:
`C:\Users\samarashima.reddy\Downloads\Group1_Advanced.pptx` / `.pdf`.

## Re-export after editing the deck

```powershell
npx --yes @marp-team/marp-cli@latest capstone-presentation.md --pptx --allow-local-files -o "C:\Users\samarashima.reddy\Downloads\Group1_Advanced.pptx"
npx --yes @marp-team/marp-cli@latest capstone-presentation.md --pdf --allow-local-files -o "C:\Users\samarashima.reddy\Downloads\Group1_Advanced.pdf"
```

The first run downloads a headless Chrome via Puppeteer (requires internet access once); subsequent runs
reuse the cached browser.

## If `npx`/Chrome isn't available

Open `capstone-presentation.md` directly — any Markdown viewer renders it as readable slide-shaped sections,
or paste each `---`-delimited section into PowerPoint manually as one slide per section.
