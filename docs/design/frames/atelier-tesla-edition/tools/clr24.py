# 第二十四輪其他淨空(主畫面 = 下弧):四個圓底到 km/h、到「車速暫不可用」和「—」(狀態 9)、到刻度、到 P R N D、圓底彼此。
# 各層是 &ink= 的 2 倍圖(ink/ 裡),亮度門檻同 clr.py(刻度 40,其他 60);距離 = 像素中心之間 ÷ 2。
# usage: python3 clr24.py [ink 資料夾] [disc 檔名,預設 disc-main.png]
import numpy as np, sys
from PIL import Image
S=2; INK=sys.argv[1] if len(sys.argv)>1 else 'ink'; DISC=sys.argv[2] if len(sys.argv)>2 else 'disc-main.png'
def pts(name,th=60): ys,xs=np.where(np.asarray(Image.open(f'{INK}/{name}').convert('L'))>th); return np.c_[xs,ys].astype(np.float32)
def edge(p): c=p.mean(axis=0); r=np.hypot(*(p-c).T); return p[r>r.max()-1.5]
def dmin(a,b):
    best=1e9
    for i in range(0,len(a),4000): best=min(best,float(np.sqrt(((a[i:i+4000,None,:]-b[None,:,:])**2).sum(axis=2)).min()))
    return best/S
def bbox(p): return tuple(round(float(v)/S,1) for v in (p[:,0].min(),p[:,1].min(),p[:,0].max()+1,p[:,1].max()+1))
d=pts(DISC); cuts=[0,360*S,422*S,484*S,844*S]; names=('最左 −117°','左中 −159°','右中 +159°','最右 +117°')
D=[(n,edge(d[(d[:,0]>=cuts[i])&(d[:,0]<cuts[i+1])])) for i,n in enumerate(names)]
L={'km/h':pts('unit.png'),'車速暫不可用':pts('unit-09.png'),'「—」':pts('num-09.png'),'刻度':pts('tick.png',40),'P R N D':pts('gear.png')}
for k,v in L.items(): print(k,'墨跡外框',bbox(v) if k!='刻度' else '')
for n,e in D:
    c=e.mean(axis=0)/S; r=np.hypot(*(e/S-c).T).max()
    row=[f'{n} 中心 ({c[0]:.1f},{c[1]:.1f}) 半徑 {r:.2f}']+[f'{k} {dmin(v,e):.1f}' for k,v in L.items()]
    row.append('別的圓底 '+' / '.join(f'{dmin(e2,e):.1f}' for n2,e2 in D if n2!=n)); print('  '.join(row))
