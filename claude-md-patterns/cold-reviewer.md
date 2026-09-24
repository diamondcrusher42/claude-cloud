# Cold-context review

**Principle.** The thing that built a change is the worst judge of whether it's done.

- A subagent's "done" is a *claim*, not a fact.
- A reviewer who shares the builder's context inherits the builder's blind spots and
  tends to accept its framing ("looks right, tests pass").
- So the reviewer should have **fresh context** and an adversarial job: find what's
  wrong, default to **NO-GO**, and only then argue itself up to GO.

## The incident that proved it

On one change, the builder and a same-context reviewer both said **GO** — 23 of 23
tests passing. A separate reviewer, given only the plan and the diff with no build
history, said **NO-GO** and listed seven concrete ways the change failed in cases the
tests didn't cover. The tests were green because they only exercised what had been
built. Green tests measure coverage of the happy path, not correctness.

## Reviewer subagent prompt

```
You did NOT build this change, and you have no stake in it being done.
Your job is to find what's wrong.

1. Read PLAN.md (or the task) line by line. For each item, check it against the
   actual diff and, where you can, against runtime/disk — not against the
   builder's summary.
2. List everything the user still cannot do, or that will break in a case the
   tests don't cover.
3. Default verdict is NO-GO. Only move to GO if you cannot find a blocking gap.
4. Before you finish, name three things you were too generous about in this very
   review, and re-check them.

Output: VERDICT (GO / NO-GO) · BLOCKING GAPS · things you're unsure about.
```

## Using it

- Run it as a separate subagent/session so it genuinely lacks the build context —
  don't just tell the same session to "now review yourself."
- Feed it the plan and the diff, not the builder's prose summary of them.
- Treat a NO-GO as the default that must be overturned with evidence, not an opinion
  to weigh against the builder's confidence.

## What to strip if you saw this elsewhere

Drop grandiose names (armor/military metaphors, "full-spectrum", numbered "layers") — it's just a
fresh-context reviewer with an attack brief. If you want structure, the six things
worth checking are: plan completeness, implementation vs. plan, implementation vs.
design, missing pieces (absence detection), data consistency, and ordinary code review.
