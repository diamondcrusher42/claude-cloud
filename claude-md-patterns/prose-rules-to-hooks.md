# Prose rules → guard hooks

**Principle.** Rules written as prose in `CLAUDE.md` decay: under load, deep in a long
session, the model skims or forgets them. An invariant you actually care about belongs
in a **PreToolUse hook** that blocks the action and returns the rule *as the error
message*. Keep `CLAUDE.md` for identity, operating protocol, and pointers — not a wall
of numbered "always/never" rules.

The mantra that replaced a page of hard rules:

> **Guards block violations automatically. If you're blocked, read the message — it IS
> the rule.**

## What happened

A `CLAUDE.md` grew to ~16 KB with 21 numbered hard rules, each with an incident ID. It
was too long to reliably obey. The rules were moved into guard hooks; the file shrank to
~4.5 KB across a few iterations and *compliance went up*, because the invariants are now
enforced at the moment of the action instead of hoped-for from memory. A regression suite
runs the guards on a schedule so they don't silently rot.

## Example guard (PreToolUse)

Blocks editing a script while the process that sources it is running — editing a
live-sourced file caused a cascading outage once. The rule lives in the message:

```bash
#!/usr/bin/env bash
# pretooluse-guard-live-edit.sh — deny edits to a script that a running process sources.
# Wire as a PreToolUse hook for Edit/Write. Exit 2 = block; the model sees stderr.
set -uo pipefail

target="$1"                       # path the tool wants to edit (from the hook payload)
base=$(basename "$target")

case "$target" in
  *.sh|*.bash|*.py)
    if pgrep -af "$base" | grep -vq "$$"; then
      echo "BLOCKED: '$base' is sourced/run by a live process. Stop that process " \
           "(check: pgrep -af $base), edit, then restart. Editing it live has " \
           "cascaded into an outage before." >&2
      exit 2
    fi
    ;;
esac
exit 0
```

Then plant-test it (see [`plant-test.md`](./plant-test.md)): start a process that runs
the script, try to edit it, confirm the block fires with that message; stop the process,
confirm the edit is allowed.

## Rules of thumb

- **Fail open on hooks that run on every prompt/turn.** A `UserPromptSubmit` hook that
  exits non-zero on a stale flag can freeze the whole session. Advisory context →
  exit 0; only a genuine invariant → exit 2.
- **Know the I/O contract.** Which stream the model actually sees, which exit code
  blocks, and that a shell `trap ... EXIT` does **not** run after `exec` (so an
  exit-logging trap before `exec claude` never fires).
- **Tool-level denies are not enough on their own.** A `Write(...)` deny doesn't stop
  `Edit` or a `sed` via Bash — real enforcement needs the PreToolUse hook too.
- **Lint `CLAUDE.md` for dangling references.** When rules move to hooks, delete the
  prose that pointed at scripts that no longer exist.
