#!/bin/bash
# 量淨空用:把頁面的每一層各截一張 2 倍圖到 ink/(階段 3:加 SF 的數字、建議版和 SF 的圓底、刻度補滿後的下弧)
cd "$(dirname "$0")"; mkdir -p ink
for v in 188 200 248 86 8 0 111 100 888; do ./shot.sh "only=corner-v$v&ink=num" "$PWD/ink/num-$v.png" >/dev/null; ./shot.sh "only=sf-v$v&ink=num" "$PWD/ink/sfnum-$v.png" >/dev/null; done
for l in unit gear tick ring; do ./shot.sh "only=corner-v86&ink=$l" "$PWD/ink/$l.png" >/dev/null; done
for lay in corner arc safe sf; do ./shot.sh "only=$lay-v86&ink=disc" "$PWD/ink/disc-$lay.png" >/dev/null; ./shot.sh "only=$lay-v86&ink=unit" "$PWD/ink/unit-$lay.png" >/dev/null; ./shot.sh "only=$lay-v86&ink=gear" "$PWD/ink/gear-$lay.png" >/dev/null; done
ls ink | wc -l
