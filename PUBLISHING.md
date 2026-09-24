# Publishing standard

Everything in this repo comes out of a private, daily-use Claude Code setup.
Before an item moves from the private side to here, it has to clear this bar.

## The bar

| # | Rule | What it means in practice |
|---|------|---------------------------|
| 1 | **Single feature** | One job, one entry point, explainable in one sentence. If the README needs "and also", split it or cut it. |
| 2 | **Tested** | It has run for real, and a reader can check it: a test script, an example run with expected output, or a documented manual check. State the evidence level honestly (see below). |
| 3 | **Portable** | No hard-coded paths, hosts, accounts, chat IDs or repo names. Config comes from env vars or `<PLACEHOLDER>` values, with a sample config. |
| 4 | **Clean** | No personal data, not even "anonymized" real data. Examples are synthetic. Passes `tools/pre-publish-scan.sh` with your denylist. |
| 5 | **Plain** | Descriptive names, no hype, no unverifiable numbers. Say what it does not do. |
| 6 | **Attributed** | Third-party skills and ideas are linked, not copied. Adaptations credit the original and follow its license. |

### Evidence levels

- **Proven**: used on real work repeatedly. Failures were hit and fixed, the fix is written down (gotchas, changelog, a test).
- **Likely**: complete and coherent, some real use, no recorded failure history.
- **Unproven**: an idea, stub or plan. Do not publish as a tool. At most, publish the principle and mark it untested.

## Sanitization checklist (per item)

1. **Copy, don't fork.** Start from a fresh file tree. Never push a private repo's git history: secrets and personal data live in old commits.
2. **People → roles.** Names of yourself, family, friends, clients and colleagues become "the owner", "a client", "a teammate".
3. **Identifiers → placeholders.** Company and client names, internal repo names, hostnames, tunnel names, IPs, chat and account IDs, ad-account IDs, emails and phone numbers become `<YOUR_…>`.
4. **Paths → `$HOME`.** `/home/<you>/…`, `C:\Users\<you>\…` and WSL mount paths become `$HOME/…` or a config variable.
5. **Drop sensitive domains entirely.** Health, finance, invoices, legal matters, family logistics. Rewrite the example from scratch rather than redacting a real one.
6. **Local business context: keep it only if it's the point.** A country-specific e-invoice builder is useful *because* it's country-specific. A generic tool that happens to mention your accountant is not.
7. **Tone down.** Rename "super-agent", "god mode", "CEO agent" and similar to what the thing does. Remove claims you can't reproduce.
8. **Strip to one feature.** Keep the happy path plus the one failure mode people will hit. Cut integrations that exist only for your setup.
9. **Scan.** Run `tools/pre-publish-scan.sh <path>` with a denylist of your private words (see below) and review every hit.
10. **Read every file** in the final diff before pushing. The scanner is a safety net, not a reviewer.
11. **Rotate** any secret you find in the private source, even if it never goes public.

## The scanner

`tools/pre-publish-scan.sh` greps for emails, phone numbers, IBANs, IPv4 addresses, home-directory paths,
chat IDs, private keys and common API-token formats (Anthropic, OpenAI, GitHub, Slack, AWS, Google, Telegram,
JWT, `api_key = "…"` assignments). Matches are masked in its output.

```sh
tools/pre-publish-scan.sh path/to/candidate/      # exit 0 = clean, 1 = findings
tools/test-pre-publish-scan.sh                    # its own test suite
```

- **Denylist** (never commit it): `~/.config/publish-deny.txt`, one private word per line: your name,
  family names, client names, hostnames, internal repo names, street, company. Checked case-insensitively.
- **Allowlist** (commit it): `.publish-allow`, one regex per line for known-safe hits,
  such as a documentation IP. Placeholders like `example.com`, `127.0.0.1` and `/home/user` are always allowed.

Optional pre-commit hook (`.git/hooks/pre-commit`, make it executable):

```sh
#!/bin/sh
git diff --cached --name-only --diff-filter=ACM -z | xargs -0 tools/pre-publish-scan.sh
```

Also turn on GitHub **secret scanning** and **push protection** for this repo (Settings → Code security).
