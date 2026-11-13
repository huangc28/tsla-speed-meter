# lead 交接:速度表設計(ATELIER / Center Stage),2026-11-13 更新

**最新在這裡(2026-11-13,第二十四輪,L102)**:車主選好了。安全建議版四點全採用、數字 Hanken Grotesk、長弧 = 地平線(對)、**圖示排列改用「下弧」**、頁尾「總里程」改 ODO。知識庫那一條車主沒回答(= 沒同意,不寫,回報時再問一次)。

- **車主滿意這一版(2026-11-13,L103)**:「這版 ui 滿意…接著往下微調」。基準 = 頁面 `218482e6`(發佈第 3 版),原樣存在 `frames/atelier-tesla-edition/stage5/`(含 `approved-2026-11-13.sha1`)。多改的兩處(前後車廂填滿、車門加長)算車主接受。**微調項目等車主點名,不要自己挑;要不要 commit 已問車主,沒回答前不 commit。**
- **現在的頁面**:`frames/atelier-tesla-edition.html`(同一個檔、同一個網址 https://claude.ai/artifact/7ZXxShuz3vMj7Zx7unsxTA;發佈方法同下)。最上面是主畫面十一個狀態(`main-01…11`):下弧的格位(前車廂 −117°、車門 −159°、後車廂 +159°、胎壓 +117°)+ 建議版 + Hanken。四角、照圖的畫法、SF Pro、選之前的下弧三張都在最下面的 `<details>`「未選(保留參考)」。上一輪的頁面和圖在 `frames/atelier-tesla-edition/stage4/`。
- **審查後 lead 多裁的六條**(`00-rulings.md` L102、board 2026-11-13):關著的前後車廂加車頭 / 車尾的實心記號、開著的車門加長(這兩個車主的圖上沒有,要跟車主說)、狀態 9 的字上移到「—」下面 12、虛線實線段加長、頁面文字、候選 `alt-*` 不放頁面。
- **量到的**:淨空 0–250 全掃最小 10.4(尾數 2 的三位數對胎壓),visual 和 safety 各算一次;圓底沒移。虛線 1 倍最小 2 px。關著的前後車廂 1 倍差 63–67 個像素;車門開對關 13–15 個(四個裡最小)。
- **Hanken Grotesk 授權**:SIL OFL 1.1(lead 看了 google/fonts 的 `ofl/hankengrotesk/OFL.txt`),可以包進 app,要附授權文字。
- **規範** `DESIGN-atelier-tesla-edition.md` 已改成車主選的版本,仍是 DRAFT、不取代根目錄 `DESIGN.md`。
- **還開著**:狀態不明時前後車廂只靠位置;251 以上、瞄一眼實測、上車驗證、色弱模擬;右欄(和圓裡重複、胎壓低是紅的)、停車畫面、直式、左右面板、音樂卡;規範要不要取代 `DESIGN.md`;`PRODUCT.md` 的 Platform 一欄;知識庫候選。
- **團隊**:三位都在 tab「design team 速度表」。visual、safety 這一輪都重開過(safety 重開兩次),ux 約 25%。重開 codex 前先送 ctrl+u。

---

(以下是 2026-11-12 寫的。「等車主選」那幾題已經答完;其他背景仍然有效。)


**最新在這裡(2026-11-12)**:車主說「之前討論的速度表設計先放掉」,自己做了兩張新圖,問能不能用 impeccable 從這兩張圖開始做設計規範。**下面 2026-11-10 的內容(第二十二輪新頁、四個問題、辛 / 子基底)全部退為保留參考,四個問題不用再問。**

- **新圖**(車主的,當 brief):`docs/design/frames/atelier-tesla-edition/reference/dashboard-2026-11-12.png`(1774 × 887,儀表畫面)、`icon-system-2026-11-12.png`(1536 × 1024,圖示規範表)。
- **impeccable 的走法**(lead 讀過 `init.md`、`document.md` 含 Seed mode、`new-work.md`、`mode-operate.md`):`init` 只寫 `PRODUCT.md`(已經有;缺 Platform 一欄,impeccable 會當成 web,要補 `ios`)。`document` 預設是掃現有程式,會寫出現在 app 的雙翼。新的視覺走 new-work(車主釘住的方向優先,不用抽方向),有兩步:**現在可以先寫一份「種子」規範**(`document --seed`:只寫世界觀和不變的原則,不寫色碼尺寸,檔頭標 SEED);**第一個畫面畫出來之後再掃一次,補上真正的數值**。速度表屬於 Operate,照 impeccable 是直接用程式畫(code-led),不走「圖是量過的合約」那套關卡;但車主看的是像不像參考圖,所以我們照舊用量的。根目錄 `DESIGN.md` 是現在 app 的規格、`DESIGN_v2.md` 是車主的檔,都不能沒問就蓋掉(`document.md` 也規定要先問)。
- **量到的**(儀表圖縮到 844 寬 = ×0.4758):畫面比例 2:1,縮完高 422,比 iPhone 橫式 390 多 32;底色 `#070B11`;圓環半徑 144、中心 (421.6, 193.7);數字「86」高 72.8、寬 106、直筆約 10.5–13;`km/h` 高 12.8;`P R N D` 高 10.5(亮 `#FFFFFF`、暗 `#636871`);圖示圓底直徑約 37、圖示墨跡寬 20–26;速限牌直徑約 44;開門紅最飽和點 `#FC413B`、胎壓琥珀 `#FEA82A`;圓底填色約 `#181F26`。
- **三位數可能放不下(估的,第一張圖畫出來再確認)**:左右兩顆圖示圓底之間約 167 寬;照「86」的字寬推三位數約 162,兩邊各剩 2 到 3,遠小於「離數字墨跡 ≥ 9」。有「1」的數字會窄一點。圖上只畫了 86。
- **規範表的色碼**:圓底那格印成 `#1822BE`(鮮藍),色塊量到 `#17222A`,應該是 `#18222B` 打錯。其他色碼 lead 只粗量過(取色塊中心和最飽和的一點),**不足以說表和圖對不上**;要用的時候請 visual 好好量線條的中位色。上一行的紅和琥珀也是最飽和的一點,只能當參考。
- **兩張圖互相不一樣**:方向盤圖示(12 點鐘)只有規範表有;駐車圖示儀表圖是「(P)」帶括弧、規範表是圈 P;規範表「Active / On」那一列有五個和「Off」看不出差別。
- **資料對照**(這次讀了 `TeslaBLE/Generated/*.pb.swift`):
  - 有:車速、檔位、車門、前後廂、胎壓、電量、續航、里程、車外溫度(停車時才更新)。
  - **協定裡有、app 還沒讀、沒上車驗過**:音樂(歌名、歌手、進度、長度、播放狀態;也有上一首 / 下一首 / 播放的指令)。之前寫「沒有音樂」要更正成「還沒接」。送指令是新能力,而且開車中操作和 L98(停車才能操作)衝突。
  - 沒有:道路速限(協定裡的 `SpeedLimitMode` 是車主自己設的限速上限,不是路上的速限)、自動輔助(方向盤)、車道輔助、駐車煞車(只有檔位 P)、天氣圖示。右上角的訊號、Wi-Fi 是手機的東西,沒查。
- **圖上沒畫、不能自己編的**:狀態不明(L87 虛線)、沒有有效車速、停車畫面、三位數、直式、充電中、GPS 備援。
- **車主 2026-11-12 回答了(第二十三輪,brief `00-brief-tesla-edition.md`)**:① 沒資料的四個圖示現在拿掉,以後有硬體再做;剩前車廂 / 後車廂 / 車門 / 胎壓,**重新分佈要平均好看**。② 只做速度表和圖示,**拿掉下方的長弧**(lead 解讀成舊設計的地平線),左右資訊區先留舊設計。③ 兩張圖不一樣的以儀表圖為準。④ **圓放大到三位數放得下,圓的大小固定**。音樂卡這一輪不做。
- **第二十三輪做完了(L101)**:新頁 `frames/atelier-tesla-edition.html`(`3935c990`,發佈第 2 版),發佈在 **https://claude.ai/artifact/7ZXxShuz3vMj7Zx7unsxTA**(發佈時 `root` = `docs/design/frames`,帶 `atelier-tesla-edition/reference/crop-gauge.png` 和四張 `crop-<frunk|trunk|door|tire>@6x.png`;重發同一個檔就保留網址)。圖在 `frames/atelier-tesla-edition/`(`corner-01…11`、`safe-01/02/07`、`font-*`、`arc-*`、`sheet.png`、`tools/`、`export.sh`;階段 1 備份在 `stage1/`)。報告 `18-tesla-edition-visual.md`(visual)、`19-tesla-edition-critique.md`(ux)、`20-tesla-edition-safety.md`(safety,複驗後沒有新增問題)。規範 `DESIGN-atelier-tesla-edition.md` 已補量到的數值(不取代根目錄 `DESIGN.md`)。
- **畫成什麼**:圓心 (422, 172) 半徑 156,所有狀態同一個;四個格位永遠畫(前 / 後車廂 ∓49°、車門 / 胎壓 ∓124°,9 點和 3 點空著);三位數 100–250 全掃淨空最小 9.5(上排原本照圖 ∓56°,尾數 7 / 5 / 4 的數字只剩 1.0–6.7,lead 補查才發現,所以上移約 14;251 以上沒掃);刻度細 0.8 補滿一圈;數字 Hanken Grotesk 500 置中;地平線拿掉;上排時間移到左邊;底色改成車主圖上的藍黑。頁面順序:和車主的圖對照 → 主畫面十一個狀態(照圖)→ 安全建議版(狀態 1、2、7 左右並排)→ 字型比較 → 圖示對照 → 備案下弧。
- **等車主選**:① 照他的圖,還是安全建議版(四項可以分開選:關著的圖示換形狀、前車廂蓋子畫在車頭、圓環的紅和琥珀改藍白、關著調暗 + 沒選到的檔位調亮);② 數字字型 Hanken Grotesk(最像圖,要包進 app,授權檔要有人看一眼)還是 SF Pro(內建,比較寬,上排圖示移到 ∓52°);③「下方的長弧」= 地平線這個解讀對不對;④ 規範以後放新檔還是取代 `DESIGN.md`。
- **弱點(要跟車主說)**:主畫面照圖 = 開關只差顏色、前後車廂圖示幾乎一樣、圓環的紅和琥珀緊鄰狀態色、沒選到的檔位對比 2.9:1(safety 列為要改,所以才畫建議版);建議版關著的前後車廂長得一樣只靠左右分、關著的胎壓像杯子;三位數淨空只多 0.5;右欄的車門列和圓裡的圖示重複(車主說兩邊之後再調);瞄一眼實測和上車驗證沒做;停車畫面只有 P 和 0;直式沒畫。
- **過程中的事**:safety 重開時 Codex 自己跑了一次 npm 更新(lead 沒有要它更新,之前的規矩是跳過更新),要跟車主說;ux 中途用量到上限,等到 19:50 自動繼續。
- `.llm-wiki/` 學習候選要改:車藍牙沒有速限、自動輔助、車道輔助、駐車煞車;**音樂在協定裡有、未驗證**。等車主批准才寫。
- 團隊:三位都在 tab「design team 速度表」,這一輪都重開過一次(交接:`handoff-visual-speed-meter.md`、`handoff-ux-speed-meter.md`、`handoff-safety-speed-meter.md`)。visual 輪末約 49%,已請它重寫交接,下個任務前重開;ux、safety 各做了一到兩個任務,長任務前先看 context。重開 codex 時 pane 裡殘留的字會讓指令打壞,先送 ctrl+u 再 `herdr agent start`。

---

(以下是 2026-11-10 晚寫的。**設計內容**退為保留參考;但**規矩照舊有效**:什麼都沒 commit、commit 前要問、車主自己的檔不動、關 tab 前要問、團隊表和重開參數、車主的習慣。)

**最新在這裡(2026-11-10 晚,第二十二輪,L100)**:車主要把 Dashla 式的圖示放到子上、不要再硬塞白車,而且**畫在新的一頁**。

- **新頁**:`docs/design/frames/speed-meter-icons.html`,發佈在 https://claude.ai/artifact/XbEiqgfdJZmQTBF1F2jY1C(發佈時要帶 `speed-meter-icons/reference/crop-*@6x.png` 八張,`root` = `docs/design/frames`)。圖和 `export.sh` 在 `frames/speed-meter-icons/`;車主的 Dashla 截圖和裁圖在 `reference/`;ux 的批評裁圖在 `critique/`。
- **之後車主看的是這一頁**。舊比較頁(下面第 1 節那張表、v11)只保留參考,不要再往上加東西。
- 新頁的內容:圖示對照(Dashla 裁圖 vs 我們畫的)→ 兩種擺法(環位 / 一排)11 個狀態並排 → 一張示範(速限、紅綠燈、方向盤、駐車,車子沒給資料)。白車開車、停車都不畫;未知 = 同形狀灰色短線段虛線(只畫前車廂 / 車門 / 後車廂)。
- **等車主回答**:① 白車兩種畫面都不畫,對不對(lead 的解讀);② 環位還是一排(ux、safety 都建議一排);③ 胎壓低用紅還是 Dashla 的琥珀;④ 圖示大小(現在照 Dashla 原大小,配我們比較小的數字偏大;ux 建議縮 0.88)。
- 已知弱點:未知的虛線在實際大小只認得出「有三個灰色虛線圖示」,前後廂分不出來,靠右欄的字;圖示和 Dashla 截圖疊起來輪廓差最多約 0.5–0.6 px。
- safety 這一輪:0 個不能上路、1 個要改(未知虛線,修完已複驗結案)、2 個小的(示範圖警語已結案;圖示高度照 Dashla 比例,lead 接受)。ux 的批評都裁了(board 上 11 條 + 3b)。瞄一眼實測、上車驗證還沒做。
- `.llm-wiki/` 學習候選(等車主批准):車藍牙沒有速限、紅綠燈、自動輔助、駐車 (H) 這四種訊號(加上之前的「沒有下一個路口」)。
- 下面第 3 節「子還沒裁的」1–4 已被 L100 取代(不跳、沒有膠囊、新圖示、虛線未知);5(直式)、6(瞄一眼實測)還開著。
- 團隊:三位都還在 tab「design team 速度表」。visual 這一輪後 context 約 58%,已請它重寫 `handoff-visual-speed-meter.md`,**下個任務前先重開**;ux 約 40%、safety 做了兩個任務,下個長任務前也重開。visual 的 `rm -f "$f"` 會被安全提示擋住(lead 不替車主按同意,等它自動取消),提醒它刪檔用寫死的路徑。

---

(以下是 2026-11-10 下午寫的,除了上面說被取代的部分都還有效。)

## 2026-11-10 下午的交接

給下一個 lead session。車主 2026-11-10 說「太發散了」,**基底只留辛和子**,從這兩個繼續(L99)。這份只寫下個 session 要知道的,細節看連到的檔。

## 1. 現在的基底

| 版本 | 網址參數 | 是什麼 | 主圖 |
|---|---|---|---|
| 辛 Center Stage | `?variant=h`(橫 844 × 390) | 車主選的排法:導航左、速度 + 白車中、胎壓 + 車門右、電量 / 里程頁尾 | `frames/prototype-speed-meter/atelier-compare-h.png` |
| 辛 直式 | `?variant=hv`(直 390 × 844) | 照 ChatGPT 交接包的直式:上卡輪播(停車才能翻,L98)/ 核心 / 下卡導航 | `atelier-compare-hv.png` |
| 子 停車看車 | `?variant=k`(橫;`&park=1` = 停車畫面) | 車主看完壬癸後的合成:**開車不畫白車**(門沒關好 → SF Symbols 小圖示放弧內,數字維持大小往下 28);**停車(P)數字換成白車**(188、車下膠囊、右欄只剩胎壓);只看檔位切換 | `atelier-compare-zi.png`、`icons-zi.png` |

比較頁:`docs/design/frames/prototype-speed-meter.html`,發佈在 https://claude.ai/artifact/8DdjFeMAGXuFVLSxYv7TjB(v11)。甲到庚、壬 `i`、癸 `j` 都是**未選(保留參考)**,頁面上不刪(車主的規矩)。備份在 `frames/prototype-speed-meter/v1/`…`v11/`。

## 2. 哪個檔管什麼(車主說文件亂,照這份就好)

**畫的時候看的圖**(都在 `docs/design/atelier-center-stage-v2/`,車主從 ChatGPT 匯入的包):
- 橫式排法:`references/approved-horizontal-reference.png`(車主自己提供,**說了算**)。
- 直式排法:`references/recovered-rollback.png`(中文那張,包裡說是直式正本);`boards/atelier-vertical.png` 是同一張的英文板。
- 直式各區高度:`DESIGN-HANDOFF.md` §Portrait references。
- 包裡其他的(生成的橫板、1194 × 597 的數字、`assets/` 的車 PNG 只有關門)**沒拿來畫**。

**車、數字、弧的畫法**:第十七輪照 `docs/atelier-reference.png`(DESIGN_v2 那張)量出來的己 / 庚程式(`carF`、`drawF`),辛 / 子沿用。`DESIGN.md`、`DESIGN_v2.md` 只當背景。

**規矩**:
- `00-rulings.md` L90–L99(速度表這幾輪)+ 歷來安全規則:開著 = 紅;狀態不只靠顏色;未知 = 同形狀虛線(L87);開車畫面只有車速和目前檔位用主字色;其他東西離數字墨跡 ≥ 9;停車才能操作(L98);數字高 ≥ 105 / 直筆 ≥ 9 對辛 / 子**暫時放寬**(L97,上車驗過再定)。
- `atelier-center-stage-v2/PROJECT-READ-FIRST.md` 只拿它的邊界:資料只有車藍牙給的(速度、檔位、電量、續航、門 / 前後廂、胎壓整數 psi、里程、導航四項:目的地 / 剩餘分鐘 / 剩餘 km / 抵達電量;**沒有轉彎、沒有音樂**);充電狀態有(`ChargingState`)。

**工作文件**(`docs/design/`):
- brief:`00-brief-center-stage.md`(第十八到二十一輪,一輪一段)。
- 摘要:`00-summary-atelier.md`(每輪補記)。board:`team-board.md`。
- 成員報告:`15-center-stage-visual.md`(visual,最上面是最新一輪)、`16-center-stage-critique.md`(ux)、`17-center-stage-safety.md`(safety)。
- 成員交接:`handoff-visual-speed-meter.md`(頁面程式結構、加整頁版本要動哪幾處、量的工具)、`handoff-safety-speed-meter.md`。
- 圖示:`frames/sf-symbols/`(lead 匯出的 Apple SF Symbols 俯視開門圖示 + README;授權只限 Apple 平台)。

## 3. 子還沒裁的(下個 session 先問車主或裁)

1. P ↔ D 切換時 `P R N D` 和弧**跳 28**,還是白車縮到 161 不跳。
2. 前 / 後行李廂圖示:visual 補畫的俯視版,還是 SF 側視版(`icons-zi.png`)。
3. 開車畫面的「未知」用淡色四門圖示(#A6ACB5)代替 L87 的虛線(SF PNG 畫不了虛線)→ 要 safety 看。
4. 「3 處開著」長膠囊離地平線只有 4。
5. 子的**直式**還沒畫(辛直式 `hv` 是基底,子的開車 / 停車邏輯要套上去)。
6. ux / safety 第二十、二十一輪都沒出動 → 子定案後一起審(0.3 秒瞄一眼實測、S17-02 也還開著)。

## 4. 其他還開著的

- Dashla 的指示燈 / 元素清單:車主會照自己的設計規範列,之後再擺。
- 直式要不要進 app(app 目前只做橫式)。
- 上車驗證數字大小(L97)。
- `.llm-wiki/` 學習候選沒批准(車藍牙沒有下一個路口)。
- **什麼都沒 commit**(車主的規矩:commit 前要問;`.gitignore`、`tsla-speed-meter.pen`、`DESIGN_v2.md`、`docs/atelier-reference.png`、`atelier-center-stage-v2/`、`handoff-visual.md` 是車主自己的檔,不要動也不要提交)。

## 5. 團隊(herdr tab「design team 速度表」)

| 成員 | kind | pane | 狀態 |
|---|---|---|---|
| visual | claude | `wH:p17` | 2026-11-10 重開過一次(交接在 `handoff-visual-speed-meter.md`),第二十一輪後 context 約 50%,下個長任務前先自我交接 + 重開 |
| ux | claude | `wH:p16` | 第十九輪後閒置 |
| safety | codex | `wH:p18` | 第十九輪後閒置;重開參數 `--search -a never -s workspace-write`;出現更新提示按 esc 跳過(不裝更新) |

**關 tab 前要問車主。** `wH:p19` 不是我們的,不要動。Claude 成員重開參數:`--permission-mode auto --append-system-prompt-file docs/design/roles/<name>-speed-meter.md -n <name>`。`herdr agent prompt` 不吃 `--no-focus`。

## 6. 車主的習慣(照做)

短的、白話的繁中報告,不要行話和編號;「全部做完再說」= 一份報告;`/bro` = 太技術了,重講;看設計看的是**像不像參考圖**(量,不要用講的);設計在 HTML 上改,不用 Pen;沒選的版本留著標「未選(保留參考)」;重畫前先備份;commit 前問。
