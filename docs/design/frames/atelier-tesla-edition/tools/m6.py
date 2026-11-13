import numpy as np
from PIL import Image
pol=np.asarray(Image.open('polar.png')).astype(float)
rs=np.arange(330,236,-0.25); degs=np.arange(0,360,0.25)
lum=pol.mean(axis=2); k=844/1774; R=301.4
# tick: column profile minus mean of columns +-1.5..2.5 deg away
def tickprof(j):
    c=lum[:,[(j-1)%1440,j,(j+1)%1440]].max(axis=1)
    nb=np.r_[[lum[:,(j+o)%1440] for o in (-9,-8,-7,-6,6,7,8,9)]].mean(axis=0)
    return c-nb
# find tick columns in band r 262..285 (safe)
tb=(rs>264)&(rs<284)
score=np.array([np.clip(lum[tb,j]-np.r_[[lum[tb,(j+o)%1440] for o in (-8,-7,7,8)]].mean(axis=0),0,None).mean() for j in range(1440)])
peaks=[j for j in range(1440) if score[j]>6 and score[j]==max(score[(j+o)%1440] for o in range(-8,9))]
print(len(peaks))
prev=None; angs=[]
for j in peaks:
    p=tickprof(j); on=np.where(p>8)[0]
    # contiguous run containing the band centre
    mid=np.where(tb)[0][len(np.where(tb)[0])//2]
    a=mid
    while a>0 and p[a-1]>6: a-=1
    b=mid
    while b<len(p)-1 and p[b+1]>6: b+=1
    r_out=rs[a]; r_in=rs[b]
    pk=pol[a:b+1,j].max(axis=0)
    print(f'{degs[j]:7.2f} d={"" if prev is None else round(degs[j]-prev,2):>5} r {r_in:.1f}-{r_out:.1f}  /R {r_in/R:.3f}-{r_out/R:.3f} len844 {(r_out-r_in)*k:.1f} peak {pk.round().astype(int)} med {np.median(pol[a:b+1,j],axis=0).round().astype(int)}')
    prev=degs[j]; angs.append(degs[j])
angs=np.array(angs)
# fit regular grid: angle = n*step, test steps
for n in (40,42,44,45,48):
    step=360/n; res=(angs+step/2)%step-step/2
    print(n,'step',round(step,3),'rms',round(np.sqrt((res**2).mean()),2),'max',round(np.abs(res).max(),2))
# ring single-column profiles
print('single column ring profiles: deg: fwhm844, peak rgb, r/R')
for d in (0,20,45,60,85,90,110,125,135,145,160,180,200,220,230,240,250,260,270,290,305,330):
    j=int(d*4); l=lum[:,j]; band=np.where((rs>290)&(rs<312))[0]; i=band[l[band].argmax()]
    base=np.median(l[rs>318]); half=(l[i]+base)/2
    a=i
    while l[a]>half: a-=1
    b=i
    while l[b]>half: b+=1
    # sub-pixel
    print(f'{d:3d} fwhm {(b-a-1)*0.25*k:.2f}-{(b-a)*0.25*k:.2f} peak {pol[i,j].round().astype(int)} r/R {rs[i]/R:.3f}  profile(lum, .5src steps -6..+6):',' '.join(f'{l[i+o]:.0f}' for o in range(-24,25,2)))
