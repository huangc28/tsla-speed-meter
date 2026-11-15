# usage: python3 cmp30.py <重截的資料夾> [基準資料夾,預設 ../stage14]
# 第三十輪(L109:車子不會傳駐車、車道、速限 → 拿掉駐車、車道,速限牌的位置留著)的 0 像素規則,逐條檢查(1 倍、2 倍都比):
#   (1) 基準資料夾裡的每一張(main、alw、fute、row、futa…futd、col*、alt、corner*、safe、font、arc、compare、icons-compare;sheet.png 除外)對重截的同名檔:整張 0。
#   (2) futm-03 對 fute-03:0(它本來就沒有駐車、車道)。
#   (3) futm-01、futm-02 對 fute-01、fute-02:只有車道那一塊不同(那一塊要真的不同);其他地方 0。
#   (4) futm-NN 對主畫面的同一個狀態(01 → main-01、02 → main-02、03 → main-07):只多速限牌那一塊;其他地方 0。
#   (5) futm-NN 的左下(原本駐車)、右下(原本車道)兩格:沒有任何比背景亮的東西。
# 車道、駐車、速限牌的中心照第二十八輪的報告(和 cmp29.py 同一組數)。
import numpy as np, sys, os
from PIL import Image
Image.MAX_IMAGE_PIXELS = None
H = os.path.dirname(os.path.abspath(__file__)); N = sys.argv[1].rstrip('/') + '/'; B = (sys.argv[2] if len(sys.argv) > 2 else os.path.join(H, '..', 'stage14')).rstrip('/') + '/'
EXTRA = {'park': (329.89, 237.46), 'lane': (514.11, 237.46), 'sign': (422.0, 281.82)}
def im(p): return np.asarray(Image.open(p).convert('RGB')).astype(int)
def grid(S): yy, xx = np.mgrid[:390 * S, :844 * S]; return (xx + .5) / S, (yy + .5) / S
def circ(X, Y, c, r): return np.hypot(X - c[0], Y - c[1]) < r
bad = []
print('===== (1) 基準的每一張對重截的同名檔(sheet.png 除外)')
cnt = 0; diff = {}; miss = []
for f in sorted(os.listdir(B)):
    if not f.endswith('.png') or f == 'sheet.png': continue
    if not os.path.exists(N + f): miss.append(f); continue
    a = im(N + f); b = im(B + f); cnt += 1
    n = -1 if a.shape != b.shape else int((np.abs(a - b).max(axis=2) > 0).sum())
    if n: diff[f] = n
print(f'  比了 {cnt} 張;不是 0 的:', diff or '沒有'); print('  基準有、這次沒重截的:', miss or '沒有'); bad += [('', k, '對基準不同', v) for k, v in diff.items()]
for suf, S in (('', 1), ('@2x', 2)):
    X, Y = grid(S); tag = f'{S} 倍'; lane = circ(X, Y, EXTRA['lane'], 20); sign = circ(X, Y, EXTRA['sign'], 23.5)
    print(f'===== {tag}')
    n = int((np.abs(im(f'{N}futm-03{suf}.png') - im(f'{N}fute-03{suf}.png')).max(axis=2) > 0).sum()); print(f'(2) futm-03 對 fute-03:{n}')
    if n: bad.append((tag, 'futm-03', '和 fute-03 不同', n))
    print('(3) futm-01 / 02 對 fute-01 / 02')
    for k in ('01', '02'):
        df = np.abs(im(f'{N}futm-{k}{suf}.png') - im(f'{N}fute-{k}{suf}.png')).max(axis=2) > 0; inn = int((df & lane).sum()); rest = int((df & ~lane).sum())
        ys, xs = np.where(df); print(f'  futm-{k}: 車道那一塊 {inn} 個像素不同(x {xs.min() / S:.1f}–{(xs.max() + 1) / S:.1f}、y {ys.min() / S:.1f}–{(ys.max() + 1) / S:.1f});其他地方 {rest}')
        if rest: bad.append((tag, 'futm-' + k, '車道以外的地方和 fute 不同', rest))
        if inn == 0: bad.append((tag, 'futm-' + k, '車道那一塊應該不同但沒有'))
    print('(4) futm-NN 對主畫面的同一個狀態')
    for k, mk in (('01', '01'), ('02', '02'), ('03', '07')):
        df = np.abs(im(f'{N}futm-{k}{suf}.png') - im(f'{N}main-{mk}{suf}.png')).max(axis=2) > 0; inn = int((df & sign).sum()); rest = int((df & ~sign).sum())
        print(f'  futm-{k} 對 main-{mk}: 速限牌那一塊 {inn};其他地方 {rest}')
        if rest: bad.append((tag, 'futm-' + k, '速限牌以外的地方和主畫面不同', rest))
        if inn == 0: bad.append((tag, 'futm-' + k, '速限牌應該在但沒有不同'))
    print('(5) futm-NN 左下、右下兩格裡最亮的像素(背景大約 20 以下;有圖示的話是 100 以上)')
    for k in ('01', '02', '03'):
        lum = im(f'{N}futm-{k}{suf}.png') @ np.array([.299, .587, .114]); m = {'左下': int(lum[circ(X, Y, EXTRA['park'], 20)].max()), '右下': int(lum[lane].max())}
        print(f'  futm-{k}: {m}')
        if max(m.values()) > 40: bad.append((tag, 'futm-' + k, '左下 / 右下有東西', m))
print('\n不過的:', bad if bad else '沒有')
