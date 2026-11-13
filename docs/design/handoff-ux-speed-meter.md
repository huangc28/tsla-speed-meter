# handoff:ux,速度表設計團隊(寫於 2026-11-12,給下一個 ux session)

Status: 第二十二輪做完了,第二十三輪還沒輪到 ux(階段 2 才出動)。這份只寫我的檔裡沒寫的東西:**量圖和批評的方法、腳本、改掉的建議、裁定和 board 的索引、還開著的事**。舊設計(辛 / 子 / 第二十二輪圖示頁)車主 2026-11-12 說先放掉,所以舊設計的細節只列位置。

## 先看哪裡(照順序)

Status: 完成

1. `00-brief-tesla-edition.md`:第二十三輪的全部要求。ux 寫 `19-tesla-edition-critique.md`,裁圖放 `frames/atelier-tesla-edition/critique/`。要審的是:像不像車主的圖、四個圖示分佈平不平均好不好看、主方案「四角」和備案「下弧」哪個好。
2. 共同規則在 `00-brief-speed-meter.md`「共同規則」;tesla brief 第一行又加了:**不上網查**;刪檔用寫死的路徑(`rm -f "$f"` 會被安全提示擋住)。
3. `handoff-visual-speed-meter.md` §4:visual 怎麼量圖示、怎麼畫、怎麼做疊圖(tesla brief 裁定 11 叫 visual 照這個做)。我的檢查要**自己重畫一次**,不要只看 visual 的 `overlay-*.png`。
4. `DESIGN-atelier-tesla-edition.md`:lead 寫的種子規範,畫完會補數字。
5. 這份的「二、批評的流程」和「三、工具箱」。

## 一、還開著的事(照順序)

Status: 完成

1. **第二十三輪階段 2**:等 board 上 lead 叫 ux,而且 visual 交了 `18-tesla-edition-visual.md`、`frames/atelier-tesla-edition.html` 和 `frames/atelier-tesla-edition/` 的 PNG,才開始寫 19。開始時先做快照(見二-1)。
   - 我預計會看的(推論,還沒做):圓在所有狀態是不是真的同一個位置、同一個大小(拿 1 倍 PNG 量圓環半徑剖面,見三-6);四個圓底的角度和距離左右對不對稱、上下兩排對數字中線對不對稱;圖示和 `crop-*@6x.png` 疊圖(自己重畫);顏色是不是照「線條像素的中位數」;188 / 200 / 248 的淨空(見三-5);1 倍實際大小認不認得出;備案下弧三張和主方案同狀態並排比。
2. **第二十二輪留給車主的 5 個問題**(`16` 最上面「待確認」):新 brief 都取代了,不用再問:
   - 擺法(環位 / 一排)→ 改成「四角」/「下弧」;
   - 圖示大小 → 照車主的圖;
   - 胎壓低紅或琥珀 → 車主的圖是琥珀;
   - 右欄小圖示換不換 → 右欄這輪原樣複製,不管;
   - 胎壓未知的「!」→ L100 已經是「胎壓沒讀值不畫圖示」。但新 brief 說四個格位永遠畫(裁定 6),裁定 13 只講車門狀態不明,**胎壓沒讀值時那一格畫什麼沒寫**。19 可能要提出來(推論)。
