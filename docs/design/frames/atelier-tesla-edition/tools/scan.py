import numpy as np, sys
from ic1 import mask_of
def runs(v):
    out=[];s=None
    for i,x in enumerate(v):
        if x and s is None: s=i
        if not x and s is not None: out.append((s,i));s=None
    if s is not None: out.append((s,len(v)))
    return out
name=sys.argv[1]; step=int(sys.argv[2]) if len(sys.argv)>2 else 8
im,m=mask_of(name)
ys,xs=np.where(m)
print('ROWS y: runs x0-x1 (mid,width)')
for y in range(ys.min(),ys.max()+1,step):
    print(y,' '.join(f'{a}-{b}({(a+b)/2:.0f},{b-a})' for a,b in runs(m[y])))
print('COLS x: runs y0-y1 (mid,width)')
for x in range(xs.min(),xs.max()+1,step):
    print(x,' '.join(f'{a}-{b}({(a+b)/2:.0f},{b-a})' for a,b in runs(m[:,x])))
