#!/bin/bash
# usage: main28_sweep.sh <OUTDIR> [倍率;預設 2] [FROM TO]   (預設 0 250)
# 第二十八輪(主畫面改成照車主的圖的排法,三格空著)全掃要的截圖,都是單層圖(&ink=)。做法同 fut27_sweep.sh,只換來源和倍率:
#   OUTDIR/sweep/num-<v>.png  每個數字的數字層,從新的主畫面截(only=main-v<v>&ink=num)
#   OUTDIR/ink/main-<層>.png   主畫面的四格和其他東西從主畫面截:d-frunk、d-door、d-trunk、d-tire、unit、tick、gear、unit-09(「車速暫不可用」)、num-09(「—」);
#                             預留的三格(主畫面上不畫)從 futd 截:park、lane、sign、signring、signnum-<50|100|110>
# 四個 Chrome 同時跑,各自的 profile。截完:python3 fut27_clr.py OUTDIR main <倍率>
T="$(cd "$(dirname "$0")" && pwd)"; OUT="${1:?usage: main28_sweep.sh <OUTDIR> [倍率] [FROM TO]}"; S=${2:-2}; A=${3:-0}; B=${4:-250}
mkdir -p "$OUT/sweep" "$OUT/ink"
work() { for v in $(seq $A $B); do [ $((v % 4)) -eq $1 ] || continue; [ -s "$OUT/sweep/num-$v.png" ] || "$T/shot.sh" "only=main-v$v&ink=num" "$OUT/sweep/num-$v.png" 844,390 $S "ms$1" >/dev/null; done; }
work 0 & work 1 & work 2 & work 3 & wait
for k in d-frunk d-door d-trunk d-tire unit tick gear; do "$T/shot.sh" "only=main-v86&ink=$k" "$OUT/ink/main-$k.png" 844,390 $S ms0 >/dev/null; done
"$T/shot.sh" "only=main-09&ink=unit" "$OUT/ink/main-unit-09.png" 844,390 $S ms0 >/dev/null; "$T/shot.sh" "only=main-09&ink=num" "$OUT/ink/main-num-09.png" 844,390 $S ms0 >/dev/null
for k in park lane sign signring; do "$T/shot.sh" "only=futd-v86&ink=$k" "$OUT/ink/main-$k.png" 844,390 $S ms0 >/dev/null; done
for n in 50 100 110; do "$T/shot.sh" "only=futd-v86&ink=signnum&lim=$n" "$OUT/ink/main-signnum-$n.png" 844,390 $S ms0 >/dev/null; done
echo "sweep: $(ls "$OUT/sweep" | wc -l | tr -d ' ') 張;ink: $(ls "$OUT/ink" | wc -l | tr -d ' ') 張"
