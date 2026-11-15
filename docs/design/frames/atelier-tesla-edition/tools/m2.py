import numpy as np
from PIL import Image
R='/Users/huangchihan/develop/tsla-speed-meter/docs/design/frames/atelier-tesla-edition/reference/'
im=np.asarray(Image.open(R+'dashboard-2026-11-12.png').convert('RGB')).astype(float)
H,W,_=im.shape
lum=im.mean(axis=2)
def bil(a,xs,ys):
    x0=np.floor(xs).astype(int);y0=np.floor(ys).astype(int)
    fx=xs-x0;fy=ys-y0
    x0=np.clip(x0,0,W-2);y0=np.clip(y0,0,H-2)
    if a.ndim==3: fx=fx[...,None];fy=fy[...,None]
    return a[y0,x0]*(1-fx)*(1-fy)+a[y0,x0+1]*fx*(1-fy)+a[y0+1,x0]*(1-fx)*fy+a[y0+1,x0+1]*fx*fy
cx,cy=884.8,404.3
for it in range(6):
    X=[];Y=[]
    for deg in np.arange(0,360,1.0):
        th=np.radians(deg)
        rs=np.arange(285,318,0.2)
        l=bil(lum,cx+rs*np.sin(th),cy-rs*np.cos(th))
        # background subtract
        l2=l-np.median(l)
        if l2.max()<12: continue
        # centroid around the peak
        i=l2.argmax(); s=slice(max(0,i-8),i+9)
        wts=np.clip(l2[s],0,None); rc=(rs[s]*wts).sum()/wts.sum()
        X.append(cx+rc*np.sin(th));Y.append(cy-rc*np.cos(th))
    x=np.array(X);y=np.array(Y)
    A=np.c_[2*x,2*y,np.ones(len(x))];b=x*x+y*y
    c=np.linalg.lstsq(A,b,rcond=None)[0]
    cx,cy=c[0],c[1];r=np.sqrt(c[2]+cx*cx+cy*cy)
    res=np.hypot(x-cx,y-cy)-r
    print(it,round(cx,2),round(cy,2),round(r,2),len(x),'res std',round(res.std(),2),'max',round(np.abs(res).max(),2))
k=844/1774
print('844:',cx*k,cy*k,r*k)
# ellipse check: horizontal vs vertical radius
for deg in (0,90,180,270,45,135,225,315):
    th=np.radians(deg); rs=np.arange(280,320,0.2)
    l=bil(lum,cx+rs*np.sin(th),cy-rs*np.cos(th)); l2=l-np.median(l); i=l2.argmax(); s=slice(max(0,i-8),i+9); wts=np.clip(l2[s],0,None)
    print(deg, round((rs[s]*wts).sum()/wts.sum(),2), round(l.max()))
# polar unwrap: x = angle (0..360 step 0.25 -> 1440), y = radius 200..330 step 0.25 -> 520
degs=np.arange(0,360,0.25); rs=np.arange(330,236,-0.25)
TH,RR=np.meshgrid(np.radians(degs),rs)
pol=bil(im,cx+RR*np.sin(TH),cy-RR*np.cos(TH))
Image.fromarray(np.clip(pol,0,255).astype(np.uint8)).save('polar.png')
# brightened
Image.fromarray(np.clip(pol*2.2,0,255).astype(np.uint8)).save('polar-bright.png')
np.save('centre.npy',np.array([cx,cy,r]))
print(pol.shape)
