# usage: python3 cmp29.py <重截的資料夾> [基準資料夾,預設 ../stage12]
# 第二十九輪(L108:車況圖示只在出事時出現)的 0 像素規則,逐條檢查(1 倍、2 倍都比):
#   (1) 新的 main-NN 對 基準/main-NN:只有「被拿掉的圓底」那幾塊、和右欄胎壓不足那顆輪胎 + 讀數(第 2、3、7 張)可以不同;還畫著的圓底(開著、胎壓不足、虛線)要 0;其他地方要 0。
#   (2) alw-NN(第二十八輪的主畫面換新名字)對 基準/main-NN:0。
#   (3) 其他每一張(row、col、corner、safe、font、arc、alt、futa、futb、futc、futd)對 基準 的同名檔:0。
#   (4) icons-compare.png:階段 1 只有表格下面那句說明可以不同;階段 3 修訂 lead 放行改表格裡的字 → 不同的地方只能是一行一行的字(每段高 ≤ 32),圖的大小不變。
#   (5) 圓裡沒有圖示的張數(第 1、4、8、9、11 張;第 10 張的胎壓格):四個格位裡沒有任何比背景亮的東西。
#   (6) 新的「以後有資料時」fute-NN 對新的主畫面的同一個狀態:只多駐車 / 車道 / 速限牌那幾塊;速限牌和 基準/futd 的同一張逐像素一樣。
# 圓底中心讀 slots28.json;預留三格的中心照第二十八輪的報告。
import numpy as np, sys, os, json
from PIL import Image
H = os.path.dirname(os.path.abspath(__file__)); N = sys.argv[1].rstrip('/') + '/'; B = (sys.argv[2] if len(sys.argv) > 2 else os.path.join(H, '..', 'stage12')).rstrip('/') + '/'
PIC = {k: tuple(v) for k, v in json.load(open(os.path.join(H, 'slots28.json'))).items()}
EXTRA = {'park': (329.89, 237.46), 'lane': (514.11, 237.46), 'sign': (422.0, 281.82)}
NAME = {'frunk': '前車廂', 'door': '車門', 'trunk': '後車廂', 'tire': '胎壓', 'park': '駐車', 'lane': '車道', 'sign': '速限牌'}
DRAWN = {'02': ('door', 'tire'), '03': ('door', 'tire'), '05': ('frunk',), '06': ('trunk',), '07': ('frunk', 'door', 'trunk', 'tire'), '10': ('frunk', 'door', 'trunk')}
LOWTYRE = ('02', '03', '07'); COLBOX = (590, 196, 668, 236)   # 右欄左後輪和它的讀數(1 倍座標:x0, y0, x1, y1)
def im(p): return np.asarray(Image.open(p).convert('RGB')).astype(int)
def grid(S): yy, xx = np.mgrid[:390 * S, :844 * S]; return (xx + .5) / S, (yy + .5) / S
def circ(X, Y, c, r): return np.hypot(X - c[0], Y - c[1]) < r
bad = []
for suf, S in (('', 1), ('@2x', 2)):
    X, Y = grid(S); tag = f'{S} 倍'
    box = (X >= COLBOX[0]) & (X < COLBOX[2]) & (Y >= COLBOX[1]) & (Y < COLBOX[3])
    print(f'===== {tag}')
    print('(1) 新的 main-NN 對 基準/main-NN')
    for k in range(1, 12):
        key = f'{k:02d}'; a = im(f'{N}main-{key}{suf}.png'); b = im(f'{B}main-{key}{suf}.png'); df = np.abs(a - b).max(axis=2) > 0
        gone = [s for s in PIC if s not in DRAWN.get(key, ())]; kept = [s for s in PIC if s in DRAWN.get(key, ())]
        okm = np.zeros(df.shape, bool)
        for s in gone: okm |= circ(X, Y, PIC[s], 20)
        if key in LOWTYRE: okm |= box
        rest = int((df & ~okm).sum()); row = []
        for s in gone:
            n = int((df & circ(X, Y, PIC[s], 20)).sum()); row.append(f'拿掉 {NAME[s]} {n}')
            if n == 0: bad.append((tag, 'main-' + key, NAME[s] + ' 應該被拿掉但沒有不同'))
        for s in kept:
            n = int((df & circ(X, Y, PIC[s], 20)).sum()); row.append(f'還畫著 {NAME[s]} {n}')
            if n: bad.append((tag, 'main-' + key, NAME[s] + ' 還畫著的圓底不同', n))
        nb = int((df & box).sum())
        if key in LOWTYRE:
            ys, xs = np.where(df & box); row.append(f'右欄胎壓不足 {nb}(x {xs.min() / S:.1f}–{(xs.max() + 1) / S:.1f}、y {ys.min() / S:.1f}–{(ys.max() + 1) / S:.1f})')
            if nb == 0: bad.append((tag, 'main-' + key, '右欄應該變琥珀但沒有不同'))
        if rest: bad.append((tag, 'main-' + key, '其他地方不同', rest))
        print(f'  main-{key}: ' + '、'.join(row) + f';其他地方 {rest}')
    print('(2) alw-NN 對 基準/main-NN')
    r2 = {f'alw-{k:02d}': int((np.abs(im(f'{N}alw-{k:02d}{suf}.png') - im(f'{B}main-{k:02d}{suf}.png')).max(axis=2) > 0).sum()) for k in range(1, 12)}
    print('  不是 0 的:', {k: v for k, v in r2.items() if v} or '沒有(11 張都 0)'); bad += [(tag, k, 'alw 對 基準 main 不同', v) for k, v in r2.items() if v]
    print('(5) 圓裡沒有圖示:四個格位裡最亮的像素(背景大約 20 以下;有圖示的話是 100 以上)')
    for key, slots in (('01', PIC), ('04', PIC), ('08', PIC), ('09', PIC), ('11', PIC), ('10', ('tire',))):
        a = im(f'{N}main-{key}{suf}.png'); lum = a @ np.array([.299, .587, .114]); m = {NAME[s]: int(lum[circ(X, Y, PIC[s], 20)].max()) for s in slots}
        print(f'  main-{key}: {m}')
        if max(m.values()) > 40: bad.append((tag, 'main-' + key, '格位裡有東西', m))
    a1 = im(f'{N}main-01{suf}.png'); a11 = im(f'{N}main-11{suf}.png'); ring = circ(X, Y, (422, 172), 160)
    n = int(((np.abs(a1 - a11).max(axis=2) > 0) & ring).sum()); print(f'  main-11 對 main-01,整個圓裡面:{n} 個像素不同')
    if n: bad.append((tag, 'main-11', '圓裡和 main-01 不同', n))
    print('(6) fute-NN 對新的主畫面的同一個狀態')
    for fk, mk, add in (('01', '01', ('lane', 'sign')), ('02', '02', ('lane', 'sign')), ('03', '07', ('sign',)), ('04', '08', ('park', 'sign'))):
        a = im(f'{N}fute-{fk}{suf}.png'); b = im(f'{N}main-{mk}{suf}.png'); df = np.abs(a - b).max(axis=2) > 0; okm = np.zeros(df.shape, bool); row = []
        for s in add: m = circ(X, Y, EXTRA[s], 23.5 if s == 'sign' else 20); okm |= m; row.append(f'{NAME[s]} {int((df & m).sum())}')
        rest = int((df & ~okm).sum()); print(f'  fute-{fk} 對 main-{mk}: 多了 ' + '、'.join(row) + f';其他地方 {rest}')
        if rest: bad.append((tag, 'fute-' + fk, '其他地方不同', rest))
    for fk, bk in (('01', '01'), ('02', '02'), ('03', '07')):
        a = im(f'{N}fute-{fk}{suf}.png'); b = im(f'{B}futd-{bk}{suf}.png'); m = circ(X, Y, EXTRA['sign'], 23.5); n = int(((np.abs(a - b).max(axis=2) > 0) & m).sum())
        print(f'  fute-{fk} 的速限牌 對 基準/futd-{bk} 的速限牌: {n}')
        if n: bad.append((tag, 'fute-' + fk, '速限牌和 futd 不同', n))
