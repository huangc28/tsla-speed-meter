# 第二十六輪:駐車、車道、速限牌和車主的裁圖疊圖,量輪廓的偏差(做法同 ov.py:精確 EDT;單位換成 1 倍的 px)。
# usage: python3 fut_ov.py <資料夾>   裡面要有頁面畫的 mine-park.png、mine-lane.png(?only=futi-park / futi-lane,576 × 576,白線黑底)
#        和 mine-sign.png(?only=futi-sign,768 × 768,彩色)。疊圖寫到同一個資料夾的 overlay-<名字>.png
#        (白線 = 畫的輪廓、洋紅 = 圖上有畫的沒有、青 = 畫的多出來的)。
import numpy as np, sys, os
from PIL import Image
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))+'/reference/'; D=sys.argv[1].rstrip('/')+'/'; K=0.4758/6
def edt(mask):
    INF=1e12; f=np.where(mask,0.,INF)
    def p1(f):
        n=len(f); d=np.empty(n); v=np.zeros(n,int); z=np.empty(n+1); k=0; z[0]=-INF; z[1]=INF
        for q in range(1,n):
            while True:
                s=((f[q]+q*q)-(f[v[k]]+v[k]*v[k]))/(2*q-2*v[k])
                if s<=z[k]: k-=1
                else: break
            k+=1; v[k]=q; z[k]=s; z[k+1]=INF
        k=0
        for q in range(n):
            while z[k+1]<q: k+=1
            d[q]=(q-v[k])**2+f[v[k]]
        return d
    g=np.array([p1(c) for c in f.T]).T; return np.sqrt(np.array([p1(r) for r in g]))
def contour(m):
    e=m.copy(); e[1:]&=m[:-1]; e[:-1]&=m[1:]; e[:,1:]&=m[:,:-1]; e[:,:-1]&=m[:,1:]; return m&~e
def report(name,im,ref,mine):
    cr,cm=contour(ref),contour(mine); d1=edt(cr)[cm]; d2=edt(cm)[cr]; d=np.r_[d1,d2]
    print(f'{name}: 最大 {d.max()*K:.2f}、95% {np.percentile(d,95)*K:.2f}、中位 {np.median(d)*K:.2f}(1 倍 px)| 畫的→圖 最大 {d1.max()*K:.2f}、圖→畫的 最大 {d2.max()*K:.2f} | IoU {(ref&mine).sum()/(ref|mine).sum():.3f}')
    ys,xs=np.where(cm); j=d1.argmax(); print('   畫的離圖最遠的點',xs[j],ys[j],end=''); ys,xs=np.where(cr); j=d2.argmax(); print(';圖離畫的最遠的點',xs[j],ys[j])
    out=im.copy()*0.9; out[mine&~ref]=out[mine&~ref]*0.3+np.array([0,200,220])*0.7; out[ref&~mine]=np.array([255,40,200]); out[cm]=255
    Image.fromarray(np.clip(out,0,255).astype(np.uint8)).save(D+f'overlay-{name}.png')
def rgb(p): return np.asarray(Image.open(p).convert('RGB')).astype(float)
for n in ('park','lane'):
    im=rgb(R+f'crop-{n}@6x.png'); yy,xx=np.mgrid[:576,:576]
    report(n,im,(im.mean(axis=2)>105)&(np.hypot(xx-288,yy-288)<215),rgb(D+f'mine-{n}.png').mean(axis=2)>127)
im=rgb(R+'crop-sign@6x.png'); me=rgb(D+'mine-sign.png'); yy,xx=np.mgrid[:768,:768]; rr=np.hypot(xx-384.4,yy-388.4)
report('sign-digits',im,(im.mean(axis=2)<90)&(rr<215),(me.mean(axis=2)<90)&(rr<215))
report('sign-ring',im,((im[...,0]-im[...,1])>60)&(rr<300),((me[...,0]-me[...,1])>60)&(rr<300))
report('sign-outline',im,(im.mean(axis=2)>60)&(rr<300),(me.mean(axis=2)>60)&(rr<300))
