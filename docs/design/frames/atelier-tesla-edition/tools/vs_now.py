# 「現有的圖一個像素都不動」的驗收(第二十五輪階段 4 起每一輪都用):用現在的頁面全部重匯到另一個資料夾,逐張和資料夾裡現有的檔比(整張)。
# usage: python3 vs_now.py <全部重匯到的資料夾> [不比的檔名開頭,用逗號分開;例如 fut]
# sheet.png 不比(另外拼的);現有資料夾沒有的檔列在「新的」。Chrome 偶爾一張有幾千個像素不同,單獨重截那一張再跑一次。
import numpy as np, os, sys
from PIL import Image
Image.MAX_IMAGE_PIXELS = None
D = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) + '/'; O = sys.argv[1].rstrip('/') + '/'; skip = tuple(sys.argv[2].split(',')) if len(sys.argv) > 2 else ()
new = sorted(f for f in os.listdir(O) if f.endswith('.png') and f != 'sheet.png'); bad = []; fresh = []; n = 0
for f in new:
    if skip and f.startswith(skip) or not os.path.exists(D + f): fresh.append(f); continue
    a = np.asarray(Image.open(O + f).convert('RGB')).astype(int); b = np.asarray(Image.open(D + f).convert('RGB')).astype(int); n += 1
    d = -1 if a.shape != b.shape else int((np.abs(a - b).max(axis=2) > 0).sum())
    if d: bad.append((f, d))
cur = [f for f in os.listdir(D) if f.endswith('.png') and f != 'sheet.png']
print(f'比了 {n} 張(整張);不同的:{bad if bad else "沒有"}')
print(f'新的(現有資料夾沒有、或指定不比的){len(fresh)} 張:{fresh}')
print('資料夾有、這次沒重匯的:', sorted(f for f in cur if f not in new))
