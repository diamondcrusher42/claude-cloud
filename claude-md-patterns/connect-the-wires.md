# Connect the wires

**Principle.** Building a thing and *reaching* it are different achievements. A feature
that exists but nothing calls is not done — it's dead code that passed its own unit
tests.

## The incident

A semantic-memory store was built, populated, and unit-tested — all green. But the
session-start checklist never called it, so the agent never actually read from it. For
weeks it behaved as if it had no memory at all, while every component "worked". Nobody
had checked whether a *fresh session* would reach the feature in the normal flow.

## The three questions (ask before "done")

1. **Cold-start reach:** would a brand-new session, doing the normal thing, actually
   use this — right now, with no manual nudging? Trace from the real entry point
   (a hook, a command, a cron line, a skill name) to the new code.
2. **Removal test:** what test or check *fails* if you delete the wiring? If nothing
   fails, nothing depends on it — it isn't wired.
3. **Execution-path trace:** name the call path from entry point to new code out loud.
   If you can't, you don't know that it runs.

## Five reasons wiring gets skipped

- **Completion bias** — writing the component *feels* like finishing the task.
- **No end-to-end instinct** — unit tests pass, so the loop closes too early.
- **Invisible integration points** — the registration/wiring step lives in a different
  file than the feature and is easy to forget.
- **Existence ≠ connection** — "the function is there" gets mistaken for "the function
  runs".
- **No smoke test** — nothing exercises the whole path from the outside.

## Cheap enforcement

- Add one **smoke test** that drives the real entry point and asserts the new code ran
  (a log line, a side effect, a returned value) — this is also the "removal test" from
  question 2.
- When closing a task, require the answer to question 1 in the report: *"a fresh session
  reaches this via `<entry point>` → … → `<new code>`."* "Working on the feature" is not
  an answer; a call path is.
