# handoff:visual,圓形儀表頁(重寫 2026-11-12 晚,第二十三輪結束後;給下一個 session)

## 第二十四輪補記(2026-11-13;只寫下面還沒寫到的,和下面不一樣的地方以這一段為準)

Status: 第二十四輪結束,safety 複驗全過。現役頁面 `frames/atelier-tesla-edition.html` 是 620 行、shasum **`218482e6`**,已發佈在同一個網址(第 3 版)。量到的數字都在 `18-tesla-edition-visual.md` 最上面「第二十四輪」:先看「階段 3 修訂」(最新),再看「重點(階段 1)」以下。裁定在 `00-brief-tesla-edition.md` 檔尾「第二十四輪」和 board 2026-11-13 01:31 那一行。

### 現在的主畫面和 variant

主畫面是 **`main`**:`LOWARC` 的格位(前車廂 −117°、車門 −159°、後車廂 +159°、胎壓 +117°)+ 建議版四點 + Hanken,再加階段 3 的四個修訂。下面「`st` 和四種 variant」那張表現在多兩列,原本四列都變成未選(保留參考):

| variant | 用在 | 格位 | 和 `main` 差在哪 |
|---|---|---|---|
| **`main`** | 主畫面十一個狀態、對照段的右邊、`compare.png` | `LOWARC` | — |
| `alt` | 只匯圖 `alt-01 / 07`,不在頁面上(候選,沒被採用,圖檔留著) | `ALTARC`(後車廂和胎壓對調) | 建議版,但**沒有**階段 3 的修訂(維持當時匯出的樣子) |
| `corner` / `safe` / `sf` / `arc` | 摺疊「未選(保留參考)」裡 | 同下表 | 都沒動,只有頁尾的 `ODO` 跟著換 |

階段 3 的修訂由一個旗標 **`rev`** 管(`drawT` 裡 `rev = variant === "main" && !REV0`),一路傳到 `slotT` → `tiInner` → `TI[name].parts(form, dash, rev)` 和 `unitT`。`rev` 管四件事:關著的前 / 後車廂的記號(`T_MARK`,車身輪廓裁到 x < 228 / x > 350 填色)、開著的車門加長、狀態 9 的字的位置(`TE.num.noteTop = 177.5`)、虛線的實線段(`T_SEG_REV = 60`、`T_MIN_REV = 50`)和起點(`T_OFF_LOW`)。**未選的畫面不帶 `rev`,所以不會被連動;以後改主畫面的形狀都走 `rev`,不要直接改共用的零件。**

圖示對照表:`compareTable("now")` = 現在用的形狀(帶 `rev`),`compareTable("owner")` = 照圖的畫法(在摺疊裡)。`CMP` 的欄位順序改成主畫面由左到右的順序。

### 新的參數(頁面上不寫)

- `?only=main-01…11`、`?only=alt-01` / `alt-07`;每個 variant 都能接 `-v<數字>`(例如 `main-v107`)。
- `&mono=1`:四個圖示都畫成關著的灰(量「不看顏色」的形狀差)。
- `&swap=1`:前車廂和後車廂的圖示互換格位(同一個位置比兩個形狀)。
- `&rev=0`:主畫面改回階段 3 之前的形狀(量修訂前的數字;這時起點用 `T_OFF_LOW0`)。
- `&ink=`、`&toff=` 照舊,`main` 也能用。
- 摺疊預設關著;網址加 `#corner`、`#iconsold` 這種摺疊裡的錨點,Chrome 會自己打開(截摺疊打開的整頁圖就靠這個)。

### 行號大致怎麼移(566 行 → 620 行;下面「頁面的程式結構」那張表的舊行號 → 現在)

| 舊 | 現在 | 區段 |
|---|---|---|
| 14–68 | 18–83 | CSS(多了 `ul.intro`、`ul.diff`、`details.old`) |
| 72–82 | 87–111 | HTML:說明(條列)、`#main`、`#icons`、`#cmp`、`<details id="old">` 裡的 `#corner`、`#safe`、`#font`、`#arc`、`#iconsold` |
| 85–228 | 113–257 | 從舊頁複製的那一段。**唯一改過的一行是 256**(`footX` 的標籤「總里程」→ `ODO`) |
| 229–300 | 259–330 | 舊 `ICONS` / `icon()`、`topRow` |
| 302–351 | 332–393 | 四個圖示:`T_MARK` 347、`TI` 349、虛線常數 358–365(`T_OFF`、`T_OFF_LOW0`、`T_OFF_LOW`)、`tDash` 372、`tiInner` 382 |
| 353–379 | 395–422 | 常數:`TE` 395、`T_COL` 404、`CORNER` 408、`LOWARC` 410、`ALTARC` 412、`INK` 420、`MONO` / `SWAP` / `REV0` 422 |
| 382–448 | 424–492 | 畫各層:`ringT` 438、`numT` 463、`unitT` 477、`tiCol` 486、`tiForm` 488、`slotT` 489 |
| 450–462 | 494–507 | `tyreColT` |
| 464–473 | 509–519 | `drawT` |
| 477–492 | 522–537 | `STATES`、`VARIANTS`、`stOf` |
| 495–531 | 541–582 | `GZ`、`compareHtml`、`CMP_DIFF`(對照清單八點)、`tiSvg`、`compareTable(which)`、`NOTE_ICONS`、`SAFE_DIFF` |
| 533–561 | 584–618 | `build`、`fit`(摺疊打開時重算)、字型和 `CJK` |

