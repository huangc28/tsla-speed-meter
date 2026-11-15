import numpy as np
from PIL import Image
pol=np.asarray(Image.open('polar.png')).astype(float)   # rows: r 330 -> 236 step .25 ; cols: deg 0..360 step .25
rs=np.arange(330,236,-0.25); degs=np.arange(0,360,0.25)
lum=pol.mean(axis=2)
k=844/1774
bg=np.median(pol[:40],axis=(0,1)); print('bg outside ring',bg)
# ring per 5 deg: peak radius, FWHM width, peak colour, integrated
print('deg  rpk(src) rpk844  fwhm844  peakRGB   halo(lum at +-6px src)')
for d in range(0,360,5):
    c0=int(d/0.25); sl=pol[:, max(0,c0-6):c0+7].mean(axis=1) if d>0 else np.concatenate([pol[:,-6:],pol[:,:7]],axis=1).mean(axis=1)
    l=sl.mean(axis=1)
    band=(rs>290)&(rs<312)
    i=np.where(band)[0][l[band].argmax()]
    base=np.median(l[(rs>316)])
    half=(l[i]-base)/2+base
    a=i
    while a>0 and l[a]>half: a-=1
    b=i
    while b<len(l)-1 and l[b]>half: b+=1
    print(f'{d:3d}  {rs[i]:.1f}  {rs[i]*k:.1f}  {(b-a)*0.25*k:.2f}  {sl[i].round().astype(int)}  out {l[i-24]:.0f} in {l[i+24]:.0f} in12 {l[i+48]:.0f} base {base:.0f}')
# ticks: band r in [262,288]; column mean vs neighbours
tb=(rs>258)&(rs<292)
col=lum[tb].max(axis=0)
# local background
from numpy.lib.stride_tricks import sliding_window_view
pad=np.r_[col[-40:],col,col[:40]]
med=np.median(sliding_window_view(pad,81),axis=1)
ex=col-med
peaks=[j for j in range(len(ex)) if ex[j]>12 and ex[j]==ex[max(0,j-6):j+7].max()]
print('ticks:',len(peaks))
prev=None
for j in peaks:
    c=lum[:,j]; cc=c-np.median(c[(rs>258)&(rs<262)])
    on=np.where((cc>10)&(rs>250)&(rs<296))[0]
    r_out=rs[on.min()]; r_in=rs[on.max()]
    # width in deg: FWHM across columns at mid radius
    mid=(on.min()+on.max())//2
    row=lum[mid-8:mid+9].mean(axis=0); w=0
    h=(row[j]-med[j])/2+med[j]
    a=j
    while row[a%1440]>h: a-=1
    b=j
    while row[b%1440]>h: b+=1
    print(f'{degs[j]:7.2f}  d={"" if prev is None else round(degs[j]-prev,2)}  r {r_in:.1f}-{r_out:.1f} (844: {r_in*k:.1f}-{r_out*k:.1f}, len {(r_out-r_in)*k:.1f})  wdeg {(b-a)*0.25:.2f} = {np.radians((b-a)*0.25)*rs[mid]*k:.2f}px  peak {pol[mid,j].round().astype(int)} ')
    prev=degs[j]
