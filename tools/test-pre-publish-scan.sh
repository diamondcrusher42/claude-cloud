#!/usr/bin/env bash
# Tests for pre-publish-scan.sh. Fake values are assembled at runtime so this
# file itself never contains a string the scanner (or GitHub) would flag.
set -uo pipefail

scanner="$(cd "$(dirname "$0")" && pwd)/pre-publish-scan.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
pass=0 fail=0

check() { # description, condition-exit-code
  if [ "$2" -eq 0 ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $1"; fi
}

run() { # dir -> sets out, code
  out=$(cd "$1" && PUBLISH_DENY_FILE="$tmp/deny.txt" PUBLISH_ALLOW_FILE=.publish-allow \
        bash "$scanner" . 2>&1)
  code=$?
}

rep() { printf "%${2}s" | tr ' ' "$1"; }   # char, count

# --- clean directory -------------------------------------------------------
mkdir -p "$tmp/clean"
cat > "$tmp/clean/README.md" <<'EOF'
Contact: someone@example.com. Runs on 127.0.0.1:8080, files in /home/user/app.
Version 2026.09.24.1 is not an IP address.
EOF
: > "$tmp/deny.txt"
run "$tmp/clean"
check "clean dir exits 0 (got $code: $out)" "$([ "$code" -eq 0 ]; echo $?)"

# --- one hit per category --------------------------------------------------
mkdir -p "$tmp/dirty"
d="$tmp/dirty"
echo "mail me at jane.doe@""gmail.com"                          > "$d/email.md"
echo "call +386"" 41 123 456"                                  > "$d/phone.md"
echo "pay to SI56"" 0201 0001 2345 678"                        > "$d/iban.md"
echo "ssh into 192.168"".1.23 today"                           > "$d/ip.md"
echo "path /ho""me/janedoe/projects"                           > "$d/home.md"
echo "chat_id = -100""1234567890"                              > "$d/chat.md"
echo "-----BEGIN RSA ""PRIVATE KEY-----"                       > "$d/key.pem"
echo "k=sk-""ant-api03-$(rep a 30)"                            > "$d/anthropic.env"
echo "g=gh""p_$(rep B 36)"                                     > "$d/github.env"
echo "s=xo""xb-$(rep 1 12)-abc"                                > "$d/slack.env"
echo "a=AK""IA$(rep Q 16)"                                     > "$d/aws.env"
echo "t=12345678"":$(rep x 35)"                                > "$d/telegram.env"
echo "api_key: \"$(rep z 20)\""                                > "$d/assign.yml"
echo "Our client Acme""corp Ltd"                               > "$d/deny.md"
echo "acmecorp" > "$tmp/deny.txt"
run "$d"
check "dirty dir exits 1" "$([ "$code" -eq 1 ]; echo $?)"
for cat in email phone iban ipv4 home-path chat-id private-key anthropic github \
           slack aws telegram assignment denylist; do
  echo "$out" | grep -q "^$cat " ; check "detects $cat" $?
done
echo "$out" | grep -q "$(rep a 30)"; check "secret value is masked in output" "$([ $? -ne 0 ]; echo $?)"

# --- allowlist suppresses a known-safe hit ----------------------------------
mkdir -p "$tmp/allow"
echo "docs mirror at 10.0"".0.1" > "$tmp/allow/doc.md"
echo '10\.0\.0\.1' > "$tmp/allow/.publish-allow"
: > "$tmp/deny.txt"
run "$tmp/allow"
check "allowlist suppresses hit (got $code: $out)" "$([ "$code" -eq 0 ]; echo $?)"

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
