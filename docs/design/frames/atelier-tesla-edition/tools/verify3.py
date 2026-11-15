import numpy as np
from PIL import Image
D='/Users/huangchihan/develop/tsla-speed-meter/docs/design/frames/atelier-tesla-edition/'
def im(p): return np.asarray(Image.open(D+p).convert('RGB')).astype(int)
H,W=780,1688; yy,xx=np.mgrid[:H,:W]; rr=np.hypot(xx/2-422,yy/2-172)
print('== (a) 階段 1 對現在(2 倍;圓外 = 離圓心 > 160)')
for k in ('01','02','03','04','05','06','07','08','09'):
    a=im(f'stage1/corner-{k}@2x.png'); b=im(f'corner-{k}@2x.png'); d=np.abs(a-b).max(axis=2)
    out=d[rr>160]; band=d[(rr>138)&(rr<=160)]; inner=d[rr<=138]
    print(k,'圓外 變動像素',int((out>0).sum()),'最大差',int(out.max()),'| 刻度環帶 變動',int((band>0).sum()),'| 圓內(<138) 變動',int((inner>0).sum()),'最大',int(inner.max()))
print('== (d) 建議版 對 主畫面(2 倍)')
for k in ('01','02','07'):
    a=im(f'corner-{k}@2x.png'); b=im(f'safe-{k}@2x.png'); d=np.abs(a-b).max(axis=2)
    ys,xs=np.where(d>0)
    # classify regions
    th=(np.degrees(np.arctan2(xx/2-422,-(yy/2-172)))+360)%360
    ringband=(rr>146)&(rr<166)
    warmseg=ringband&(((th>55)&(th<120))|((th>222)&(th<280)))
    slots=np.zeros((H,W),bool)
    for (sx,sy) in ((338.2,99.1),(505.8,99.1),(329.7,233.8),(513.8,233.9)): slots|=np.hypot(xx/2-sx,yy/2-sy)<19.5
    gear=(yy/2>56)&(yy/2<72)&(xx/2>380)&(xx/2<465)
    other=(d>0)&~warmseg&~slots&~gear
    print(k,'變動像素 總共',len(ys),'| 圓環兩段',int(((d>0)&warmseg).sum()),'| 四個圓底內',int(((d>0)&slots).sum()),'| P R N D',int(((d>0)&gear).sum()),'| 其他地方',int(other.sum()), ('最大差 %d'%d[other].max() if other.any() else ''))
    if other.any():
        oy,ox=np.where(other); print('   其他:x %.1f-%.1f y %.1f-%.1f  θ %.0f-%.0f r %.1f-%.1f'%(ox.min()/2,ox.max()/2,oy.min()/2,oy.max()/2,th[other].min(),th[other].max(),rr[other].min(),rr[other].max()))
    # warm pixels in ring band of safe version
    rb=b[(rr>140)&(rr<170)]; warm=(rb[:,0]>rb[:,2]+6)&(rb.max(axis=1)>40)
    ra=a[(rr>140)&(rr<170)]; warma=(ra[:,0]>ra[:,2]+6)&(ra.max(axis=1)>40)
    print('   圓環帶暖色像素(R > B + 6):主畫面',int(warma.sum()),'建議版',int(warm.sum()))
