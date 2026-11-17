#!/usr/bin/env bash
set -u

root="${1:-.}"
errors=0
count=0

fail() {
  printf 'error: %s\n' "$1" >&2
  errors=$((errors + 1))
}

frontmatter_value() {
  awk -v key="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    index($0, key ":") == 1 {
      v = substr($0, length(key) + 2)
      sub(/^[ \t]+/, "", v)
      sub(/[ \t]+$/, "", v)
      if ((v ~ /^".*"$/) || (v ~ /^'"'"'.*'"'"'$/)) v = substr(v, 2, length(v) - 2)
      print v
      exit
    }
  ' "$1"
}

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 2; }

for skill in "$root"/plugins/*/skills/*/SKILL.md; do
  [ -f "$skill" ] || continue
  count=$((count + 1))
  dir="$(basename "$(dirname "$skill")")"
  name="$(frontmatter_value "$skill" name)"
  desc="$(frontmatter_value "$skill" description)"

  if [ -z "$name" ]; then
    fail "$skill: name is missing"
  else
    printf '%s' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' \
      || fail "$skill: name '$name' must match ^[a-z0-9]+(-[a-z0-9]+)*$ (lowercase, digits, hyphens)"
    [ "${#name}" -le 64 ] || fail "$skill: name exceeds 64 characters"
    [ "$name" = "$dir" ] || fail "$skill: name '$name' must equal directory name '$dir'"
  fi

  if [ -z "$desc" ]; then
    fail "$skill: description is missing or empty"
  elif [ "${#desc}" -gt 1024 ]; then
    fail "$skill: description exceeds 1024 characters (${#desc})"
  fi
done

if [ -d "$root/plugins" ]; then
  while IFS= read -r hit; do
    [ -n "$hit" ] && fail "$hit: forbidden term 'matt'"
  done < <(grep -rniw matt "$root/plugins" 2>/dev/null)
  while IFS= read -r hit; do
    [ -n "$hit" ] && fail "$hit: forbidden term 'pocock'"
  done < <(grep -rni pocock "$root/plugins" 2>/dev/null)
  while IFS= read -r hit; do
    [ -n "$hit" ] && fail "$hit: legacy skill prefix (oporpino:|matt:|qwert:)"
  done < <(grep -rniE '(oporpino|matt|qwert):[a-z]' "$root/plugins" 2>/dev/null)
fi

market="$root/.claude-plugin/marketplace.json"
if [ ! -f "$market" ]; then
  fail "$market: file is missing"
else
  jq -e '.name and ((.plugins | length) > 0)' "$market" >/dev/null 2>&1 \
    || fail "$market: invalid JSON or missing required fields (name, plugins)"
fi

for pj in "$root"/plugins/*/.claude-plugin/plugin.json; do
  [ -f "$pj" ] || continue
  jq -e '.name' "$pj" >/dev/null 2>&1 \
    || fail "$pj: invalid JSON or missing required field (name)"
done

if [ "$errors" -gt 0 ]; then
  printf 'validation failed: %d error(s)\n' "$errors" >&2
  exit 1
fi

printf 'ok: %d skills\n' "$count"
