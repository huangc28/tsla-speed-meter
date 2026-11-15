# 第二十四輪階段 3:和修訂前比。
# usage: python3 vs_before.py <修訂前的 main-*.png 資料夾> [<用現在的頁面重截的未選畫面 1 倍圖資料夾>]
# (a) main-NN 新舊比:不同的像素只該在四個圓底裡(填滿的記號、加長的車門、虛線)和狀態 9 的那行字(舊位置、新位置);
#     圓底裡變動的像素離圓底中心最遠多少(要小於圓底邊線的內緣 17.85,才算沒畫出圓底)。
# (b) 未選的畫面和候選:用現在的頁面重截的 1 倍圖,和資料夾裡沒重匯的檔逐像素比,要是 0(形狀沒有被連動)。
import numpy as np, os, sys
from PIL import Image
D=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))+'/'; B=sys.argv[1].rstrip('/')+'/'
def im(p): return np.asarray(Image.open(p).convert('RGB')).astype(int)
LOW={'前車廂':(323.03,222.43),'車門':(382.20,275.69),'後車廂':(461.80,275.69),'胎壓':(520.97,222.43)}
for suf,S in (('@2x',2),('',1)):
    print('== (a)',suf or '1x'); H,W=390*S,844*S; yy,xx=np.mgrid[:H,:W]; X=(xx+.5)/S; Y=(yy+.5)/S
    for k in range(1,12):
        n=f'main-{k:02d}{suf}.png'; d=np.abs(im(D+n)-im(B+n)).max(axis=2)>0; rest=d.copy(); row=[]
        for nm,c in LOW.items():
            r=np.hypot(X-c[0],Y-c[1]); m=d&(r<19.5); rest&=~(r<19.5)
            if m.any(): row.append(f'{nm} {int(m.sum())} 個、離中心最遠 {r[m].max():.2f}')
        txt=rest&(X>380)&(X<464)&(Y>175)&(Y<224); rest&=~txt
        if txt.any(): row.append(f'狀態 9 的字 {int(txt.sum())} 個(y {Y[txt].min():.1f}–{Y[txt].max():.1f})')
        print(f'  main-{k:02d}:', ';'.join(row) if row else '沒有不同', '| 其他地方不同的像素', int(rest.sum()))
if len(sys.argv)>2:
    O=sys.argv[2].rstrip('/')+'/'; bad=[]; names=sorted(f for f in os.listdir(O) if f.endswith('.png'))
    for f in names:
        d=np.abs(im(O+f)-im(D+f)).max(axis=2)
        if d.max()>0: bad.append((f,int((d>0).sum()),int(d.max())))
    print('== (b) 未選的畫面和候選(1 倍,%d 張)用現在的頁面重截 vs 資料夾裡的檔:'%len(names), bad if bad else '全部 0 個像素不同')
