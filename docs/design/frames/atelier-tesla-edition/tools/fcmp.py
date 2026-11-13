import numpy as np, sys
from PIL import Image
R='/Users/huangchihan/develop/tsla-speed-meter/docs/design/frames/atelier-tesla-edition/reference/'
im=Image.open(R+'dashboard-2026-11-12.png').convert('L')
ref=im.crop((760,290,1020,480))
S=4
refb=np.asarray(ref.resize((ref.width*S,ref.height*S),Image.BICUBIC))>128
L=[["Inter",400],["Inter",500],["Inter",600],["Manrope",500],["Manrope",600],["Manrope",700],["Outfit",400],["Outfit",500],["Plus Jakarta Sans",500],["Plus Jakarta Sans",600],["Nunito",600],["Nunito",700],["Nunito Sans",600],["Figtree",500],["Figtree",600],["Lexend",400],["Lexend",500],["Rubik",400],["Rubik",500],["DM Sans",500],["DM Sans",600],["Urbanist",500],["Urbanist",600],["Sora",400],["Sora",500],["Albert Sans",500],["Albert Sans",600],["Red Hat Display",500],["Red Hat Display",600],["Poppins",400],["Poppins",500],["Montserrat",500],["M PLUS Rounded 1c",500],["Quicksand",600],["Quicksand",700],["Varela Round",400],["Readex Pro",400],["Readex Pro",500],["Onest",500],["Onest",600],["Be Vietnam Pro",500],["Mulish",600],["Mulish",700],["Public Sans",500],["Public Sans",600],["Instrument Sans",500],["Instrument Sans",600],["Hanken Grotesk",500],["Hanken Grotesk",600],["Golos Text",500],["Golos Text",600],["Gabarito",400],["Gabarito",500],["Wix Madefor Display",500],["Wix Madefor Display",600],["Geologica",400],["Geologica",500],["Roboto",500],["Open Sans",600],["Lato",700],["Source Sans 3",600],["Work Sans",500],["Jost",500],["Kumbh Sans",500],["Kumbh Sans",600],["Lexend Deca",400],["Lexend Deca",500],["Afacad",600],["Comfortaa",700],["Baloo 2",500],
["system-ui",400],["system-ui",500],["system-ui",600],["SFR",400],["SFR",500],["SFR",600],["ui-rounded",500]]
def digits(mask):
    cols=mask.any(axis=0); xs=np.where(cols)[0]; segs=[];s=None
    for i,v in enumerate(cols):
        if v and s is None: s=i
        if not v and s is not None: segs.append((s,i));s=None
    if s is not None: segs.append((s,len(cols)))
    out=[]
    for a,b in segs:
        ys=np.where(mask[:,a:b].any(axis=1))[0]; out.append(mask[ys.min():ys.max()+1,a:b])
    return out,segs
rd,rsegs=digits(refb)
assert len(rd)==2
def stem(m):  # median horizontal run at mid-lower rows (60-70% height) leftmost run ; horizontal stroke: vertical run at centre column top
    h,w=m.shape; runs=[]
    for y in range(int(h*.62),int(h*.72)):
        row=m[y]; x=0
        while x<w and not row[x]: x+=1
        s=x
        while x<w and row[x]: x+=1
        runs.append(x-s)
    col=m[:,w//2]; y=0
    while y<h and not col[y]: y+=1
    s=y
    while y<h and col[y]: y+=1
    return np.median(runs)/h,(y-s)/h
def cmp(a,b):   # a ref digit, b candidate digit; scale b to a's height, centre align
    h=a.shape[0]; w2=max(1,round(b.shape[1]*h/b.shape[0]))
    bb=np.asarray(Image.fromarray((b*255).astype(np.uint8)).resize((w2,h),Image.BILINEAR))>127
    W=max(a.shape[1],w2)+4
    A=np.zeros((h,W),bool);B=np.zeros((h,W),bool)
    oa=(W-a.shape[1])//2; ob=(W-w2)//2
    A[:,oa:oa+a.shape[1]]=a; B[:,ob:ob+w2]=bb
    return (A&B).sum()/(A|B).sum()
print('ref: 8 w/h %.3f stem %.3f horiz %.3f | 6 w/h %.3f stem %.3f | gap/h %.3f'%(rd[0].shape[1]/rd[0].shape[0],*stem(rd[0]),rd[1].shape[1]/rd[1].shape[0],stem(rd[1])[0],(rsegs[1][0]-rsegs[0][1])/rd[0].shape[0]))
rows=[]; seen={}
for p in range(3):
    img=np.asarray(Image.open(f'fonts-{p}.png').convert('L'))
    for i in range(26):
        idx=p*26+i
        if idx>=len(L): break
        cell=img[i*400:(i+1)*400]>127
        if not cell.any(): continue
        d,segs=digits(cell)
        if len(d)!=2: rows.append((0,L[idx],'segs',len(d))); continue
        key=cell.tobytes()
        dup=seen.get(key); seen.setdefault(key,L[idx])
        i8=cmp(rd[0],d[0]); i6=cmp(rd[1],d[1])
        s8=stem(d[0]); 
        rows.append(((i8+i6)/2,L[idx],'8 IoU %.3f 6 IoU %.3f | 8 w/h %.3f stem %.3f horiz %.3f | 6 w/h %.3f | gap/h %.3f | capH/em %.3f'%(i8,i6,d[0].shape[1]/d[0].shape[0],*s8,d[1].shape[1]/d[1].shape[0],(segs[1][0]-segs[0][1])/d[0].shape[0],d[0].shape[0]/300),dup))
for r in sorted(rows,key=lambda r:-r[0]): print('%.3f'%r[0],r[1],r[2],'DUP of %s'%r[3] if r[3] else '')
