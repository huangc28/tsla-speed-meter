# 第二十七輪(以後有資料時,照車主的圖的排法)的淨空。截圖先用 fut27_sweep.sh 截好。
# usage: python3 fut27_clr.py <OUTDIR> [排法,用逗號分開;預設 futc,futd] [倍率;預設 2]
# 第二十八輪:倍率變成第三個參數(1 = 原生 1 倍的圖;量法不變,距離 = 像素中心之間 ÷ 倍率);排法可以給 main(主畫面的四格 + 預留的三格,截圖用 main28_sweep.sh)。
# 量法同 fut_clr.py(第二十六輪):亮度 > 60 算墨(刻度 > 40),距離 = 像素中心之間 ÷ 2;每個東西一張單層圖。
# 和 fut_clr.py 不一樣的地方:這一輪七個格位(六個圓底 + 速限牌)都搬過,所以七個都量;不過的照實全部列出來(futc 原樣本來就不過,不修)。
# 量的:(1) 0–250 每個數字的墨跡 → 七個格位,要 ≥ 9;(2) 七個格位 → km/h、「車速暫不可用」、「—」、P R N D(≥ 8)、刻度(≥ 6);
#       (3) 圓底和速限牌彼此(≥ 8);(4) 速限牌裡的數字(50、100、110)到紅圈內緣(≥ 3)。
import numpy as np, sys, os, json
from PIL import Image
S = int(sys.argv[3]) if len(sys.argv) > 3 else 2; O = sys.argv[1].rstrip('/') + '/'; LAYS = sys.argv[2].split(',') if len(sys.argv) > 2 else ['futc', 'futd']
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
SLOTS = ('d-frunk', 'd-door', 'park', 'd-trunk', 'd-tire', 'lane', 'sign')
NAME = {'park': '駐車', 'lane': '車道', 'sign': '速限牌', 'd-frunk': '前車廂', 'd-door': '車門', 'd-trunk': '後車廂', 'd-tire': '胎壓'}
nums = {}
for v in range(0, 251):
    p = pts(f'{O}sweep/num-{v}.png')
    if len(p) < 300 * S * S / 4: print('EMPTY', v); continue
    nums[v] = p
print('數字層', len(nums), '張')
out = {}
for lay in LAYS:
    bad = []
    print(f'\n===== {lay}')
    E = {k: edge(pts(f'{O}ink/{lay}-{k}.png')) for k in SLOTS}
    for k, e in E.items(): c, r = circ(e); print(f'  {NAME[k]}: 中心 ({c[0]:.2f}, {c[1]:.2f})、半徑 {r:.2f}')
    print('  (1) 數字墨跡 → 七個格位(要 ≥ 9)')
    for k in SLOTS:
        e = E[k]; cx, cy = e.mean(axis=0); rows = []
        for v, ink in nums.items():
            near = ink[(np.abs(ink[:, 0] - cx) < 300) & (np.abs(ink[:, 1] - cy) < 300)]; rows.append((round(dmin(near, e), 2), v))
        rows.sort(); m = rows[0][0]; out[f'{lay}:{k}'] = rows
        grp = {t: min(d for d, v in rows if lo <= v <= hi) for lo, hi, t in ((0, 9, '一位數'), (10, 99, '兩位數'), (100, 199, '1xx'), (200, 250, '2xx'))}
        print(f'    {NAME[k]}: 最小 {m:.2f},是 {[v for d, v in rows if d <= m + .01][:16]};各組最小 {grp}')
        low = [(d, v) for d, v in rows if d < 9]
        if low:
            by = {}
            for d, v in low: by.setdefault(d, []).append(v)
            print(f'      低於 9 的 {len(low)} 個:' + ';'.join(f'{d:.2f} → {sorted(vs)}' for d, vs in sorted(by.items())))
            bad.append((NAME[k], '數字', m, len(low)))
    L = {'km/h': (pts(f'{O}ink/{lay}-unit.png'), 8), '車速暫不可用': (pts(f'{O}ink/{lay}-unit-09.png'), 8), '「—」': (pts(f'{O}ink/{lay}-num-09.png'), 8), '刻度': (pts(f'{O}ink/{lay}-tick.png', 40), 6), 'P R N D': (pts(f'{O}ink/{lay}-gear.png'), 8)}
    print('  (2) 七個格位 → 其他東西(km/h、車速暫不可用、「—」、P R N D ≥ 8;刻度 ≥ 6)')
    for k in SLOTS:
        row = []
        for n, (p, lim) in L.items():
            d = dmin(p, E[k]); row.append(f'{n} {d:.1f}')
            if d < lim: bad.append((NAME[k], n, d))
        print(f'    {NAME[k]}: ' + '、'.join(row))
    print('  (3) 圓底和速限牌彼此(≥ 8)')
    for a in SLOTS:
        row = []
        for b in SLOTS:
            if a == b: continue
            d = dmin(E[a], E[b]); row.append((d, NAME[b]))
            if d < 8: bad.append((NAME[a], NAME[b], d))
        row.sort(); print(f'    {NAME[a]}: 最近的是 {row[0][1]} {row[0][0]:.1f}、{row[1][1]} {row[1][0]:.1f}')
    print('  (4) 速限牌裡的數字 → 紅圈內緣(≥ 3)')
    ring = pts(f'{O}ink/{lay}-signring.png'); c, ro = circ(ring); rin = float(np.hypot(*(ring / S - c).T).min())
    inner = ring[np.hypot(*(ring / S - c).T) < rin + 1]
    for n in (50, 100, 110):
        dg = pts(f'{O}ink/{lay}-signnum-{n}.png'); d = dmin(dg, inner)
        print(f'    {n}: 離紅圈內緣最近 {d:.2f}(紅圈內半徑 {rin:.2f}、外半徑 {ro:.2f})')
        if d < 3: bad.append(('速限牌數字', str(n), d))
    print(f'  {lay} 不過的:', bad if bad else '沒有')
json.dump(out, open(O + f'fut27_clr-{S}x.json', 'w'))
