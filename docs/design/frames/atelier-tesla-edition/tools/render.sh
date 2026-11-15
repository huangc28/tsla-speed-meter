#!/bin/bash
cd "$(dirname "$0")"
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
for n in "$@"; do "$CH" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files --window-size=576,576 --force-device-scale-factor=1 --virtual-time-budget=3000 --screenshot="$PWD/mine-$n.png" "file://$PWD/harness.html?n=$n" >/dev/null 2>&1; done
