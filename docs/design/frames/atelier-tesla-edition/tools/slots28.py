# usage: python3 slots28.py [暫存資料夾]   第二十八輪:主畫面四個圓底的中心,從頁面截出來的單層圖(only=main-v86&ink=d-<名字>,2 倍)算,寫到同一個資料夾的 slots28.json。
# dashgap.py、fixed.py、shapediff.py、offsearch.py 讀這個檔,不手抄座標;頁面上的格位改了(FUT27)就重跑這一支。
import numpy as np, sys, os, json, subprocess, tempfile
from PIL import Image
H = os.path.dirname(os.path.abspath(__file__)); T = sys.argv[1] if len(sys.argv) > 1 else tempfile.mkdtemp(); out = {}
for k in ('frunk', 'door', 'trunk', 'tire'):
    f = os.path.join(T, f'slot-{k}.png'); subprocess.run([os.path.join(H, 'shot.sh'), f'only=main-v86&ink=d-{k}', f, '844,390', '2', 'sl'], capture_output=True)
    ys, xs = np.where(np.asarray(Image.open(f).convert('L')) > 127); out[k] = [round(float(xs.mean() + .5) / 2, 2), round(float(ys.mean() + .5) / 2, 2)]
    print(k, out[k], '半徑', round(float(np.sqrt(len(xs) / np.pi)) / 2, 2))
json.dump(out, open(os.path.join(H, 'slots28.json'), 'w')); print('slots28.json 寫好了')
