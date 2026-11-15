#!/bin/bash
# usage: shot.sh <query> <outfile> [WxH] [scale] [profile-id]
# 第二十四輪:同時開好幾個 Chrome 時,每個給不同的 profile-id(各自的 --user-data-dir,放在暫存資料夾),不然會互相卡住
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
F="$(cd "$(dirname "$0")/../.." && pwd)/atelier-tesla-edition.html"
P=(); [ -n "$5" ] && P=(--user-data-dir="${TMPDIR:-/tmp}/tesla-edition-shot-p$5")
"$CH" --headless=new --disable-gpu --hide-scrollbars "${P[@]}" --window-size=${3:-844,390} --force-device-scale-factor=${4:-2} --virtual-time-budget=15000 --screenshot="$2" "file://$F?$1" >/dev/null 2>&1
[ -s "$2" ] && echo "$(basename "$2") ok" || echo "$(basename "$2") FAIL"
