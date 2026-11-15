# 三位數全掃:100–250 每個數字的墨跡(&ink=num 的 2 倍圖,亮度 > 60)到四個圓底(&ink=disc)的最短距離。量法同 clr.py(像素中心之間的距離 ÷ 2)
import numpy as np, sys, json
from PIL import Image
S=2
def mask(p,th=60): return np.asarray(Image.open(p).convert('L'))>th
def discs(p):
    m=mask(p); out=[]
    ys,xs=np.where(m)
    for name,(qx,qy) in (('前車廂(左上)',(-1,-1)),('後車廂(右上)',(1,-1)),('車門(左下)',(-1,1)),('胎壓(右下)',(1,1))):
        sel=((xs/S-422)*qx>0)&((ys/S-172)*qy>0); out.append((name,np.c_[xs[sel],ys[sel]].astype(np.float32)))
    return out
def edge(pts):   # 只留圓底的邊(最短距離一定落在邊上),省時間
    c=pts.mean(axis=0); r=np.hypot(*(pts-c).T); return pts[r>r.max()-1.5]
res={}
for lay in ('corner','sf'):
    D=[(n,edge(p)) for n,p in discs(f'ink/disc-{lay}.png')]; rows=[]
    for v in range(100,251):
        m=mask(f'sweep/{lay}-{v}.png'); ys,xs=np.where(m)
        if len(ys)<500: print('EMPTY',lay,v); continue
        ink=np.c_[xs,ys].astype(np.float32)
        ds=[]
        for n,e in D:
            near=ink[(np.abs(ink[:,0]-e[:,0].mean())<160)&(np.abs(ink[:,1]-e[:,1].mean())<160)]
            d=np.sqrt(((near[:,None,:]-e[None,:,:])**2).sum(axis=2)).min()/S; ds.append(round(float(d),2))
        rows.append((v,ds))
    res[lay]=rows
    names=[n for n,_ in D]
    print('==',lay)
    for i,n in enumerate(names):
        col=sorted((r[1][i],r[0]) for r in rows); print(f'  {n}: 最小 {col[0][0]:.1f}(在 {col[0][1]});最小的六個',[(v,d) for d,v in col[:6]], '| < 9:',[(v,d) for d,v in col if d<9])
    allmin=min((min(r[1]),r[0]) for r in rows); print('  全部最小',allmin)
    must=[107,117,147,177,197,205,215,245,247,104,114,144,105,155,111,211,188,200,248]
    print('  點名的:',{v:dict(rows)[v] for v in must})
json.dump(res,open('sweep.json','w'))
