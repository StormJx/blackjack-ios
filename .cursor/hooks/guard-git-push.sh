#!/usr/bin/env bash
# Cursor：拦截含 git push 的 shell，先跑仓库推送检查。
set -euo pipefail

input="$(cat)"

if ! printf '%s' "$input" | grep -q '"command"'; then
  printf '%s\n' '{"permission":"allow"}'
  exit 0
fi

command="$(printf '%s' "$input" | python3 -c 'import json,sys
try:
    print(json.load(sys.stdin).get("command") or "")
except Exception:
    print("")
')"

if ! printf '%s' "$command" | grep -Eq 'git[[:space:]]+push'; then
  printf '%s\n' '{"permission":"allow"}'
  exit 0
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CHECK="$ROOT/scripts/check-before-push.sh"

if [ -f "$CHECK" ]; then
  chmod +x "$CHECK" 2>/dev/null || true
  if ! "$CHECK" origin; then
    printf '%s\n' '{"permission":"deny","user_message":"推送前检查未通过（私有计划或疑似密钥）。请先 git rm --cached 相关文件并确认 .gitignore。","agent_message":"Blocked git push: check-before-push.sh failed."}'
    exit 0
  fi
fi

printf '%s\n' '{"permission":"allow"}'
exit 0
