#!/bin/bash
# usage: docs/design/frames/export-gauges.sh [ID...]   (no args = all)
# Renders gauge-variants.html?screen=<ID> to gauge-variants/<ID>.png at 2x with headless Google Chrome.
F="$(cd "$(dirname "$0")" && pwd)"
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# 第二段(L35–L37):特寫 300×300;完整畫面 844×390(行車、提醒、沒資料、停車)和 667×375;合成比較圖。第一段的 PNG 在 gauge-variants/part1/(已取代)
ALL="compare:1760:1400"; for k in cur A B C; do for st in 88 128 na 0; do ALL="$ALL $k-$st:300:300"; done; for m in drive alert nodata parked; do ALL="$ALL $k-$m:844:390"; done; ALL="$ALL $k-drive667:667:375 $k-parked667:667:375"; done
# 第三段:胎壓圖示(tire 推薦款主要狀態)
for st in fresh unknown historical missing; do ALL="$ALL tire-$st:184:288"; done
IDS="$*"; [ -z "$IDS" ] && IDS=$(for e in $ALL; do echo "${e%%:*}"; done)
mkdir -p "$F/gauge-variants"
for id in $IDS; do
  e=$(for x in $ALL; do [ "${x%%:*}" = "$id" ] && echo "$x"; done); [ -z "$e" ] && { echo "$id -> unknown"; continue; }
  rest=${e#*:}; w=${rest%%:*}; h=${rest#*:}
  rm -f "$F/gauge-variants/$id.png"
  "$CH" --headless=new --disable-gpu --hide-scrollbars --window-size=$w,$h --force-device-scale-factor=2 \
    --virtual-time-budget=8000 --screenshot="$F/gauge-variants/$id.png" "file://$F/gauge-variants.html?screen=$id" >/dev/null 2>&1
  echo "$id -> gauge-variants/$id.png $( [ -f "$F/gauge-variants/$id.png" ] && echo ok || echo FAIL)"
done
