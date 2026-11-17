#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.." || exit 1
fails=0

check() {
  local name="$1" fixture="$2" want_exit="$3" want_msg="$4" want_rule="${5:-}" out code
  out=$(bash scripts/validate.sh "test/fixtures/$fixture" 2>&1)
  code=$?
  local ok=1
  if [ "$want_exit" = "0" ]; then
    [ "$code" -eq 0 ] || ok=0
  else
    [ "$code" -ne 0 ] || ok=0
  fi
  case "$out" in *"$want_msg"*) ;; *) ok=0 ;; esac
  if [ -n "$want_rule" ]; then
    case "$out" in *"$want_rule"*) ;; *) ok=0 ;; esac
  fi
  if [ "$ok" -eq 1 ]; then
    echo "PASS: $name"
  else
    echo "FAIL: $name (exit=$code, expected $want_exit; wanted '$want_msg' / '$want_rule')"
    echo "$out" | sed 's/^/    /'
    fails=$((fails + 1))
  fi
}

check "valid repo passes" valid 0 "ok: 2 skills"
check "name with colon" invalid-name-colon fail "plugins/br4zz4/skills/a-b/SKILL.md" "must match"
check "name with uppercase" invalid-name-upper fail "plugins/br4zz4/skills/Upper/SKILL.md" "must match"
check "name differs from folder" invalid-name-mismatch fail "plugins/br4zz4/skills/folder-one/SKILL.md" "must equal directory name"
check "name longer than 64" invalid-name-too-long fail "SKILL.md" "exceeds 64"
check "description missing" invalid-desc-missing fail "plugins/br4zz4/skills/alpha/SKILL.md" "description is missing"
check "description longer than 1024" invalid-desc-too-long fail "plugins/br4zz4/skills/alpha/SKILL.md" "exceeds 1024"
check "term matt" invalid-term-matt fail "plugins/br4zz4/skills/alpha/SKILL.md" "forbidden term 'matt'"
check "term pocock" invalid-term-pocock fail "plugins/br4zz4/skills/alpha/SKILL.md" "forbidden term 'pocock'"
check "old prefix oporpino:" invalid-term-oldprefix fail "plugins/br4zz4/skills/alpha/SKILL.md" "legacy skill prefix"
check "broken marketplace json" invalid-marketplace-json fail ".claude-plugin/marketplace.json" "invalid JSON or missing required fields"
check "broken plugin json" invalid-plugin-json fail "plugin.json" "invalid JSON or missing required field"
check "marketplace with empty plugins" invalid-marketplace-empty fail "marketplace.json" "invalid JSON or missing required fields"

if [ "$fails" -ne 0 ]; then
  echo "$fails case(s) failed"
  exit 1
fi
echo "all cases passed"
