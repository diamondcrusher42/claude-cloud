# Share candidates

A curated list of what's worth sharing publicly, drawn from the private agent
setup (skills library, the two long-running agent repos, and their tooling).
Each item is judged against [`PUBLISHING.md`](./PUBLISHING.md): single feature,
tested, portable, clean, plain, attributed.

**How to read this**

- **Evidence** — `PROVEN` (used on real work, failures hit and fixed on the
  record), `LIKELY` (complete and coherent, some real use), `UNPROVEN` (idea or
  stub — principle only, never shipped as a tool).
- **Verdict** — `SKILL`/`TOOL` (extract as a clean standalone), `PRINCIPLE`
  (write up the idea; the code is too entangled to lift), `SKIP`.
- Nothing here ships until it passes `tools/pre-publish-scan.sh` and a human read.
  Personal values are never reproduced in this document — only categories and paths.

Sources are two instances of the **same operating model** (an unattended Claude
Code session on tmux/WSL, supervised by a watchdog, driven over a chat channel,
governed by a slim CLAUDE.md plus guard hooks, with a git-backed error/ticket
system). The strongest material is that model's hard-won operating principles,
which are almost wiring-free and broadly useful.

---

## 0. Do this first — rotate leaked credentials (not a publishing task)

Independent reviewers found these in the **private** repos. They must be rotated
and purged from git history regardless of what gets published, because history
outlives any file deletion. Paths and types only:

| What | Where (private repos) | Action |
|------|----------------------|--------|
| Telegram bot tokens (2 bots) | `errors/resolved/ERR-268/269/274/275/280/281.md:13`; `plans/maintenance-system-fix-v1.2.md:361,375` — leaked via HTTP exception text the error tracker auto-filed | Rotate via BotFather; purge history; redact URLs before logging (see lesson L23) |
| Cloudflare API token (+ account/zone IDs) | `knowledge/fable-infra-access.md:151,184`; `knowledge/cloudflare-tokens.md` | Rotate; purge |
| Committed browser profile (Cookies, Login Data, History DBs) | agent4wiki `\\wsl.localhost\…\lighthouse.*/Default/` (junk dir from an unset-env WSL path) | Delete, purge history, fix the script to use a Linux tmp dir |
| Partial bot token echoed to logs | agent4wiki `start-v4.sh:28` | Stop echoing; rotate if any log was shared |
| Secrets recorded as resolved incidents | `errors/INDEX.md:17,38,59` (CF token, bot token + mail key, CF token) | Confirm all were rotated |
| Real phone number (self-flagged "must remove") | skills repo `keychain/SKILL.md:119` | Remove from the file |
| Internal IPs + chat id + inbox, SSH key paths, private API endpoint, a second home path | skills repo `keychain/SKILL.md:120`, `handshake/SKILL.md:112,142`, `google/SKILL.md:10-17`, `image-gen/SKILL.md:16,32`, `chrome-human/SKILL.md` | Identifiers, not live tokens — strip before any of these skills ship (see §4/§7) |

Then: turn on GitHub **secret scanning + push protection**, add `tmp/`, `*.pid`,
`*.db`, `*.bak*` to `.gitignore`, and `git rm --cached` what's already tracked
(`.gitignore` does not untrack — lesson L30). Run `gitleaks`/`trufflehog` over
full history before making any repo public.

---

## 1. Operating-model principles — the crown jewels

Highest value, lowest effort to share: mostly prose, PROVEN by documented
incidents, almost no personal wiring. Publish as a short essay pack or a
"CLAUDE.md patterns" gist.