3. **還開著、但掛在舊設計上的**:0.3 秒瞄一眼實測、S17-02、上車驗證(L86 的 AT01–AT14,在 GitHub #73)。這些不是 ux 現在能做的,新設計定了以後再接。

## 二、批評的流程(我每輪都這樣做)

Status: 完成

1. **快照**:一開始就把要審的頁面和 PNG 資料夾複製到自己的 scratchpad,記 `shasum <頁> | cut -c1-8` 和 `date`,寫進報告第一個 Status 行。之後都審快照。理由:審到一半 visual 可能還在改。
2. **先定對應公式**:參考圖的座標怎麼換成我們 844 × 390 的頁面座標,寫進「怎麼看、怎麼量」第一條。之後所有數字都用頁面座標(1 倍 px);我們的 2 倍圖除以 2。
3. **自己重畫我們的圖**:把頁面裡畫圖示的 SVG 原封不動抄出來,用 headless Chrome 畫成和參考裁圖**同一個倍率**的 PNG,逐像素比(三-2)。
4. **量**:外框、墨跡面積比、筆畫粗細(10 / 50 / 90 百分位)、外緣剖面(轉角、弧度)、半徑剖面(圓環)、亮度、對比。每個數字標**事實**(量的)/**估計**(換算或模型算的、我給的修改路徑)/**推論**(判斷)。
5. **裁圖**:同一個倍率並排,每格上面一條標籤(英文,見三-1 字型的問題)。比較用 LANCZOS 縮放;看 1 倍像素用 NEAREST 放大 3 倍。需要時加輔助線(例如數字中心 x 422 的藍線)。
6. **寫報告**:重點結論 ≤ 5 條 → 怎麼看、怎麼量(含裁圖表)→ 差異分「大 / 中 / 小」,每條寫「差什麼、量到多少、怎麼改(起點值)、改完量什麼算對」→「有差異但照規則不改」→「符合的」→ 假設 → 待確認(≤ 5 條、白話、給車主)。每個標題下一行 `Status:`。新的一輪加在檔案**最上面**,舊的不動。
7. **和 brief 不同的建議**單獨一段,寫「要 lead 同意」,不要混在差異表裡。
8. **board**:寫之前跑 `date`,格式 `- [YYYY-MM-DD HH:MM] ux → <對象>: <摘要>`;摘要寫大 / 中的數字和「只改了哪些檔」。
9. **交之前**:`grep -nE '^#|^Status:'` 確認每個標題都有 Status;回覆最後一行照任務寫的 DONE 行。

### 我學到的(下次照做)

Status: 完成

- **建議一個畫法之前,先把它畫出來,每個受影響的圖示都在 1 倍看一次。** 第二十二輪我只算了車門的縫就建議圓點,結果前 / 後車廂在 1 倍變成一團點,lead 在 3b 改回平頭短線段。
- **圓頭線的虛線**:看得到的空 = dasharray 的空 − 線寬,看得到的線段 = 線段 + 線寬(兩端各多半個線寬)。平頭(butt)才是照寫的值。量的時候沿直線段讀亮度,不要看彎的地方(彎的地方外側本來就會分開)。
- **參考截圖可能是夜間調暗的**(Dashla 那張就是),拿它的顏色比亮度不公平,要寫出來。
- **比例和絕對大小會互相打架**:我用「圖示高 ÷ 數字高」說我們的圖示太大,lead 選了「照參考圖彼此的比例」。這輪車主的圖說了算,所以絕對大小以車主的圖為準,比例只當參考資訊。
- **brief 裡 lead 的粗量只是起點**,自己再量一次;量法不同時兩個都寫。

## 三、工具箱(腳本和環境)

Status: 完成

舊 scratchpad 還可能在(重開機或清 /tmp 就沒了):`/private/tmp/claude-501/-Users-huangchihan-develop-tsla-speed-meter/858ea7ca-7cbe-4db4-98e7-fd5f8872caa0/scratchpad/`(`num.py`、`arc.py`、`mock.py`、`cr.py`、`r19/`、`r19v/`、`r22/`)。新 session 的 scratchpad 是另一個資料夾,所以重要的腳本都抄在下面。

### 三-1 環境

Status: 完成

- `python3` 有 PIL、numpy、cv2 4.13;**沒有** scipy、skimage(細線化要自己寫或用 cv2)。
- Chrome:`/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`,用 `--headless=new`。**視窗最窄 500**,`--window-size=390,…` 其實是 500 寬,所以 390 寬會不會左右滑我一直沒驗到(可以試 chrome-devtools MCP 的 `emulate` / `resize_page`,或在外層頁放一個 390 寬的 iframe;都**未試**)。
- 亮度 = RGB 平均,用 PIL 讀,沒做色彩管理。Chrome 截的 PNG 當 sRGB。
- 裁圖標籤用 `/System/Library/Fonts/SFNS.ttf`(可變字型,軸:Width 30–150、Optical Size 17–96、GRAD 400–1000、Weight 1–1000),寫英文。中文字型在 PIL 有時開不了,見 `handoff-visual-speed-meter.md` §3 的 PingFang 路徑。
- 同一張圖重截兩次會有雜訊(頁尾總里程的字最多差 62 / 255),見 `handoff-visual-speed-meter.md` §3;比「有沒有改到」要看差在哪裡。
- 對比用 WCAG 公式:`rl(c) = c/12.92 if c ≤ 0.03928 else ((c+0.055)/1.055)^2.4`,`L = .2126R + .7152G + .0722B`,對比 `(L1+.05)/(L2+.05)`。背景取圖示中心 26 × 32 的平均。

### 三-2 把我們的 SVG 畫成和裁圖同倍率

Status: 完成

第二十二輪的做法(頁面上 `ICONS` 用裁圖像素當座標,所以畫出來直接等於 6 倍裁圖)。新頁的結構可能不同:原則是**把畫圖示的那段程式原封不動抄出來,讓 SVG 的 viewBox = 裁圖大小、視窗 = 裁圖大小、縮放 1**。

```sh
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
{ echo '<!doctype html><html><body style="margin:0;background:#000"><div id=o></div><script>const f2=(v)=>Math.round(v*100)/100;'
  sed -n <ICONS 起訖行>p <visual 的頁>          # 原封不動抄,不要改
  cat <<'EOF'
const q=new URLSearchParams(location.search); const n=q.get('n'), mode=q.get('m')||'on';
const I=ICONS[n], [W,H]=I.vb, dash=mode==='unk'&&I.sw?DASH(I.sw):'';
document.getElementById('o').innerHTML=`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" style="display:block;background:#000">${I.draw(mode==='unk'?'#a6acb5':'#ff5a5f',dash,mode)}</svg>`;
</script></body></html>
EOF
} > r.html
"$CH" --headless=new --disable-gpu --hide-scrollbars --window-size=$W,$H --force-device-scale-factor=1 \
  --virtual-time-budget=3000 --screenshot="$PWD/our-$n.png" "file://$PWD/r.html?n=$n" >/dev/null 2>&1
```

- 這輪的圖示有深色圓底:比形狀時背景用純黑、只畫線;比整體時再加圓底。
- 整頁截圖:`--window-size=1280,9000 --virtual-time-budget=15000`(頁面用 JS 畫,時間要給夠)。

### 三-3 顏色遮罩和筆畫粗細

Status: 完成

```python
import cv2, numpy as np
def mask_ref(path, kind):                      # 參考裁圖
    a=cv2.imread(path).astype(int); b,g,r=a[...,0],a[...,1],a[...,2]
    if kind=='amber': m=(r>70)&(r-b>35)&(g>45)
    elif kind=='grey': m=(abs(r-g)<18)&(abs(r-b)<18)&(r>60)
    else: m=(r>70)&(r-g>35)&(r-b>35)          # red
    return m.astype(np.uint8)
def mask_our(path): return (cv2.imread(path).astype(int).mean(2)>60).astype(np.uint8)   # 黑底
def stroke(m):                                 # 線寬 = 中脊上的距離 × 2
    dt=cv2.distanceTransform(m,cv2.DIST_L2,5)
    ridge=(dt>=cv2.dilate(dt,np.ones((3,3),np.uint8))-1e-6)&(dt>3)
    return np.percentile(2*dt[ridge],[10,50,90]), int(m.sum())
```

- 看 p50;交叉點會讓 p90 偏大。兩邊都報外框(墨跡 bbox)、墨跡面積和比值。
- **這輪要注意(推論)**:關著的圖示是灰的,灰色遮罩也會抓到圓底的細邊。用離圓底中心的距離把圓底邊去掉(圓底邊是一圈,半徑固定),或先量圓底再減掉。
- **顏色**:我以前取「最亮 10% 的平均」;tesla brief 裁定 11 改成**線條像素的中位數**。這輪照中位數,要的話另外附最亮 10%,標清楚是哪一種。

### 三-4 轉角、弧度、虛線

Status: 完成

- **外緣剖面**:同一欄找第一個墨跡像素 `np.argmax(m[:,x])`(上緣),同一列找第一個 / 最後一個(左 / 右緣),每 12–20 px 取一次,兩邊並排印出來比。看得出弧有沒有拱、S 形有沒有內縮。
- **圓角半徑**:外緣上取三點擬合一個圓。外緣半徑 − 半個線寬 = SVG 路徑(中線)該用的半徑。
- **虛線有沒有真的空**:在 1 倍、2 倍匯出圖上,沿一段**直的**線,跨線方向取 3 列的最大值,亮度 < 50 印 `_`、其他印 `#`。要看到 `_`(3b 的要求是 1 倍實際空 ≥ 2 px)。

### 三-5 數字墨跡和淨空(第十七輪的 `num.py` + `arc.py`)

Status: 完成

用系統字照頁面的置中方式重畫數字,拿來算「最壞的數字」到圓環 / 圖示的距離。第十七輪和頁面截圖比過:墨跡重疊 0.96、外框差 ≤ 0.5。

```python
from PIL import Image, ImageDraw, ImageFont
import numpy as np
def font(w, px, opsz):                         # w = 字重
    f=ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', round(px))
    f.set_variation_by_axes([100, min(96, opsz), 400, w])   # Width, Optical Size, GRAD, Weight
    return f
def ink(s, w, fs, cx, cy, W=844, H=390, sc=4):  # 數字 s,字級 fs,'0' 的墨跡中心在 (cx, cy)
    f=font(w,fs*sc,fs)
    im=Image.new('L',(W*sc,H*sc),0); d=ImageDraw.Draw(im)
    b0=f.getbbox('0',anchor='ls',features=['tnum'])
    base=cy*sc + (-b0[1]-b0[3])/2
    d.text((cx*sc, base), s, font=f, fill=255, anchor='ms', features=['tnum'])
    return np.asarray(im)>=128
def boundary(m,sc=4):                          # 墨跡邊緣點(頁面座標)
    e=m & ~(np.roll(m,1,0)&np.roll(m,-1,0)&np.roll(m,1,1)&np.roll(m,-1,1))
    ys,xs=np.where(e); return np.stack([(xs+.5)/sc,(ys+.5)/sc],1)
def clear(P,A,sw=3):                           # 墨跡邊緣到線中線的最短距離 − 半個線寬
    return np.sqrt(((P[:,None,:]-A[None,:,:])**2).sum(2)).min()-sw/2
```

- 三位數取「該位數所有數字墨跡的聯集」(第十七輪:100–199、200–299 的聯集);這輪 brief 指定 188 / 200 / 248,另外再跑一次聯集,看有沒有比這三個更壞的。
- 圓底的淨空:圓底是圓,用「圓心到墨跡邊緣點的最短距離 − 圓底半徑」。
- 字型如果不是 SF Pro(visual 可能選 Google Fonts 的字),先用頁面截圖量墨跡,不要用這個模型。

### 三-6 圓環 / 弧的半徑剖面(第十九輪的 `varc.py`)

Status: 完成

沿半徑方向每 0.25 px 取樣,找亮度峰值、峰值偏離設定半徑多少(dr)、半高寬(粗細)、背景。可以直接拿來量這輪的圓:每 10° 一次,左右兩邊各量,看圓心和半徑對不對、各狀態一不一樣。

```python
from PIL import Image; import numpy as np, math
def prof(path,cx,cy,r,angs,span=10,scale=2):  # (cx, cy, r) 頁面座標;scale = 圖的倍率
    A=np.asarray(Image.open(path).convert('RGB')).astype(float); L=A.mean(2); out={}
    for ang in angs:                           # 從 12 點鐘順時針
        res=[]
        for side in (-1,1):
            a=math.radians(side*ang); best=(-1,0,None); vals=[]
            for k in range(-int(span*4),int(span*4)+1):
                dr=k*.25; x=cx+(r+dr)*math.sin(a); y=cy-(r+dr)*math.cos(a)
                X,Y=int(round(scale*x)),int(round(scale*y))
                if 0<=X<L.shape[1] and 0<=Y<L.shape[0]:
                    v=L[Y,X]; vals.append(v)
                    if v>best[0]: best=(v,dr,(X,Y))
                else: vals.append(np.nan)
            vals=np.array(vals); bg=np.nanmedian(np.concatenate([vals[:12],vals[-12:]]))
            fw=(vals>(best[0]+bg)/2).sum()*.25
            res.append((best[0],best[1],A[best[2][1],best[2][0]],bg,fw))   # 峰值、dr、峰值 RGB、背景、半高寬
        out[ang]=res
    return out
```

參考圖用它自己的倍率(`scale` = 參考圖 px ÷ 頁面 px),兩邊同一組角度並排印。

### 三-7 裁圖拼版(第十九輪的 `crop.py`)

Status: 完成

```python
import sys
from PIL import Image, ImageDraw, ImageFont
# 用法:crop.py out x0 y0 x1 y1(1 倍頁面座標)zoom 2倍圖...
out=sys.argv[1]; x0,y0,x1,y1=map(float,sys.argv[2:6]); z=float(sys.argv[6]); files=sys.argv[7:]
F=ImageFont.truetype('/System/Library/Fonts/SFNS.ttf',22); tiles=[]
for f in files:
    c=Image.open(f).convert('RGB').crop((round(x0*2),round(y0*2),round(x1*2),round(y1*2)))
    c=c.resize((round(c.width*z/2),round(c.height*z/2)),Image.LANCZOS)
    t=Image.new('RGB',(c.width,c.height+30),(40,40,40)); t.paste(c,(0,30))
    ImageDraw.Draw(t).text((6,2),f.split('/')[-1].replace('.png',''),fill=(255,220,120),font=F); tiles.append(t)
vert=tiles[0].width>tiles[0].height*1.3       # 扁的上下疊,窄的左右排
W=max(t.width for t in tiles) if vert else sum(t.width+6 for t in tiles)
H=sum(t.height+6 for t in tiles) if vert else max(t.height for t in tiles)
o=Image.new('RGB',(W,H),(80,80,80)); p=0
for t in tiles:
    o.paste(t,(0,p) if vert else (p,0)); p+=(t.height if vert else t.width)+6
o.save(out)
```

參考圖要先換算到同一個頁面倍率再放進來(先另存一張「參考圖照頁面座標」的 2 倍圖)。亮度拉伸(例如 0–44 拉到 0–255)只用來**看**光在哪裡,不拿來量。

### 三-8 頁面會不會左右滑

Status: 完成

把下面這段插到頁面 `</body>` 前另存一份(用 python 的字串取代,我用 sed 第一次沒成功),`--dump-dom` 後抓 `<title>`:

```html
<script>setTimeout(()=>{const d=document.documentElement;document.title="SW="+d.scrollWidth+" CW="+d.clientWidth;},3000)</script>
```

`SW > CW` 就是會左右滑。要查哪一塊太寬,再加那一塊的 `scrollWidth` / `clientWidth`。視窗最窄 500 的問題見三-1。

## 四、第二十三輪可以先算好的(都是**估計**,動手時再驗)

Status: 完成

- **儀表圖 → 頁面**:`dashboard-2026-11-12.png` 1774 × 887,× 0.4758 到 844 寬,**高是 422,比我們的 390 高 32**。所以垂直位置不能 1 : 1 照抄,只能比相對關係(第十七輪的參考圖也有同樣問題,矮 13)。lead 的目標圓 (422, 172) r 156 和車主圖的 (421.6, 193.7) r 144 本來就不一樣,批評時要分清楚「照圖」和「照裁定」。
- **圖示裁圖**:`crop-<frunk|trunk|door|tire>@6x.png` 都是 576 × 576 = 原圖 96 px = 頁面 45.7 px 見方;**1 裁圖 px ≈ 頁面 0.0793 px**(假設是從 1774 寬的原圖裁的,要用 `crop-gauge.png` 上同一個圖示的位置驗一次)。第二十二輪 Dashla 的是 0.0703,不要沿用。
- **`crop-gauge.png`** 640 × 634(brief 說是原尺寸)→ 頁面 304.5 × 301.6。
- **規範表裁圖** `crop-sheet-*@6x.png` 624 × 624,來自 1536 寬的另一張圖,倍率和儀表圖不同;brief 說只當輔助,只比形狀,不比大小和顏色(它印的色碼不一定對)。
- 胎壓這輪叫 `tire`(第二十二輪叫 `tpms`)。

## 五、我做過的判斷和理由、改掉 / 被否決的建議

Status: 完成

下一個 session 不要再提已經被否決的。

| 輪 | 我的建議 | 理由(當時) | 結果 |
|---|---|---|---|
| 16 | 乙「橫尺」、丙「直軌」、丁「大字」、戊「刻度扇」四個方向(`10` §4) | A 太像 Dashla,要結構不同、至少兩個不用圓環 | 車主後來選庚的風格、辛的排法,現在又換新圖;四個都**未選(保留參考)** |
| 17 | 弧 r 162 → 170、速度表 cx 223 → 230.5、車 cx 472 → 500 | 參考圖比例要 r ≈ 211 放不下;r 170 時三位數離弧 27.6(≥ 9) | 採用(board 11-08 03:17) |
| 17 | 弧心往下移(A 下 40 / C 下 62) | 想讓弧更包住數字 | 會縮短弧,**未選**(13 §兩個判斷 ①,裁圖 08、09) |
| 17 | 最大差距是車的光影,不是外形 | 外形逐段寬度只差 ≤ 2 px | 採用 |
| 19 橫 | 地平線在車旁淡出、背景的光(遠暗、車旁光暈、光帶、車尾暗) | 參考圖量到 | 採用 |
| 19 橫 | 車照高縮後橫向 × 1.084 | 車窄 5 px | **否決**:不做非等比縮放,5 px 接受 |
| 19 橫 | 車的光影做辛專用 | 參考圖的引擎蓋、接縫、車尾光影不同,改共用的車又會動到己 / 庚 | **否決**:同一台車 |
| 19 直 | 高度預算 28 / 148 / 415 / 104、車回 190 | 核心比參考圖少 41 | 採用 |
| 19 直 | `‹ ›` 只在 P 檔畫 | 行駛中不翻頁 | lead 再加嚴:`‹ ›`、頁碼、圓點三樣都只在停車畫 |
| 22 | 未知改圓點(dasharray 0.01 / 2.1 倍線寬) | 圓頭把縫吃掉,直線段量不到空 | 先採用,3b **改回**平頭短線段(約 1.8 / 0.95 倍線寬):圓點讓前 / 後車廂在 1 倍認不出形狀。「縫被吃掉」的診斷是對的,圓點是錯的修法 |
| 22 | 圖示整組縮 × 0.88 | 對我們的數字,比例是 Dashla 的 1.6 倍 | **否決**(S22-03):照 Dashla 彼此的比例,不縮不放 |
| 22 | 一排改成 382 / 422 / 462 / 502,車門在數字正下方 | 原本車門偏左 20,停車 `0` 下最明顯 | 採用(兩種擺法都留給車主) |
| 22 | 車門擋風玻璃加弧、轉角 R 50 → 70、車鼻 / 車尾圓角、後車廂 S 形、右欄換新圖示 | Dashla 裁圖量到 | 採用;我給的路徑是估計,visual 用疊圖對準 |
| 22 | 頁面:對照表不左右滑、兩種擺法每狀態並排 | 1280 寬看不到右邊三個;相隔 11 張不好對 | 採用 |
| 22 | 胎壓低改琥珀(Dashla 的顏色) | 待車主決定 | 當時不做;**這輪車主的圖就是琥珀** |
| 22 | 不建議「只亮開著的那扇門」 | 一扇門的線 1 倍只有 2.5 px,紅了也看不出是哪一扇 | lead 同意,不做 |

## 六、照著做的裁定

Status: 完成

全文在 `00-rulings.md`。這裡只寫它們怎麼限制我的批評。

| 裁定 | 對批評的限制 |
|---|---|
| 共同規則(`00-brief-speed-meter.md`)+ tesla brief 第一行 | 不進 plan mode、不問、不開 subagent、不上網、只寫自己的檔和 board;不 commit、不 checkout |
| L87 | 開著 = 紅,紅只用在開著的車況;未知 = 同形狀灰色虛線;離數字墨跡 ≥ 9 是硬規定(R7-02、L48)。這輪 brief 裁定 9 另有自己的淨空表(數字 ≥ 9、`P R N D` / `km/h` ≥ 8、刻度 ≥ 6、圓底之間 ≥ 8),以 brief 為準 |
| L88 | 一個數字大小、固定格子、等寬數字,不隨位數左右跳 |
| L90、L92 | 車主嫌「抄 Dashla」;紅色的意思不變 |
| L97 | 辛的數字暫時放寬下限;這輪改成「字高 ≥ 車主圖上的 72.8」(brief 5) |
| L98 | 翻頁控制只在停車畫 |
| L100 | 未知 = 平頭短線段虛線、不填色;沒資料的圖示只在示範。這輪沒資料的圖示**整個拿掉**(brief 1) |
| tesla brief 3、6、11、12、13、15 | 儀表圖說了算(規範表只輔助);四個格位永遠畫(關灰、開紅、胎壓低琥珀);顏色取線條中位數;開 / 關只差顏色、前後車廂幾乎一樣先照圖畫(候選修法只放對照段);圖上沒有的狀態照現有規矩;craft-floor 和車主的圖衝突時車主的圖贏 |
| 「和 brief 不同要 lead 同意」 | 我每輪都把這種建議單獨列一段 |
| 記憶:未選的保留 | 沒選的東西不刪,標「未選(保留參考)」 |

## 七、board 上跟我有關的幾行(`team-board.md`)

Status: 完成

| 時間 | 誰 | 重點 |
|---|---|---|
| 11-07 17:50 | ux | 10 §4.4 戊「刻度扇」 |
| 11-08 03:13 | ux | 13 第十七輪批評(車的光影、弧 r 170、右移) |
| 11-08 03:17 | lead | 照 ux:弧 r 170、cx 230.5、車 cx 500;開著紅色保留光影 |
| 11-08 19:06 | ux | 16 辛橫式批評 |
| 11-08 19:10 | lead | 地平線淡出、背景光都做;車不橫拉、不做辛專用光影 |
| 11-08 19:57 | ux | 16 辛直式批評 |
| 11-08 19:58 | lead | 預算 28 / 148 / 415 / 104;翻頁控制只在停車 |
| 11-10 17:06 | ux | 16 第二十二輪圖示和擺法批評 |
| 11-10 17:07 | lead | 11 條裁定(未知圓點、圖示路徑照 ux 修、不縮 0.88、一排置中、頁面並排) |
| 11-10 17:18 | lead | 3b:圓點認不出形狀,改平頭短線段 |
| 11-10 17:26 / 17:31 | lead | 第二十二輪結束(L100),safety 複驗結案 |
| 11-12 15:20 | lead | 第二十三輪開始,新 brief;ux 先寫交接、重開,等階段 2 |

## 八、已經寫在檔裡的(只列位置,不重抄)

Status: 完成

| 內容 | 在哪 |
|---|---|
| 第二十二輪:圖示逐個量的數字、未知虛線、1 倍、兩種擺法、頁面、待確認 | `16-center-stage-critique.md` 最上面「第二十二輪(2026-11-10)」;裁圖 `frames/speed-meter-icons/critique/c-01…c-04` |
| 第二十二輪的量法(遮罩門檻、自己重畫、筆畫、外緣剖面、虛線、對比) | 16 同一段「怎麼看、怎麼量」 |
| 辛直式:參考圖裁法(三支手機 338 × 758,× 1.154)、卡內 × 0.84、高度預算 | 16「直式(2026-11-08 階段 3)」→「怎麼看、怎麼量」「三區的高度預算」;裁圖 `frames/prototype-speed-meter/critique/hv-01…hv-09` |
| 辛橫式:對應公式(頁面 x = 422 + (參考 x − 887) × 0.44、y × 0.44)、地平線 / 弧峰值和半高寬 | 16「16 辛橫式…(第十九輪)」→「怎麼看、怎麼量」;裁圖 `critique/h-01…h-10` |
| 己 / 庚:參考圖裁法(× 0.7232)、車的亮度剖面、數字模型、「看得見的弧」= 亮度 ≥ 0.07 | `13-atelier-critique.md`「怎麼看、怎麼量」「兩個判斷」;裁圖 `frames/prototype-speed-meter/critique/01…11` |
| 速度表調查(五類例子、原則、乙丙丁戊) | `10-speed-meter-survey.md`(只當參考;這輪不上網) |
| visual 的圖示量法、匯圖、頁面結構 | `handoff-visual-speed-meter.md` §1–§4 |
