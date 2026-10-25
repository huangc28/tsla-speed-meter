#!/bin/bash
# usage: docs/design/frames/main-redesign/check-copy.sh
# 檢查 main-redesign.html 裡「複製」的 CSS 和程式,和 landscape-mockups.html 的原文一字不差(第十二輪 visual)。
# 範圍是 landscape-mockups.html 的行號(2026-10-25 的版本);原檔改了行號就要跟著改。
F="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$F/landscape-mockups.html" "$F/main-redesign.html" <<'PY'
import sys
src = open(sys.argv[1], encoding="utf-8").read().split("\n")
dst = open(sys.argv[2], encoding="utf-8").read()
ranges = {"CSS": [(15, 47), (56, 57), (72, 88), (265, 265), (298, 299), (305, 305), (312, 315), (370, 409), (420, 430), (433, 463)],
          "JS": [(470, 470), (473, 473), (489, 490), (634, 906)]}
bad = 0
for kind, rs in ranges.items():
    for a, b in rs:
        block = "\n".join(src[a - 1:b])
        ok = block in dst
        bad += not ok
        print(f"{kind} {a}-{b} ({b - a + 1} 行): {'一樣' if ok else '不一樣'}")
print("全部一字不差" if not bad else f"{bad} 段不一樣")
sys.exit(1 if bad else 0)
PY
