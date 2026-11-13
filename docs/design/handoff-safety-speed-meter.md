# safety 交接：第二十四輪階段3短複驗前

Status: 2026-11-13 重寫。已完成的審查在20；**尚未審階段3修訂圖**。本次只寫本檔，沒有更新20或board。交接時頁面仍是 `150b3bff`、18仍報階段1完成；等visual修完及lead派工，再開始複驗。

## 1. 新session的入口與範圍

1. 先讀最新派工、`team-board.md` **2026-11-13 01:31 lead**那行，再讀18最上面新修訂與實際HTML／PNG。brief第二十四輪九條是基底，下面六條階段3裁定取代衝突部分。
2. 檔案均在 `docs/design/`。輸出沿用 `20-tesla-edition-safety.md`，按派工追加複驗、更新頂部結論，再留board一行；本次交接不先做它。
3. 共同規則照舊：自己做、不開subagent、不問、不上網、不進plan mode、不commit、不重新匯圖；只改當次准寫的檔。缺圖寫「沒量」。舊角色檔是第十六輪，不用其輸出名。
4. 現在的主線是 `main-*`（下弧＋建議版＋Hanken），`corner-*`、`safe-*`、SF等是未選參考。左右欄、圓／數字大小不在上次派工範圍。候選不是已採用主畫面。

## 2. 已記在20的內容：用索引，不重抄

以下全部指 `20-tesla-edition-safety.md`，後加段落優先：

| 要找的證據／判斷 | 段落 |
|---|---|
| 本輪獨立0–250全掃、全部尾數、最小案例、其他淨空、原生1倍202與素材根目錄 | 「第二十四輪」§1 |
| 正常／異常形狀差、車門差異弱、灰與熄檔對比、圓底裝飾與訊號的區別 | 同節§2 |
| 為何延續S23-03／P1、目前排序的辨識負擔、我對alt的判斷及其限制 | 同節§3；**alt建議已被後續lead裁定取代** |
| 下弧＋關閉形狀的未知覆蓋率算法、實量座標、我與visual分佈差異 | 同節§4 |
| 11張固定性、08亮檔／字重、09原因文字的合法例外 | 同節§5 |
| 結案範圍、唯一延續P1、沒做／沒量 | 同節§6 |
| 四角舊取樣漏掉尖角、撤回概括放行；上排49°那次到底量了什麼 | 「上排∓49°複驗」§1（實際標題有空格：`上排 ∓49° 複驗`） |
| 更早建議版與主畫面分開處置、10／11拆分的驗證 | 「階段3複驗」§2、§4（實際標題：`階段 3 複驗`） |

較早14／17是歷史，只有追溯舊尺寸豁免、互動／來源新鮮度問題才讀；不把舊未結案清單套到這次短複驗。

## 3. 20尚未收錄的轉述與裁定

來源是 `team-board.md`；以作者、日期、時間定位，不只看追加順序。

### ux轉述的更正與採納理由

- **01:26 → 01:27 → 01:30 ux**：最後一行取代前兩行三處。ux由「關閉前後廂不用修」改成「建議加記號」；紅／灰由「一樣亮」更正為「幾乎一樣亮」，色弱沒有模擬。紅色兩個廂都會變，不能拿來分前後；右欄之後要改，不能當必要辨識支柱。
- ux實際畫過五種候選狀態，認為alt沒有更好認、還把胎壓下移；我只做過靜態結構推論，**沒有做那五種候選的實驗比較**。這是證據範圍差，不再堅持我的排序建議。
- 車門：我上次判的是「已有可見非色彩差」，不是已驗證容易快讀。ux要求把那一小段加長，lead已採用；下一次直接驗修後，不為上次判過辯護。ux候選的像素數是參考，並非lead另訂了新的數量硬門檻。

### 2026-11-13 01:31 lead：第二十四輪階段3六條（最新）

| 條 | 需要執行／核對的裁定 |
|---|---|
| 1 | **關閉前廂填滿車頭一小段、關閉後廂填滿車尾一小段**，照ux `critique/d-04` 右上。只用在關閉；開啟蓋子方向照舊；未知虛線不加記號，因ux試過會讓空掉到1px。**順序不動**。 |
| 2 | **開門斜線加長**：裁圖座標端點(158,282)→(128,304)，不出圓底。lead接受與車主原圖不同，因車主已選開關要有形狀差；頁面相關「和你的圖一樣」句子要改。 |
| 3 | **狀態9原因文字上移到「—」下面12**，照ux `d-08` 中間。明確取代brief第二十四輪第4條「位置照舊」。 |
| 4 | **未知虛線實線段36→60，空不變**，照ux `d-09` 右邊；起點從15試，**四圖示原生1倍每段空仍≥2px**。起點15是起跑候選，不是保證會過。 |
| 5 | 頁首說明拆條列；摺疊每個小標帶「未選(保留參考)」；對照差異補車門／胎壓，以及這次記號與加長車門。短複驗若派工只看安全，不擴成整頁文案審查。 |
| 6 | 正常胎壓杯子形維持；順序維持；alt不放頁面、圖檔保留。visual修完後由safety短複驗。 |

