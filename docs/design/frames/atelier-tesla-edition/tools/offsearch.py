# usage: python3 offsearch.py   每 3 單位試一個虛線起點(&toff=,強制所有封閉輪廓;0–96,主畫面的週期 = 實線段 60 + 空 35 上下),
# 第二十八輪:主畫面的格位換了(照車主的圖的排法),這裡量的是新的 main-10,圓底中心用 dashgap.py 的 PIC(slots28.json);要量上一版(下弧)就把 only=main-10 換成 row-10、PIC 換成 LOW。
# 第二十九輪:main-10 還是畫三個虛線(和 alw-10 一樣),這一支不用改;胎壓的虛線主畫面不畫了。
# 在 1 倍的 main-10(關著的形狀)上量,列出每個圖示「沒有 < 2 px 小縫」的起點。要同一個資料夾的 shot.sh、dashgap.py;截圖放在同一個資料夾的 t/
import subprocess, os, sys
sys.argv=[sys.argv[0]]
H=os.path.dirname(os.path.abspath(__file__)); dg={'__file__':os.path.join(H,'dashgap.py')}
exec(open(os.path.join(H,'dashgap.py'),encoding='utf-8').read().split("if __name__=='__main__':")[0],dg)
dg['SLOTS'].clear(); dg['SLOTS'].update(dg['PIC'])
os.makedirs(os.path.join(H,'t'),exist_ok=True); res={}; R=range(0,99,3)
for off in R:
    f=os.path.join(H,'t',f'os-main-{off}.png')
    subprocess.run([os.path.join(H,'shot.sh'),f'only=main-10&toff={off}',f,'844,390','1','8'],capture_output=True)
    for s in ('frunk','door','trunk'):
        r,_,_,_=dg['measure'](f,s); g=[x[2] for x in r]; res[(s,off)]=(sum(1 for x in g if x<2),len(g),min(g) if g else 9)
for s in ('frunk','door','trunk'):
    print('main',s,'過的起點:',[off for off in R if res[(s,off)][0]==0],'| 不過的(起點, (小於 2 的段數, 總段數, 最小))',[(off,res[(s,off)]) for off in R if res[(s,off)][0]>0])
