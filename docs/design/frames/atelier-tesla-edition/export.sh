#!/bin/bash
# usage: docs/design/frames/atelier-tesla-edition/export.sh [OUTDIR]
# 第二十四輪(visual,2026-11-13):把 atelier-tesla-edition.html 的畫面各匯 1 倍和 2 倍(844 × 390):
#   主畫面 main-01 … main-11(下弧的格位 + 建議版 + Hanken)、候選 alt-01 / alt-07(前後車廂在外側;只匯圖,不在頁面上)、
#   未選(保留參考):四角 corner-01 … corner-11、corner-200、四角的建議版 safe-01 / 02 / 07、字型比較 font-hanken-86 / 248 和 font-sf-86 / 248、照圖的下弧 arc-02 / 03 / 07。
#   狀態編號見頁面和 18-tesla-edition-visual.md。
#   另外:compare.png(車主的圖 vs 主畫面的狀態 2,1280 × 634,2 倍)、icons-compare.png(圖示對照表,2 倍)、sheet.png(總表,sheet.py 用 Pillow 拼的)。
# 用 headless Google Chrome;要網路(Google Fonts);font-sf-* 要在 Mac 上匯(system-ui = SF Pro)。--screenshot 會直接蓋掉舊檔,這裡不刪檔。偶爾一張被系統中止或反鋸齒不同,單獨重跑就好。
# 階段 3 修訂(同一天)只改主畫面:ONLY='main-*|compare.png|icons-compare.png' ./export.sh 只重匯這幾張(未選的畫面和候選沒有變,不用重匯)。
# 第二十五輪(2026-11-13 下午,L104):主畫面的右欄只剩胎壓(排法甲);main-01 … 11 重匯(上一版的在 stage5/)。新增:
#   右欄的候選 colb-01 / 02 / 11(乙:大小不變、下移)、colc-01 / 02 / 11(丙:放到最大)、加選 colx-07(車上標出哪裡開著)、上一版的右欄 col0-01 / 07(和 stage5/main-01 / 07 一模一樣)。
#   只重匯這一輪有變的:ONLY='main-*|col*' ./export.sh。未選的畫面、alt、compare.png、icons-compare.png 沒有變(驗過 0 個像素不同),不用重匯。
# 階段 3 修訂(同一天):甲的標題右移 6.5,只重匯 main-*(ONLY='main-*' ./export.sh);加選 colx-07 不在頁面上了,圖照匯(畫法留著)。階段 1 的頁面和 main-*:stage6/(b8b3e28a)。
# 階段 4(同一天,車主挑了甲):只改頁面的排版和文字(乙、丙搬進摺疊區),畫面沒有動,圖都不用重匯;只有 sheet.png 的兩排標題改成「未選(保留參考)」(python3 sheet.py 重拼)。階段 3 的頁面:stage6/(eda4a4b4)。
# 第二十六輪(2026-11-14,L105):主畫面和現有的圖都沒有動。新增「以後有資料時」(駐車、車道、速限牌;app 現在沒有這三個資料):
#   放法甲 futa-01 / 02 / 07、放法乙 futb-01 / 02 / 07(速限 50 / 50 / 110)。只匯這一輪新的:ONLY='fut*' ./export.sh。動手前的頁面和圖:stage7/(13762619)。
#   階段 3 修訂:速限牌三位數的字距 1.15 → 2(futa-07、futb-07 重匯);新增 futb-00(放法乙、狀態 1、沒有速限資料:牌子不畫,正下方空一格)。
#   淨空:tools/fut_sweep.sh + tools/fut_clr.py;疊圖偏差:tools/fut_ov.py。
# 第二十七輪(2026-11-14,L106):主畫面和現有的圖(含 futa / futb)都沒有動。「以後有資料時」改成照車主的圖的排法(左:前車廂、車門、駐車;右:後車廂、胎壓、車道;速限牌正下方):
#   futc(照你的圖,原樣)-01 / 02 / 07 / w、futd(照你的圖,三位數挪一點)-01 / 02 / 07 / w / 00。w = 最緊的三位數(107,狀態 1、速限 50);00 = 狀態 1、沒有速限牌。
#   階段 3 修訂:畫面沒有動;新增 futc-wt、futd-wt(同 w:107、速限 50,後車廂開著;頁面上「右上角放大」那一排用的狀態)。動手前的頁面:stage9/(779dedd7)。
#   只匯這一輪新的:ONLY='futc*|futd*' ./export.sh(sheet.png 一定會重拼)。動手前的頁面和圖:stage8/(0cdc359d)。淨空:tools/fut27_sweep.sh + tools/fut27_clr.py。
# 第二十八輪(2026-11-14 下午,L107):主畫面改成照車主的圖的排法(futd 的格位,車主選的「挪一點」),駐車、車道、速限牌三格空著。main-01 … 11 重匯(新的排法)。
#   新增 row-01 … row-11 = 上一版的主畫面(四個圖示在下面一排;未選,保留參考),和 stage10/main-01 … 11 一模一樣。compare.png 跟著換成新的主畫面。其他的圖都沒有動(icons-compare.png 也不動)。
#   階段 3 修訂:位置和畫面沒有動;icons-compare.png 重匯了(只有最下面那句說明變:拿掉色碼、位置改成新排法的說法;圖示的像素沒變)。動手前的頁面:stage11/(248bbf3d)。
#   只重匯這一輪有變的:ONLY='main-*|row-*|compare.png' ./export.sh。動手前的頁面和圖:stage10/(7210c313)。淨空:tools/main28_sweep.sh + tools/fut27_clr.py <OUT> main <倍率>;圓底中心:tools/slots28.py。
# 第二十九輪(2026-11-15,L108):車況圖示只在出事時出現(關好、正常不畫;胎壓讀不到圓裡也不畫),右欄胎壓不足改琥珀;位置一個都沒動。main-01 … 11 重匯(新的規則)。
#   新增 alw-01 … alw-11 = 第二十八輪的主畫面(關好的圖示也一直畫著;未選,保留參考),和 stage12/main-01 … 11 一模一樣。
#   新增 fute-01 … fute-04 = 新的「以後有資料時」(駐車拉起來、車道開著才出現,速限牌一直顯示;app 現在沒有這三個資料)。舊的 futd-* 沒有動。
#   compare.png 跟著換成新的主畫面;icons-compare.png 只有最下面那句說明變(表格和圖示的像素沒變)。其他的圖都沒有動。
#   只重匯這一輪有變的:ONLY='main-*|alw-*|fute-*|compare.png|icons-compare.png' ./export.sh。動手前的頁面和圖:stage12/(b98f79f0)。驗收:tools/cmp29.py(0 像素規則)、tools/fixed.py、tools/consist.py、tools/dashgap.py。
#   階段 3 修訂:位置和畫面沒有動;icons-compare.png 重匯(lead 放行改表格裡的字:「11/14 舊版:關著、正常」、胎壓讀不到時不畫、「胎壓不足」;圖示的像素沒變)。階段 1 的頁面:stage13/(8ad027c3)。
# 改之前的頁面和圖:stage5/(第二十四輪結束、車主說滿意的那一版,218482e6)、stage4/(第二十三輪結束,3935c990)、stage3/、stage1/。匯完跑 tools/consist.py、tools/fixed.py、tools/dashgap.py。
D="$(cd "$(dirname "$0")" && pwd)"; F="$(cd "$D/.." && pwd)/atelier-tesla-edition.html"
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
OUT=${1:-$D}; mkdir -p "$OUT"
one() { # one <檔名> <?only=> <視窗 寬,高> <倍率>
  if [ -n "$ONLY" ]; then local ok="" p PATS; IFS='|' read -ra PATS <<< "$ONLY"; for p in "${PATS[@]}"; do case "$1" in $p) ok=1;; esac; done; [ -n "$ok" ] || return 0; fi   # ONLY='main-*|compare.png|icons-compare.png' ./export.sh 只重匯符合的檔名(sheet.png 一定重拼)
  "$CH" --headless=new --disable-gpu --hide-scrollbars --window-size=$3 --force-device-scale-factor=$4 --virtual-time-budget=15000 --screenshot="$OUT/$1" "file://$F?only=$2" >/dev/null 2>&1
  [ -s "$OUT/$1" ] && echo "$1 ok" || echo "$1 FAIL"; }