| Principle | One line | Evidence | Verdict |
|-----------|----------|----------|---------|
| **Evidence-gated close** | Every task ends `DONE` (with evidence: ran → observed → concluded), `PARTIAL` (what's left) or `BLOCKED` (what unblocks). Unverified is labelled UNVERIFIED. | PROVEN: survived every CLAUDE.md rewrite in both repos | PRINCIPLE + 15-line snippet |
| **Builder never grades its own work** | A subagent's "done" is a claim. A *cold-context* reviewer whose job is to attack the change decides GO/NO-GO, default NO-GO. | PROVEN: a GO (23/23 tests) was overturned by a cold reviewer that found 7 critical bypasses | PRINCIPLE |
| **Plant-test doctrine** | A detector/guard/alert doesn't exist until you've injected the fault it should catch and watched it fire end-to-end, delivery included. | PROVEN: 7 documented silent no-ops that all passed review (guard calling a missing function → exit 0 → allow-all; alert needing an unset env var; detection window narrower than the cron) | PRINCIPLE + template |
| **Connect the wires** | Before "done": would a *fresh* session reach this? what test fails if the wiring is removed? trace the call path. | PROVEN: a fully-built vector memory was never called by the boot checklist → weeks of "amnesia" | PRINCIPLE + 3-question checklist |
| **Mechanize fixes; behavior doesn't stick** | An incident closes only with a *mechanism* (a guard/test that's wired and plant-tested), a structural impossibility argument, or a dated acceptance. "I'll remember" is rejected. | PROVEN: 693 resolved incidents; a behavioral-only fix recurred 4+ times | TOOL (`log_error.sh`+`resolve_error.sh`+`regenerate_index.sh`) + PRINCIPLE |
| **Prose rules → guard hooks** | Rules decay under load. Move invariants into PreToolUse hooks that exit non-zero with an instructive message ("if blocked, read the message — it IS the rule"); keep CLAUDE.md for identity and pointers. | PROVEN: CLAUDE.md shrank 15.7 KB → 4.5 KB across 4 versions; guard regression suite runs every 6h | PRINCIPLE + one example guard |
| **"Exists" ≠ "deployed"** | Staged hooks/allowlists that were never promoted produced false "verified working" claims; subagents optimize for "tests pass," not for a working deployment. | PROVEN: multiple incidents | PRINCIPLE |

**Single-feature packaging:** a `claude-md-patterns/` folder with (a) a 15-line
paste-able Execution Core block, (b) the cold-reviewer prompt, (c) the plant-test
template (`plant:` / `expect:` / `observed:`), (d) the 3-question wiring checklist,
(e) a before/after CLAUDE.md showing the shrink. Strip agent codenames, incident
IDs and the owner's name; drop the "Kevlar Gold / F16 / super-agent" branding.

---

## 2. Reliability & ops tooling (SHARE-AS-TOOL)

Small, PROVEN, and useful to anyone running scheduled or unattended agents.

| Tool | What it does | Evidence | Strip |
|------|--------------|----------|-------|
| **`cron_wrapper.sh` + `cron_absence_check.sh`** | Wrap every cron job: per-run log + `last_run.json`; alert on non-zero exit **or empty output** (4h cooldown); a separate check catches jobs that never ran. If the wrapper's own infra breaks, it `exec`s the job so work isn't lost. | PROVEN: 52–64 crontab lines use it | notifier command → param; `$HOME` log base; hardcoded job name → loop over `last_run.json`. Fix: `set -e` re-enable bug; heredoc breaks on `"` in job name |
| **Severity-routed notifier** (`alert.sh`+`tg_alert.py`+`redact_output.sh`) | Severity decides *delivery*: CRIT sent now, HIGH/MED into hourly/daily digests, LOW logged. A failed CRIT is demoted to the queue, never dropped. Secrets redacted before send; token kept out of argv. | PROVEN: cron-installed flushes | chat ID, token path; merge the 3 duplicated redaction copies. Ship as `notify.py --severity … / --flush` |
| **`cc-supervisor`** (from `watchdog.sh`) | Keep one unattended session alive in tmux: singleton flock with FD_CLOEXEC, real process-liveness check (not just the pane), classify transient vs permanent *before* restarting, STANDBY instead of a restart loop, pane capture on kill, one `NOTIFY_CMD`. | PROVEN: iterated through ~20 incidents | ~150-line env-driven core; cut chat plugin, quota proxy, bot-identity walls to optional `preflight.d/`. **Flag as opt-in:** auto-answering the trust prompt and `git pull` on every recovery are risky defaults |
| **`cc-watch`** (`cc_update_monitor.sh`) | Daily: detect a CLI/plugin version bump (`npm view …` works even with auto-update off), then have a headless model review the changelog against *your* hooks and settings before you upgrade. | PROVEN: an auto-update once added a blocking prompt that hung the unattended session | Slack path, model pin |
| **`dr_restore_drill.sh`** | Monthly: restore a *random* member of the newest backup, sha256-compare to the live file, restore one DB table, alert on mismatch. "A backup you've never restored is a hope." | PROVEN: timer exists | backup glob, report dir → env |
| **`quota` burn-rate router** (`quota_monitor_v2.py`) | From rate-limit utilisation, compute burn/hour and projected end-of-window %, map to PLENTY/…/BLOCKED, and route model tier by mode. | LIKELY | Publish the math with an input adapter; the header-reading proxy is a grey area — see §7 |