### 備份(`frames/atelier-tesla-edition/stage4/`,別動)

- `atelier-tesla-edition-3935c990.html` + 52 張 PNG:第二十三輪結束時的頁面和全部的圖。
- `atelier-tesla-edition.stage1-24.html`(`150b3bff`):第二十四輪階段 1 的頁面(修訂前)。
- `main-stage1-24.sha1`:階段 1 那 22 張 `main-*` 的 shasum(圖沒有另外備份)。
- `stage1/`、`stage3/` 照舊。下次要備份再開新的資料夾。

資料夾現在 78 張 PNG:原本 52 + `main-*` 22 + `alt-*` 4。未選的舊畫面在階段 1 重匯過(只差 `ODO`),原檔在 `stage4/`。

### 這一輪新增或改過的 `tools/` 腳本怎麼跑

新的和改過的都**不用再複製、改路徑**(路徑跟著檔案走),在哪裡跑都可以。`shot.sh` 的第五個參數是 Chrome 的 profile 編號:同時開好幾個 Chrome 時一定要各給一個,不然會互相卡住。

| 腳本 | 新 / 改 | 怎麼跑 | 過的標準 |
|---|---|---|---|
| `export.sh` | 改 | 全部重匯:`./export.sh`。只匯一部分:`ONLY='main-*\|compare.png\|icons-compare.png' ./export.sh`(三個檔名樣式中間用直線 `\|` 隔開;`sheet.png` 一定重拼) | 每行 ok |
| `tools/consist.py`、`tools/fixed.py` | 改 | `python3 tools/consist.py`、`python3 tools/fixed.py`(每次重匯後跑) | 都印「沒有」 |
| `tools/dashgap.py` | 改 | `python3 tools/dashgap.py [資料夾]`:量 `main-10 / 11`(下弧)和 `corner-10 / 11`(四角)的 1 倍圖 | 每個圖示最小 ≥ 2,沒有「< 2 的」 |
| `tools/offsearch.py` | 改 | `python3 tools/offsearch.py`:起點 0–96 每 3 試一次(33 張 1 倍圖,寫在腳本旁邊的 `t/`),列出 `main-10` 三個圖示能過的起點;結果手動寫進 `T_OFF_LOW` | — |
| `tools/sweep24.sh` + `sweep24.py` + `clr24.py` | 新 | `tools/sweep24.sh <資料夾>` 截 0–250 的數字層和各層(四個 Chrome 同時跑);再 `cd <資料夾> && python3 <tools>/sweep24.py sweep ink/disc-main.png && python3 <tools>/clr24.py ink` | 全掃「< 9」都是空的;其他淨空看 18 的門檻 |
| `tools/vs_stage4.py` | 新 | `python3 tools/vs_stage4.py`:和第二十三輪結束時比(舊畫面只差 `ODO`;`main-01 / 02 / 07` 對舊的 `safe-*`) | 框外「沒有」、(b) 都是 0 |
| `tools/vs_before.py` | 新 | `python3 tools/vs_before.py <修訂前的 main-*.png 資料夾> [<用現在的頁面重截的未選畫面 1 倍圖資料夾>]`。改主畫面前先把 `main-*.png` 複製到 scratchpad 當「修訂前」 | 「其他地方不同的像素」0;(b) 全部 0 |
| `tools/shapediff.py` | 新 | 先截六張 1 倍圖(檔名和參數寫在腳本開頭:`A`、`A0`、`As`、`As0`、`B`、`B0`),再 `python3 tools/shapediff.py <資料夾>` | 只是量,沒有門檻 |
| `tools/wrap390.html` | 改 | 做法同下面 §2 的說明;現在摺疊關著、打開各量一次,讀 `RESULT closed` / `RESULT open` 兩行 | 兩行的 `html.scrollWidth` = `html.clientWidth`、`overflowing=[]` |
| `tools/ti.js` | 改 | 圖示那一段的複本(頁面 332–393 行原樣切出來);改了圖示要重切 | — |

**沒改的**:`clr.py`、`clr.sh`、`verify3.py`、`sweep.py`、`sweep2.py` 和量車主的圖那些,還是舊 scratchpad 的絕對路徑和四角的圓底中心(`sweep.py` 用象限分圓底,下弧不能用)。

兩個坑:① 這台的 shell 是 zsh,`for q in "a b"; do set -- $q` 不會拆字,要拆字的迴圈寫進 `#!/bin/bash` 的腳本裡;② Chrome 偶爾截出整張反鋸齒不同的一張(這一輪是 `corner-02@2x`,還有一次 `main-01` 的單張),`consist.py` 會抓到,單獨重截就好。

### 這一輪做的判斷(數字和理由在 18「第二十四輪」的「假設」「待確認」)

