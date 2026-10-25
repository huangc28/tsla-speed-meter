#!/bin/bash
# usage: docs/design/frames/main-redesign/export.sh [OUTDIR]
# 第十二輪(visual):把 main-redesign.html 的 12 張畫面和總覽輸出成 2 倍 PNG(預設輸出到這個資料夾)。修訂 1(L73)加了三張 *-drive-ble-unknown;修訂前的 PNG 在 v1/。
# 用 headless Google Chrome;要網路(Google Fonts 的 Inter、Noto Sans TC、Barlow Semi Condensed 和 lucide 圖示)。
# 總覽的高度先用 --dump-dom 讀 ?screen=overview 的 data-h。
# stderr 的 CVDisplayLinkCreateWithCGDisplay failed、Trying to load the allocator multiple times 是雜訊;偶爾有一張被系統中止,單獨重跑就好。
D="$(cd "$(dirname "$0")" && pwd)"; F="$(cd "$D/.." && pwd)/main-redesign.html"
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
OUT=${1:-$D}; mkdir -p "$OUT"
OVH=$("$CH" --headless=new --disable-gpu --window-size=1344,900 --virtual-time-budget=20000 --dump-dom "file://$F?screen=overview" 2>/dev/null | grep -o 'data-h="[0-9]*"' | head -1 | tr -dc 0-9)
[ -n "$OVH" ] || { echo "讀不到總覽高度"; exit 1; }
while read q w h; do
  [ "$h" = "OVH" ] && h=$OVH
  rm -f "$OUT/$q.png"
  "$CH" --headless=new --disable-gpu --hide-scrollbars --window-size=$w,$h --force-device-scale-factor=2 \
    --virtual-time-budget=15000 --screenshot="$OUT/$q.png" "file://$F?screen=$q" >/dev/null 2>&1
  [ -f "$OUT/$q.png" ] && echo "$q ok ${w}x${h}" || echo "$q FAIL"
done <<T
A-drive-ble 844 390
A-drive-gps 844 390
A-parked 844 390
A-drive-ble-unknown 844 390
B-drive-ble 844 390
B-drive-gps 844 390
B-parked 844 390
B-drive-ble-unknown 844 390
C-drive-ble 844 390
C-drive-gps 844 390
C-parked 844 390
C-drive-ble-unknown 844 390
overview 1344 OVH
T