**Also worth extracting (score 3):** `probe_gate.sh` (open a ticket only after N
failures in a window), `git_context.sh` (fail-open one-line git state for a hook),
`state_db.py` (WAL SQLite survives `kill -9` where JSONL corrupts — nice demo),
`vault_janitor.py`/`vault_generate_index.sh` (report-only lint; only `--apply`
writes), `c_drive_watcher.sh` (read Windows C: free space from WSL2 with interop
off via `df /usr/lib/wsl/drivers`).

---

## 3. Security & safety

| Item | What / principle | Evidence | Notes |
|------|------------------|----------|-------|
| **Untrusted-content scanner** (`injection_check.py` + tests) | Screen anything fetched (READMEs, Reddit, web, MCP results) for instruction-shaped content **before** it enters context. Scans each JSON *string value* so keys/structure can't false-positive. Exit 0/1/2. | PROVEN: regression tests cover 2 real bugs; incident-driven (a fake system-reminder tag in a public README) | Frame honestly as a *tripwire*, not a security boundary (it's regex). `PROTECTED_NAMES` from env. Fix the hook that swallows its own exit code. Merge the two divergent pattern sets |
| **`skill-audit` + `skill-lock`** | Before installing a third-party skill: fetch it, grep for RCE/exfil/injection, check repo age/contributors/advisories → PASS/WARN/FAIL. Keep a sha256+tree-hash manifest to detect later tampering/drift. | LIKELY: tests present | Extend the scan from `SKILL.md` to bundled scripts before shipping; move the "safe hosts" allowlist to config |
| **Secret hygiene set** | Audit credential files by name/mode/mtime **without reading them**; export `.env` as key *names* only; fail the whole export on any secret pattern; **agents never push — a gated cron runs `gitleaks` then pushes**. | Mixed (gate PROVEN via a real PATH bug: cron lacked `gitleaks`, read as "leak found", blocked pushes 3 days) | Resolve binaries to absolute paths in cron |
| **Agent self-protection** | Deny writes to own `settings.json`, `.git/config`, `.git/hooks/*`; back up settings at session start; `chmod 444` the supervisor while it runs so the supervised agent can't edit it. | PROVEN: plant-tested (ERR-200) | **Say explicitly:** a `Write(...)` deny does *not* stop `Edit` or `sed`; real enforcement needs a PreToolUse hook (lesson L31) |
| **`pre-publish-scan.sh`** (this repo) | Grep a tree for emails/phones/IBANs/IPs/home-paths/chat-ids and common token formats + your private denylist, masked output; pre-commit hook. | PROVEN: 18-case test suite in `tools/` | Already clean & portable — the reference implementation of "clean" in `PUBLISHING.md` |

---

## 4. Claude Code skills to publish

### Top picks (PROVEN, near-clean)

