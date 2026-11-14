# 第二十六輪(以後有資料時:駐車、車道、速限牌)的淨空。截圖先用 fut_sweep.sh 截好。
# usage: python3 fut_clr.py <OUTDIR>   (裡面有 sweep/num-<v>.png 和 ink/<放法>-<層>.png,都是 2 倍的單層圖)
# 量法同 clr24.py / sweep24.py:亮度 > 60 算墨(刻度 > 40),距離 = 像素中心之間 ÷ 2;每個東西一張單層圖,不用 x 分。
# 量的:(1) 0–250 每個數字的墨跡 → 新加的東西(駐車、車道、速限牌)和挪過位置的圓底(放法乙的車門、後車廂),要 ≥ 9;
#       (2) 新加的 / 挪過的 → km/h、「車速暫不可用」、「—」(≥ 8)、刻度(≥ 6)、P R N D;(3) 所有圓底和速限牌彼此(≥ 8);
#       (4) 速限牌裡的數字(50、100、110)到紅圈內緣(階段 3 起要 ≥ 3)。
import numpy as np, sys, os, json
from PIL import Image
S = 2; O = sys.argv[1].rstrip('/') + '/'
def pts(p, th=60):
    ys, xs = np.where(np.asarray(Image.open(p).convert('L')) > th); return np.c_[xs, ys].astype(np.float32)
def edge(p):   # 實心圓:只留最外面一圈的點(省時間)
    c = p.mean(axis=0); r = np.hypot(*(p - c).T); return p[r > r.max() - 1.5]
def dmin(a, b):
    if not len(a) or not len(b): return float('nan')
    best = 1e9
    for i in range(0, len(a), 3000): best = min(best, float(np.sqrt(((a[i:i + 3000, None, :] - b[None, :, :]) ** 2).sum(axis=2)).min()))
    return best / S
def circ(p): c = p.mean(axis=0) / S; return c, float(np.hypot(*(p / S - c).T).max())
DISCS = ('d-frunk', 'd-door', 'd-trunk', 'd-tire'); NAME = {'park': '駐車', 'lane': '車道', 'sign': '速限牌', 'd-frunk': '前車廂', 'd-door': '車門', 'd-trunk': '後車廂', 'd-tire': '胎壓'}
nums = {}
for v in range(0, 251):
    p = pts(f'{O}sweep/num-{v}.png')
    if len(p) < 300: print('EMPTY', v); continue
    nums[v] = p
print('數字層', len(nums), '張')
bad = []; out = {}
for lay, moved in (('futa', ()), ('futb', ('d-door', 'd-trunk'))):
    print(f'\n===== {lay}(放法{"甲" if lay == "futa" else "乙"})')
    E = {k: edge(pts(f'{O}ink/{lay}-{k}.png')) for k in ('park', 'lane', 'sign') + DISCS}
    for k, e in E.items(): c, r = circ(e); print(f'  {NAME[k]}: 中心 ({c[0]:.1f}, {c[1]:.1f})、半徑 {r:.2f}')
    new = ('park', 'lane', 'sign') + tuple(moved)
    print('  (1) 數字墨跡 → 新加的 / 挪過的(要 ≥ 9)')
    for k in new:
        e = E[k]; cx, cy = e.mean(axis=0); rows = []
        for v, ink in nums.items():
            near = ink[(np.abs(ink[:, 0] - cx) < 300) & (np.abs(ink[:, 1] - cy) < 300)]; rows.append((round(dmin(near, e), 2), v))
        rows.sort(); m = rows[0][0]; out[f'{lay}:{k}'] = rows
        grp = {t: min(d for d, v in rows if lo <= v <= hi) for lo, hi, t in ((0, 9, '一位數'), (10, 99, '兩位數'), (100, 199, '1xx'), (200, 250, '2xx'))}
        print(f'    {NAME[k]}: 最小 {m:.2f},是 {[v for d, v in rows if d <= m + .01][:12]};次小 {sorted(set(d for d, v in rows))[1:4]};各組最小 {grp}')
        if m < 9: bad.append((lay, NAME[k], '數字', m))
    L = {'km/h': (pts(f'{O}ink/{lay}-unit.png'), 8), '車速暫不可用': (pts(f'{O}ink/{lay}-unit-09.png'), 8), '「—」': (pts(f'{O}ink/{lay}-num-09.png'), 8), '刻度': (pts(f'{O}ink/{lay}-tick.png', 40), 6), 'P R N D': (pts(f'{O}ink/{lay}-gear.png'), 8)}
    print('  (2) 新加的 / 挪過的 → 其他東西(km/h、車速暫不可用、「—」≥ 8;刻度 ≥ 6)')
    for k in new:
        row = []
        for n, (p, lim) in L.items():
            d = dmin(p, E[k]); row.append(f'{n} {d:.1f}')
            if d < lim: bad.append((lay, NAME[k], n, d))
        print(f'    {NAME[k]}: ' + '、'.join(row))
    print('  (3) 圓底和速限牌彼此(≥ 8)')
    ks = list(E)
    for i, a in enumerate(ks):
        row = []
        for b in ks:
            if a == b: continue
            d = dmin(E[a], E[b]); row.append((d, NAME[b]))
            if d < 8 and (a in new or b in new): bad.append((lay, NAME[a], NAME[b], d))
        row.sort(); print(f'    {NAME[a]}: 最近的是 {row[0][1]} {row[0][0]:.1f}、{row[1][1]} {row[1][0]:.1f}')
    print('  (4) 速限牌裡的數字 → 紅圈內緣')
    ring = pts(f'{O}ink/{lay}-signring.png'); c, ro = circ(ring); rin = float(np.hypot(*(ring / S - c).T).min())
    inner = ring[np.hypot(*(ring / S - c).T) < rin + 1]
    for n in (50, 100, 110):
        dg = pts(f'{O}ink/{lay}-signnum-{n}.png'); d = dmin(dg, inner); w = (dg[:, 0].max() + 1 - dg[:, 0].min()) / S; h = (dg[:, 1].max() + 1 - dg[:, 1].min()) / S
        print(f'    {n}: 數字墨跡 {w:.1f} × {h:.1f},離紅圈內緣最近 {d:.2f}(紅圈內半徑 {rin:.2f}、外半徑 {ro:.2f})')
        if d < 3: bad.append((lay, '速限牌數字', str(n), d))   # 階段 3 的裁定:≥ 3
json.dump(out, open(O + 'fut_clr.json', 'w'))
print('\n不過的:', bad if bad else '沒有')
