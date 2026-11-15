import numpy as np, json
from PIL import Image
pol=np.asarray(Image.open('polar.png')).astype(float)
rs=np.arange(330,236,-0.25); lum=pol.mean(axis=2); k=844/1774
band=np.where((rs>292)&(rs<311))[0]
cols=[];wid=[]
for j in range(1440):
    l=lum[:,j]; i=band[l[band].argmax()]
    base=np.median(l[rs>318]); half=(l[i]+base)/2
    a=i
    while l[a]>half: a-=1
    b=i
    while l[b]>half: b+=1
    # colour: mean of pixels above 85% of peak within the run
    run=pol[a+1:b,j]; lr=l[a+1:b]; cols.append(run[lr>=l[i]*0.85].mean(axis=0)); wid.append((b-a-1)*0.25*k)
cols=np.array(cols); wid=np.array(wid)
tab=[]
for d in range(0,360,5):
    idx=[(d*4+o)%1440 for o in range(-8,9)]
    c=np.median(cols[idx],axis=0); w=np.median(wid[idx])
    tab.append([int(round(c[0])),int(round(c[1])),int(round(c[2])),round(float(w),2)])
print(json.dumps(tab).replace('], [','],[').replace(', ',','))
# halo: mean lum profile relative to ring peak radius, per sector
for name,(a0,a1) in {'top':(330,30),'right':(60,110),'left':(250,300),'bottom':(160,200)}.items():
    js=[j for j in range(1440) if (a0<=j/4<a1) or (a0>a1 and (j/4>=a0 or j/4<a1))]
    prof=[]
    for o in range(-48,49,4):
        v=[]
        for j in js:
            l=lum[:,j]; i=band[l[band].argmax()]; v.append(l[i+o])
        prof.append(np.median(v))
    print(name,'lum by offset(844px; + = inward):',' '.join(f'{o*0.25*k:+.1f}:{p:.0f}' for o,p in zip(range(-48,49,4),prof)))
