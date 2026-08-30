#!/usr/bin/env bash
# L5：在 iPhone 模拟器上拍商店截图。一次只开一个模拟器。
# 默认：iPhone 16 Pro Max（6.9″ / 1320×2868），zh-Hans + en，五张画面。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEVICE="${STORE_SCREENSHOT_DEVICE:-iPhone 16 Pro Max}"
BUNDLE_ID="JiXiang.cards"
OUT_ROOT="${STORE_SCREENSHOT_OUT:-$ROOT/store/screenshots/iphone-69}"
# bet 须在 table 之前，避免下注页带上「上次未完成」恢复条。
SCENES=(welcome bet table help settings)

if [ -n "${STORE_SCREENSHOT_LANGS:-}" ]; then
  # shellcheck disable=SC2206
  LANGS=($STORE_SCREENSHOT_LANGS)
else
  LANGS=(zh-Hans en)
fi

echo "==> L5 截图  device=${DEVICE}"
echo "    输出 ${OUT_ROOT}"

udid="$(xcrun simctl list devices available | grep -F "${DEVICE} (" | sed -n 's/.*(\([0-9A-Fa-f-]\{36\}\)).*/\1/p' | head -1)"
if [ -z "${udid}" ]; then
  echo "找不到可用模拟器：${DEVICE}" >&2
  xcrun simctl list devices available >&2
  exit 1
fi

if ! xcrun simctl list devices | grep -F "$udid" | grep -q Booted; then
  echo "==> 启动模拟器"
  xcrun simctl boot "$udid"
  xcrun simctl bootstatus "$udid" -b
fi

echo "==> 编译 Debug"
DEST="platform=iOS Simulator,id=${udid}"
LOG="${TMPDIR:-/tmp}/cards-store-screenshot-build.log"
xcodebuild -project cards.xcodeproj -scheme cards -destination "$DEST" \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO \
  > "$LOG" 2>&1

APP_PATH="$(xcodebuild -project cards.xcodeproj -scheme cards -destination "$DEST" \
  -configuration Debug -showBuildSettings CODE_SIGNING_ALLOWED=NO \
  | awk -F ' = ' '/ TARGET_BUILD_DIR / { dir=$2 } / FULL_PRODUCT_NAME / { name=$2 } END { print dir "/" name }')"
if [ ! -d "$APP_PATH" ]; then
  echo "找不到 .app：$APP_PATH" >&2
  tail -40 "$LOG" >&2
  exit 1
fi

echo "==> 安装 $APP_PATH"
xcrun simctl uninstall "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$udid" "$APP_PATH"
xcrun simctl status_bar "$udid" override --time "9:41" --batteryLevel 100 --batteryState charged --cellularMode active --dataNetwork wifi >/dev/null

sleep_for_scene() {
  case "$1" in
    table) sleep 6 ;;
    welcome) sleep 4 ;;
    bet|help|settings|privacy) sleep 4 ;;
    *) sleep 3 ;;
  esac
}

launch_scene() {
  local scene="$1" lang="$2"
  xcrun simctl launch "$udid" "$BUNDLE_ID" \
    -StoreScreenshot "$scene" \
    -StoreLanguage "$lang" >/dev/null
}

for lang in "${LANGS[@]}"; do
  dest="${OUT_ROOT}/${lang}"
  mkdir -p "$dest"
  echo "==> 语言 ${lang}"
  xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl uninstall "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl install "$udid" "$APP_PATH"

  index=1
  for scene in "${SCENES[@]}"; do
    xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
    launch_scene "$scene" "$lang"
    sleep_for_scene "$scene"
    file="$(printf '%s/%02d-%s.png' "$dest" "$index" "$scene")"
    xcrun simctl io "$udid" screenshot "$file" >/dev/null
    echo "    $file"
    index=$((index + 1))
  done
done

xcrun simctl status_bar "$udid" clear >/dev/null 2>&1 || true
echo "==> 完成。上传 App Store Connect 的 6.9″ 槽。"
