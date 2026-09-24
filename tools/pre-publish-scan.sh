#!/usr/bin/env bash
# pre-publish-scan.sh — flag personal data and secrets before files go public.
#
# Usage:  tools/pre-publish-scan.sh [path ...]     (default: current directory)
# Exit:   0 = nothing found, 1 = findings
#
# Allowlist  regexes, one per line, matched against "file:line:match".
#            Default ./.publish-allow (override with PUBLISH_ALLOW_FILE).
#            Commit it: it only holds known-safe placeholders.
# Denylist   private words, one per line: your name, family, clients, hostnames.
#            Default ~/.config/publish-deny.txt (override with PUBLISH_DENY_FILE).
#            Never commit it: it contains the very words you are hiding.
#
# Matches are masked in the output so the report is safe to paste or run in CI.

set -uo pipefail

paths=("$@")
[ ${#paths[@]} -eq 0 ] && paths=(.)
allow_file=${PUBLISH_ALLOW_FILE:-.publish-allow}
deny_file=${PUBLISH_DENY_FILE:-$HOME/.config/publish-deny.txt}

# Placeholders that are always fine.
builtin_allow='example\.(com|org|net)|noreply@|@users\.noreply\.github\.com|/home/user([/:]|$)|/Users/you([/:]|$)|(^|[^0-9])(127\.0\.0\.1|0\.0\.0\.0)([^0-9]|$)'

findings=0

allowed() { # hit -> 0 if allowlisted
  printf '%s\n' "$1" | grep -qE "$builtin_allow" && return 0
  [ -s "$allow_file" ] && printf '%s\n' "$1" | grep -qEf "$allow_file" && return 0
  return 1
}

report() { # category, "file:line:match"
  local file=${2%%:*} rest=${2#*:}
  local line=${rest%%:*} match=${rest#*:}
  printf '%-18s %s:%s  %s… (%d chars)\n' "$1" "$file" "$line" "${match:0:3}" "${#match}"
  findings=$((findings + 1))
}

scan() { # category, extra grep flags (may be empty), regex
  local hit
  while IFS= read -r hit; do
    allowed "$hit" || report "$1" "$hit"
  done < <(grep -rnoHIE $2 --exclude-dir=.git --exclude-dir=node_modules \
             -e "$3" -- "${paths[@]}" 2>/dev/null)
}

Q="[\"']"             # a quote character
V="[^\"'[:space:]]"   # a value character

# Personal data
scan email       ""   '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
scan phone       ""   '\+[0-9]{1,3}[ .-]?[0-9]{2,4}[ .-]?[0-9]{3,4}[ .-]?[0-9]{3,4}'
scan iban        ""   '(^|[^A-Za-z0-9])[A-Z]{2}[0-9]{2}( ?[A-Z0-9]{4}){3,7}( ?[A-Z0-9]{1,4})?'
scan ipv4        ""   '(^|[^0-9.])([0-9]{1,3}\.){3}[0-9]{1,3}([^0-9.]|$)'
scan home-path   ""   '(/home/[a-z_][a-z0-9_-]*|/Users/[A-Za-z0-9._-]+|[A-Za-z]:\\+Users\\+[A-Za-z0-9._-]+)'
scan chat-id     "-i" "chat[_-]?id${Q}?[[:space:]]*[:=][[:space:]]*${Q}?-?[0-9]{6,}"

# Secrets
scan private-key ""   '-----BEGIN [A-Z ]*PRIVATE KEY-----'
scan anthropic   ""   'sk-ant-[A-Za-z0-9_-]{20,}'
scan openai      ""   'sk-(proj-)?[A-Za-z0-9]{32,}'
scan github      ""   '(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{40,}'
scan slack       ""   'xox[abprs]-[A-Za-z0-9-]{10,}'
scan aws         ""   'AKIA[0-9A-Z]{16}'
scan google      ""   'AIza[0-9A-Za-z_-]{35}'
scan telegram    ""   '[0-9]{8,10}:[A-Za-z0-9_-]{35}'
scan jwt         ""   'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
scan assignment  "-i" "(api[_-]?key|secret|token|passw(or)?d)${Q}?[[:space:]]*[:=][[:space:]]*${Q}${V}{8,}"

# Your own private words
if [ -s "$deny_file" ]; then
  while IFS= read -r hit; do
    allowed "$hit" || report denylist "$hit"
  done < <(grep -rnoHIiF --exclude-dir=.git --exclude-dir=node_modules \
             -f "$deny_file" -- "${paths[@]}" 2>/dev/null)
else
  echo "note: no denylist at $deny_file — names, clients and hostnames are not checked" >&2
fi

if [ "$findings" -gt 0 ]; then
  echo "$findings finding(s). Remove them, or allowlist known-safe ones in $allow_file." >&2
  exit 1
fi
echo "clean" >&2