**判斷的銜接**：lead採「正常記號幫助平常學部位＋開啟蓋子方向」這條路，並接受未知不帶記號。若修後1倍確實辨得出記號，可在這個靜態設計範圍評估S23-03結案；不再以「未知前後廂沒有各自記號」或「沒有改成alt」重開同一個P1。未知仍需辨得出車身輪廓、與正常實線不同，並守斷口底線；0.3秒命名與實車證明另記未做。

## 4. 工具與腳本的真實狀態

- 本session自寫Python都是 `functions.exec`→`exec_command` 的here-doc，**沒有另存獨立.py**。工具store曾用 `s24base`、`s23last`、`s23rbase` 等key；這不是磁碟路徑，新session不能依賴它們。下節把必要邏輯留成可執行的唯讀碼。
- 可用：`python3`＋Pillow＋NumPy；當時沒有SciPy、fontTools。看圖用 `tools.view_image` 原尺寸。我的全掃是自己算距離，原圖仍是visual交付，不寫成「自己截圖」。
- 上次DevTools連9222是ECONNREFUSED；沒有成功自截。更舊CUA對本機file URL曾被policy拒絕，交接不解除拒絕，別換介面繞過。這次規則已禁止重匯，不需要恢復瀏覽器。
- visual的 `frames/atelier-tesla-edition/tools/`：`dashgap.py`、`fixed.py`、`consist.py` 可作第二套交叉檢查，**先讀當版程式**。`sweep24.py`會寫 `sweep24.json`，這次自己做唯讀運算；`sweep24.sh`／`shot.sh`是匯圖程式，本輪不跑。舊 `sweep.py`／`clr.py` 還綁四角／舊路徑，不用來量下弧。
- 原始素材的完整路徑與指紋已列20「第二十四輪」§1。那批是**150b3bff基準**；下節預設指到它，`SAFETY_RAW`可改成visual新交付的分層目錄。新狀態9文字層尤其不能誤拿舊的 `unit-09.png`。
- 之前的 `/private/tmp/s19-*`、`s22-*` 只適合歷史追溯；新session不必先找它們。暫存若消失，不恢復截圖流程，按缺的證據記沒量。

## 5. 自寫量法的唯讀重跑入口

**用途／限制**：以下是本session邏輯整理成的可重跑版本；方法定義、門檻、已得數值看20「第二十四輪」§1、§2、§4、§5。預設RAW是舊基準，跑通不代表新修訂已驗。先核版本／來源；新修訂若圓底和數字都沒變，不用為改圖示再全掃251個速度。

從repo根目錄執行，下列命令只讀本檔的Python區塊並執行，不另外建.py：
```bash
SAFETY_CHECK=sweep python3 - <<'PY'
import re
from pathlib import Path
s = Path("docs/design/handoff-safety-speed-meter.md").read_text()
exec("\n".join(re.findall(r"```python\n(.*?)\n```", s, re.S)))
PY
```

`SAFETY_CHECK`可選 `sweep`（0–250）、`clear`（各分層到圓底）、`dash`（當前main-10/11）、`fixed`（當前十一張）、`contrast`。不設時只顯示用法。可用 `SAFETY_PNG` 指向指定PNG資料夾，`SAFETY_RAW` 指向同版分層根目錄。`dash/fixed`可在RAW不見時用本輪固定格位幾何；若格位也改，必須重設。