- **淨空全掃從 0 掃到 250**,而且先用新腳本重現上一輪的 9.5 才相信它。結果圓底不用移(最小 10.4,尾數 2 對最右的胎壓)。251–299 沒掃。
- **ODO 的樣式**我定的:500 / 14 / `#92969C`、和里程數字同一條基線(學左導航的「12 km」)。ux 說沒問題。
- **未選的舊 PNG 重匯成有 ODO 的版本**,讓資料夾和頁面一致;階段 3 只重匯 `main-*`,因為未選的沒有變。
- **摺疊裡多放兩塊** brief 沒列的(選之前看到的下弧三張、照圖的圖示畫法表),理由是「沒選的要留著」;lead 沒說要拿掉。
- **虛線起點各取能過的範圍中間**(前車廂 24、後車廂 9、車門 33),不是 ux 試的 15。
- **虛線最短 50** 是從 ux 的草稿指令查到的(`seg=60&smin=50`),19 沒寫;只改 60 的話胎壓兩臂會切成三段,和 lead 同意的 `d-09` 不一樣。
- **候選 `alt` 不跟著階段 3 改**,留著當時的樣子。
- **修訂只掛在 `main`**(`rev` 旗標),不新開 form 名字,也不動未選的畫面。
- 記號、加長的車門、字的位置都照 ux 草稿頁的數值,沒有自己另外調。

### 還開著的事(接在下面 §7 後面)

- 下面 §6「車主選了之後要改哪幾處」已經做完(選了建議版四項 + Hanken + 下弧),那一節只剩參考價值。
- 狀態 10 的虛線沒有車頭 / 車尾的記號,前後車廂在那個狀態只能靠位置分;車門開對關的形狀差仍是四個裡最小的(13–15 個像素)。
- 關著的胎壓像杯子(裁定不改;ux 畫過打勾版備著)。
- 沒做:直式、夜間、充電中、GPS 備援、右欄和圓裡不一致、實機和 3 倍的驗證、251–299。
- `DESIGN-atelier-tesla-edition.md` 是 lead 的檔,數值有沒有跟上這一輪要問 lead。

---

Status: 第二十三輪(階段 1、階段 3 修訂、三位數全掃)完成。現役頁面是 **`frames/atelier-tesla-edition.html`**(566 行,shasum `d76f0833`)。**發佈在 https://claude.ai/artifact/7ZXxShuz3vMj7Zx7unsxTA 的還是全掃之前的 `1fcd0c91`**(lead 發的,要不要重發問 lead)。

**2026-11-12 深夜補記(三位數全掃,寫完這份 handoff 之後做的)**:上排兩個圓底從 ∓56° 改成 **∓49°**,因為個位 7 / 5 / 4 的數字右上角離後車廂圓底只有 1.0 / 2.8 / 6.7。SF 的排法也用 ∓49°(`SFPOS = CORNER`,不再有例外)。下面各節裡凡是寫「上排 ∓56°」「SF 上排 ∓52°」的,都以這一段為準;細節在 18 最上面「三位數全掃」。改之前的頁面和圖在 `stage3/`。下面表格的行號大致往後移 2 行。**量淨空一定要全掃(`tools/sweep.py`:100–250 每個數字、兩種排法),不能只挑幾個數字**;最凸的是平頂數字(7、5、4)的右上角,不是最寬的數字。舊的兩頁 `frames/speed-meter-icons.html`(`830663ab`)、`frames/prototype-speed-meter.html`(`fa5b7f4c`)**只保留參考,不要動**;它們的結構摘要在檔尾「附:舊頁」(這份 handoff 的上一版沒有進 git,被這一版蓋掉了,所以把還用得到的留在那裡)。

等車主選三件事:照他的圖還是安全建議版(四項可分開)、字型 Hanken 還是 SF Pro、「下方的長弧 = 舊的地平線」這個解讀對不對。

## 先看哪裡

1. `00-brief-tesla-edition.md`(車主的四個決定、lead 的 15 條)+ `team-board.md` 檔尾 lead 2026-11-12 20:17(階段 3 的 11 條)和 21:12(結束、裁定 L101)。
2. `18-tesla-edition-visual.md`:**最上面「階段 3 修訂」是最新的**(裁定 → 改了什麼 → 量到的值、兩張淨空表、弱點、待確認、假設);再往下是階段 1 原文(§1 從車主的圖量到的值、§2 座標、§3 字型候選、§4 圖示、§5 淨空、§6 和圖不一樣的地方、§7 craft-floor 的衝突)。**量到的數字都在那裡,這份不重抄。**
3. `19-tesla-edition-critique.md`(ux;裁圖 `frames/atelier-tesla-edition/critique/c-01…c-13`)、`20-tesla-edition-safety.md`(safety;S23-01…08 和檔尾的複驗)。
4. 參考圖 `frames/atelier-tesla-edition/reference/`(lead 放的,不要動):`dashboard-2026-11-12.png` 說了算。
5. `DESIGN-atelier-tesla-edition.md`(lead 寫的規範,已補數值;不是我的檔)。

## 1. 頁面的程式結構(`frames/atelier-tesla-edition.html`)

單一檔案,自己能開;外部資源只有 Google Fonts(Hanken Grotesk 500 / 600、Inter、Noto Sans TC)。**這個 HTML 就是原始檔**:階段 1、3 是在 scratchpad 用幾個片段拼出來的,那些片段會被清掉,以後直接改 HTML。

