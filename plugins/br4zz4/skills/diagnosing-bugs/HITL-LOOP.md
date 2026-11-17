# HITL loop template

Copy the block below to a script, adjust the steps, and run it so a human can be guided and the output captured.

```bash
#!/usr/bin/env bash
set -euo pipefail

step() {
  printf '\n==> %s\n' "$1"
  read -r -p "    [press Enter once finished] " _
}

capture() {
  local var="$1" prompt="$2" reply
  printf '\n==> %s\n' "$prompt"
  read -r -p "    : " reply
  printf -v "$var" '%s' "$reply"
}

step "Start the Rails server with bin/dev, open http://localhost:3000 and log in."

capture FAILED "Press the 'Download report' button. Did it fail? (y/n)"

capture FAILURE_TEXT "Paste the message shown (or type 'none'):"

printf '\n--- Results ---\n'
printf 'FAILED=%s\n' "$FAILED"
printf 'FAILURE_TEXT=%s\n' "$FAILURE_TEXT"
```
