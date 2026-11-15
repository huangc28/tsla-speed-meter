import numpy as np, sys
from PIL import Image
from ic1 import mask_of
K=0.4758/6
def edt(mask):   # exact squared EDT to nearest True (Felzenszwalb), numpy-per-row implementation
    INF=1e12
    f=np.where(mask,0.,INF)
    def pass1d(f):
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
    g=np.array([pass1d(c) for c in f.T]).T
    g=np.array([pass1d(r) for r in g])
    return np.sqrt(g)
def contour(m):
    e=m.copy(); e[1:]&=m[:-1]; e[:-1]&=m[1:]; e[:,1:]&=m[:,:-1]; e[:,:-1]&=m[:,1:]
    return m&~e
for name in sys.argv[1:]:
    im,ref=mask_of(name)
    mine=np.asarray(Image.open(f'mine-{name}.png').convert('L'))>127
    cr,cm=contour(ref),contour(mine)
    d1=edt(cr)[cm]; d2=edt(cm)[cr]; d=np.r_[d1,d2]
    iou=(ref&mine).sum()/(ref|mine).sum()
    print(f'{name}: max {d.max()*K:.2f} p95 {np.percentile(d,95)*K:.2f} median {np.median(d)*K:.2f} (1x px) | mine→ref max {d1.max()*K:.2f}, ref→mine max {d2.max()*K:.2f} | area ref {ref.sum()} mine {mine.sum()} IoU {iou:.3f}')
    ys,xs=np.where(cm); j=d1.argmax(); print('   worst mine pt',xs[j],ys[j]); ys,xs=np.where(cr); j=d2.argmax(); print('   worst ref pt',xs[j],ys[j])
    out=im.copy()*0.9
    out[mine&~ref]=out[mine&~ref]*0.3+np.array([0,200,220])*0.7
    out[ref&~mine]=np.array([255,40,200])
    out[cm]=255
    Image.fromarray(np.clip(out,0,255).astype(np.uint8)).save(f'overlay-{name}.png')
