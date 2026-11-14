# 第二十五輪:右欄(胎壓)到周圍東西的最短距離。
# usage: python3 colclr.py <ink 資料夾>   裡面要有 2 倍的 &ink=col 圖:col-<a|b|c|x>-<狀態>.png,和 ring.png(&ink=ring)
# 齒輪、ODO 的墨跡從 stage5/main-01@2x.png 取(亮度 > 40;這兩樣這一輪沒動)。距離 = 像素中心之間 ÷ 2。門檻:右欄的墨跡 60、圓環 40。
import numpy as np, os, sys, glob
from PIL import Image
S=2; D=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))+'/'; INK=sys.argv[1].rstrip('/')+'/'
def pts(a,th,box=None):
    if box: x0,y0,x1,y1=[int(v*S) for v in box]; m=np.zeros(a.shape,bool); m[y0:y1,x0:x1]=a[y0:y1,x0:x1]>th
    else: m=a>th
    ys,xs=np.where(m); return np.c_[xs,ys].astype(np.float32)
def L(p): return np.asarray(Image.open(p).convert('RGB')).max(axis=2)
def dmin(a,b):
    best=1e9
    for i in range(0,len(a),3000): best=min(best,float(np.sqrt(((a[i:i+3000,None,:]-b[None,:,:])**2).sum(axis=2)).min()))
    return best/S
def bbox(p): return tuple(round(float(v)/S,1) for v in (p[:,0].min(),p[:,1].min(),p[:,0].max()+1,p[:,1].max()+1))
full=L(D+'stage5/main-01@2x.png'); cog=pts(full,40,(715,10,780,70)); odo=pts(full,40,(600,320,844,380)); ring=pts(L(INK+'ring.png'),40); ring=ring[ring[:,0]>500*S]
print('齒輪墨跡',bbox(cog),' ODO 那一排墨跡',bbox(odo),' 圓環墨跡最右',ring[:,0].max()/S+.5)
for c,name in (('a','甲(主畫面)'),('b','乙'),('c','丙'),('x','加選')):
    fs=sorted(glob.glob(f'{INK}col-{c}-*.png'))
    if not fs: continue
    for f in fs:
        p=pts(L(f),60); b=bbox(p); st=os.path.basename(f)[6:8]
        print(f'{name} 狀態 {st}: 墨跡外框 x {b[0]}–{b[2]}、y {b[1]}–{b[3]};到圓環 {dmin(p,ring):.1f};到圓的邊(半徑 156){(np.hypot(p[:,0]/S+.25-422,p[:,1]/S+.25-172).min()-156):.1f};到齒輪 {dmin(p,cog):.1f};到 ODO {dmin(p,odo):.1f};'
              f'左緣離 592 {b[0]-592:+.1f};右緣離 768 {768-b[2]:+.1f}(離螢幕右邊 {844-b[2]:.1f});上面離導航卡頂 79 {b[1]-79:+.1f};下面離導航卡底 260 {260-b[3]:+.1f}')
