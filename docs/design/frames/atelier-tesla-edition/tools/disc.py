import numpy as np
from PIL import Image
R='/Users/huangchihan/develop/tsla-speed-meter/docs/design/frames/atelier-tesla-edition/reference/'
for name in ('frunk','trunk','door','tire'):
    im=np.asarray(Image.open(R+f'crop-{name}@6x.png').convert('RGB')).astype(float); lum=im.mean(axis=2)
    x0,y0=288.,288.
    for it in range(6):
        X=[];Y=[]
        for deg in np.arange(0,360,2.0):
            th=np.radians(deg); rs=np.arange(205,262,0.5)
            xs=x0+rs*np.sin(th); ys=y0-rs*np.cos(th)
            l=lum[np.clip(ys.round().astype(int),0,575),np.clip(xs.round().astype(int),0,575)]
            ls=np.convolve(l,np.ones(5)/5,'same'); g=np.gradient(ls); i=g[4:-4].argmin()+4
            X.append(x0+rs[i]*np.sin(th));Y.append(y0-rs[i]*np.cos(th))
        x=np.array(X);y=np.array(Y); A=np.c_[2*x,2*y,np.ones(len(x))];b=x*x+y*y
        c=np.linalg.lstsq(A,b,rcond=None)[0]; res=np.hypot(x-c[0],y-c[1]); keep=np.abs(res-np.median(res))<4
        c=np.linalg.lstsq(A[keep],b[keep],rcond=None)[0]; x0,y0=c[0],c[1]; rr=np.sqrt(c[2]+x0*x0+y0*y0)
    print(name,'disc centre (%.1f,%.1f) r_outer_edge %.1f (=%.2f pt)'%(x0,y0,rr,rr*0.0793))
    rs=np.arange(150,262,2.0); out=[]
    th=np.radians(np.arange(0,360,3))
    for rv in rs:
        xs=x0+rv*np.sin(th); ys=y0-rv*np.cos(th); ok=(xs>=0)&(xs<576)&(ys>=0)&(ys<576)
        px=im[ys[ok].round().astype(int),xs[ok].round().astype(int)]
        out.append((rv,np.median(px,axis=0)))
    print('  radial median RGB:',' '.join(f'{rv:.0f}:{p.round().astype(int).tolist()}' for rv,p in out if rv>=196))
    # fill gradient top vs bottom inside disc (away from icon): sample at r=190 by angle
    for deg in (0,45,90,135,180,225,270,315):
        t=np.radians(deg); xs=int(x0+195*np.sin(t)); ys=int(y0-195*np.cos(t)); print('  fill@%d'%deg, np.median(im[ys-4:ys+5,xs-4:xs+5],axis=(0,1)).astype(int).tolist(), end=';')
        xs=int(x0+229*np.sin(t)); ys=int(y0-229*np.cos(t)); print(' rim', im[ys-3:ys+4,xs-3:xs+4].reshape(-1,3).max(axis=0).astype(int).tolist())