```python
from pathlib import Path
from PIL import Image
import numpy as np, os

MODE = os.environ.get("SAFETY_CHECK", "help")
P = Path(os.environ.get("SAFETY_PNG", "docs/design/frames/atelier-tesla-edition"))
Q = Path(os.environ.get("SAFETY_RAW", "/private/tmp/claude-501/-Users-huangchihan-develop-tsla-speed-meter/bd9a88cf-bc98-4f11-b39d-0385f98a92b8/scratchpad/r24"))
def rgb(p): return np.asarray(Image.open(p).convert("RGB"), float)
def mask(p, t=60): return np.asarray(Image.open(p).convert("L")) > t
def edge(m):
    z = np.zeros_like(m)
    z[1:-1,1:-1] = (m[1:-1,1:-1] & m[:-2,1:-1] & m[2:,1:-1]
                    & m[1:-1,:-2] & m[1:-1,2:])
    return m & ~z
def points(m, scale=2):
    y,x = np.where(m)
    return np.c_[(x+.5)/scale, (y+.5)/scale]
def distance(a,b,scale=2):
    assert a.shape == b.shape and a.any() and b.any()
    if (a & b).any(): return 0.
    A,B = points(edge(a),scale), points(edge(b),scale)
    best = float("inf")
    for k in range(0,len(A),128):
        best = min(best, ((A[k:k+128,None]-B[None])**2).sum(2).min())
    return float(np.sqrt(best))
def discs():
    m = mask(Q/"ink/disc-main.png")
    assert m.shape == (780,1688)
    y,x = np.indices(m.shape)
    cuts = [0,720,844,968,1688]
    return [m & (x>=cuts[i]) & (x<cuts[i+1]) for i in range(4)]
angles = np.radians([-117,-159,159,117])
C = np.c_[422+111.072*np.sin(angles), 172-111.072*np.cos(angles)]
if (Q/"ink/disc-main.png").exists():
    C = np.array([points(d).mean(0) for d in discs()])

if MODE == "sweep":
    D = discs()
    yy,xx = np.mgrid[240:406,660:1030]
    A = np.c_[(xx.ravel()+.5)/2,(yy.ravel()+.5)/2]
    maps = []
    for d in D:
        B = points(edge(d)); out = []
        for k in range(0,len(A),512):
            out.extend(np.sqrt(((A[k:k+512,None]-B[None])**2).sum(2).min(1)))
        maps.append(np.asarray(out).reshape(166,370))
    rows = []
    for v in range(251):
        n = mask(Q/f"sweep/main-{v}.png")
        r = n[240:406,660:1030]
        assert r.any() and r.sum() == n.sum(), ("ROI",v)
        ds = [0. if (n & d).any() else float(z[r].min()) for d,z in zip(D,maps)]
        rows.append((v,ds))
    for i in range(4):
        lo = min(ds[i] for v,ds in rows)
        print(i,"min",lo,"speeds",[v for v,ds in rows if abs(ds[i]-lo)<1e-7],
              "below9",[v for v,ds in rows if ds[i]<9])
    for k in range(10):
        print("ones",k,[min(ds[3] for v,ds in rows if v//100==h and v%10==k)
                         for h in (1,2)])

elif MODE == "clear":
    D = discs()
    layers = [("km/h","unit",60),("reason","unit-09",60),
              ("dash","num-09",60),("tick","tick",40),("gear","gear",60)]
    for i,d in enumerate(D):
        print(i,{name:distance(d,mask(Q/f"ink/{f}.png",t)) for name,f,t in layers},
              "nearest disc",min(distance(d,e) for j,e in enumerate(D) if i!=j))

elif MODE == "dash":
    fg = np.array([166,172,181.])
    for n,indices in [("main-10",(0,1,2)),("main-11",(3,))]:
        a = rgb(P/f"{n}.png")
        assert a.shape[:2] == (390,844), "需要原生1倍"
        for i in indices:
            c = C[i]; x0,y0 = int(c[0])-17,int(c[1])-17
            w = a[y0:y0+35,x0:x0+35]
            y,x = np.mgrid[:35,:35]
            inside = np.hypot(x+x0+.5-c[0],y+y0+.5-c[1]) < 16.5
            cov = np.zeros((35,35))
            for j in range(35):
                sel = inside[j]
                if sel.sum()<3: continue
                bg = w[j,sel].min(0)
                d = fg-bg
                cov[j] = ((w[j]-bg)*d).sum(1)/(d*d).sum()
            cov[~inside] = 0
            found,qualified = [],[]
            for axis in (0,1):
                for j in range(35):
                    v = cov[j] if axis==0 else cov[:,j]
                    cuts = np.r_[0,np.where(np.diff((v>=.25).astype(int)))[0]+1,35]
                    runs = [(v[l]>=.25,l,r) for l,r in zip(cuts[:-1],cuts[1:])]
                    for k,(on,l,r) in enumerate(runs):
                        if on or not 0<k<len(runs)-1 or r-l>4: continue
                        L,R = runs[k-1],runs[k+1]
                        if v[L[1]:L[2]].max()<.5 or v[R[1]:R[2]].max()<.5: continue
                        item = ("row" if axis==0 else "col",
                                j+(y0 if axis==0 else x0),
                                l+(x0 if axis==0 else y0),r-l)
                        found.append(item)
                        if (v>=.5).sum()>=5: qualified.append(item)
            print(n,i,"all min",min([z[-1] for z in found],default=None),
                  "short lines included",found,
                  "qualified distribution",{k:sum(z[-1]==k for z in qualified) for k in range(1,5)})

elif MODE == "fixed":
    ref = rgb(P/"main-01.png")
    y,x = np.mgrid[:390,:844]
    r = np.hypot(x+.5-422,y+.5-172)
    rois = {"ring+tick":(r>=135)&(r<=163),
            "gear":(x>=383)&(x<462)&(y>=56)&(y<72),
            "unit":(x>=400)&(x<443)&(y>=208)&(y<227)}
    for j,c in enumerate(C):
        rr = np.hypot(x+.5-c[0],y+.5-c[1])
        rois[f"rim{j}"] = (rr>=16)&(rr<=19.5)
    for v in range(1,12):
        a = rgb(P/f"main-{v:02d}.png")
        d = np.any(a!=ref,2)
        print(v,{k:int((d&m).sum()) for k,m in rois.items()})

elif MODE == "contrast":
    def lum(c):
        c = np.asarray(c)/255
        c = np.where(c<=.04045,c/12.92,((c+.055)/1.055)**2.4)
        return float(c @ [.2126,.7152,.0722])
    def cr(a,b):
        lo,hi = sorted([lum(a),lum(b)])
        return (hi+.05)/(lo+.05)
    a = rgb(P/"main-01.png")
    for fg in ([127,135,144],[124,130,138]):
        print("foreground",fg,"exact pixels",int(np.all(a==fg,2).sum()))
    print("normal/disc",[cr([127,135,144],bg) for bg in ([25,32,39],[19,25,31],[13,18,24])])
    print("gear off/ground",cr([124,130,138],[10,15,21]))
    print("gear on/off",cr([255,255,255],[124,130,138]))
else:
    print("SAFETY_CHECK=sweep|clear|dash|fixed|contrast")
```

