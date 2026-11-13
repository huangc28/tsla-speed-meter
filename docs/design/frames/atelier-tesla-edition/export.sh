#!/bin/bash
# usage: docs/design/frames/atelier-tesla-edition/export.sh [OUTDIR]
# 第二十四輪(visual,2026-11-13):把 atelier-tesla-edition.html 的畫面各匯 1 倍和 2 倍(844 × 390):
#   主畫面 main-01 … main-11(下弧的格位 + 建議版 + Hanken)、候選 alt-01 / alt-07(前後車廂在外側;只匯圖,不在頁面上)、
#   未選(保留參考):四角 corner-01 … corner-11、corner-200、四角的建議版 safe-01 / 02 / 07、字型比較 font-hanken-86 / 248 和 font-sf-86 / 248、照圖的下弧 arc-02 / 03 / 07。
#   狀態編號見頁面和 18-tesla-edition-visual.md。
#   另外:compare.png(車主的圖 vs 主畫面的狀態 2,1280 × 634,2 倍)、icons-compare.png(圖示對照表,2 倍)、sheet.png(總表,sheet.py 用 Pillow 拼的)。
# 用 headless Google Chrome;要網路(Google Fonts);font-sf-* 要在 Mac 上匯(system-ui = SF Pro)。--screenshot 會直接蓋掉舊檔,這裡不刪檔。偶爾一張被系統中止或反鋸齒不同,單獨重跑就好。
# 階段 3 修訂(同一天)只改主畫面:ONLY='main-*|compare.png|icons-compare.png' ./export.sh 只重匯這幾張(未選的畫面和候選沒有變,不用重匯)。
# 改之前的頁面和圖:stage4/(第二十三輪結束,3935c990)、stage3/、stage1/。匯完跑 tools/consist.py、tools/fixed.py、tools/dashgap.py。
D="$(cd "$(dirname "$0")" && pwd)"; F="$(cd "$D/.." && pwd)/atelier-tesla-edition.html"
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
OUT=${1:-$D}; mkdir -p "$OUT"
one() { # one <檔名> <?only=> <視窗 寬,高> <倍率>
  if [ -n "$ONLY" ]; then local ok="" p PATS; IFS='|' read -ra PATS <<< "$ONLY"; for p in "${PATS[@]}"; do case "$1" in $p) ok=1;; esac; done; [ -n "$ok" ] || return 0; fi   # ONLY='main-*|compare.png|icons-compare.png' ./export.sh 只重匯符合的檔名(sheet.png 一定重拼)
  "$CH" --headless=new --disable-gpu --hide-scrollbars --window-size=$3 --force-device-scale-factor=$4 --virtual-time-budget=15000 --screenshot="$OUT/$1" "file://$F?only=$2" >/dev/null 2>&1
  [ -s "$OUT/$1" ] && echo "$1 ok" || echo "$1 FAIL"; }
two() { one "$1.png" "$2" 844,390 1; one "$1@2x.png" "$2" 844,390 2; }   # two <檔名不含副檔名> <?only=>
for n in 01 02 03 04 05 06 07 08 09 10 11; do two "main-$n" "main-$n"; done
for n in 01 07; do two "alt-$n" "alt-$n"; done
for n in 01 02 03 04 05 06 07 08 09 10 11; do two "corner-$n" "corner-$n"; done
two "corner-200" "corner-v200"
for n in 01 02 07; do two "safe-$n" "safe-$n"; done
for v in 86 248; do two "font-hanken-$v" "corner-v$v"; two "font-sf-$v" "sf-v$v"; done
for n in 02 03 07; do two "arc-$n" "arc-$n"; done
one "compare.png" "compare" 1280,634 2
one "icons-compare.png" "icons" 1104,2060 2
python3 "$D/sheet.py" "$OUT"
