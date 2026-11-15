# 第二十四輪全掃:0–250 每個數字的墨跡(&ink=num 的 2 倍圖,亮度 > 60)到主畫面(下弧)四個圓底(&ink=disc)的最短距離。
# 量法同 clr.py / sweep.py(像素中心之間的距離 ÷ 2)。下弧的四個圓底都在圓心下面,所以用 x 分(不能像 sweep.py 用象限分)。
# usage: python3 sweep24.py [SWEEPDIR] [DISC.png]   (SWEEPDIR 裡是 main-<v>.png)
import numpy as np, sys, json, os
from PIL import Image
S=2
SW=sys.argv[1] if len(sys.argv)>1 else 'sweep'; DISC=sys.argv[2] if len(sys.argv)>2 else 'ink/disc-main.png'
def mask(p,th=60): return np.asarray(Image.open(p).convert('L'))>th
def edge(pts): c=pts.mean(axis=0); r=np.hypot(*(pts-c).T); return pts[r>r.max()-1.5]
def discs(p, names):
    ys,xs=np.where(mask(p)); pts=np.c_[xs,ys].astype(np.float32); cuts=[0,360*S,422*S,484*S,844*S]; out=[]
    for i,n in enumerate(names):
        sel=(pts[:,0]>=cuts[i])&(pts[:,0]<cuts[i+1]); d=pts[sel]; out.append((n,edge(d),d.mean(axis=0)/S))
    return out
def dist(ink,e):
    near=ink[(np.abs(ink[:,0]-e[:,0].mean())<260)&(np.abs(ink[:,1]-e[:,1].mean())<260)]
    return float(np.sqrt(((near[:,None,:]-e[None,:,:])**2).sum(axis=2)).min())/S
if __name__=='__main__':
    NAMES=('前車廂 −117°','車門 −159°','後車廂 +159°','胎壓 +117°')
    D=discs(DISC,NAMES); print('圓底中心(遮罩重心):',[(n,tuple(round(float(x),1) for x in c)) for n,_,c in D])
    rows=[]
    for v in range(0,251):
        ys,xs=np.where(mask(f'{SW}/main-{v}.png'))
        if len(ys)<300: print('EMPTY',v); continue
        ink=np.c_[xs,ys].astype(np.float32); rows.append((v,[round(dist(ink,e),2) for _,e,_ in D]))
    print('量了',len(rows),'個數字')
    for i,n in enumerate(NAMES):
        col=sorted((r[1][i],r[0]) for r in rows); m=col[0][0]
        print(f'  {n}: 最小 {m:.2f};是這些數字:',[v for d,v in col if d<=m+.01],'| 次小的幾個',sorted(set(d for d,v in col))[:5],'| < 9:',[(v,d) for d,v in col if d<9])
    print('  全部最小',min((min(r[1]),r[0]) for r in rows))
    for lo,hi,t in ((0,9,'一位數'),(10,99,'兩位數'),(100,199,'1xx'),(200,250,'2xx')):
        sub=[r for r in rows if lo<=r[0]<=hi]; print(f'  {t}: 各圓底最小',[min(r[1][i] for r in sub) for i in range(4)])
    byd={}
    for v,ds in rows:
        if v>=100: byd.setdefault(v%10,[]).append(ds[3]); 
    print('  三位數、依個位:胎壓 +117° 的最小',{k:min(x) for k,x in sorted(byd.items())})
    byh={}
    for v,ds in rows:
        if v>=100: byh.setdefault(v//100,[]).append(ds[0])
    print('  三位數、依百位:前車廂 −117° 的最小',{k:min(x) for k,x in sorted(byh.items())})
    json.dump(rows,open('sweep24.json','w'))