two() { one "$1.png" "$2" 844,390 1; one "$1@2x.png" "$2" 844,390 2; }   # two <檔名不含副檔名> <?only=>
for n in 01 02 03 04 05 06 07 08 09 10 11; do two "main-$n" "main-$n"; done
for n in 01 02 03 04 05 06 07 08 09 10 11; do two "alw-$n" "alw-$n"; done
for n in 01 02 03 04; do two "fute-$n" "fute-$n"; done
for n in 01 02 03 04 05 06 07 08 09 10 11; do two "row-$n" "row-$n"; done
for n in 01 02 07; do two "futa-$n" "futa-$n"; two "futb-$n" "futb-$n"; done
two "futb-00" "futb-00"
for n in 01 02 07 w; do two "futc-$n" "futc-$n"; two "futd-$n" "futd-$n"; done
two "futd-00" "futd-00"
two "futc-wt" "futc-wt"; two "futd-wt" "futd-wt"
for n in 01 02 11; do two "colb-$n" "colb-$n"; two "colc-$n" "colc-$n"; done
two "colx-07" "colx-07"
for n in 01 07; do two "col0-$n" "col0-$n"; done
for n in 01 07; do two "alt-$n" "alt-$n"; done
for n in 01 02 03 04 05 06 07 08 09 10 11; do two "corner-$n" "corner-$n"; done
two "corner-200" "corner-v200"
for n in 01 02 07; do two "safe-$n" "safe-$n"; done
for v in 86 248; do two "font-hanken-$v" "corner-v$v"; two "font-sf-$v" "sf-v$v"; done
for n in 02 03 07; do two "arc-$n" "arc-$n"; done
one "compare.png" "compare" 1280,634 2
one "icons-compare.png" "icons" 1104,2060 2
python3 "$D/sheet.py" "$OUT"
