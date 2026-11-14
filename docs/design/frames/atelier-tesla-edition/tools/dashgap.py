# usage: python3 dashgap.py [資料夾,預設是匯圖的資料夾]   量 main-10.png / main-11.png(第二十八輪起:照車主的圖的排法)、row-10.png / row-11.png(上一版的主畫面,下弧)和 corner-10.png / corner-11.png(四角)
# 第二十九輪:主畫面的圖示只在出事時出現 → main-11 的圓裡沒有胎壓的虛線(胎壓讀不到時不畫),改量 alw-11(第二十八輪的主畫面);main-10 的三個虛線照量,alw-10 也量(兩張應該一樣)。
# 第二十八輪:主畫面的圓底中心讀 slots28.json(slots28.py 從頁面截圖算的,不手抄);沒有 row-10.png 的資料夾(第二十七輪以前的備份)就跳過那兩行。量到 0 段 = 圓底中心對不上,不算過。
# 未知虛線的空(裁定 7 / S23-07 的量法):1 倍圖,扣掉圓底的漸層換成墨的覆蓋率;覆蓋率 ≥ 25% 算墨。
# 沿每一列、每一欄找「線上的空」:兩邊都是覆蓋率 ≥ 50% 的墨、中間連續 < 25% 的像素,長度 ≤ 4(更長的是圖形本身的空白)。報每個圖示的最小值和 safety 點名的四段。
import numpy as np, sys, os, json
from PIL import Image
D=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))+'/'
INK=np.array([166,172,181.])
# 圓底中心:CORNER = 未選的四角(上排 ∓49°、下排 ∓124°);LOW = 第二十四輪主畫面的下弧(前車廂 −117°、車門 −159°、後車廂 +159°、胎壓 +117°)
CORNER={'frunk':(338.17,99.13),'trunk':(505.83,99.13),'door':(329.92,234.11),'tire':(514.08,234.11)}
LOW={'frunk':(323.03,222.43),'door':(382.20,275.69),'trunk':(461.80,275.69),'tire':(520.97,222.43)}
PIC={k:tuple(v) for k,v in json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'slots28.json'))).items()}   # 第二十八輪的主畫面:前車廂 / 後車廂在上面兩側、車門 / 胎壓在 9 點 / 3 點
SLOTS=dict(LOW)
def cover(path,slot):
    im=np.asarray(Image.open(path).convert('RGB')).astype(float); cx,cy=SLOTS[slot]
    x0,y0=int(cx)-17,int(cy)-17; w=im[y0:y0+35,x0:x0+35]; lum=w.mean(axis=2)
    yy,xx=np.mgrid[:35,:35]; inside=np.hypot(xx+x0+.5-cx,yy+y0+.5-cy)<16.5
    cov=np.zeros((35,35))
    for r in range(35):
        v=lum[r][inside[r]]
        if len(v)<4: continue
        bg=np.percentile(v,20)           # 這一列的圓底亮度
        cov[r]=np.clip((lum[r]-bg)/(INK.mean()-bg),0,1)*inside[r]
    return cov,x0,y0
def runs(line):
    out=[]; n=len(line); i=0
    while i<n:
        if line[i]>=.5:
            j=i
            while j+1<n and line[j+1]>=.25: j+=1     # 墨(含 ≥25% 的反鋸齒)
            k=j+1
            while k<n and line[k]<.25: k+=1          # 空
            if k<n and k-j-1<=4:
                # 空的另一邊要接到 ≥50% 的墨
                e=k
                while e<n and line[e]>=.25 and line[e]<.5: e+=1
                if e<n and line[e]>=.5 and k-j-1>=1: out.append((j+1,k-j-1))
            i=max(k,i+1)
        else: i+=1
    return out
def measure(path,slot):
    cov,x0,y0=cover(path,slot); res=[]
    for r in range(35):
        if (cov[r]>=.5).sum()>=5:
            for s,g in runs(cov[r]): res.append(('列 y%d'%(y0+r),'x%d'%(x0+s),g))
    for c in range(35):
        if (cov[:,c]>=.5).sum()>=5:
            for s,g in runs(cov[:,c]): res.append(('欄 x%d'%(x0+c),'y%d'%(y0+s),g))
    return res,cov,x0,y0
if __name__=='__main__':
    B=(sys.argv[1].rstrip('/')+'/') if len(sys.argv)>1 else D
    for path,slots,tab in ((B+'main-10.png',('frunk','door','trunk'),PIC),(B+'alw-10.png',('frunk','door','trunk'),PIC),(B+'alw-11.png',('tire',),PIC),(B+'row-10.png',('frunk','door','trunk'),LOW),(B+'row-11.png',('tire',),LOW),(B+'corner-10.png',('frunk','trunk','door'),CORNER),(B+'corner-11.png',('tire',),CORNER)):
        if not os.path.exists(path): print(path.split('/')[-1],'沒有這張,跳過'); continue
        SLOTS.clear(); SLOTS.update(tab)
        for s in slots:
            res,cov,x0,y0=measure(path,s); g=[r[2] for r in res]
            print(path.split('/')[-1],s,'線上的空:共',len(g),'段,最小',min(g) if g else '-','px;分佈',{k:g.count(k) for k in sorted(set(g))})
            bad=[r for r in res if r[2]<2]
            if bad: print('   < 2 的:',bad)