- **`plan-skill`** — implementation plans that survive 3 code reviews first try:
  7 gates (build-against-real-world, execute-don't-describe, test-the-failure-mode,
  prove-red-before-green, global-must-be-global, every-new-path-tested,
  catch-the-actual-exception) each tied to a documented failure. PROVEN from a real
  8-version saga. Cut only the crosswalk to sibling skills.
- **`upgrade-plan-skill`** — turn a plan+code into its next version in one pass:
  verify-the-world → run-the-code audit → fold the review in as a **carry-forward
  ledger** so the plan grows, never silently shrinks. PROVEN (same saga).
  (Also a listed built-in — attribute accordingly.)
- **`project-plan`** — docs-before-code protocol for large projects: Phase-0
  problem space → vision/architecture/SPEC/CLAUDE.md → module-by-module vertical
  slices → Chat→Code→Chat debrief loop. Distilled from a public r/ClaudeAI thread
  (cite it). Near-zero PII; ships almost as-is.
- **`prompt-optimizer`** — rewrite a prompt for a specific named weakness, no
  padding. Zero PII, zero wiring. Publish as-is.
- **`workflow`** — orchestration patterns + the standout idea: **subagent
  context-isolation** (attention decays over long context → spawn a fresh Agent per
  step, hand off only file paths). Strip agent names.

### Strong, after a strip (SHARE-AS-SKILL, score 4)

`media-in` (folder → compressed web assets + Haiku alt-tags from 512px thumbnails;
cut Slovenia defaults + OAuth path), `multi-llm` (same-prompt-many-providers compare
+ cost-tiered routing; keys from env), `n8n` (clean REST recipe layer — the most
portable "integrate service X" skill), `photo-sort` (local-only EXIF/CLIP/faces/
captions with dry-run-before-move; ship the missing index script), `printA4` (any
input → print-safe A4 HTML using CSS border-box checkboxes, not `<input>`),
`research` (landscape brief with search-before-writing discipline + injection gate),
`routines` (one line → paste-ready claude.ai Routine spec, 13 templates; drop Notion),
`security-monitor` (token-minimal OSV/pip-audit/file-integrity watch, silent on clean
runs; ship the script, drop the repo list), `startup-check` (idea → scored pitch HTML;
drop venture names + chat step), `voice` (local faster-whisper STT + edge-tts TTS;
ship both scripts), `pravopis-slovenija` (generalize to "proofread HTML in language X"),
`website-builder` (**instrument every site with Clarity+GA4+GSC before launch** +
"don't block AI crawlers" — placeholder the real name/domain/handles in the JSON-LD).

### By family (from the a–l inventory — mostly clean, group into small packs)

Grouping keeps each publishable unit coherent and one-job. Most of these carry only
the ubiquitous home-path / agent-name / chat-id wiring to strip; per-skill exceptions
are noted.

- **Build discipline** (PROVEN): `code-skill` (pre/during/post build gates),
  `janitor` (the canonical audit engine — dead code, secrets, wiring, scope; other
  skills point at it rather than re-implement), `doit-skill` (implement-to-done with
  honest verification + subagent-distrust), `code-audit` (structured good/bad/ugly
  review), `build-app` (plan→mockup→build→test). Zero meaningful PII (only internal
  ERR ids). Strong candidates as a "build-discipline" pack.
- **Plan interrogation** (thinking scaffolds, clean): `grill-me` and `grill-with-docs`
  (relentless one-question-at-a-time plan stress-test, the second tied to a glossary/
  ADRs), `challenger` (adversarial partner), `architect` (idea→implementation plan),
  `decompose`, `first-principles`, `expert`. UNPROVEN as tools — publish as a labelled
  prompt pack.
- **Design / frontend** (PROVEN, near-zero PII): `_hot-skills/pixel-perfect`
  (screenshot→code with quality gates, score 5), `_hot-skills/visual-redesign`
  (CSS-only aesthetic upgrade that leaves JS untouched, score 5),
  `_hot-skills/awwwards-hero`, `_hot-skills/awwwards-motion`,
  `_hot-skills/imagegen-frontend`, `app-design`. (Anthropic's `frontend-design` is
  third-party — §7.)
