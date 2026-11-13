#!/bin/bash
# usage: sweep24.sh <OUTDIR> [FROM TO]   (預設 0 250)
# 第二十四輪全掃要的截圖:主畫面每個數字的數字層(2 倍)放 OUTDIR/sweep/main-<v>.png,
# 另外各層(圓底、km/h、狀態 9 的字和「—」、刻度、P R N D)放 OUTDIR/ink/。四個 Chrome 同時跑,各自的 profile。
# 截完:cd OUTDIR && python3 <tools>/sweep24.py sweep ink/disc-main.png && python3 <tools>/clr24.py ink
T="$(cd "$(dirname "$0")" && pwd)"; OUT="${1:?usage: sweep24.sh <OUTDIR> [FROM TO]}"; A=${2:-0}; B=${3:-250}
mkdir -p "$OUT/sweep" "$OUT/ink"
work() { for v in $(seq $A $B); do [ $((v % 4)) -eq $1 ] || continue; [ -s "$OUT/sweep/main-$v.png" ] || "$T/shot.sh" "only=main-v$v&ink=num" "$OUT/sweep/main-$v.png" 844,390 2 "sw$1" >/dev/null; done; }
work 0 & work 1 & work 2 & work 3 & wait
for x in "main-v86&ink=disc disc-main" "alt-v86&ink=disc disc-alt" "main-v86&ink=unit unit" "main-09&ink=unit unit-09" "main-09&ink=num num-09" "main-v86&ink=tick tick" "main-v86&ink=gear gear"; do set -- $x; "$T/shot.sh" "only=$1" "$OUT/ink/$2.png" 844,390 2 sw0 >/dev/null; done
echo "sweep: $(ls "$OUT/sweep" | wc -l | tr -d ' ') 張;ink: $(ls "$OUT/ink" | wc -l | tr -d ' ') 張"
