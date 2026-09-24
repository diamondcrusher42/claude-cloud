# Evidence-gated close

**Principle.** Every task ends in one of three states, and "done" is the one that
needs proof:

- **DONE** — with evidence: what you *ran*, what you *observed*, and the conclusion
  that follows. Anything you didn't verify is labelled `UNVERIFIED`.
- **PARTIAL** — what works, and exactly what's left.
- **BLOCKED** — what's in the way and what would unblock it.

This one block survived every rewrite of a heavily-iterated `CLAUDE.md`, because it's
what stops an agent from reporting success it didn't achieve.

## Paste-able CLAUDE.md block

```md
## Execution core
- Every response does work, shows evidence, or states a decision. No filler.
- "Done" REQUIRES evidence: ran → observed → concluded. Unverified work is
  labelled UNVERIFIED, never "done".
- Close every task as one of:
  - DONE — <what ran> → <what you observed> → <conclusion>
  - PARTIAL — <what works> · <what remains>
  - BLOCKED — <the blocker> · <what would unblock it>
- Two attempts at the same fix; the third time, stop and report BLOCKED.
- Refer to code as path:line (quote ≤5 lines); show changes as diffs.
- End with a one-line status: STATUS · EVIDENCE · TOUCHED.
```

## Why each line is there

- **"ran → observed → concluded"** — the failure mode is an agent that says "done"
  after *writing* code but never running it. Forcing the three-part chain makes the
  gap obvious: if you can't fill "observed", you're not done.
- **UNVERIFIED label** — gives the agent an honest option other than lying. It's
  allowed to have not checked, as long as it says so.
- **Two-attempts-then-BLOCKED** — without it, an agent will loop on the same broken
  fix, burning budget and context. The third identical attempt is almost never the
  one that works; escalate instead.
- **path:line, diffs, one-line status** — token economy. Re-quoting whole files and
  re-explaining unchanged context is how long sessions run out of room.

## Gotcha

Pair the block with one filled-in example. Left with only the template, some models
copy the *shape* (`DONE — <what ran>`) literally instead of filling it in. One good
example fixes that.
