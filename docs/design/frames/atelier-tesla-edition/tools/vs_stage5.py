# 第二十五輪(右欄):和 stage5/(車主說滿意的那一版)逐像素比。
# usage: python3 vs_stage5.py <用現在的頁面全部重匯的資料夾>
# (a) main-NN 對 stage5/main-NN:右欄矩形 RECT 以外要 0 個像素不同(1 倍、2 倍都比);
# (b) col0-01 / 07(上一版的右欄)對 stage5/main-01 / 07:整張 0;
# (c) 候選 colb / colc、加選 colx 對同一個狀態的新 main:矩形以外 0;
# (d) 未選的畫面、alt、compare.png、icons-compare.png:重匯的對資料夾裡現有的檔,整張 0。
#     階段 3 起 colb / colc / colx / col0 也算「沒改的」,一起比(只有 main-* 重匯)。
import numpy as np, os, sys
from PIL import Image
D=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))+'/'; O=sys.argv[1].rstrip('/')+'/'
RECT=(584,70,776,298)   # x0, y0, x1, y1(844 × 390 的座標;不含 x1、y1)
def im(p): return np.asarray(Image.open(p).convert('RGB')).astype(int)
def cmp(a,b,S,rect=True):
    d=np.abs(im(a)-im(b)).max(axis=2)>0
    if not rect: return int(d.sum()),0,None
    x0,y0,x1,y1=[v*S for v in RECT]; ins=d[y0:y1,x0:x1]; n_in=int(ins.sum()); box=None
    if n_in: ys,xs=np.where(ins); box=((x0+xs.min())/S,(y0+ys.min())/S,(x0+xs.max()+1)/S,(y0+ys.max()+1)/S)
    return int(d.sum())-n_in,n_in,box
bad=0
for suf,S in (('',1),('@2x',2)):
    print('== (a) main 對 stage5,',suf or '1x','矩形',RECT)
    for k in range(1,12):
        n=f'main-{k:02d}{suf}.png'; out,ins,box=cmp(O+n,D+'stage5/'+n,S); bad+=out
        print(f'  main-{k:02d}: 矩形外 {out}、矩形裡 {ins} 個,變動的外框 {box}')
    print('== (b) col0 對 stage5/main(整張)')
    for k in ('01','07'):
        out,_,_=cmp(O+f'col0-{k}{suf}.png',D+f'stage5/main-{k}{suf}.png',S,False); bad+=out; print(f'  col0-{k}: {out}')
    print('== (c) 候選、加選對新的 main(矩形外)')
    for v,ks in (('colb',('01','02','11')),('colc',('01','02','11')),('colx',('07',))):
        for k in ks:
            out,ins,box=cmp(O+f'{v}-{k}{suf}.png',O+f'main-{k}{suf}.png',S); bad+=out; print(f'  {v}-{k}: 矩形外 {out}、矩形裡 {ins},外框 {box}')
print('== (d) 未選、alt、對照圖:重匯的對現有的檔(整張)')
names=sorted(f for f in os.listdir(O) if f.endswith('.png') and f.split('-')[0] in ('corner','safe','arc','font','alt','colb','colc','colx','col0') or f in ('compare.png','icons-compare.png')); miss=[]
for f in names:
    if not os.path.exists(D+f): miss.append(f); continue
    a,b=im(O+f),im(D+f)
    n=int((np.abs(a-b).max(axis=2)>0).sum()) if a.shape==b.shape else -1
    if n: bad+=abs(n); print(f'  {f}: {n}')
print(f'  比了 {len(names)-len(miss)} 張;少了現有檔的 {miss}')
print('合計不該有的不同像素:',bad)
