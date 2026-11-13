import numpy as np
from PIL import Image, ImageDraw
R='/Users/huangchihan/develop/tsla-speed-meter/docs/design/frames/atelier-tesla-edition/reference/'
def mask_of(name):
    im=np.asarray(Image.open(R+f'crop-{name}@6x.png').convert('RGB')).astype(float)
    lum=im.mean(axis=2); r,g,b=im[...,0],im[...,1],im[...,2]
    if name in('frunk','trunk'): m=lum>105
    elif name=='door': m=(r>110)&(r-g>40)
    else: m=(r>110)&(r-b>50)
    # restrict to inside disc radius 215
    yy,xx=np.mgrid[:576,:576]; m&=np.hypot(xx-288,yy-288)<222
    return im,m
if __name__=='__main__':
    for name in ('frunk','trunk','door','tire'):
        im,m=mask_of(name)
        ys,xs=np.where(m)
        print(name,'bbox x',xs.min(),xs.max()+1,'y',ys.min(),ys.max()+1,'w',xs.max()+1-xs.min(),'h',ys.max()+1-ys.min(),'| pt w %.1f h %.1f'%((xs.max()+1-xs.min())*0.0793,(ys.max()+1-ys.min())*0.0793),'centre',(xs.min()+xs.max()+1)/2,(ys.min()+ys.max()+1)/2)
        px=im[m]; lum=px.mean(axis=1)
        print('  colour median all',np.median(px,axis=0),'median of top half by lum',np.median(px[lum>np.median(lum)],axis=0),'p90',np.percentile(px,90,axis=0))
        # stroke width estimate: area / skeleton length ~ use distance transform approx: 2*median of max inscribed radius along medial axis -> brute: erosion count
        mm=m.copy(); n=0; areas=[mm.sum()]
        while mm.any():
            e=mm.copy(); e[1:]&=mm[:-1]; e[:-1]&=mm[1:]; e[:,1:]&=mm[:,:-1]; e[:,:-1]&=mm[:,1:]; mm=e; n+=1; areas.append(mm.sum())
        print('  erosions to vanish',n,'areas',areas[:14])
        # save a gridded 2x view
        big=Image.open(R+f'crop-{name}@6x.png').convert('RGB').resize((1152,1152),Image.LANCZOS)
        big=Image.eval(big,lambda v:min(255,int(v*1.3)))
        d=ImageDraw.Draw(big)
        for t in range(0,576,48):
            d.line([(t*2,0),(t*2,1152)],fill=(0,90,140),width=1); d.line([(0,t*2),(1152,t*2)],fill=(0,90,140),width=1)
            d.text((t*2+3,2),str(t),fill=(0,220,255)); d.text((2,t*2+3),str(t),fill=(0,220,255))
        big.save(f'grid-{name}.png')