**使用判讀**：

- `sweep/clear`要同版分層。上移後的原因文字如果沒有新層，可從新main-09的純背景ROI分離文字，沿用圓底幾何量；明列是整張圖取墨的估值。沒有證據就沒量，不跑匯圖。
- `dash`輸出的列／欄短縫是取樣，不是「獨立dash個數」。新記號若誤畫到未知，會破壞單色alpha模型／讀形，先目視及核SVG。細輪廓交點、邊角、圖形本來的空，要對原1倍確認；2倍÷2不能替代它。
- `fixed`會列08／09預期差異。**新狀態9文字上移後，原unit ROI可能幾乎空白**：不要因此說文字位置相同；另外以新文字的實際bbox與指定「—下面12」核對。顏色／字重改變需還原墨遮罩或讀固定錨點，別把全屏差分當位移。
- `contrast`色碼是150b3bff預期值，先確認完整前景像素確實存在；數值定義與背景選法看20。RGB算術平均只用來分墨，不能拿來當sRGB相對亮度；「兩色幾乎同亮」也不等於已做色弱模擬。

## 6. 接手後的複驗順序與完成界線

1. **等修完、核版本**：讀18新修訂、board交付與新頁／PNG指紋；150b3bff僅是前一版。核對現在仍是main、原順序／格位；確認沒有把alt當主畫面。本次交接沒有替未交付圖先判過。
2. **關閉前／後廂記號**：看main-01及相關狀態原生1倍，能否看出填在車頭／車尾不同側；分離顏色後比較，而非只數新增墨像素。開啟形狀照舊、未知不帶填塊。若修法達到lead採用的辨識方式，評估S23-03剩餘P1可否在靜態範圍結案；0.3秒／上車照記沒做。
3. **加長的開門形狀**：main-01對02／07，1倍能否看出往外的那一段，是否仍在圓底內；核SVG端點及非色彩遮罩。不要僅因程式端點改了就判可讀。
4. **新虛線**：main-10／11，關閉形狀、不加填塊、線段加長且空不變；四圖示全部逐列／欄≥25%算墨，附真斷口座標。新dash起點不能繼承舊版的通過；需要時2倍只作輪廓輔助。
5. **狀態9**：新原因文字頂部到「—」底的空是否依裁定12；新文字墨到四個圓底皆≥8；不把舊unit-09分層、舊y209附近ROI當成新證據。核原因文字可讀對比，不動數字／圓。
6. **固定性與範圍**：逐張核環／刻度／PRND／km/h／四圓底，區分08選檔與09刻意文字變更；與修前相比只允許裁定的圖示／文字差。若圓底與數字不變，既有全掃證據保留，不為短複驗再掃一次；若意外動了，先記偏差再重算相關影響。
7. **交付**：只在新的派工允許時更新20頂部與檔尾複驗、board一行。舊數值／裁定與新版本分清；已結項目不因別處缺實機測試重開。這次交接到此停下。
