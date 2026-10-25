# 06 — 配對圖解調查:別人怎麼教「去哪裡找 / 放在哪裡」(visual)

> 2026-10-24。起因:老闆看了 `frames/pairing/S14-vin-guide.png`、`S16-key-card.png`,覺得「還不夠簡單清楚」。lead 要先調查再提案,不要直接重畫。提案頁:`docs/design/frames/pairing-guide-proposals.html`,PNG 在 `docs/design/frames/pairing-proposals/`。
> 編號注意:這份是設計資料夾的 06,不是市場研究的 `docs/market-research/06-risk-review.md`。
> 下面引用的網頁都是 2026-10-24 讀的;tesla.com 擋直接抓取,用 Internet Archive 存檔(標時間)。圖片是下載來看的,只寫描述,沒有放進 repo。

> **修訂 1(2026-10-24)**,照 lead 17:04 的檢查補出處,原本的句子就地改:
> - §4 取捨表:`PhaseAnimator`、`KeyframeAnimator` 補 Apple 開發者文件連結(兩個都是 iOS 17 起)。
> - §4 新增「圖上用到的事實和出處」:「控制 › 軟體」、其他 VIN 位置、兩代感應區、螢幕上按確認,連結都直接寫在這份,不再指到 `pairing-art.html`。
> - §6:VIN 位置、螢幕確認兩條補上手冊和 vehicle-command 的連結;Progressive 2011 年新聞補連結;eero 改寫成「連結 2026-10-24 回 502」+ 存檔沒有步驟圖、沒查證;刪掉沒有出處的「approximately January 2024」那一條。
> - 提案頁(`frames/pairing-guide-proposals.html`)同時改版面:「請老闆選」放最上面、筆電寬度看得完、C 用 1 → 2 → 3 三格靜態呈現;調查內容和建議沒變。

## 重點結論

- 一看就懂的例子都只做一件事:一張圖一個動作、一個強調、一兩句話(Apple、Nintendo、IKEA、Duolingo)。目前版本一張圖塞了兩步加一個目標(VIN 圖 52 個形狀)。
- 要點的東西要「長得像真的」:截圖裡是真的字(Settings › About、Serial Number),或直接畫出要找的那串號碼;灰條看不出是什麼。
- 實體動作(放卡、按按鈕)大家用箭頭或動畫;Tesla 自己的手冊就是灰階擬真圖加一組青色圈,舊款那張是循環動畫(卡片落下、青色圈閃,一輪約 11 秒)。
- 兩代感應區:Tesla 手冊分兩張圖,Tessie 也放兩張並標車款;Tesla 官網支援頁只寫一個位置(杯架後面),新款車主照做會放錯。所以要依車型給圖,另外留一個「不是這個位置?」。
- 我的建議:VIN 指南用 **A 一圖一事**(特寫、一步一張);鑰匙卡也用 A 的兩張特寫,**C** 的「卡片落下」動畫之後再加。B 工最多、高對比最難,也最像 Tesla 原廠圖,先不選。

## 1. 範例

