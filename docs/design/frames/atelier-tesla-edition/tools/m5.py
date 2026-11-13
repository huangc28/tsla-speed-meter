import numpy as np
from PIL import Image
R='/Users/huangchihan/develop/tsla-speed-meter/docs/design/frames/atelier-tesla-edition/reference/'
im=np.asarray(Image.open(R+'dashboard-2026-11-12.png').convert('RGB')).astype(float)
H,W,_=im.shape
lum=im.mean(axis=2); k=844/1774
cx,cy,r=np.load('centre.npy')
def bil(a,xs,ys):
    x0=np.floor(xs).astype(int);y0=np.floor(ys).astype(int)
    fx=xs-x0;fy=ys-y0
    if a.ndim==3: fx=fx[...,None];fy=fy[...,None]
    return a[y0,x0]*(1-fx)*(1-fy)+a[y0,x0+1]*fx*(1-fy)+a[y0+1,x0]*(1-fx)*fy+a[y0+1,x0+1]*fx*fy
# discs: rough centres from the image
guess={'frunk':(707,287),'trunk':(1065,287),'door':(671,407),'tire':(1100,407),'park':(711,530),'lane':(1061,530)}
for name,(gx,gy) in guess.items():
    x0,y0=gx,gy
    for it in range(5):
        X=[];Y=[]
        for deg in np.arange(0,360,3.0):
            th=np.radians(deg); rs=np.arange(30,48,0.2)
            l=bil(lum,x0+rs*np.sin(th),y0-rs*np.cos(th))
            # disc edge = max negative gradient going outward (inside lighter than outside), or rim peak
            g=np.gradient(l); i=g.argmin()
            X.append(x0+rs[i]*np.sin(th));Y.append(y0-rs[i]*np.cos(th))
        x=np.array(X);y=np.array(Y)
        A=np.c_[2*x,2*y,np.ones(len(x))];b=x*x+y*y
        c=np.linalg.lstsq(A,b,rcond=None)[0]
        res=np.hypot(x-c[0],y-c[1]); med=np.median(res); keep=np.abs(res-med)<2
        A=A[keep];b=b[keep]; c=np.linalg.lstsq(A,b,rcond=None)[0]
        x0,y0=c[0],c[1]; rr=np.sqrt(c[2]+x0*x0+y0*y0)
    dx,dy=x0-cx,y0-cy
    ang=np.degrees(np.arctan2(dx,-dy))
    # radial profile averaged
    rs=np.arange(0,52,0.5); prof=[]
    for rv in rs:
        th=np.radians(np.arange(0,360,4)); prof.append(bil(im,x0+rv*np.sin(th),y0-rv*np.cos(th)).mean(axis=0))
    prof=np.array(prof)
    print(f'{name}: centre src ({x0:.1f},{y0:.1f}) r_edge {rr:.1f} | 844: ({x0*k:.1f},{y0*k:.1f}) r {rr*k:.2f} dia {2*rr*k:.1f} | from ring centre: dist {np.hypot(dx,dy)*k:.1f} ({np.hypot(dx,dy)/r:.3f} R) angle {ang:.1f} keep {keep.sum()}')
    print('   radial profile (r src: RGB):',' '.join(f'{rv:.0f}:{p.round().astype(int).tolist()}' for rv,p in zip(rs[::4],prof[::4])))
    idx=[(rv,p) for rv,p in zip(rs,prof) if 32<=rv<=46]
    print('   edge zone:',' '.join(f'{rv:.1f}:{p.mean():.0f}' for rv,p in idx))
# ground colour: several far-away patches
for (x,y) in [(1300,300),(1500,450),(300,700),(885,800),(600,120),(100,100),(1700,800)]:
    print('ground',(x,y),np.median(im[y-15:y+15,x-15:x+15],axis=(0,1)))
# inside the ring ground (between icons)
for (x,y) in [(885,250),(885,560),(760,620),(1010,620),(800,240),(970,240)]:
    print('inside',(x,y),np.median(im[y-8:y+8,x-8:x+8],axis=(0,1)))
