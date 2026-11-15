import numpy as np
from PIL import Image
S=2
def mask(p,th=60): return np.asarray(Image.open(p).convert('L'))>th
def ring_pts(m):  # 墨的邊緣像素(省時間)
    e=m.copy(); e[1:]&=m[:-1]; e[:-1]&=m[1:]; e[:,1:]&=m[:,:-1]; e[:,:-1]&=m[:,1:]
    ys,xs=np.where(m&~e); return np.c_[xs,ys]/S
U={}
for lay in ('corner','sf'):
    u=np.zeros((780,1688),bool); per={}
    for v in range(100,251):
        m=mask(f'sweep/{lay}-{v}.png'); u|=m; per[v]=ring_pts(m)
    U[lay]=(ring_pts(u),per)
# 校正有效半徑:現在的量測(後車廂、107)= 1.0 / 6.0
def geo(pts,c): return np.hypot(pts[:,0]-c[0],pts[:,1]-c[1]).min()
c56=(422+111.072*np.sin(np.radians(56)),172-111.072*np.cos(np.radians(56))); c52=(422+111.072*np.sin(np.radians(52)),172-111.072*np.cos(np.radians(52)))
print('r_eff:', geo(U['corner'][1][107],c56)-1.0, geo(U['sf'][1][107],c52)-6.0)
REFF=18.86
gear=ring_pts(mask('ink/gear.png',40))
for lay in ('corner','sf'):
    pts,per=U[lay]; print('==',lay,'上排角度 → 100–250 全部的最小淨空(右 / 左)、到 P R N D')
    for th in np.arange(56,43.9,-0.5):
        cr=(422+111.072*np.sin(np.radians(th)),172-111.072*np.cos(np.radians(th))); cl=(844-cr[0],cr[1])
        r=geo(pts,cr)-REFF; l=geo(pts,cl)-REFF; g=min(geo(gear,cr),geo(gear,cl))-REFF
        worst=min(per,key=lambda v:geo(per[v],cr))
        print(f'  ∓{th:4.1f}°  右 {r:5.2f}(最近 {worst})  左 {l:5.2f}  P R N D {g:5.1f}  離車主圖上的位置 {2*111.072*np.sin(np.radians((56-th)/2)):.1f} px')
# 備案下弧:用現有的圓底遮罩
ys,xs=np.where(mask('ink/disc-arc.png')); dp=np.c_[xs,ys]/S
for name,sel in (('前車廂 −117°',(dp[:,0]<360)),('胎壓 +117°',(dp[:,0]>480)),('車門 −159°',(dp[:,0]>=360)&(dp[:,0]<422)),('後車廂 +159°',(dp[:,0]>=422)&(dp[:,0]<=480))):
    d=dp[sel]; c=d.mean(axis=0); rows=sorted((geo(p,c)-REFF,v) for v,p in U['corner'][1].items())
    print('下弧',name,'最小',[(v,round(x,1)) for x,v in rows[:1]],'< 9:',sorted(set(v%10 for x,v in rows if x<9)), '個數',sum(1 for x,v in rows if x<9), [ (v,round(x,1)) for x,v in rows if x<9][:6])