| # | 產品・情境 | 圖的種類 | 元素 | 一步一張? | 動畫 | 強調方式 | 字 | 為什麼一看就懂 | 來源 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Apple Watch:開機鍵在哪 | 產品照(去背) | 手錶 + 1 個箭頭 | 是 | 無 | 一個藍色箭頭指著側邊按鈕 | 一句 | 只有東西本身和「按這裡」 | [Set up your Apple Watch](https://support.apple.com/en-us/HT204505) |
| 2 | Apple Watch:配對 | iPhone 鏡頭畫面 | 取景框 + 標題 + 一句 + 手動連結 | 是 | 錶面的粒子動畫給鏡頭讀 | 黃色取景框 | 「Hold Apple Watch up to the Camera」「Align it with the viewfinder above.」 | 鏡頭自己讀,不用學;讀不到才有「Pair Apple Watch Manually」 | 同上 |
| 3 | AirPods:第一次連線 | 產品 3D 圖,放在一張卡片裡 | 名稱 + 產品圖 + 一顆「Connect」 | 是 | 有(設定動畫) | 沒有,只有一顆按鈕 | 名稱 + 一顆按鈕 | 畫的是你手上的那個東西,只有一件事要做 | [Connect AirPods](https://support.apple.com/en-us/HT207010) |
| 4 | AirPods:序號在哪 | 產品照 + 放大鏡圓圈 | 充電盒 + 1 個放大圈,圈裡是假序號「Serial XX0Y12X3X4XX」 | 一個位置一張 | 無 | 放大鏡 | 一句(「on the underside of the lid」) | 全景說在哪,放大鏡說長什麼樣 | [AirPods serial number](https://support.apple.com/en-us/108041) |
| 5 | iPhone:序號 / IMEI | 螢幕截圖(只裁上半)、SIM 卡托線條圖 | 截圖只剩「About」幾行;卡托圖上直接印假號碼 | 一個位置一張 | 無 | 沒有額外記號,靠真的標籤「Serial Number」和裁切 | 路徑「Settings > General > About」 | 截圖裡是真的字,裁到只剩要看的那幾行 | [iPhone serial number](https://support.apple.com/108037?device-type=iphone) |
| 6 | Apple Pay:加卡 | 幾乎純文字 | — | 是 | — | — | iPhone:「Tap or hold your card close to your iPhone to add it.」;Apple Watch:「position your debit or credit card in the frame」;失敗就「Enter Card Details Manually」 | 能感應 / 能用鏡頭就不用教,手動是備援 | [Set up Apple Pay](https://support.apple.com/en-us/108398) |
| 7 | Tesla 車主手冊:Keys | 灰階擬真算圖 | 新款:中控台前段 + 一張卡 + 青色同心圓;舊款:循環 GIF,卡片約 1 秒落到杯架後面,停 1 秒,青色圈閃約 3 秒,再停住(54 格,一輪約 11 秒) | 一個位置一張 | 舊款有 | 一組青色同心圓(畫面其他都是灰的) | 一句位置 | 灰階讓唯一的青色跳出來;動畫示範「放下去」 | Model 3 [2017–2023](https://web.archive.org/web/20240808052433/https://www.tesla.com/ownersmanual/2017_2023_model3/en_us/GUID-E004FAB7-1C71-448F-9492-CACF301304D2.html)、[2024 起](https://web.archive.org/web/20250323032322/https://www.tesla.com/ownersmanual/model3/en_us/GUID-E004FAB7-1C71-448F-9492-CACF301304D2.html);Model Y [2020–2024](https://web.archive.org/web/20250228133433/https://www.tesla.com/ownersmanual/2020_2024_modely/en_us/GUID-E004FAB7-1C71-448F-9492-CACF301304D2.html)、[2025 起](https://web.archive.org/web/20250403001539/https://www.tesla.com/ownersmanual/modely/en_us/GUID-E004FAB7-1C71-448F-9492-CACF301304D2.html) |
| 8 | Tesla 官網支援頁:Tesla Vehicle Keys | 純文字,沒有圖 | — | — | — | — | 「For Model 3 and Model Y, place the key card on top of the center console behind the cup holders.」 | **反例**:只寫一個位置,和手冊的新款(手機充電板)不一致 | [美國 2026-02-17 存檔](https://web.archive.org/web/20260217003251/https://www.tesla.com/support/tesla-vehicle-keys)、[澳洲 2026-05-15](https://web.archive.org/web/20260515091057/https://www.tesla.com/en_au/support/tesla-vehicle-keys)、[香港 2026-04-15](https://web.archive.org/web/20260415102750/https://www.tesla.com/en_hk/support/tesla-vehicle-keys) |
| 9 | Tessie(第三方 Tesla app):卡片要感應哪裡 | 灰階擬真算圖兩張 | 新款:駕駛座看出去,整張壓暗,只有充電板上的卡片是亮的;舊款:側面視角,杯架後面一個藍色爆炸記號 | 兩張並排 | 無 | 亮度(卡片最亮)/ 一個記號 | 只有小標「Where to tap your key card for authorization」和圖說(「Older Model 3 and Model Y」) | 兩代各一張、各標車款 | [Phone & Watch Key](https://help.tessie.com/article/108-phone-watch-key) |
| 10 | GEICO:VIN 在哪 | 文字清單 + 一張裝飾照片 | 5 個位置 + 「Person sitting in a car」的照片 | 全部一頁 | 無 | 無 | 一段 | **反例**:照片沒有指任何位置;真正好用的是「You can scan the VIN barcode … with the GEICO Mobile app」 | [GEICO: VIN](https://www.geico.com/living/vin/) |
| 11 | Nintendo Switch:配對 Joy-Con | 主機畫面截圖 + 手把示意圖 + 線條手勢圖 | 每步 0–2 張 | 是 | 無 | 手把各部位名稱 | 每步 5–26 個英文字 | 截圖就是你電視上會看到的畫面 | [How to Pair Joy-Con](https://en-americas-support.nintendo.com/app/answers/detail/a_id/22416) |
| 12 | IKEA:無字說明書 | 黑白線條圖 | 每格一個階段 | 是 | 無 | 灰色只用在重點步驟 | 無字 | 先給成品;一格一階段;「測試的人不讀字也要能組好」才算過 | [Wordless Instructions(Justin Zhuang,2018-01-16)](https://justinzhuang.com/posts/wordless-instructions/) |
| 13 | Duolingo:開場 | 深色畫面 + 吉祥物 + 一句話氣泡 | 一題一畫面 | 是 | 吉祥物 | 進度條 | 「Just 7 quick questions before we start your first lesson!」 | 先說有幾步;一次一個決定 | [Duolingo Onboarding Design(ScreensDesign)](https://screensdesign.com/articles/duolingo-onboarding-design/) |

設計準則(原文):

- Apple HIG Onboarding:「When you have instructional content that refers to a specific area of the interface, display these instructions near that area.」;「if you try to teach too much, people can feel overwhelmed and may be less likely to remember what they learned.」([Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding);頁面要 JavaScript,讀的是同一頁的 JSON 資料)
- Apple HIG Motion:「Make motion optional. … avoid using it as the only way to communicate important information.」;「Aim for brevity and precision in feedback animations.」([Motion](https://developer.apple.com/design/human-interface-guidelines/motion))
- NN/g(Alita Kendrick,2020-06-21):「Instructional onboarding should not be used to supplement poor design.」;教學卡片要「limit the number of cards」、「one concept per card」。([Mobile-App Onboarding](https://www.nngroup.com/articles/mobile-app-onboarding/))

## 2. 原則(套到我們的兩張圖)

| # | 原則 | 依據 | 目前版本 | 提案怎麼做 |
|---|---|---|---|---|
| P1 | **一張圖只講一件事**:一個動作、一句話 | #1、#3、#11、#12、#13;NN/g「one concept per card」 | VIN 圖一張塞了「點車子圖示」「點軟體」「VIN 在這」三件事 | A:VIN 分 3 張;鑰匙卡 2 張小特寫。C:同一張圖分 3 格播 |
| P2 | **只畫要碰的那一塊**:裁切、放大鏡,或把其他壓暗 | #4、#5(裁切)、#9(壓暗) | 整個螢幕都畫,要點的車子圖示只有 20 px 寬 | A:特寫(車子圖示放大到 55 px 寬);B:全景壓暗 + 放大鏡 |
| P3 | **一個強調**:一個顏色、一個記號 | #1(一個箭頭)、#7(一組青色圈)、#12(灰色只給重點) | 三處青色(車子圖示的圈 + ①、軟體列 + ②、VIN 框),搶來搶去 | A:每張一個青色圈;B:VIN 一個圈 + 放大鏡、鑰匙卡一組圈 + 一個箭頭 |
| P4 | **畫得像使用者眼前看到的**:真的字、真的形狀、同一個視角 | #5(真的標籤)、#11(主機截圖)、#4(假序號) | 選單是灰條,看不出「軟體」;VIN 是一條灰條 | 圖上寫出「軟體」、畫出 VIN 的樣子(`5YJ3XXXXXXX000000`,假的);B 畫得像真的車內 |
| P5 | **字:一句、動詞開頭、放在圖旁邊;先說有幾步** | #2(一句)、#13(先說 7 題)、HIG「display these instructions near that area」 | 兩行說明 + 一行小字,和圖上的編號要自己對 | 每張圖下一句(「點螢幕左下角的車子圖示」);A 有 3 個點表示共三步 |
| P6 | **動作可以用動畫,但不能只靠動畫** | #7 舊款 GIF、#3;HIG「Make motion optional」 | 沒有動畫 | C:3 格循環;「減少動態」開啟時給有 ① ② 的靜圖 |
| P7 | **依車型給對的圖,選錯一鍵換** | #7(手冊分兩張)、#9(兩張標車款)、#8(反例) | 只畫舊款,新款車主會放錯 | 三個方向都照 lead「依 VIN 選圖」,再加「不是這個位置?」換成另一張 |
| P8 | **能用鏡頭就不用教;指南是備援,要短、能關** | #2、#6、#10(GEICO 掃條碼);NN/g「should not be used to supplement poor design」 | (指南本來就是 S14 的備援) | 指南開在右邊卡片,左邊鏡頭不關,看完直接對準;× 一下就關 |

## 3. 目前版本為什麼不夠清楚

數字是用 XML 數 `assets/pairing/*.svg` 的形狀(rect、circle、path 等):

- **VIN 圖 52 個形狀**:整個車子螢幕都畫了(左邊的車、8 列灰色選單、右邊的車和三條灰條、下方一排按鈕),要看的三個地方(車子圖示、軟體、VIN)在 320 × 200 裡各只有 15–20 px 高,車子圖示只有 21 px 寬。選單是灰條,圖上看不出哪一列是「軟體」,要靠旁邊的編號對。違反 P1、P2、P3、P4。
- **鑰匙卡圖 24 個形狀**:方向盤、儀表板、螢幕、對話框、兩個手機座、兩個杯架、扶手、波紋、兩個編號;感應區只有 82 × 28。只畫舊款。違反 P1、P2、P7。
- 好的地方要留:槍灰 + 青色只給要做的事、沒有字(可以翻譯)、有高對比版。三個提案都保留這幾點。

## 4. 三個方向

都用一樣的畫面殼(S14:左邊鏡頭 + 右邊「VIN 在哪裡?」卡;S16:左欄圖、右欄說明),只換圖和那一兩行字。圖都是 320 × 200。

| | A 一圖一事 | B 擬真全景 + 單一強調 | C 短動畫 |
|---|---|---|---|
| VIN 指南 | 3 張特寫翻頁:① 螢幕左下角(車子圖示放大 + 青色圈)② 選單只剩 4 列,「軟體」那列有字、有圈 ③ VIN 那一行 + 鏡頭取景角;每張下一句,第 3 張放其他位置的小字 | 像真的車子螢幕,整張壓暗,只亮 VIN 那一行 + 放大鏡;怎麼進來寫在圖上方的標籤「🚗 控制 › 軟體」 | 同一個簡化螢幕播 3 格:點車子圖示 → 面板打開、點「軟體」→ VIN 亮起;下面那句話跟著換 |
| 鑰匙卡 | 兩張小特寫並排:① 中控台那一格 + 卡片 ② 螢幕上的確認按鈕 | 駕駛座看出去的車內,只有卡片那一處亮,一組青色圈 + 一個箭頭;確認那一步只寫在右邊 | 卡片落到感應區 → 青色圈擴散 → 螢幕確認按鈕亮起、被點一下;右邊 ① ② 跟著標 |
| 形狀數(一張圖) | 每張 12–14(含底框);鑰匙卡兩張共 20 | VIN 52(大多壓暗)、鑰匙卡 22 | VIN 50(每格只看得到一部分)、鑰匙卡 21 |

圖上用到的事實和出處(三個方向共用;tesla.com 手冊都是 Internet Archive 存檔,2026-10-24 讀):

- **「控制 › 軟體」**(A 第 1、2 張,B 的路徑標籤,C 第 1、2 格):手冊 Identification Labels「You can find the VIN at the following locations: Touch Controls > Software on the touchscreen.」,Model 3 [2024 起](https://web.archive.org/web/20260118142730/https://www.tesla.com/ownersmanual/model3/en_us/GUID-B27A666D-866B-4766-B690-CCD1B66E2134.html)、[2017–2023](https://web.archive.org/web/20251111173050/https://www.tesla.com/ownersmanual/2017_2023_model3/en_us/GUID-B27A666D-866B-4766-B690-CCD1B66E2134.html),Model Y [新款](https://web.archive.org/web/20260209002111/https://www.tesla.com/ownersmanual/modely/en_us/GUID-B27A666D-866B-4766-B690-CCD1B66E2134.html)、[舊款 2024-03 存檔](https://web.archive.org/web/20240301145717/https://www.tesla.com/ownersmanual/modely/en_us/GUID-B27A666D-866B-4766-B690-CCD1B66E2134.html)。「控制」是底部列最左邊的車子圖示,見 Touchscreen 頁的總覽圖(Model 3 [2024 起](https://web.archive.org/web/20250331233222/https://www.tesla.com/ownersmanual/model3/en_us/GUID-518C51C1-E9AC-4A68-AE12-07F4FF8C881E.html) 第 5 項、Model Y [舊款](https://web.archive.org/web/20240301075813/https://www.tesla.com/ownersmanual/modely/en_us/GUID-518C51C1-E9AC-4A68-AE12-07F4FF8C881E.html) 第 4 項),同頁「The Controls screen appears over the map.」
- **其他 VIN 位置那一行小字**(A 第 3 張、B、C 的說明卡):擋風玻璃和車門邊來自同一頁 Identification Labels「Stamped on a plate located at the top of the dashboard. Can be seen by looking through the windshield.」「Printed on the Vehicle Certification label, located on the door pillar. This can be seen when the driver's door is open.」([Model 3 2024 起](https://web.archive.org/web/20260118142730/https://www.tesla.com/ownersmanual/model3/en_us/GUID-B27A666D-866B-4766-B690-CCD1B66E2134.html));「Tesla app」「行照」來自裁定 L63(`docs/design/00-rulings.md`),Model 3 / Y 手冊沒有列 Tesla app。
- **兩代感應區**:見 §1 #7 的四個手冊連結。
- **螢幕上按確認**:見 §6 第二條。

取捨(lead 要的四欄):

| | 清楚度 | SwiftUI 工時 | 無障礙(大字、高對比、減少動態、讀屏) | 兩代感應區 |
|---|---|---|---|---|
| **A 一圖一事** | **最高**:每張只有一件事;要點的字直接畫出來 | **低**:5 張小向量圖(VIN 3 + 鑰匙卡 2,新款再多 1)+ 原生文字;VIN 多一個翻頁 | 好:讀屏一次唸一步;大字時特寫不縮,說明捲動;沒有動態;高對比只換中性色 | 只換第 ① 張特寫;選錯的代價最低 |
| **B 擬真全景** | 高:一眼認得出「這是我的車」;但全景裡的東西還是小,要靠壓暗和放大鏡 | **高**:漸層、陰影、遮罩;實際上最好請插畫或 3D 出圖,高對比要另出一套 | 中:擬真圖在高對比下難調;壓暗的部分對比本來就低(只當背景);沒有動態 | 要兩張完整的擬真圖,選錯的代價最高 |
| **C 短動畫** | 高:動作一看就懂、順序自己會播;但要等它播到那一格 | **中高**:iOS 17 的 [`PhaseAnimator`](https://developer.apple.com/documentation/swiftui/phaseanimator) / [`KeyframeAnimator`](https://developer.apple.com/documentation/swiftui/keyframeanimator)(Apple 文件標 iOS 17.0 起)做 3 格,外加一張靜圖;參考圖測試要逐格凍結 | 「減少動態」要有靜圖(就是有編號的那張);讀屏唸三句;動畫不能是唯一的說明(HIG) | 兩套動畫,其實只換卡片落點;靜圖也要兩張 |

兩代感應區(三個方向都一樣):舊款(2017–2023 Model 3、2020–2024 Model Y)在杯架後面;新款(2024 起 Model 3、2025 起新款 Model Y)在手機無線充電板上(#7)。照 lead,app 用 VIN 選圖;另外都留一個「不是這個位置?」一點就換成另一張,年份和車款世代對不上時(例如換代前後同年份的車)不會卡住。右欄第 ① 句也跟著車款寫(「把鑰匙卡放在杯架後面」/「把鑰匙卡放在手機充電板上」),取代 01 原本的「感應區位置依車型年份不同,請參考車主手冊」。

## 5. 建議

- **VIN 指南:A。** 兩次點擊最適合一步一張;「軟體」和 VIN 的樣子直接畫出來,P4 做得最好;工最少。
- **鑰匙卡:A 的兩張特寫**,之後再加 **C** 的「卡片落下」當加分(Tesla 手冊的舊款也是這樣做,#7)。
- **B 先不選**:最像真的,但工最多、高對比最難,而且灰階擬真 + 青色圈就是 Tesla 手冊的畫法(#7),容易被看成原廠圖。真的要做,不能放 logo、方向盤畫圓的(不畫 yoke)、卡片沒有字。
- 這是 visual 的建議,由 lead / 老闆定。選定後再出正式 SVG(含 `-hc`)和對應的英文。

## 6. 假設、待確認、沒查到

**沿用上一版的待確認(每個方向都會用到)**:

- VIN 在「軟體」頁車名 / 車型下面:照 lead 的描述;手冊只寫「Touch Controls > Software > Name Your Vehicle located on the right side of the touchscreen below the image of Model 3.」([Touchscreen,2017–2023 Model 3,2024-12-04 存檔](https://web.archive.org/web/20241204091304/https://www.tesla.com/ownersmanual/2017_2023_model3/en_us/GUID-518C51C1-E9AC-4A68-AE12-07F4FF8C881E.html)),沒有那一頁的圖。
- 「在車子螢幕上按確認」:手冊寫的是 Tesla 自己的加鑰匙流程(Controls > Locks > Keys > Add Key,再刷一張已配對的卡確認,[Keys,2017–2023 Model 3,2024-08-08 存檔](https://web.archive.org/web/20240808052433/https://www.tesla.com/ownersmanual/2017_2023_model3/en_us/GUID-E004FAB7-1C71-448F-9492-CACF301304D2.html));第三方 app 加鑰匙時,vehicle-command 只印出「Confirm by tapping NFC card on center console.」([commands.go](https://github.com/teslamotors/vehicle-command/blob/main/cmd/tesla-control/commands.go)、[tesla-control README](https://github.com/teslamotors/vehicle-command/blob/main/cmd/tesla-control/README.md):「confirm the new key by tapping your NFC card on the center console」,2026-10-24 讀),都沒寫螢幕上要按確認。依據是裁定 L67 和車主 2026-10-23 實測。
- 車子介面的中文是不是「軟體」、「控制」:沒有實車確認。A、C 圖上會直接寫「軟體」,錯了要改;車子介面用英文時改寫 Software。
- VIN 年份 → 感應區世代:照 lead 說可以從 VIN 判斷;換代前後同年份的車沒查證,所以留「不是這個位置?」。

**這輪的假設**:

- VIN 樣子用 `5YJ3XXXXXXX000000`(17 碼,前 4 碼像 Tesla,其餘明顯是假的,學 Apple 的 `XX0Y12X3X4XX`)。
- 指南仍開在 S14 右邊的卡片,左邊鏡頭不關(P8)。01 還沒有第十一輪的 S14,版面以 ux 補的 01 為準。
- 提案的圖寫在提案頁裡(示意),沒有出成正式 SVG;選定後再做。

**沒查到 / 沒採用**:

- Philips Hue(按橋接器按鈕)、Carfax 的 VIN 位置圖、Root / Lemonade / Progressive 的 VIN 說明頁:沒找到官方頁面或圖,不列。Progressive 的「VIN Capture」(用手機拍 VIN 條碼)只找到 2011 年的新聞:[Insurance-Canada.ca,2011-07-25](https://insurance-canada.ca/2011/07/25/progressives-new-mobile-services-put-car-insurance-in-the-palm-of-your-hand/)「Now customers can simply take a picture of a car's Vehicle Identification Number (VIN) bar code」;現在的 app 是不是還有,沒查證。
- eero 的設定步驟圖:說明頁 `https://support.eero.com/hc/en-us/articles/207937603` 會轉到 eero.com,連結 2026-10-24 回 502;Internet Archive 有舊網址的[存檔(2025-07-08)](https://web.archive.org/web/20250708233938/https://support.eero.com/hc/en-us/articles/207937603-How-do-I-set-up-eero),但只有文字(「Our app will walk you through the process and do most of the heavy lifting」),沒有步驟圖。「每一步都有圖」這個說法沒查證,不列。
- App Store 截圖沒有逐一看;Tesla app 裡「設定手機鑰匙」那一頁的樣子沒有查到。
