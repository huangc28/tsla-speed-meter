# 位置固定的驗證:每張畫面(@2x 和 1 倍)的圓環 + 刻度、P R N D、四個圓底的邊逐像素比。
# 第二十四輪:主畫面 main-01…11 對 main-01(下弧的四個圓底);候選 alt-01 / 07 的圓底邊也對 main-01(格位一樣,只是圖示換位置);
# 第二十八輪:主畫面換成照車主的圖的排法 → main-01…11 對 main-01 比的是新的四個圓底(中心讀 slots28.json);上一版的主畫面 row-01…11、候選 alt、照圖的下弧 arc 的圓底邊改對 row-01(下弧)。
# 第二十九輪:主畫面的圖示只在出事時出現 → main-01 的圓裡沒有圓底。所以新的 main-NN:畫著的格位,圓底邊對 alw-NN(同一個狀態、第二十八輪的畫法)要 0;沒畫的格位對 main-01(空的)要 0。
#   alw-01…11(第二十八輪的主畫面)照第二十八輪的比法:四個圓底邊、圓環、P R N D 對 alw-01。fute-01…04 的四格也照同一個規則(對 alw 的同狀態 / main-01)。
# 第三十輪:futm-01…03(「以後接上地圖時」,只有速限牌)的四格照 fute 的同一個規則(對應的狀態:01 → 01、02 → 02、03 → 07)。
# 未選的照舊對 corner-01(建議版扣掉換色的兩段;SF 兩張互比;照圖的下弧三張互比,它們的圓底邊也和 main-01 比)。
import numpy as np, os, json
from PIL import Image
D=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))+'/'
def im(p): return np.asarray(Image.open(D+p).convert('RGB')).astype(int)
NEW=[f'main-{k:02d}' for k in range(1,12)]; ROW=[f'row-{k:02d}' for k in range(1,12)]; ALT=['alt-01','alt-07']
PICD={k:tuple(v) for k,v in json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'slots28.json'))).items()}; PIC=list(PICD.values())   # 第二十八輪起主畫面的四個圓底
ALW=[f'alw-{k:02d}' for k in range(1,12)]
# 第二十九輪:每個狀態畫哪幾格(o = 開著 / 胎壓不足;u = 虛線)。fute-NN 對應的 alw 狀態:01 → 01、02 → 02、03 → 07、04 → 08
DRAWN={'02':('door','tire'),'03':('door','tire'),'05':('frunk',),'06':('trunk',),'07':('frunk','door','trunk','tire'),'10':('frunk','door','trunk')}
FUTE={'fute-01':'01','fute-02':'02','fute-03':'07','fute-04':'08','futm-01':'01','futm-02':'02','futm-03':'07'}
MAIN=[f'corner-{k:02d}' for k in range(1,12)]+['corner-200','font-hanken-86','font-hanken-248']; SAFE=['safe-01','safe-02','safe-07']; SFN=['font-sf-86','font-sf-248']; ARC=['arc-02','arc-03','arc-07']
C={'tl':(338.17,99.13),'tr':(505.83,99.13),'bl':(329.92,234.11),'br':(514.08,234.11)}          # 四角
LOW=[(323.03,222.43),(382.20,275.69),(461.80,275.69),(520.97,222.43)]                          # 下弧
for suf,S in (('@2x',2),('',1)):
    H,W=390*S,844*S; yy,xx=np.mgrid[:H,:W]; X=(xx+.5)/S; Y=(yy+.5)/S; rr=np.hypot(X-422,Y-172); th=(np.degrees(np.arctan2(X-422,-(Y-172)))+360)%360
    ring=(rr>135)&(rr<165); warm=((th>56)&(th<118))|((th>226)&(th<278)); gear=(Y>56)&(Y<72)&(X>380)&(X<465)
    edge=lambda c:(np.hypot(X-c[0],Y-c[1])>16.8)&(np.hypot(X-c[0],Y-c[1])<19.5)
    low=np.zeros((H,W),bool); pic=np.zeros((H,W),bool)
    for c in LOW: low|=edge(c)
    for c in PIC: pic|=edge(c)
    out=[]
    def d(a,b,m): return int(np.abs(a-b).max(axis=2)[m].max()), int((np.abs(a-b).max(axis=2)[m]>0).sum())
    ref=im('main-01'+suf+'.png'); aref=im('alw-01'+suf+'.png')
    v=d(aref,ref,ring|gear)
    if v[0]>0: out.append(('alw-01 vs main-01 整圈+PRND',v))
    for n in ALW:   # 第二十八輪的主畫面:照舊,四個圓底邊都對 alw-01
        a=im(n+suf+'.png'); r={'圓環+刻度':d(a,aref,ring),'四個圓底邊':d(a,aref,pic)}
        if n!='alw-08': r['PRND']=d(a,aref,gear)
        bad={k:v for k,v in r.items() if v[0]>0}
        if bad: out.append((n,bad))
    for n in NEW+list(FUTE):   # 第二十九輪:畫著的格位對 alw 的同一個狀態,沒畫的對 main-01(空的)
        key=FUTE.get(n,n[-2:]); a=im(n+suf+'.png'); same=im('alw-'+key+suf+'.png'); r={}
        if n in NEW: r['圓環+刻度']=d(a,ref,ring)   # fute 的圓環上有速限牌、駐車 / 車道的圓底,不比整圈
        for k,c in PICD.items(): r[('畫著的 ' if k in DRAWN.get(key,()) else '沒畫的 ')+k]=d(a,same if k in DRAWN.get(key,()) else ref,edge(c))
        if key!='08': r['PRND']=d(a,ref,gear)
        bad={k:v for k,v in r.items() if v[0]>0}
        if bad: out.append((n,bad))
    rowref=im('row-01'+suf+'.png')
    v=d(rowref,ref,ring|gear)
    if v[0]>0: out.append(('row-01 vs main-01 整圈+PRND',v))
    for n in ROW+ALT:
        a=im(n+suf+'.png'); r={'圓環+刻度':d(a,rowref,ring),'下弧圓底邊':d(a,rowref,low)}
        if n!='row-08': r['PRND']=d(a,rowref,gear)
        bad={k:v for k,v in r.items() if v[0]>0}
        if bad: out.append((n,bad))
    for n in ARC:
        v=d(im(n+suf+'.png'),rowref,low)
        if v[0]>0: out.append((n+' 下弧圓底邊 vs row-01',v))
    print(suf or '1x','主畫面、以後有資料時、11/14 的版本、11/13 的主畫面、候選:不是 0 的(最大差, 像素數):',out if out else '沒有')
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
