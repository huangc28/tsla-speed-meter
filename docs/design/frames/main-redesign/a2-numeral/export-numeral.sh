#!/bin/bash
# usage: docs/design/frames/main-redesign/a2-numeral/export-numeral.sh [OUTDIR]
# 第十五輪(2026-10-27):車速數字候選的 PNG。每個候選(cur 現行、a 穩、b 勻、c 大、x 全比例未選)匯出同一組畫面 + 一排 14 個車速的對照(strip)。
# 用 headless Google Chrome;要網路(Google Fonts)。輸出:<OUTDIR>/<候選>/<ID>.png,預設是這個資料夾。
D="$(cd "$(dirname "$0")" && pwd)"; F="$(cd "$D/../.." && pwd)/main-redesign-a2-numeral.html"
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
OUT=${1:-$D}
IDS="A-drive-ble:844:390 A-drive-gps:844:390 A-drive-all:844:390 A-drive-night:844:390 A-v-667:667:375 A-v-mph-70:844:390 A-v-mph-99:844:390 A-v-mph-100:844:390 A-v-147-dest:844:390"
for n in cur a b c x; do
  mkdir -p "$OUT/$n"
  for item in $IDS strip:2100:600; do
    IFS=: read -r q w h <<< "$item"
    rm -f "$OUT/$n/$q.png"
    "$CH" --headless=new --disable-gpu --hide-scrollbars --window-size=$w,$h --force-device-scale-factor=2 \
      --virtual-time-budget=15000 --screenshot="$OUT/$n/$q.png" "file://$F?screen=$q&num=$n" >/dev/null 2>&1
    [ -f "$OUT/$n/$q.png" ] && echo "$n/$q ok" || echo "$n/$q FAIL"
  done
done
