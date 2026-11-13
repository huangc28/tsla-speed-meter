# 每張畫面裡不該變的東西(時間、導航卡、頁尾左、頁尾右的 ODO 和里程、齒輪、km/h、同樣的「86」)逐像素比。
# 第二十四輪:主畫面 main-01…11 和候選 alt-01 / 07 對 main-01 比;未選的(四角、建議版、字型、照圖的下弧)對 corner-01 比。兩組的頁尾、時間、導航卡再互比一次。
import numpy as np, os
from PIL import Image
D=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))+'/'
def im(p): return np.asarray(Image.open(D+p).convert('RGB')).astype(int)
NEW=[f'main-{k:02d}' for k in range(1,12)]+['alt-01','alt-07']
OLD=[f'corner-{k:02d}' for k in range(1,12)]+['corner-200','safe-01','safe-02','safe-07','font-hanken-86','font-hanken-248','font-sf-86','font-sf-248','arc-02','arc-03','arc-07']
HAS86=('main-02','main-05','main-06','main-10','main-11','corner-02','corner-05','corner-06','corner-10','corner-11','safe-01','safe-02','font-hanken-86','arc-02')
for suf,S in (('@2x',2),('',1)):
    bad=[]
    for names,refn in ((NEW,'main-01'),(OLD,'corner-01')):
        ref=im(refn+suf+'.png')
        for n in names:
            a=im(n+suf+'.png')
            regs={'時間':(100,16,165,44),'導航卡':(62,79,246,261),'頁尾左':(85,333,240,358),'頁尾右(ODO、里程)':(640,333,775,358),'齒輪':(721,16,769,64)}
            if n[-3:]!='-09': regs['km/h']=(400,206,445,228)
            if n in HAS86: regs['86']=(362,122,482,204)
            for r,(x0,y0,x1,y1) in regs.items():
                d=np.abs(a[y0*S:y1*S,x0*S:x1*S]-ref[y0*S:y1*S,x0*S:x1*S]).max()
                if d>0: bad.append((n+suf,r,int(d)))
    a=im('main-01'+suf+'.png'); b=im('corner-01'+suf+'.png')
    for r,(x0,y0,x1,y1) in {'時間':(100,16,165,44),'導航卡':(62,79,246,261),'頁尾整排':(85,333,775,358),'齒輪':(721,16,769,64),'km/h':(400,206,445,228),'86':(362,122,482,204),'右欄':(592,70,775,262)}.items():
        d=np.abs(a[y0*S:y1*S,x0*S:x1*S]-b[y0*S:y1*S,x0*S:x1*S]).max()
        if d>0: bad.append(('main-01 對 corner-01'+suf,r,int(d)))
    print(suf or '1x','不一致:',bad if bad else '沒有(每張的時間、導航卡、頁尾、齒輪、km/h、同樣的 86 都逐像素一樣;主畫面和未選的四角這幾處也一樣)')
