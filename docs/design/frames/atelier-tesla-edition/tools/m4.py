import numpy as np
from PIL import Image
R='/Users/huangchihan/develop/tsla-speed-meter/docs/design/frames/atelier-tesla-edition/reference/'
im=np.asarray(Image.open(R+'dashboard-2026-11-12.png').convert('RGB')).astype(float)
lum=im.mean(axis=2); k=844/1774
cx,cy,r=np.load('centre.npy'); print('centre',cx,cy,r)
def bbox(mask,x0,y0):
    ys,xs=np.where(mask); return xs.min()+x0,ys.min()+y0,xs.max()+x0+1,ys.max()+y0+1
def rep(name,b):
    x0,y0,x1,y1=b
    print(f'{name}: src x {x0}-{x1} y {y0}-{y1} w {x1-x0} h {y1-y0} | 844: x {x0*k:.1f}-{x1*k:.1f} y {y0*k:.1f}-{y1*k:.1f} w {(x1-x0)*k:.1f} h {(y1-y0)*k:.1f} | centre rel ring ({((x0+x1)/2-cx)*k:.1f},{((y0+y1)/2-cy)*k:.1f})')
# numeral 86: region x 760-1020, y 290-480 ; threshold at half
reg=lum[290:480,760:1020]
for th in (128,90,200):
    b=bbox(reg>th,760,290); rep(f'86 @lum>{th}',b)
m=reg>128
cols=m.any(axis=0); xs=np.where(cols)[0]
# split digits
gaps=[i for i in range(xs.min(),xs.max()) if not cols[i]]
print('gap cols',760+min(gaps),760+max(gaps)+1,'gap w',(max(gaps)-min(gaps)+1)*k)
g0=min(gaps);g1=max(gaps)+1
rep('8',bbox(m[:,:g0],760,290)); rep('6',bbox(m[:,g1:],760+g1,290))
print('numeral colour (median of lum>200):',np.median(im[290:480,760:1020][reg>200],axis=0))
# stroke widths: horizontal run lengths at several rows in '6' left stem & '8'
for y in (330,360,385,400,420,440):
    row=m[y-290]; runs=[];s=None
    for i,v in enumerate(row):
        if v and s is None: s=i
        if not v and s is not None: runs.append((760+s,i-s));s=None
    print('row',y,[(a,round(w*k,1)) for a,w in runs])
for x in (830,838,946,950):
    colm=m[:,x-760]; runs=[];s=None
    for i,v in enumerate(colm):
        if v and s is None: s=i
        if not v and s is not None: runs.append((290+s,i-s));s=None
    print('col',x,[(a,round(w*k,1)) for a,w in runs])
# km/h
reg=lum[475:520,830:945]; th=(reg.max()+np.median(reg))/2; print('km/h peak',reg.max(),'th',th)
b=bbox(reg>th,830,475); rep('km/h',b)
mm=reg>th; print('km/h colour median(top30% of ink)',np.median(im[475:520,830:945][reg>reg.max()*0.8],axis=0))
# x-height: bbox of 'm' : columns
cols=mm.any(axis=0); segs=[];s=None
for i,v in enumerate(cols):
    if v and s is None: s=i
    if not v and s is not None: segs.append((s,i));s=None
if s is not None: segs.append((s,len(cols)))
for a,b2 in segs:
    ys=np.where(mm[:,a:b2].any(axis=1))[0]; print('  glyph x',830+a,830+b2,'w',round((b2-a)*k,1),'y',475+ys.min(),475+ys.max()+1,'h',round((ys.max()+1-ys.min())*k,1))
# PRND
reg=lum[175:222,795:980]
for th in (60,):
    mm=reg>th; cols=mm.any(axis=0); segs=[];s=None
    for i,v in enumerate(cols):
        if v and s is None: s=i
        if not v and s is not None: segs.append((s,i));s=None
    for a,b2 in segs:
        ys=np.where(mm[:,a:b2].any(axis=1))[0]
        sub=im[175:222,795+a:795+b2]; sl=reg[:,a:b2]
        print('  PRND glyph x',795+a,795+b2,'cx844',round((795+(a+b2)/2)*k,1),'rel',round((795+(a+b2)/2-cx)*k,1),'w',round((b2-a)*k,1),'y',175+ys.min(),175+ys.max()+1,'y844',round((175+ys.min())*k,1),round((175+ys.max()+1)*k,1),'h',round((ys.max()+1-ys.min())*k,1),'col',np.median(sub[sl>sl.max()*0.8],axis=0), 'peak',sl.max())