| 行 | 區段 | 內容 |
|---|---|---|
| 14–68 | CSS | 頁面的淺色 / 深色色票;`.screen`(844 × 390,舊頁的底色和上排位置,原樣);**46–48 行是這一輪的**:`.screen.te` 藍黑底色、時間移到左邊(`left: 109px`)、`.inkonly` 量測用的黑底;`.fit`(一般畫面的縮放框)、`.gz`(對照段的方形取景)、`.cmp`(圖示對照表四欄)、`ol.diff`、`body.shot`(匯圖模式) |
| 72–82 | HTML | 標題、「最新 2026-11-12」、說明,六個 `<section>`:`#cmp` 對照、`#corner` 主畫面、`#safe` 建議版、`#font` 字型比較、`#icons` 圖示對照、`#arc` 備案。**每段的白話說明寫在這裡**,圖由 JS 塞 |
| 85–228 | 從舊頁複製(一字不改) | `QP`、`CK` / `arcCk` / `svgFull`、`FF`、`placeF`(寫死 system-ui)、白車線條、`FH`(左導航 / 右欄 / 頁尾的座標)、`tyreColX`(179,右欄胎壓圖)、`navX`(199)、`footX`(218)。等於舊頁第 79–221 行 |
| 229–300 | 也是舊頁複製 | 舊的 `ICONS` / `icon()`(230–291;**只剩右欄車門列的小圖示在用**)、舊顏色常數(292)、上排 `LUC` / `topRow`(293–300) |
| 302–351 | **四個圖示** | `TK`(1 裁圖單位 = 0.0793 px)、`TSW = 21`(線寬)、車身 / 蓋子 / 車門 / 胎面的路徑常數、`TI`(316:每個圖示的圓底中心 `c` 和 `parts(form, dash)`)、虛線 `T_GAP` / `T_SEG` / `T_OFF` / `tDash`(325–344)、`tiInner(name, col, { form, dash })`(345)。座標 = 車主裁圖(576 × 576)的像素。**`tools/ti.js` 是這一段的複本**(疊圖檢查的 `harness.html` 載它),改了圖示兩邊都要改 |
| 353–379 | 常數 | **`TE`(357)= 圓、圓環表、刻度、`P R N D`、數字、`km/h`、圓底、軌道**;`T_COL`(366,含建議版的 `offSafe`);`slotAt`、三組格位 `CORNER` / `LOWARC` / `SFPOS`(369–373);`SF`(字族和格寬 60);`SAY_T`(朗讀句);`coolRing`(建議版圓環換色);`INK` |
| 382–448 | 畫各層 | `inkG` / `putG`(Hanken 的量和放)、`defsT`(圓底漸層、光暈的模糊)、`ringT(safe)`、`ticksT`、`gearsT(gl, safe)`、`numBox` / `numT(v, font)`、`unitT`、`discT`、`tiCol` / `tiForm`(顏色和形狀的規則)、`slotT` |
| 450–462 | `tyreColT` | 右欄:呼叫原樣的 `tyreColX` 畫胎壓圖,車門列照舊頁的寫法;收兩個分開的旗標 `doorUnk` / `tireUnk` |
| 464–473 | **`drawT(variant, st)`** | 一個狀態 → 一張 844 × 390。算每格的 mode(`off` / `on` / `unk`),疊圓環、刻度、檔位、數字、單位、四格、右欄、左導航、頁尾、上排 |
| 477–492 | 狀態 | `STATES`(11 個:`[編號, 標題, 括號裡的標, st]`)、`SAFE_KEYS` / `ARC_KEYS` / `VARIANTS`、`stOf(key)`(`"07"` 查表;`"v200"` = 全關、只換數字) |
| 495–531 | 對照和圖示表 | `GZ`(把我們的畫面裁成和 `crop-gauge.png` 一樣的取景)、`compareHtml`、`tiSvg`(獨立的圓底 + 圖示)、`compareTable`(兩塊:照你的圖 / 建議版)、`NOTE_ICONS`、`SAFE_DIFF`(建議版四個不同的白話) |
| 533–561 | `build` / `fit` / 字型 | `?only=` 匯圖分支、一般頁面的六段;`fit()` 縮放;`FONTS` 和 `CJK`(**畫面上會出現的中文字要列在 `CJK` 裡**先載入,不然匯圖時有的字會用系統字畫) |

### `st` 和四種 variant

`st = { gl: "D" | "P", v(數字;`null` = 沒有有效車速), open: { frunk, fr, trunk }, tire(胎壓低), doorUnk, tireUnk }`。

| variant | 用在 | 格位 | 數字 | 和主畫面差在哪 |
|---|---|---|---|---|
| `corner` | 主畫面、對照段、建議版和字型比較的左欄 | `CORNER`(∓49° / ∓124°) | Hanken 500,格寬 57.8 | —(照車主的圖) |
| `safe` | 建議版右欄 | `CORNER` | 同上 | `ringT(true)`、`gearsT(_, true)`、`tiCol` / `tiForm` 的 `safe` 分支 |
| `sf` | 字型比較右欄 | `SFPOS`(= `CORNER`) | SF Pro 500 + `ss01` + 等寬,格寬 60 | 只換車速的數字 |
| `arc` | 備案 | `LOWARC`(∓117° / ∓159°) | Hanken | 只換格位 |