- **Utilities** (PROVEN unless noted): `fixmath` (re-derive and check every number in
  a doc — score 5, strip chat id), `caveman` (ultra-terse token-saving output mode,
  clean), `cron-manager` (durable systemd user-timer scheduling), `gui-builder` (wrap
  a CLI in a FastAPI dashboard), `large-docs` (chunk/RAG for oversized docs),
  `claude-mentor` (Claude Code internals/version reference; strip the localhost proxy
  addr), `ai-seo` (earn citations in AI answers), `book2skill` (turn a method into a
  SKILL.md), `ideas-log` / `ideas-to-project` (idea capture→triage→validated project).
- **`_super-agents`** — a shared honesty/verification core (`00-FABLE-CORE`) prepended
  to 19 role prompts. The reusable part is the **core**, not the 19 personas. Publish
  the core as a role-prompt template; strip home paths, the owner's name, ERR ids and
  the "Fable/super-agent" branding.

**Marketing/agency skills** (`fb-ads`, `google-ads`, `cold-emailing`, `copy`,
`design-workflow`, `geo-track`) are shareable in principle but lean on business
context; publish only if a genuinely generic version survives the strip.

---

## 5. Workflows & patterns (write-ups, code too entangled to lift)

1. **File-based loop runner** — an agent is a folder: `GOAL.md` (one iteration +
   stop condition), `state.json` (the only memory between iterations), optional
   `precheck.sh` + `token_budget.json`; headless CLI once per iteration until
   `done.flag` or the cap. PROVEN (hundreds of logged runs) — *and* a cautionary
   tale: without respecting `done.flag`/advancing the cursor, one agent re-ran ~410
   times in 4 days, ~327 doing nothing, each still committing. Ship the loop shape +
   the interlocks; take token counts from the CLI's JSON, not by scanning transcripts.
2. **Cheap deterministic gate before every model run** — never wake a model to find
   there's nothing to do: a new-work check + dependency health probe first.
3. **Spawn contract + harvest gate** — every child gets a fixed brief
   (TASK/INPUTS/DELIVERABLE/DONE-CRITERIA/RETURN/BUDGET/FORBIDDEN); the parent
   re-runs the done-criteria itself and checks the diff stayed in scope.
4. **Zero-token detection first, LLM second** — hash/diff deterministically, queue
   changes, call the model only on a real change or finding (page-watch, dep-watch,
   ingest catalog, transcript skill-mining).
5. **LLM-free MCP calls from the shell** — `initialize → tools/call → shutdown` over
   stdio/HTTP; deterministic MCP work costs no tokens and stays out of the session.
6. **Human reply as ground truth** — the agent replies in-thread with its prediction;
   the human's short "OK / correction" reply becomes the label for an accuracy metric.
7. **Dual-implementation test vectors** — write the business math twice: an
   exact-decimal oracle generates the vectors, the production code is asserted against
   them. (Great for finance/tax logic.)
8. **JSONL mailbox with a cursor** — append-only with `flock`; each reader keeps an
   atomically-written cursor; a relay to chat is *not* the agent's inbox, so it must
   drain pending messages at session start.
9. **Context hygiene** — a handoff doc with "re-run *these* evidence commands" +
   traps; guarded auto-`/clear` gated on (fresh handoff, cooldown, idle pane,
   kill-switch file); a wake-up brief written on exit.
10. **Doc-rot tooling** — flag dead paths in code blocks, `last_verified` TTL frontmatter,
    index/orphan lint. Nearly generic already.
11. **Prose-quality gate** (`gate_narrative.py` + lexicon regex) — hard gates on report
    text: word band, banned hedge words, 1–3 actions with deadlines, must contain
    numbers. **Reframe as editing quality** and drop the detector/karma framing (see §7).

---