print('===== (3) 其他每一張對 基準 的同名檔')
skip = ('main-', 'alw-', 'fute-', 'compare', 'sheet', 'icons-compare'); cnt = 0; diff = {}; miss = []
for f in sorted(os.listdir(B)):
    if not f.endswith('.png') or f.startswith(skip): continue
    if not os.path.exists(N + f): miss.append(f); continue
    a = im(N + f); b = im(B + f); cnt += 1
    n = -1 if a.shape != b.shape else int((np.abs(a - b).max(axis=2) > 0).sum())
    if n: diff[f] = n
print(f'  比了 {cnt} 張;不是 0 的:', diff or '沒有'); print('  基準有、這次沒重截的:', miss or '沒有'); bad += [('', k, '對 基準 不同', v) for k, v in diff.items()]
print('===== (4) icons-compare.png(階段 3 修訂:lead 放行改表格裡的字,圖示 0 個像素)')
# 不同的地方只能是一行一行的字:每一段連續不同的列,高度要 ≤ 32(2 倍圖上一行字的高度;圖示的那幾排高 100 到 300)。圖的大小不能變(表格沒有挪)。
a = im(N + 'icons-compare.png'); b = im(B + 'icons-compare.png')
if a.shape != b.shape: print('  大小不同', a.shape, b.shape); bad.append(('', 'icons-compare', '大小不同'))
else:
    d = np.abs(a - b).max(axis=2) > 0; rows = np.where(d.any(axis=1))[0]; bands = []
    if len(rows):
        s0 = p0 = rows[0]
        for r in rows[1:]:
            if r > p0 + 1: bands.append((int(s0), int(p0))); s0 = r
            p0 = r
        bands.append((int(s0), int(p0)))
    print(f'  不同的像素 {int(d.sum())} 個,分成 {len(bands)} 段(每段是一行字):', [f'y {y0}–{y1}' for y0, y1 in bands])
    tall = [(y0, y1) for y0, y1 in bands if y1 - y0 + 1 > 32]
    if tall: bad.append(('', 'icons-compare', '有比一行字高的區塊不同(可能動到圖示)', tall))
print('\n不過的:', bad if bad else '沒有')