### 參數(頁面上不寫)

- `?only=<variant>-<NN>`:`corner-01…11`、`safe-01…11`、`sf-NN`、`arc-NN` 都畫得出來(頁面和匯圖只用其中一部分)。`?only=<variant>-v<數字>`:全關、只換數字(`corner-v200`、`sf-v248`)。
- `?only=icons`(圖示對照表,1080 寬)、`?only=compare`(1280 × 634,車主的圖 vs 我們的)。
- `&ink=num|unit|gear|tick|disc|ring`:黑底只畫那一層(量淨空);`disc` 把圓底畫成白色實心圓。
- `&toff=<數>`:只給 `tools/offsearch.py` 用,強制所有封閉輪廓的虛線起點。
- **`corner-10` 的意思在階段 3 變了**(只有車門不明);`corner-11` = 只有胎壓沒讀值。

### 加東西要動哪幾處

- **加一個狀態**:`STATES` 加一列;`export.sh` 的 `for n in …`;`sheet.py` 的 `T` 和 `ROWS`;右欄會出現新中文字就加進 `CJK`;18 補表。
- **加 / 改一個圖示**:`TI` 的 `c`、`parts`;`SAY_T`;`drawT` 的 `mode` 和格位表;`CMP`;同步 `tools/ti.js`;跑疊圖(§3)和 `offsearch.py`(虛線起點)。
- **改圓的大小或位置**:只改 `TE.cx / cy / R`(圓環、刻度、軌道、`P R N D` 的高度跟著走;數字、圓底、圖示不跟)。`defsT` 裡 `tGlow` 的 filter 範圍(x 240、y −10、364 × 364)和 `GZ` 是寫死配 (422, 172) / 156 的,要一起改。改完全部重量。
- **改格位**:`CORNER` / `LOWARC` / `SFPOS`;`tools/clr.py`、`dashgap.py`、`fixed.py`、`verify3.py` 裡寫死的四個圓底中心也要改;虛線起點重找。

## 2. 匯圖和每次重匯後要跑的檢查

`frames/atelier-tesla-edition/export.sh [OUTDIR]`:headless Chrome,22 個畫面 × 1 倍和 2 倍(`corner-01…11`、`corner-200`、`safe-01/02/07`、`font-hanken-86/248`、`font-sf-86/248`、`arc-02/03/07`)+ `compare.png` + `icons-compare.png`(視窗 1104 × 2060)+ `sheet.png`(呼叫 `sheet.py`)。要網路;`font-sf-*` 要在 Mac 上匯(`system-ui` = SF Pro)。腳本裡不刪檔,`--screenshot` 直接蓋。`stage1/` 是階段 1 的頁面(`52616be6`)和圖的備份,別動。

**每次重匯後一定跑**(都在 `tools/`,在 scratchpad 複製一份再跑比較安全;腳本裡的路徑是寫死的絕對路徑):

| 腳本 | 做什麼 | 過的標準 |
|---|---|---|
| `consist.py` | 44 張的時間、導航卡、頁尾左、齒輪、`km/h`、同樣的「86」各自和 `corner-01` 比 | 印「沒有」。Chrome 偶爾會截出整張反鋸齒不同的一張(階段 1 的 `corner-06@2x`、這一輪第一次的 `corner-08.png`),那張單獨重截 |
| `fixed.py` | 44 張的圓環 + 刻度、`P R N D`、圓底的邊和 `corner-01` 比(建議版扣掉換色的兩段;SF 上排兩張互比;下弧三張互比) | 兩行都印「沒有」 |
| `sweep.py`(改了格位、字型、字級才跑;約 10 分鐘) | 100–250 每個數字的 `&ink=num` 各截一張到 `sweep/`,量四個圓底到每個數字的最短距離;`sweep2.py` 估各個上排角度的結果 | 兩種排法「< 9」都是空的 |
| `dashgap.py` | 1 倍的 `corner-10.png` / `corner-11.png`(和 scratchpad 的 `t/safe-10.png` / `safe-11.png`,要自己先截)量虛線的空 | 每個圖示「最小 2 px」以上,沒有「< 2 的」 |

其他(改了對應的東西才跑):

