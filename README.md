# claude-cloud

Battle-tested patterns, tools, and principles for running **Claude Code agents** —
especially long-running or unattended ones — distilled from a private daily-use setup
and stripped to what's safe and useful to share.

Everything here is meant to be lifted into your own setup. Each item is a single
feature, has been used on real work, carries no personal data, and says plainly what
it does and doesn't do. The bar every item clears is written down in
[`PUBLISHING.md`](./PUBLISHING.md).

## What's here

| Path | What it is |
|------|------------|
| [`claude-md-patterns/`](./claude-md-patterns/) | The operating principles that made an unattended agent reliable — evidence-gated close, builder/auditor review, the plant test, connect-the-wires, mechanized fixes, prose-rules→hooks. Mostly paste-able prose and prompts. |
| [`tools/`](./tools/) | Small, self-contained scripts. Currently `pre-publish-scan.sh` (+ tests): scan a tree for personal data and secret formats before it goes public. |
| [`PUBLISHING.md`](./PUBLISHING.md) | The standard each item must meet, plus a sanitization checklist and the scanner's usage. |
| [`SHARE-CANDIDATES.md`](./SHARE-CANDIDATES.md) | The running catalog of what's queued to publish next, with evidence levels and what still needs stripping. |

## Start here

If you run an agent unattended, the highest-value, lowest-effort things to adopt are
the principles in [`claude-md-patterns/`](./claude-md-patterns/):

1. **Close every task as DONE / PARTIAL / BLOCKED**, and require evidence for "done".
2. **Never let the builder grade its own work** — a fresh-context reviewer decides.
3. **A detector doesn't exist until it has fired on a planted fault.**
4. **"Done" means wired** — a fresh session must actually reach the thing.

## Provenance & honesty

- Items are labelled by evidence: **proven** (used repeatedly, failures fixed on the
  record), **likely** (complete, some real use), or **untested** (idea only — shared as
  a principle, never as a finished tool).
- The names, hosts, accounts and business context of the original setup have been
  removed; examples are synthetic.
- Third-party skills and tools the original setup used (e.g. Anthropic's public skills,
  and others under their own licenses) are **not** republished here — they're linked in
  `SHARE-CANDIDATES.md` and belong to their authors.

## Contributing / reuse

Take what's useful. If you extend a tool, keep it single-feature and configurable via
environment variables — no hard-coded paths, hosts, or accounts. Run
`tools/pre-publish-scan.sh` (with your own `~/.config/publish-deny.txt` denylist)
before committing anything derived from a private setup.

## License

No license has been chosen yet — add one before treating this as reusable
(and note that any third-party material stays under its original license).
