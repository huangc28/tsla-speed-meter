#!/usr/bin/env python3
# usage: sheet.py [DIR]  把 DIR 裡的 @2x 圖拼成一張總表 sheet.png(兩欄;每張上面一行標題)。要 Pillow。
# 第二十四輪:主畫面 11 張(下弧 + 建議版)→ 未選(保留參考):四角 11 張、四角的照圖 / 建議版並排、字型比較、照圖的下弧。候選 alt-01 / 07 不放。
import sys, os, glob
from PIL import Image, ImageDraw, ImageFont
D = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
T = {"01": "86,全部關好", "02": "86,車門開著、胎壓低(車主圖上的狀態)", "03": "188,車門開著、胎壓低(三位數)", "04": "8,全部關好(一位數)", "05": "86,前車廂開著",
     "06": "86,後車廂開著", "07": "248,前車廂、車門、後車廂都開著,胎壓低", "08": "停車:P、0,全部關好", "09": "沒有有效車速:畫「—」(車主的圖上沒有,照現有規矩)",
     "10": "車門狀態不明:三個虛線,胎壓照常(車主的圖上沒有,照現有規矩)", "11": "胎壓沒有讀值:胎壓虛線,其他照常(車主的圖上沒有,照現有規矩)"}
ROWS = [("主畫面(2026-11-13 車主選定:下弧 + 安全建議版 + Hanken Grotesk)", [(f"main-{k}", f"{int(k)}. {T[k]}") for k in sorted(T)]),
        ("未選(保留參考):四角排列,照車主的圖的畫法", [(f"corner-{k}", f"{int(k)}. {T[k]}") for k in sorted(T)]),
        ("未選(保留參考):四角排列,左 = 照車主的圖、右 = 建議版", [x for k in ("01", "02", "07") for x in ((f"corner-{k}", f"{int(k)}. 照車主的圖:{T[k]}"), (f"safe-{k}", f"{int(k)}. 建議版"))]),
        ("未選(保留參考):字型比較(左 = 選定的 Hanken Grotesk;右 = SF Pro)", [x for v in ("86", "248") for x in ((f"font-hanken-{v}", f"{v}:Hanken Grotesk"), (f"font-sf-{v}", f"{v}:SF Pro"))]),
        ("車主選之前看到的下弧(照車主的圖的畫法)", [(f"arc-{k}", f"{int(k)}. {T[k]}") for k in ("02", "03", "07")])]
FONTS = glob.glob("/System/Library/AssetsV2/com_apple_MobileAsset_Font8/*/AssetData/PingFang.ttc") + ["/System/Library/Fonts/PingFang.ttc", "/System/Library/Fonts/STHeiti Medium.ttc", "/System/Library/Fonts/Hiragino Sans GB.ttc"]
def font(size):
    for f in FONTS:
        try: return ImageFont.truetype(f, size)
        except OSError: pass
    return ImageFont.load_default()
TW, TH, M, GAP, CAP, HEAD = 1688, 780, 48, 36, 64, 110
n_rows = sum((len(items) + 1) // 2 for _, items in ROWS)
W = M * 2 + TW * 2 + GAP; H = M + len(ROWS) * HEAD + n_rows * (CAP + TH + GAP) + M
sheet = Image.new("RGB", (W, H), (15, 17, 20)); d = ImageDraw.Draw(sheet); y = M
for head, items in ROWS:
    d.text((M, y + 20), head, font=font(52), fill=(233, 235, 238)); y += HEAD
    for i, (name, cap) in enumerate(items):
        x = M + (i % 2) * (TW + GAP)
        d.text((x, y + 8), cap, font=font(34), fill=(205, 210, 217))
        sheet.paste(Image.open(os.path.join(D, f"{name}@2x.png")).convert("RGB").resize((TW, TH)), (x, y + CAP))
        if i % 2 == 1 or i == len(items) - 1: y += CAP + TH + GAP
sheet.save(os.path.join(D, "sheet.png")); print("sheet.png", sheet.size)