| 腳本 | 做什麼 |
|---|---|
| `clr.sh` + `clr.py` | 各層分別截 2 倍圖到 `ink/`,量四角 / 下弧 / SF 排法的圓底到 188 / 200 / 248 / 888 / 111 / 100、`P R N D`、`km/h`、刻度、別的圓底。要 `shot.sh` 和 `ov.py`(借它的 `edt`) |
| `verify3.py` | 和 `stage1/` 比(圓外 / 刻度環帶 / 圓內)、建議版和主畫面比(差異只該在圓環兩段、圓底裡、`P R N D`;圓環不該有暖色像素) |
| `offsearch.py` | 每 3 單位試一個虛線起點(`&toff=`),列出每個圖示「沒有 < 2 px 小縫」的起點;結果寫進 `T_OFF` |
| `render.sh` + `harness.html` + `ov.py` | 圖示疊圖:把 `ti.js` 的圖示畫成 576 × 576,和裁圖遮罩比輪廓距離(最大 / 95% / 中位、IoU),出 `overlay-<名字>.png`。`ic1.py` = 裁圖遮罩的門檻;`scan.py` = 逐列逐欄列筆畫 |
| `m2.py`–`m6.py`、`ringtab.py`、`ringcmp.py`、`disc.py` | 量車主的圖(§3) |
| `fonts.html` + `fcmp.py`、`hk.html`、`sf.html` + `scmp.py`、`fov.py`、`met.html` | 字型候選(§3) |
| `wrap390.html` | 390 寬:在 `frames/` 開本機伺服器(`python3 -m http.server`),把頁面放進 390 寬的 iframe 讀 `scrollWidth`。headless Chrome 視窗最窄 500,所以要這樣繞。測完把暫時放進 `frames/` 的那個檔用寫死的路徑刪掉、伺服器關掉 |

`sheet.py`:Pillow 拼總表(兩欄),標題字用 PingFang(`/System/Library/AssetsV2/com_apple_MobileAsset_Font8/*/AssetData/PingFang.ttc`)。這台機器沒有 scipy,距離轉換是 numpy 寫的(慢,`clr.py` 一次約一分鐘)。

## 3. 怎麼從車主的圖量(方法;數字在 18 §1)

- **圓**(`m2.py`):每 1° 沿半徑取亮度,取峰值附近的重心,360 個點做最小平方圓,疊代 6 次。再把圓環攤平成極座標圖(角度 × 半徑,`polar.png`),後面都在這張上量。
- **圓環的顏色和線寬**(`ringtab.py`):每 0.25° 一欄找峰值,半高寬 = 線寬,顏色取峰值 85% 以上的像素平均;每 5° 取 ±2° 的中位數 → 72 筆 `[R, G, B, 寬]`,貼進 `TE.ring`。畫的時候顏色 × 1.07、線寬 × 0.94(表上是線中段的平均,這樣峰值和半高寬才對得上)。
- **光暈**(`ringtab.py` 後半、`ringcmp.py`):量離線 ±4、±7 px 比底色亮多少;我畫的匯出 2 倍圖,同樣攤平,每 10° 並排比峰值顏色、線寬、光暈,調到中位差 4、最大 12。
- **刻度**(`m6.py`):在刻度帶裡找「比左右鄰居亮」的欄;長度**一定要用和左右鄰欄相減**的剖面量,直接取門檻會被圓環往裡的光暈撐長(第一次量成 12,實際 7)。角度對 40 / 42 / 44 / 45 / 48 格各算 rms,44 最好。
- **數字、`km/h`、`P R N D`**(`m4.py`):亮度遮罩取外框、逐列逐欄量筆畫。
- **字型候選**(`fcmp.py`):車主的「8」「6」各自取遮罩,候選字 300 px 畫出、縮到同字高、中心對齊算 IoU,加寬高比、直筆、橫筆、字距。SF 用系統字檔(`/System/Library/Fonts/SFNSRounded.ttf` 複製到 scratchpad 用 `@font-face` 載);headless Chrome 的 `ui-rounded` 不會變成 SF Rounded。
- **圓底**(`m5.py`、`disc.py`):沿半徑找亮度掉最快的地方擬合圓;填色分八個方向取樣(上亮下暗)。
- **圖示**(`ic1.py` → `scan.py` → 手寫路徑 → `ov.py`):遮罩門檻前 / 後車廂用亮度 > 105,車門 R > 110 且 R − G > 40,胎壓 R > 110 且 R − B > 50,只取圓底半徑 222 以內。每 8 列 / 欄列出筆畫的起訖和中點,直接用裁圖像素當座標寫路徑。顏色取遮罩內像素的中位數(ux 指出這樣會把線邊的半透明像素算進去,線條中心其實更亮 6–15 階;lead 沒要改)。

## 4. 做過的判斷和理由、放棄的做法

