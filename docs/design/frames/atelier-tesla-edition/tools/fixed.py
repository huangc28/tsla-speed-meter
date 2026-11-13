# 位置固定的驗證:每張畫面(@2x 和 1 倍)的圓環 + 刻度、P R N D、四個圓底的邊逐像素比。
# 第二十四輪:主畫面 main-01…11 對 main-01(下弧的四個圓底);候選 alt-01 / 07 的圓底邊也對 main-01(格位一樣,只是圖示換位置);
# 未選的照舊對 corner-01(建議版扣掉換色的兩段;SF 兩張互比;照圖的下弧三張互比,它們的圓底邊也和 main-01 比)。
import numpy as np, os
from PIL import Image
D=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))+'/'
def im(p): return np.asarray(Image.open(D+p).convert('RGB')).astype(int)
NEW=[f'main-{k:02d}' for k in range(1,12)]; ALT=['alt-01','alt-07']
MAIN=[f'corner-{k:02d}' for k in range(1,12)]+['corner-200','font-hanken-86','font-hanken-248']; SAFE=['safe-01','safe-02','safe-07']; SFN=['font-sf-86','font-sf-248']; ARC=['arc-02','arc-03','arc-07']
C={'tl':(338.17,99.13),'tr':(505.83,99.13),'bl':(329.92,234.11),'br':(514.08,234.11)}          # 四角
LOW=[(323.03,222.43),(382.20,275.69),(461.80,275.69),(520.97,222.43)]                          # 下弧
for suf,S in (('@2x',2),('',1)):
    H,W=390*S,844*S; yy,xx=np.mgrid[:H,:W]; X=(xx+.5)/S; Y=(yy+.5)/S; rr=np.hypot(X-422,Y-172); th=(np.degrees(np.arctan2(X-422,-(Y-172)))+360)%360
    ring=(rr>135)&(rr<165); warm=((th>56)&(th<118))|((th>226)&(th<278)); gear=(Y>56)&(Y<72)&(X>380)&(X<465)
    edge=lambda c:(np.hypot(X-c[0],Y-c[1])>16.8)&(np.hypot(X-c[0],Y-c[1])<19.5)
    low=np.zeros((H,W),bool)
    for c in LOW: low|=edge(c)
    out=[]
    def d(a,b,m): return int(np.abs(a-b).max(axis=2)[m].max()), int((np.abs(a-b).max(axis=2)[m]>0).sum())
    ref=im('main-01'+suf+'.png')
    for n in NEW+ALT:
        a=im(n+suf+'.png'); r={'圓環+刻度':d(a,ref,ring),'下弧圓底邊':d(a,ref,low)}
        if n!='main-08': r['PRND']=d(a,ref,gear)
        bad={k:v for k,v in r.items() if v[0]>0}
        if bad: out.append((n,bad))
    for n in ARC:
        v=d(im(n+suf+'.png'),ref,low)
        if v[0]>0: out.append((n+' 下弧圓底邊 vs main-01',v))
    print(suf or '1x','主畫面、候選:不是 0 的(最大差, 像素數):',out if out else '沒有')
    ref=im('corner-01'+suf+'.png'); out=[]
    for n in MAIN+SAFE+SFN+ARC:
        a=im(n+suf+'.png'); r={}
        r['圓環+刻度']=d(a,ref,ring&~warm if n in SAFE else ring)
        if n not in SAFE and n!='corner-08': r['PRND']=d(a,ref,gear)
        if n in MAIN+SAFE+SFN: r['圓底邊']=d(a,ref,edge(C['tl'])|edge(C['tr'])|edge(C['bl'])|edge(C['br']))
        bad={k:v for k,v in r.items() if v[0]>0}
        if bad: out.append((n,bad))
    sa=im(SAFE[0]+suf+'.png')
    for n in SAFE[1:]+['main-01']:
        v=d(im(n+suf+'.png'),sa,ring|gear)
        if v[0]>0: out.append((n+' vs safe-01 整圈+PRND',v))
    print(suf or '1x','未選的:不是 0 的(最大差, 像素數):',out if out else '沒有')