## 6. Lessons learned → generic best practices (appendix)

Anonymized and deduped across all reviewers. These are the most shareable material —
each is backed by a real, on-the-record incident.

**Doneness & review**
- "Done" needs evidence (ran → observed → concluded); close as DONE/PARTIAL/BLOCKED.
- Never let the builder grade its own work; audit against the *plan*, not the code —
  green tests only cover what was built.
- A detector doesn't exist until it has fired on a *planted* fault, delivery included.
- "Exists" ≠ "wired"; "staged" ≠ "deployed"; require the fix to be referenced by a
  cron/unit/hook/skill.
- Behavioral fixes don't stick — mechanize them, or accept them with a review date.
- Untested guards are worse than none (a missing helper → exit 0 → allow-all + false confidence).
- Two attempts at the same fix, then declare BLOCKED.

**Unattended-session ops**
- Pin the agent CLI, disable auto-update, diff the changelog for new interactive
  prompts before bumping — an unattended session hangs on a prompt nobody can see.
- Classify before restarting: restarts can't fix config/PATH/parse errors; repair
  once, then STANDBY and alert instead of looping.
- Check real process liveness, not just the tmux pane; don't kill on screen-scraped
  error strings (false positives kill healthy sessions).
- Lock FDs are inherited by children (a tmux server kept a dead watchdog's flock) —
  set FD_CLOEXEC.
- A stopped service is not a stopped process — orphans survive `systemctl stop`;
  verify with `pgrep` before editing a live-sourced script.
- Non-login shells (tmux -d, cron, systemd) don't have your PATH — launch via `bash -l`
  or use absolute paths.
- Protect the supervisor from the supervised mechanically (read-only while running);
  allow edits only from an out-of-band human session.

**Multi-agent & process safety**
- One credential, state dir and tmux socket per agent, with an identity check at boot —
  a shared tmux server leaked one agent's token into another's session.
- Check who owns a PID (`/proc/PID/environ`) before killing it; never a generic `pgrep`.
- Shared services must not live in one agent's cgroup — restarting one killed a proxy
  another depended on.
- Don't spawn a headless CLI child from inside a tool call of a session holding a
  long-lived channel/MCP — the tool timeout tears down the transport.
- Serialize heavy MCP + git + file ops; parallel batches crashed the host.

**Budgets, cost & scheduling**
- Give every autonomous run a hard token/cost budget and a global kill-switch file
  checked between iterations.
- Every stop path must advance the cursor or park the trigger, and the scheduler must
  respect terminal flags — else it re-dispatches forever.
- Measure usage from an authoritative source, not by scanning shared transcript folders
  or dividing chars by 4; hardcoded prices go stale.
- Scores must punish failure — treat errored runs (0 tokens) as FAILED; never reward
  iteration count.
- A copied template is not a working agent — smoke-test one real task before scheduling
  (8 cloned "department" agents ran 20 errored iterations each and completed 0 tasks).
- An approval gate needs an owner, a reminder and a timeout, or the loop silently stalls.
- Deterministic decisions (routing, retries, status codes, time drift) belong in lookup
  tables/scripts, not LLM loops.

**Content, secrets & hooks**
- Scan external content for injected harness tags before it reaches context — and test
  the *hook's own* exit-code handling.
- HTTP-client exceptions include the full URL — tokens in URL paths end up in logs;
  redact before logging/auto-filing.
- Gate destructive cleanup on verified success of the previous step (a log scrub after a
  failed push destroyed the only copy of a token).
- `.gitignore` doesn't untrack — use `git rm --cached`.
- Bash deny patterns are fragile — use tool-level denies *plus* PreToolUse hooks.
- Know the hook I/O contract: which stream reaches the model, which exit code blocks,
  and that `trap`s don't survive `exec`.
- Large single-file writes can hit the output-token cap — outline, then Write + Edit-append.
- Zero-token detection first; the model only touches real changes/findings.

---

## 7. Do NOT publish

**Third-party — attribute and link, never republish as ours.**
Anthropic public skills (`docx`, `pdf`, `xlsx`, `skill-creator`, `mcp-builder`,
`web-artifacts-builder`, `webapp-testing`, `frontend-design`, `doc-coauthoring`,
`internal-comms`); Fabric/danielmiessler (`offer-builder`, `humanizer`,
`analyze-claims`, `digest`, `extract-wisdom`); `seo-audit` (coreyhaines31);
`compare-models` and the ~24 `gstack` symlink skills (third-party pack, not present —
`autoplan`, `benchmark`, `browse`, `canary`, `careful`, `codex`, `context-save`,
`design-review`, `investigate`, `ship`, … all SKIP); `openmontage` (**AGPL-3.0** — do
not mix into an MIT repo); `video-use`, `autoresearch` (Karpathy) — need their upstream
licenses. `openai-skill` and `book2skill` are distilled from others' work (an OpenAI
guide; a named creator's method) — rewrite in our own words and cite, or skip.

**Unsafe / dual-use.**
`win10exploits` (references unpatched zero-days + an LPE chain + a live LAN target —
do not publish, and review whether keeping it locally is intended); `tmux_commander.sh`
(chat-driven remote command execution); `bun_delivery_monitor.sh` (a second `getUpdates`
poller that races the plugin). `redteam` is general, defensively-framed security
education with an authorization gate — shareable *as a principle* with the gate and
refusals kept prominent; `twitter` humanization is anti-bot-detection platform
automation — judge ToS before sharing, at most the timing principle. Also SKIP the
skills a reviewer set aside as sensitive on the same grounds — `chrome-human`,
`humanize`, `humanizer` (detector evasion / human-mimicking automation), `instagram`,
`karma-builder` (platform gaming / fake engagement), and `doc-builder`.

**Grey-area / terms-of-service — don't present as best practice.**
Reusing the Claude Code subscription **OAuth token as an API key** in custom scripts;
routing batch automation through an interactive subscription session (tmux send-keys) to
avoid metered billing; framing browser fetch as a **bot-detection bypass** ("a fresh
context is an instant bot flag") — reframe as "agent access to *your own* logged-in
sessions"; the writing pack's "wouldn't clock it as machine-made" / karma-building angle
— reframe as editing quality.

**Personal / business — strip the domain, don't redact real data.**
Health tracking & Garmin sync; finance/invoicing skills carrying real client company
names, VAT/IBAN/addresses and amounts (`racuni-*`, `invoice_xml_builder.py`); family
travel PDFs; personal ventures and their KBs (`microplastics`); named client website
audits; the Notion "Life-OS" DB map; the "CEO/HR/legal/marketing/…" Slack department
agents (mostly stubs that never completed a task — the framing is hype); `setup-pack/`
fleet doctrine (hostnames, LAN IPs, SSH keys, device map, Cloudflare topology) — publish
only the *ideas* (Secrets Protocol = pointers-only, Protected Files, Heartbeat, Mid-Run
Steering), never the files.

**Superseded — remove before sharing anything near them:** `update-all` v1/v2 (keep v3),
the pre-v4 skill backups in `.v1-backup-*`, and the various `CLAUDE.md.bak-*`.

---

## 8. Tone-down checklist (applies everywhere)

- Rename `Kevlar Gold`, `F16 Full-Spectrum`, `super-agent`, `god-mode`, `SOUL`, `brain`,
  `clone army`, the Matrix-style codenames → plain role names (main agent, worker, reviewer).
- Drop unverifiable numbers: "cuts mistakes 41%→3%", "+37.7% in 8 experiments",
  LLM-self-assigned audit scores (68/91/95/100), "272 chunks fully wired".
- Remove contradictory guidance carried across backup files (SDK vs no-SDK, API-key vs
  no-key, `auto` vs `bypassPermissions`) — publish the *distilled* lesson, not the file.
- State what each thing does **not** do (especially the injection scanner and any "guard").
