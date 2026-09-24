# claude-md-patterns

Six operating principles that turned an unattended Claude Code agent from
"usually fine" into "reliable enough to leave running." They're mostly prose and
prompts — paste them into your `CLAUDE.md`, a reviewer subagent, or your own
checklists.

Each one came out of a real failure that recurred until it was mechanized. They're
listed here in the order they pay off.

| Pattern | The one-liner | File |
|---------|---------------|------|
| **Evidence-gated close** | Every task ends DONE / PARTIAL / BLOCKED, and "done" needs evidence. | [`execution-core.md`](./execution-core.md) |
| **Cold-context review** | The builder never grades its own work; a fresh reviewer attacks the change. | [`cold-reviewer.md`](./cold-reviewer.md) |
| **Plant test** | A detector doesn't exist until you've made it fire on a planted fault. | [`plant-test.md`](./plant-test.md) |
| **Connect the wires** | "Done" means a fresh session actually reaches it. | [`connect-the-wires.md`](./connect-the-wires.md) |
| **Mechanize fixes** | "I'll remember next time" is not a fix. | [`mechanize-fixes.md`](./mechanize-fixes.md) |
| **Prose rules → hooks** | Rules decay under load; move invariants into guard hooks. | [`prose-rules-to-hooks.md`](./prose-rules-to-hooks.md) |

## How they fit together

- **Execution core** sets the vocabulary (DONE/PARTIAL/BLOCKED, "evidence or it
  didn't happen"). Everything else builds on it.
- **Cold review** and **connect-the-wires** are the two checks that catch a false
  "done" — one social (who is allowed to say done), one mechanical (does it run).
- **Plant test** and **mechanize fixes** are how a *fix* earns the word "fixed":
  it must fire on a planted fault, and it must be a mechanism, not a promise.
- **Prose → hooks** is where these stop being things you hope the model remembers
  and become things the harness enforces.

None of this is model- or vendor-specific; it's the discipline of treating an agent
like production software. Adapt freely.
