# Mechanize fixes

**Principle.** "I'll be more careful next time" is not a fix — it's the same system
that just failed, promising to try harder. A problem is only fixed when a *mechanism*
makes the failure hard to repeat.

An incident closes only as one of:

- **mechanism** — a guard, test, or detector that is *wired in* (something actually
  runs it) and has been *plant-tested* (see [`plant-test.md`](./plant-test.md)).
- **structural** — an argument for why the condition can no longer occur (the code path
  was removed, the state is now impossible).
- **accepted** — a deliberate decision to live with it, with a review date.

A behavioral-only "fix" ("the agent will remember to…") is rejected. In the setup this
came from, that policy was added after a behavioral fix for the same issue recurred four
or more times.

## Why it works

Across ~700 resolved incidents, the ones that stayed fixed were the ones tied to a
mechanism. The taxonomy also forces two useful checks at close time:

- **"Exists" vs "wired":** the mechanism must be referenced by something that runs it —
  a cron line, a service unit, a hook, a skill, or another tool. A fix that names a file
  nobody calls isn't a fix. (A real case: a fix was cited as resolved ~20 times while the
  service that was supposed to run it had been dead the whole time.)
- **A dated `accepted`** turns "we'll ignore this for now" from a silent decision into a
  tracked one that resurfaces.

## Minimal version to adopt

You don't need the original tooling. Adopt the *rule* and a tiny closing checklist:

```
Incident closed. Fix type:
  [ ] mechanism  — file: <path>   wired by: <cron/unit/hook/skill/tool>   plant-tested: <yes + evidence>
  [ ] structural — why it can no longer happen: <…>
  [ ] accepted   — review date: <YYYY-MM-DD>   owner: <who>
Behavioral-only ("I'll remember") is not an accepted close.
```

If you want it enforced rather than remembered, this is a natural fit for a guard hook
(see [`prose-rules-to-hooks.md`](./prose-rules-to-hooks.md)): reject a close that names
a mechanism file which isn't referenced anywhere, or that has no plant-test evidence.
