# The plant test

**Principle.** A detector, guard, alert, or safety check does not exist until you have
**injected the fault it is meant to catch and watched it fire end-to-end** — including
the delivery path (the alert actually arrived, the block actually blocked).

Until then you don't have a safeguard; you have a *hope* that looks like one. Worse
than nothing, because it produces false confidence.

## Why — seven guards that all "passed review" and did nothing

Every one of these was written, looked correct, and was believed to work. None had
been made to fire on a real fault. All were silent no-ops:

1. A guard that called a helper function that didn't exist → the script errored, exited
   0, and **allowed everything**.
2. A file-change watcher that resolved the wrong user profile → it watched an empty
   folder and never saw a change.
3. A fix applied to the wrong copy of a file → the live copy was untouched.
4. A detector whose alert step needed an environment variable that was never set → it
   detected correctly and then sent nothing.
5. An `awk` field-index bug → it always compared the wrong column.
6. A detection window narrower than the schedule interval → the condition came and went
   between checks, every time.
7. A "verified working" hook that had only ever been *staged*, never promoted → it
   wasn't running at all.

The common thread: each was validated by *reading the code*, not by *making it catch a
fault*. Reading can't find any of the seven.

## The template

Record it wherever you close the task — a test, an incident note, a PR description:

```
plant:    <the exact command/edit that injects the fault>
expect:   <the observable result — the block message, the alert delivered, the exit code>
observed: <timestamp + the actual output you saw>
```

If you can't write the `plant` line, you don't yet understand what the guard is
protecting against. If `observed` doesn't match `expect`, the guard isn't done.

## Applying it

- **Guards / hooks:** trigger the thing the hook should block; confirm it blocks *and*
  that the message the model sees is the one you intended.
- **Alerts:** force the alerting condition on a real (or realistic) target; confirm the
  message actually lands in the channel, not just that the code path ran.
- **Restore/backup:** the plant is "restore a random file from the backup and diff it
  against the live one." A backup you've never restored is a hope.
- **Detectors on a schedule:** make sure the fault stays observable at least one full
  interval, or the detector will miss it between runs.
