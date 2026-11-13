# 第二十四輪階段 3:不看顏色的形狀差(量法同 ux 19:四個圖示都畫成同一個灰,1 倍,數亮度差超過 40 階的像素;亮度 = 0.299R + 0.587G + 0.114B)。
# usage: python3 shapediff.py <資料夾>   資料夾裡要有這六張 1 倍圖(主畫面的格位):
#   A = only=main-01&mono=1(全部關著)         A0 = 同上加 &rev=0(修訂前的形狀)
#   As = only=main-01&mono=1&swap=1(前後車廂的圖示互換格位)   As0 = 同上加 &rev=0
#   B = only=main-07&mono=1(前車廂、車門、後車廂開著,胎壓低)  B0 = 同上加 &rev=0
import numpy as np, sys
from PIL import Image
T=sys.argv[1].rstrip('/')+'/'
def lum(n): a=np.asarray(Image.open(T+n+'.png').convert('RGB')).astype(float); return a@np.array([.299,.587,.114])
LOW={'前車廂的格位':(323.03,222.43),'車門的格位':(382.20,275.69),'後車廂的格位':(461.80,275.69),'胎壓的格位':(520.97,222.43)}
yy,xx=np.mgrid[:390,:844]; X=xx+.5; Y=yy+.5
def diff(a,b,c,th=40):
    m=(np.abs(lum(a)-lum(b))>th)&(np.hypot(X-c[0],Y-c[1])<17.5)
    if not m.any(): return '0 個'
    ys,xs=np.where(m); return f'{int(m.sum())} 個(範圍 {xs.max()-xs.min()+1} × {ys.max()-ys.min()+1})'
for tag,sfx in (('修訂前',  '0'),('現在',''),):
    print('==',tag)
    for nm in ('前車廂的格位','後車廂的格位'): print('  關著的前車廂 對 關著的後車廂(畫在同一個位置,'+nm+'):',diff('A'+sfx,'As'+sfx,LOW[nm]))
    for nm,what in (('前車廂的格位','前車廂'),('車門的格位','車門'),('後車廂的格位','後車廂'),('胎壓的格位','胎壓 低對正常')): print('  '+what+' 開著 對 關著:',diff('B'+sfx,'A'+sfx,LOW[nm]))
for th in (25,60):
    print(f'== 門檻換成 {th}(現在):前後車廂',diff('A','As',LOW['前車廂的格位'],th),'/',diff('A','As',LOW['後車廂的格位'],th),';車門開對關',diff('B','A',LOW['車門的格位'],th))
