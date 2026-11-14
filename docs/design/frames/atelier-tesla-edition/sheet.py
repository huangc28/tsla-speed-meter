#!/usr/bin/env python3
# usage: sheet.py [DIR]  把 DIR 裡的 @2x 圖拼成一張總表 sheet.png(兩欄;每張上面一行標題)。要 Pillow。
# 第二十九輪:主畫面 11 張(圖示只在出事時出現;右欄胎壓不足琥珀)→ 以後有資料時 4 張(示意)→ 未選(保留參考):11/14 的版本(關好的也畫著)11 張 → 其餘照第二十八輪。主畫面有自己的標題 T29。
# 第二十八輪:主畫面 11 張(四個圖示照車主的圖的排法,三格空著)→ 未選(保留參考):上一版的排法(下面一排)11 張 → 其餘照第二十五輪。
# 第二十五輪:主畫面 11 張(右欄只剩胎壓,排法甲)→ 右欄的另外兩種排法乙、丙各 3 張(階段 4:車主挑了甲,這兩排改標「未選(保留參考)」)→ 未選(保留參考):上一版的右欄 2 張,其餘照第二十四輪。
# 第二十四輪:主畫面 11 張(下弧 + 建議版)→ 未選(保留參考):四角 11 張、四角的照圖 / 建議版並排、字型比較、照圖的下弧。候選 alt-01 / 07 不放。
import sys, os, glob
from PIL import Image, ImageDraw, ImageFont
D = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
T = {"01": "86,全部關好", "02": "86,車門開著、胎壓低(車主圖上的狀態)", "03": "188,車門開著、胎壓低(三位數)", "04": "8,全部關好(一位數)", "05": "86,前車廂開著",
     "06": "86,後車廂開著", "07": "248,前車廂、車門、後車廂都開著,胎壓低", "08": "停車:P、0,全部關好", "09": "沒有有效車速:畫「—」(車主的圖上沒有,照現有規矩)",
     "10": "車門狀態不明:三個虛線,胎壓照常(車主的圖上沒有,照現有規矩)", "11": "胎壓沒有讀值:胎壓虛線,其他照常(車主的圖上沒有,照現有規矩)"}
T29 = dict(T, **{"01": "86,全部關好:圓裡沒有圖示", "02": "86,車門開著、胎壓不足(車主圖上的狀態)", "03": "188,車門開著、胎壓不足(三位數)", "07": "248,前車廂、車門、後車廂都開著,胎壓不足",
     "10": "車門狀態不明:三個虛線;胎壓正常,不畫(車主的圖上沒有,照現有規矩)", "11": "胎壓沒有讀值:圓裡不畫,右邊四個「—」(車主的圖上沒有,照現有規矩)"})
FE = {"01": "86,全部關好,車道開著,速限 50", "02": "86,車門開著、胎壓不足,車道開著,速限 50", "03": "248,都開著、胎壓不足,車道沒開,速限 110", "04": "停車:P、0,全部關好,駐車拉起來,速限 50"}
ROWS = [("主畫面(2026-11-15:圖示只在出事時出現,關好、正常不畫;右欄胎壓不足是琥珀色;位置和 11/14 一樣)", [(f"main-{k}", f"{int(k)}. {T29[k]}") for k in sorted(T)]),
        ("以後有資料時(示意,app 現在不會顯示):駐車拉起來、車道開著才出現;速限牌一直顯示", [(f"fute-{k}", f"{int(k)}. {FE[k]}") for k in sorted(FE)]),
        ("未選(保留參考):11/14 的版本,關好的圖示也一直畫著", [(f"alw-{k}", f"{int(k)}. {T[k]}") for k in sorted(T)]),
        ("未選(保留參考):11/13 的排法,四個圖示排在下面一排", [(f"row-{k}", f"{int(k)}. {T[k]}") for k in sorted(T)]),
        ("未選(保留參考):右欄的另一種排法 乙 = 大小不變,往下移到中間", [(f"colb-{k}", f"{int(k)}. {T[k]}") for k in ("01", "02", "11")]),
        ("未選(保留參考):右欄的另一種排法 丙 = 放到最大", [(f"colc-{k}", f"{int(k)}. {T[k]}") for k in ("01", "02", "11")]),
        ("未選(保留參考):上一版的右欄(有車門列表)", [(f"col0-{k}", f"{int(k)}. {T[k]}") for k in ("01", "07")]),
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
