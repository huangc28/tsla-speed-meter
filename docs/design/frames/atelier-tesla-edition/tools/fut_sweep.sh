#!/bin/bash
# usage: fut_sweep.sh <OUTDIR> [FROM TO]   (預設 0 250)
# 第二十六輪(以後有資料時:駐車、車道、速限牌)全掃要的截圖,都是 2 倍的單層圖(&ink=):
#   OUTDIR/sweep/num-<v>.png  每個數字的數字層(用 futa 截;兩種放法的數字一樣)
#   OUTDIR/ink/<放法>-<層>.png 放法 = futa / futb;層 = park、lane、sign、signring、d-frunk、d-door、d-trunk、d-tire、unit、tick、gear,
#                             另外 unit-09(「車速暫不可用」)、num-09(「—」)、signnum-<50|100|110>(速限牌裡的數字)
# 四個 Chrome 同時跑,各自的 profile。截完:python3 fut_clr.py OUTDIR
T="$(cd "$(dirname "$0")" && pwd)"; OUT="${1:?usage: fut_sweep.sh <OUTDIR> [FROM TO]}"; A=${2:-0}; B=${3:-250}
mkdir -p "$OUT/sweep" "$OUT/ink"
work() { for v in $(seq $A $B); do [ $((v % 4)) -eq $1 ] || continue; [ -s "$OUT/sweep/num-$v.png" ] || "$T/shot.sh" "only=futa-v$v&ink=num" "$OUT/sweep/num-$v.png" 844,390 2 "fs$1" >/dev/null; done; }
work 0 & work 1 & work 2 & work 3 & wait
for lay in futa futb; do
  for k in park lane sign signring d-frunk d-door d-trunk d-tire unit tick gear; do "$T/shot.sh" "only=$lay-v86&ink=$k" "$OUT/ink/$lay-$k.png" 844,390 2 fs0 >/dev/null; done
  "$T/shot.sh" "only=$lay-09&ink=unit" "$OUT/ink/$lay-unit-09.png" 844,390 2 fs0 >/dev/null; "$T/shot.sh" "only=$lay-09&ink=num" "$OUT/ink/$lay-num-09.png" 844,390 2 fs0 >/dev/null
  for n in 50 100 110; do "$T/shot.sh" "only=$lay-v86&ink=signnum&lim=$n" "$OUT/ink/$lay-signnum-$n.png" 844,390 2 fs0 >/dev/null; done
done
echo "sweep: $(ls "$OUT/sweep" | wc -l | tr -d ' ') 張;ink: $(ls "$OUT/ink" | wc -l | tr -d ' ') 張"
