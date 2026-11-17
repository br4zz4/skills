#!/usr/bin/env bash

set -euo pipefail

if [[ -t 1 ]] && command -v tput &>/dev/null && [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
  BOLD=$(tput bold); DIM=$(tput dim); RESET=$(tput sgr0)
  BLUE=$(tput setaf 4); GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3); RED=$(tput setaf 1)
else
  BOLD=""; DIM=""; RESET=""; BLUE=""; GREEN=""; YELLOW=""; RED=""
fi

TOTAL_STAGES=0

_STAGE_INDEX=0
ENV_FILE="${ENV_FILE:-.env}"
WRITTEN_ENV=()
WRITTEN_SECRET=()
SKIPPED=()

_clear() {
  [[ -t 1 ]] || return 0
  if command -v tput &>/dev/null; then tput clear; else printf '\033[2J\033[3J\033[H'; fi
}

banner() {
  _clear
  printf '\n%s%s  %s%s\n' "$BOLD" "$BLUE" "$1" "$RESET"
  printf '%s  %s stages%s\n\n' "$DIM" "$TOTAL_STAGES" "$RESET"
  printf '%s  You work in the browser; this wizard says exactly what to do and\n' "$DIM"
  printf '  records the values you copy back. Press Ctrl-C whenever you like and\n'
  printf '  run it again later: values already saved are remembered.%s\n' "$RESET"
  pause "Shall we begin?"
}

stage() {
  _clear
  _STAGE_INDEX=$((_STAGE_INDEX + 1))
  printf '\n%s%s▸ Stage %s/%s · %s%s\n' \
    "$BOLD" "$BLUE" "$_STAGE_INDEX" "$TOTAL_STAGES" "$1" "$RESET"
}

say()  { printf '  %s\n' "$1"; }
step() { printf '  %s•%s %s\n' "$BLUE" "$RESET" "$1"; }
note() { printf '  %s%s%s\n' "$DIM" "$1" "$RESET"; }
warn() { printf '  %s⚠ %s%s\n' "$YELLOW" "$1" "$RESET"; }

open_url() {
  local url="$1"
  printf '  %s↗ opening%s %s\n' "$GREEN" "$RESET" "$url"
  { if   command -v wslview     >/dev/null 2>&1; then wslview "$url"
    elif command -v explorer.exe >/dev/null 2>&1; then explorer.exe "$url"
    elif command -v xdg-open    >/dev/null 2>&1; then xdg-open "$url"
    elif command -v open        >/dev/null 2>&1; then open "$url"
    else warn "no browser could be launched; open this link yourself: $url"; fi
  } >/dev/null 2>&1 || warn "no browser could be launched, so open this link yourself: $url"
}

pause() {
  printf '  %s%s%s ' "$DIM" "${1:-Press Enter to go on}" "$RESET"
  read -r _ || true
}

confirm() {
  local reply=""
  printf '  %s? %s [y/N] ' "$YELLOW" "$1"
  read -r reply || true
  [[ "$reply" =~ ^[Yy] ]]
}

_existing() {
  [[ -f "$ENV_FILE" ]] || return 1
  local line
  line=$(grep -E "^${1}=" "$ENV_FILE" | tail -n1) || return 1
  printf '%s' "${line#*=}"
}

ask() {
  local key="$1" prompt="$2" current input
  current=$(_existing "$key" || true)
  if [[ -n "$current" ]]; then
    printf '  %s%s%s %s[Enter to keep the saved value]%s ' "$BOLD" "$prompt" "$RESET" "$DIM" "$RESET"
  else
    printf '  %s%s%s ' "$BOLD" "$prompt" "$RESET"
  fi
  read -r input || true
  [[ -z "$input" && -n "$current" ]] && input="$current"
  printf -v "$key" '%s' "$input"
}

ask_secret() {
  local key="$1" prompt="$2" current input
  current=$(_existing "$key" || true)
  if [[ -n "$current" ]]; then
    printf '  %s%s%s %s[Enter to keep the saved value]%s ' "$BOLD" "$prompt" "$RESET" "$DIM" "$RESET"
  else
    printf '  %s%s%s ' "$BOLD" "$prompt" "$RESET"
  fi
  read -rs input || true
  printf '\n'
  [[ -z "$input" && -n "$current" ]] && input="$current"
  printf -v "$key" '%s' "$input"
}

write_env() {
  local key="$1" value="$2" tmp
  touch "$ENV_FILE"
  tmp=$(mktemp)
  grep -vE "^${key}=" "$ENV_FILE" > "$tmp" || true
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  mv "$tmp" "$ENV_FILE"
  WRITTEN_ENV+=("$key")
  printf '  %s✓ saved%s %s → %s\n' "$GREEN" "$RESET" "$key" "$ENV_FILE"
}

set_secret() {
  local name="$1" value="$2"
  if command -v gh &>/dev/null && gh auth status &>/dev/null; then
    if printf '%s' "$value" | gh secret set "$name" &>/dev/null; then
      WRITTEN_SECRET+=("$name")
      printf '  %s✓ stored%s GitHub secret %s\n' "$GREEN" "$RESET" "$name"
      return
    fi
  fi
  SKIPPED+=("GitHub secret $name (run by hand: gh secret set $name)")
  warn "GitHub secret $name not set: gh is not ready, so do it afterwards"
}

set_var() {
  local name="$1" value="$2"
  if command -v gh &>/dev/null && gh auth status &>/dev/null; then
    if gh variable set "$name" --body "$value" >/dev/null 2>&1; then
      printf '  %s✓ stored%s GitHub variable %s\n' "$GREEN" "$RESET" "$name"
      return
    fi
  fi
  SKIPPED+=("GitHub variable $name")
  warn "GitHub variable $name not set: gh is not ready, so do it afterwards"
}

finish() {
  _clear
  printf '\n%s%s  ✓ All done%s\n' "$BOLD" "$GREEN" "$RESET"
  (( ${#WRITTEN_ENV[@]} ))    && note "saved ${#WRITTEN_ENV[@]} value(s) in $ENV_FILE: ${WRITTEN_ENV[*]}"
  (( ${#WRITTEN_SECRET[@]} )) && note "stored ${#WRITTEN_SECRET[@]} GitHub secret(s): ${WRITTEN_SECRET[*]}"
  if (( ${#SKIPPED[@]} )); then
    printf '\n'; warn "remaining manual work:"
    for s in "${SKIPPED[@]}"; do note "  - $s"; done
  fi
  printf '\n'
}

TOTAL_STAGES=1

banner "Stripe setup"

stage "Stripe: API keys"
say "We will collect your Stripe test keys and keep them for local dev and CI."
open_url "https://dashboard.stripe.com/test/apikeys"
step "On the API keys page, copy the Publishable key (it begins with pk_test_)."
ask STRIPE_PUBLISHABLE_KEY "Paste the publishable key:"
step "On the Secret key row click 'Reveal test key', then copy the value."
ask_secret STRIPE_SECRET_KEY "Paste the secret key:"
write_env STRIPE_PUBLISHABLE_KEY "$STRIPE_PUBLISHABLE_KEY"
write_env STRIPE_SECRET_KEY "$STRIPE_SECRET_KEY"
set_secret STRIPE_SECRET_KEY "$STRIPE_SECRET_KEY"

finish