- **圓放大、內容不放大**:圓環、刻度、光暈、軌道、`P R N D` 的高度 × 1.088;數字、`km/h`、字、圓底、圖示維持車主圖上的絕對大小。一起放大的話三位數一樣擠(ux 試過,上排淨空只剩 3.3)。代價:兩個圓縮成一樣大並排時我們的數字小 8%,頁面的說明有寫。
- **四角**:下排用原本駐車 / 車道的格位,取 ∓124°(圖上 ∓125.3°)。上排原本留在車主圖上的 ∓56°,全掃後移到 ∓49°(見最上面的補記;上下不再對稱)。brief 寫「對數字的中線對稱」,那樣下排要到 ∓113°,離三位數 7.6 不過;lead 接受對圓心。
- **數字整組置中、一位數一格**:自己算格子中心放字,不靠字型的等寬功能。lead 接受換位數時重排(固定三格靠右會讓 86 偏一邊)。
- **底色改成車主的藍黑**:圓底只比底色亮 9 階,舊的中性黑上看不到。兩邊的卡沒動。
- **狀態 9**(沒有車速)照舊頁辛:圓頭線 + 「車速暫不可用」,檔位和圖示照常。ux 建議把線加粗成 58 × 7,lead 沒裁定,沒改。
- **未知的虛線**:空固定 35 單位(2.78 px),只調實線段長度讓每條線收尾;封閉輪廓的起點逐個搜尋(`T_OFF`)。**放棄的**:① 階段 1 的「線段 1.8 倍線寬、空 0.95 倍」(名義空 1.58 px,safety 量到 1 px);② 用 `pathLength` 縮放(會連空一起縮);③ 自動把實線中點對到兩條線的接點(`tDash` 的 `at`,還留在程式裡當 `T_OFF` 沒值時的後備;它解決了接點但在輪子的小腳又冒出 1 px 的縫,所以改成搜尋)。車門的窗台線在虛線時縮短(兩端離門框 2.6),那條 4.7 px 的斜線整段實線。
- **胎壓沒讀值**:兩臂 + 一條底線,不畫驚嘆號。階段 1 畫過「驚嘆號維持實線」,lead 裁定不畫。
- **建議版關著的車門**:只拿掉左邊那條往外的斜線。斜線是車主的門唯一突出門板的部分,其他改法(把斜角改方、窗台拉滿)在 1 倍看不出來。門板位置不動。
- **建議版前車廂的蓋子**:後車廂蓋子的左右鏡射,車身不移(階段 1 的候選圖曾整個右移 0.7 px,拿掉了,這樣關 / 開 / 未知三種的車身在同一個位置)。
- **建議版圓環**:`coolRing` 只換色相不動亮度,而且只作用在暖色的兩段(判斷式 `(R − B + 8) / 20`;第一版寫 `+25 / 35` 會連中性的灰段一起微調,和主畫面差了三千多個像素)。
- **建議版的兩個灰**(我定的):關著 `#7F8790`(對圓底最亮處 4.5:1、比 `km/h` 暗)、熄檔 `#7C828A`(4.96:1,再亮會和亮檔太接近)。
- **SF 的數字**:canvas 量不到 `ss01` 和等寬數字,所以每個字用 `text-anchor="middle"` 對格子中心;字級疊代到墨跡高和 Hanken 一樣,基線用上下置中算(第一版用單次量測,整組低了 0.5 px)。只換車速的數字,`km/h` / `P R N D` 沒換(ux 畫的也是這樣,淨空數字指的是這個排法)。
- **右欄**:不改複製來的 `tyreColX`,另外包一層 `tyreColT` 傳兩個旗標。右欄的胎壓低仍是紅色、車門列是第二十二輪的舊圖示,這一輪說好不管。
- **中文字先載入**(`CJK`):Noto Sans TC 是分片下載的,沒載到的字會先用系統字畫,同一張重截會不一樣。

## 5. 照的裁定

- **車主 2026-11-12**:沒資料的圖示拿掉;只做速度表和四個圖示、拿掉長弧;兩張圖不同以儀表圖為準;圓放大到三位數放得下、大小固定。
- **brief 的 15 條**(`00-brief-tesla-edition.md`):圓 (422, 172) / 156 固定;四格永遠畫;主方案四角 + 備案下弧;淨空 9 / 8 / 6 / 8;圓環照圖、固定不動;圖上沒有的狀態照現有規矩(「—」、L87 虛線);停車 = P 亮 + 0。
- **階段 3 的 11 條**(board 20:17)和 **L101**(`00-rulings.md`,lead 21:12 記的):刻度 0.8 且補滿;數字置中;主畫面 Hanken、照圖不偷改;建議版和字型比較另列給車主選;虛線空 ≥ 2 px(25% 以上算墨);狀態 10 / 11 拆開;四角不動、下弧當備案。
- **沒裁定所以沒做**(ux 提過):刻度內端 0.903 → 0.909 R、「—」58 × 7、車門線寬 1.59 → 1.74、紅段往裡的柔光加強。

## 6. 車主選了之後要改哪幾處

**選安全建議版(四項可以分開選)**。現在 `safe` 是一個開關管四項;要分開的話在 `drawT` 把 `safe` 拆成四個旗標分別傳:

| 項目 | 現在由誰管 | 併進主畫面時改 |
|---|---|---|
| ① 關著換形狀 | `tiForm`(444)的 `mode !== "on" → "closed"` | 主畫面也走這條;未知的虛線會跟著用關著的形狀 |
| ② 前車廂蓋子換邊 | `tiForm` 的 `name === "frunk" → "front"` | 同上 |
| ③ 圓環兩段改藍白 | `ringT(safe)`(395)→ `coolRing` | 主畫面傳 `true`,或直接把 `TE.ring` 的值換掉 |
| ④ 關著調暗、熄檔調亮 | `tiCol`(442)的 `offSafe`;`gearsT`(413)的 `offSafe` | 把 `T_COL.off`、`TE.gear.off` 換成那兩個值 |

之後:`STATES` 全部狀態用新畫法重匯(建議版目前只畫過 1、2、7;3–6、8–11 沒畫過,尤其 10 / 11 的虛線是關著的形狀,`T_OFF` 的 `:closed` 起點只在四角驗過);「安全建議版」那一段拿掉或改成「未選(保留參考)」(照規矩沒選的要留著、標清楚,先備份再改);`compareTable` 的兩塊對調主從;右欄要不要跟著改另外問 lead;跑 §2 三支必跑的腳本 + `clr.py`;對照段(`#cmp`)的說明補上新的不同。

