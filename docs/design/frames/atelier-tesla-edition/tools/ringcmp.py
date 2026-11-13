import numpy as np, sys
from PIL import Image
def unwrap(path,cx,cy,R):
    im=np.asarray(Image.open(path).convert('RGB')).astype(float); H,W,_=im.shape
    degs=np.arange(0,360,0.5); rs=np.arange(1.10,0.80,-0.001)*R
    TH,RR=np.meshgrid(np.radians(degs),rs)
    xs=cx+RR*np.sin(TH); ys=cy-RR*np.cos(TH)
    x0=np.clip(np.floor(xs).astype(int),0,W-2); y0=np.clip(np.floor(ys).astype(int),0,H-2); fx=(xs-x0)[...,None]; fy=(ys-y0)[...,None]
    return im[y0,x0]*(1-fx)*(1-fy)+im[y0,x0+1]*fx*(1-fy)+im[y0+1,x0]*(1-fx)*fy+im[y0+1,x0+1]*fx*fy, np.arange(1.10,0.80,-0.001)
Rf='/Users/huangchihan/develop/tsla-speed-meter/docs/design/frames/atelier-tesla-edition/reference/'
A,rn=unwrap(Rf+'dashboard-2026-11-12.png',884.97,406.13,301.4)
B,_=unwrap(sys.argv[1] if len(sys.argv)>1 else 't/c02.png',844,344,312)
def stats(P,d,Rpx_per844):
    j=int(d*2); cols=[(j+o)%720 for o in range(-3,4)]
    sl=P[:,cols].mean(axis=1); l=sl.mean(axis=1)
    band=np.where((rn>0.97)&(rn<1.03))[0]; i=band[l[band].argmax()]
    base=np.median(l[rn>1.06]); half=(l[i]+base)/2
    a=i
    while l[a]>half: a-=1
    b=i
    while l[b]>half: b+=1
    w=(b-a)*0.001*Rpx_per844
    # halo at 3px and 6 px inside / 3 px outside, in 844-px of own scale
    step=lambda px: int(round(px/Rpx_per844/0.001))
    return sl[i],w,l[i+step(4)]-base,l[i+step(7)]-base,l[max(0,i-step(4))]-base,base
print('deg | owner peakRGB w in4 in7 out4 base | mine peakRGB w in4 in7 out4 base | dRGB')
tot=[]
for d in range(0,360,10):
    a=stats(A,d,143.4); b=stats(B,d,156)
    dr=np.abs(a[0]-b[0]).max(); tot.append(dr)
    f=lambda s:f'{s[0].round().astype(int).tolist()} {s[1]:.1f} {s[2]:+.0f} {s[3]:+.0f} {s[4]:+.0f} {s[5]:.0f}'
    print(f'{d:3d} | {f(a)} | {f(b)} | {dr:.0f}')
print('max dRGB',max(tot),'median',np.median(tot))
