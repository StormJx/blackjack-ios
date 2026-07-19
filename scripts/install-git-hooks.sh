#!/usr/bin/env bash
# 一键启用本仓库 Git hooks（把 hooksPath 指到 .githooks）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
chmod +x .githooks/pre-push scripts/check-before-push.sh scripts/install-git-hooks.sh
git config core.hooksPath .githooks
echo "已设置 core.hooksPath=.githooks"
echo "之后每次 git push 会自动运行 scripts/check-before-push.sh"