**選 SF Pro**:

- `drawT` 裡 `variant === "sf"` 的判斷改成全部畫面都用 `numT(_, "sf")`(格位已經和主畫面一樣,不用動);`SF.cell = 60`。
- `km/h` 和 `P R N D` 現在還是 Hanken:要不要一起換成 SF 得問 lead;換的話 `unitT`、`gearsT` 也要走 SF 的量法(`putG` / `inkG` 寫死 Hanken),字高要重新對車主的圖。
- 格位沒變,虛線起點和 `tools/` 裡的圓底中心都不用改。
- 淨空:SF 排法全掃最小 10.0(18「三位數全掃」)。如果 `km/h`、`P R N D` 也換成 SF,或字級有動,要重掃。「—」的寬度(`TE.num.dash`)是照 Hanken 的字寬比例定的,可以不動。
- 頁面只能在 Apple 裝置上看到 SF;匯圖要在 Mac 上。和 iOS 上 SwiftUI 畫的可能差零點幾 px,app 做出來要再量。
- 備案 `LOWARC` 用 SF 沒量過。

**選 Hanken**:不用改頁面。提醒 lead:要把字型檔包進 app,用之前有人看一眼授權檔(我記得是 OFL,沒上網查過)。

**車主說「長弧」不是地平線**:這一頁是照「長弧 = 舊設計的地平線(`horizonX`)」畫的,所以整個沒畫;如果車主指的是別的(例如圓環最下面那段暗弧),回頭看參考圖再問 lead。

## 7. 還開著的事(照順序)

0. **lead 還沒回全掃的結果**:∓49° 是我取的(字面上的最小改動是 ∓49.5°);上下不對稱、離車主的圖 13.6 px 要不要接受、發佈的頁面要不要重發、ux / safety 要不要重驗,都等 lead。251–299 沒掃。
1. **等車主的三個選擇**(§6)。lead 會轉達;選完照 §6 改,改前把現在的頁面和圖備份(`stage1/`、`stage3/` 已經用掉,再開一個新的)。
2. **建議版如果被選**:前 / 後車廂關著時長得一樣(只靠左右)、未知時也分不出來,safety 說這一點還沒全結;胎壓「正常」沒有驚嘆號後像一個杯子。可能要再想形狀,先問 lead。
3. **沒畫的**:直式(390 × 844)、夜間調暗、充電中、停車時車門開著、GPS 備援(沒有車子資料時四格怎麼辦,brief 沒說)、超過自訂門檻的小錶(舊頁有,新圓裡沒放)。
4. **右欄和圓裡不一致**(胎壓低右欄紅、圓裡琥珀;車門列是舊圖示)。車主說兩邊之後再調。
5. **ux 提過沒裁定的四個小修**(§5 最後一行)。
6. **工具的限制**:`tools/` 的腳本是從 scratchpad 複製來的,路徑寫死成這台機器的絕對路徑、有的互相 import(`clr.py` → `ov.py`,`ov.py` → `ic1.py`),沒有整理成可以直接在 `tools/` 裡跑;要用時複製到新的 scratchpad、改掉舊 scratchpad 的路徑。虛線的 ≥ 2 px 只在「四角的格位、1 倍」驗過(18 階段 3 弱點 1)。

## 附:舊頁(只保留參考;上一版 handoff 的摘要)

- **`frames/speed-meter-icons.html`**(422 行,第二十二輪;檔頭標「未選(保留參考)」):14–65 CSS;67–76 HTML;78–221 從更舊的頁複製的零件(現在新頁的 85–228 行就是這一段);222–286 `ICONS`(八個照 Dashla 裁圖畫的圖示,座標 = 裁圖像素,`IK = 0.422 / 6`)和 `icon()`;287–334 這頁的常數(`K` 速度表座標、`RING` / `ROW` 兩種擺法、`topRow`、`thrTell` 門檻小錶、`gpsArr`、`tyreColK`);335–358 `drawScreen(layout, st)`;359–373 `STATES`(11 個)/ `DEMO` / `LAYOUTS`;376–397 圖示對照表;398–418 `build` / `fit`。參數 `?only=<ring|row>-<72|door|frunk|trunk|all|tire|unk|gps|park|park-door|park-charge>`、`?only=demo`、`?only=icons`;匯圖 `frames/speed-meter-icons/export.sh`;量到的值在 `15-center-stage-visual.md` 最上面「第二十二輪」。
- **`frames/prototype-speed-meter.html`**(1,600 多行,第十六到二十一輪的比較頁:甲到癸 + 子 + 辛直式,切換列、白車):車主說已經看不懂,不要再往裡面加版本。結構在 15 的「第十九輪」到「第二十一輪」;PNG 在 `frames/prototype-speed-meter/`。
- 新頁還在用舊頁的東西只有:左導航 `navX`、右欄 `tyreColX` + 舊 `icon()`、頁尾 `footX`、上排 `topRow`、`placeF`。要改這些先問 lead(車主說兩邊之後再調)。
