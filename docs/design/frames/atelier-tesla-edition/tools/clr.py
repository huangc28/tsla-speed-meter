import numpy as np, sys
from PIL import Image
from ov import edt
S=2
def mask(name,th=60): return np.asarray(Image.open(f'ink/{name}.png').convert('L'))>th
def comps(m):
    lab=np.zeros(m.shape,int); n=0
    for y,x in zip(*np.where(m)):
        if lab[y,x]: continue
        n+=1; st=[(y,x)]; lab[y,x]=n
        while st:
            a,b=st.pop()
            for c,d in ((a+1,b),(a-1,b),(a,b+1),(a,b-1)):
                if 0<=c<m.shape[0] and 0<=d<m.shape[1] and m[c,d] and not lab[c,d]: lab[c,d]=n; st.append((c,d))
    return lab,n
def bbox(m): ys,xs=np.where(m); return xs.min()/S,ys.min()/S,(xs.max()+1)/S,(ys.max()+1)/S
unit=mask('unit'); gear=mask('gear'); tick=mask('tick',40); ring=mask('ring',18)
D={k:edt(v) for k,v in (('unit',unit),('gear',gear),('tick',tick))}
V=(188,200,248,888,111,100,86,8)
def gaps(m):   # 數字之間的空(欄方向沒有墨的連續寬度)
    cols=m.any(axis=0); xs=np.where(cols)[0]; out=[];s=None
    for i in range(xs.min(),xs.max()+1):
        if not cols[i] and s is None: s=i
        if cols[i] and s is not None: out.append((i-s)/S); s=None
    return out
for pre,label in (('num','Hanken(主畫面)'),('sfnum','SF Pro(字型比較)')):
    print('==',label)
    for v in V+(0,):
        m=mask(f'{pre}-{v}'); b=bbox(m); print(f'  {v}: 墨跡 x {b[0]:.1f}-{b[2]:.1f} y {b[1]:.1f}-{b[3]:.1f} 寬 {b[2]-b[0]:.1f} 高 {b[3]-b[1]:.1f} 數字間空 {gaps(m)}')
yy,xx=np.mgrid[:tick.shape[0],:tick.shape[1]]; rr=np.hypot(xx/S-422,yy/S-172)
print('刻度 r %.2f-%.2f;圓環(含光暈)外框'%(rr[tick].min(),rr[tick].max()),bbox(ring),'km/h',bbox(unit),'P R N D',bbox(gear))
for lay,pre in (('corner','num'),('arc','num'),('sf','sfnum')):
    disc=mask(f'disc-{lay}'); lab,n=comps(disc); DN={v:edt(mask(f'{pre}-{v}')) for v in V}
    print(lay,'圓底',n,'(數字:%s)'%pre)
    for i in range(1,n+1):
        ys,xs=np.where(lab==i); cx,cy=xs.mean()/S,ys.mean()/S; ang=np.degrees(np.arctan2(cx-422,-(cy-172)))
        row=[f'({cx:.1f},{cy:.1f}) {ang:+.0f}°']+[f'{v}:{DN[v][lab==i].min()/S:.1f}' for v in V]+[f'{k}:{D[k][lab==i].min()/S:.1f}' for k in ('gear','unit','tick')]
        other=edt((lab>0)&(lab!=i)); row.append(f'disc:{other[lab==i].min()/S:.1f}'); print('  '+'  '.join(row))
print('== 位置固定:各版本的圓底 / km/h / P R N D 遮罩和主畫面比(不同的像素數)')
for lay in ('safe','sf','arc'):
    print(' ',lay,'圓底',int((mask('disc-corner')^mask(f'disc-{lay}')).sum()),'km/h',int((mask('unit-corner')^mask(f'unit-{lay}')).sum()),'P R N D',int((mask('gear-corner',40)^mask(f'gear-{lay}',40)).sum()))
