#!/bin/bash
# usage: docs/design/frames/main-redesign/a2/export-a2.sh [OUTDIR] [ID ...]
# 第十三輪(visual):把 main-redesign-a2.html 的每張畫面輸出成 2 倍 PNG(預設輸出到這個資料夾,檔名 <ID>.png)。
# 畫面清單和尺寸(844 × 390 或 667 × 375)從頁面的 <html data-list> 讀,所以頁面加了畫面不用改這裡;後面給 ID 就只匯出那幾張。
# 用 headless Google Chrome;要網路(Google Fonts 的 Inter、Noto Sans TC、Barlow Semi Condensed 和 lucide 圖示)。
# stderr 的 CVDisplayLinkCreateWithCGDisplay failed、Trying to load the allocator multiple times 是雜訊;偶爾有一張被系統中止,單獨重跑就好。
D="$(cd "$(dirname "$0")" && pwd)"; F="$(cd "$D/../.." && pwd)/main-redesign-a2.html"
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
OUT=${1:-$D}; shift 2>/dev/null; mkdir -p "$OUT"
LIST=$("$CH" --headless=new --disable-gpu --window-size=844,390 --virtual-time-budget=20000 --dump-dom "file://$F?screen=__list" 2>/dev/null | grep -o 'data-list="[^"]*"' | head -1 | sed 's/data-list="//; s/"$//')
[ -n "$LIST" ] || { echo "讀不到畫面清單"; exit 1; }
for item in ${LIST//,/ }; do
  IFS=: read -r q w h <<< "$item"
  if [ $# -gt 0 ]; then case " $* " in *" $q "*) ;; *) continue;; esac; fi
  rm -f "$OUT/$q.png"
  "$CH" --headless=new --disable-gpu --hide-scrollbars --window-size=$w,$h --force-device-scale-factor=2 \
    --virtual-time-budget=15000 --screenshot="$OUT/$q.png" "file://$F?screen=$q" >/dev/null 2>&1
  [ -f "$OUT/$q.png" ] && echo "$q ok ${w}x${h}" || echo "$q FAIL"
done
