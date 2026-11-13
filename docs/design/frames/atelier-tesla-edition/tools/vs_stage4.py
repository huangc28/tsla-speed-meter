# 第二十四輪:和改之前(stage4/,頁面 3935c990)比,確認「只有該變的地方變了」。
# (a) 未選的舊畫面重匯後,只該差在頁尾右邊的標籤(總里程 → ODO);數字 48,213 km 不該動。
# (b) 主畫面 main-01 / 02 / 07 對 stage4 的 safe-01 / 02 / 07(同樣是建議版,只是圖示在四角):圓環、刻度、P R N D、數字、km/h、導航卡、右欄、上排都該是 0。
import numpy as np, os
from PIL import Image
D=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))+'/'
def im(p): return np.asarray(Image.open(D+p).convert('RGB')).astype(int)
OLD=[f'corner-{k:02d}' for k in range(1,12)]+['corner-200','safe-01','safe-02','safe-07','font-hanken-86','font-hanken-248','font-sf-86','font-sf-248','arc-02','arc-03','arc-07']
for suf,S in (('@2x',2),('',1)):
    print('==',suf or '1x'); boxes=set(); other=[]
    for n in OLD:
        d=np.abs(im(n+suf+'.png')-im('stage4/'+n+suf+'.png')).max(axis=2); ys,xs=np.where(d>0)
        if not len(ys): other.append((n,'完全一樣(標籤沒換?)')); continue
        b=(xs.min()/S,ys.min()/S,(xs.max()+1)/S,(ys.max()+1)/S); boxes.add(b)
        if not (b[0]>=640 and b[2]<=690 and b[1]>=333 and b[3]<=358): other.append((n,b))
    print('(a) 未選的 22 張 vs stage4:不同的像素都在這個框裡(x0, y0, x1, y1):',sorted(boxes),'| 框外有差的:',other if other else '沒有')
    a=im('corner-01'+suf+'.png'); b=im('stage4/corner-01'+suf+'.png'); d=np.abs(a-b).max(axis=2)
    print('    里程數字的範圍(x 690–775、y 333–358)差:',int(d[333*S:358*S,690*S:775*S].max()))
    H,W=390*S,844*S; yy,xx=np.mgrid[:H,:W]; X=(xx+.5)/S; Y=(yy+.5)/S; rr=np.hypot(X-422,Y-172)
    disc=np.zeros((H,W),bool)
    for c in ((338.17,99.13),(505.83,99.13),(329.92,234.11),(514.08,234.11),(323.03,222.43),(382.20,275.69),(461.80,275.69),(520.97,222.43)): disc|=np.hypot(X-c[0],Y-c[1])<19.6
    odo=(X>=640)&(X<690)&(Y>=333)&(Y<358)
    for k in ('01','02','07'):
        d=np.abs(im(f'main-{k}{suf}.png')-im(f'stage4/safe-{k}{suf}.png')).max(axis=2); m=(d>0)&~disc&~odo
        print(f'(b) main-{k} vs stage4/safe-{k}:八個圓底和 ODO 標籤以外,不同的像素',int(m.sum()))
