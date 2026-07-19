#!/usr/bin/env bash
# 推送前检查：拦截私有计划文件与常见密钥内容。
# 由 .githooks/pre-push 调用；也可手动：./scripts/check-before-push.sh

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

remote_name="${1:-origin}"

echo "==> 推送前检查（remote=${remote_name}）"

is_blocked_path() {
  case "$1" in
    VERSION_ROADMAP.txt|*/VERSION_ROADMAP.txt) return 0 ;;
    *ROADMAP*.txt|*ROADMAP*.md) return 0 ;;
    PRIVATE_*|*/PRIVATE_*) return 0 ;;
    docs/private/*) return 0 ;;
    .env|.env.*|*/.env|*/.env.*) return 0 ;;
    *.pem|*.p12|*.mobileprovision) return 0 ;;
    Secrets.xcconfig|*/Secrets.xcconfig) return 0 ;;
    GoogleService-Info.plist|*/GoogleService-Info.plist) return 0 ;;
    AuthKey_*.p8|*/AuthKey_*.p8) return 0 ;;
    id_rsa|id_ed25519|*/id_rsa|*/id_ed25519) return 0 ;;
    *) return 1 ;;
  esac
}

failed=0
blocked_list=""
secret_list=""

# 1) 禁止仍被跟踪的私有计划文件
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if is_blocked_path "$f"; then
    blocked_list="${blocked_list}${f}"$'\n'
    failed=1
  fi
done <<EOF
$(git ls-files)
EOF

# 2) 扫描相对 upstream 的变更内容（无 upstream 则扫 HEAD 触及文件）
scan_files=""
if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
  scan_files="$(git diff --name-only --diff-filter=ACM '@{u}..HEAD' 2>/dev/null || true)"
fi
if [ -z "$scan_files" ]; then
  scan_files="$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null || true)"
fi

SECRET_RE='BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY|github_pat_[A-Za-z0-9_]{20,}|ghp_[A-Za-z0-9]{36}|AKIA[0-9A-Z]{16}'

while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ -f "$f" ] || continue
  case "$f" in
    *.png|*.jpg|*.jpeg|*.gif|*.webp|*.ico|*.pdf|*.zip|*.mp3|*.m4a|*.wav|*.caf) continue ;;
  esac
  if grep -a -E -q "$SECRET_RE" "$f" 2>/dev/null; then
    secret_list="${secret_list}${f}"$'\n'
    failed=1
  fi
done <<EOF
$scan_files
EOF

if [ -n "$blocked_list" ]; then
  echo "❌ 检测到禁止推送的私有计划/敏感路径："
  printf '%s' "$blocked_list" | sed '/^$/d' | sed 's/^/   - /'
  echo "   （本地可保留 VERSION_ROADMAP.txt，但必须 git rm --cached 且已被 .gitignore）"
fi

if [ -n "$secret_list" ]; then
  echo "❌ 检测到疑似密钥/私钥内容："
  printf '%s' "$secret_list" | sed '/^$/d' | sed 's/^/   - /'
fi

if [ "$failed" -ne 0 ]; then
  echo "==> 推送已中止。修复后再试。"
  exit 1
fi

echo "==> 检查通过。"
exit 0
