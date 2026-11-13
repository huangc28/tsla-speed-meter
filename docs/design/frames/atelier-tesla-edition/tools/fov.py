import numpy as np
from PIL import Image
exec(open('fcmp.py').read().split("rows=[]; seen={}")[0])
def cell_of(name,w):
    idx=[i for i,(f,ww) in enumerate(L) if f==name and ww==w][0]
    img=np.asarray(Image.open(f'fonts-{idx//26}.png').convert('L')); i=idx%26
    return img[i*400:(i+1)*400]>127
tiles=[]
for name,w in (("Hanken Grotesk",500),("Outfit",400),("system-ui",500),("SFR",500)):
    d,_=digits(cell_of(name,w)); row=[]
    for a,b in zip(rd,d):
        h=a.shape[0]; w2=round(b.shape[1]*h/b.shape[0])
        bb=np.asarray(Image.fromarray((b*255).astype(np.uint8)).resize((w2,h),Image.BILINEAR))>127
        W=max(a.shape[1],w2)+40; A=np.zeros((h+40,W),bool);B=np.zeros((h+40,W),bool)
        oa=(W-a.shape[1])//2; ob=(W-w2)//2
        A[20:20+h,oa:oa+a.shape[1]]=a; B[20:20+h,ob:ob+w2]=bb
        rgb=np.zeros((h+40,W,3),np.uint8)
        rgb[A&B]=(235,235,235); rgb[A&~B]=(230,60,60); rgb[B&~A]=(40,200,220)
        row.append(rgb)
    t=np.zeros((680,1000,3),np.uint8); x=0
    for r in row: t[:r.shape[0],x:x+r.shape[1]]=r; x+=r.shape[1]
    tiles.append(t)
out=np.concatenate(tiles,axis=0)
Image.fromarray(out).resize((out.shape[1]//2,out.shape[0]//2),Image.LANCZOS).save('font-overlay.png'); print(out.shape)
