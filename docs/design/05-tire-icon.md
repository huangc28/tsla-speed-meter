# 停車胎壓俯視圖

## 第七輪修訂

2026-10-20，**L46 對齊修訂**：以 01 §2.3／§6.2 及 03 R7-14–R7-18 為準，15 分鐘內新鮮、超過才算舊；共用時間改為六種情況，只有舊值／時間未知的輪子變暗，大字清單補可縮放的輪位名稱。四輪缺值改顯示「尚無讀值 / No readings yet」。重新自查並覆寫本輪 `r7-*.png`，新增混合已知時間、只有收到時間與天數範例，共 **102 張**。

本輪延續 L42 的整數 psi、四角無引線、放大車圖與面板移除免責說明；保留 L40 的實色字底板、確認不支援判斷及 L41 的 CustomPainter 做法。老闆依 L49 選定速度表 C，搭配陶瓷車身；R6-10 的調暗由 visual 在稿裡用車圖濾鏡做，玻璃／陶瓷 SVG 不改。共用時間改用獨立 12–18 pt，維持最多兩行；大字清單只捲四輪列，標題與時間留在上方。

本機 Chrome 前次預檢以 134 退出，本次沿用共用模型、內附 TTF 和 `rsvg-convert` 匯出 2× PNG，未重試 Chrome，也不是 Chrome 截圖。舊 68 張 PNG 留存，不作本輪畫面依據；第一版 84 張 r7 圖已全部覆寫為 L46 版。

## 重點結論

- 每輪只有整數 psi 或 `—`；固定版不寫輪位，大字清單與讀屏寫輪位。
- 保留四角與車圖尺寸；數字 19 pt、單位 12 pt，數字和單位不拆行。
- 共用時間依六種情況聚合，只算有值輪；無車子量測時間一律未知，收到時間無效。
- 舊值／未知輪逐輪變暗，新鮮值不暗；亮度比 2.98:1，文字底板保留。
- 720 組模型／字型檢查通過，102 張新 PNG 已交付；Chrome／Flutter 實機仍待驗收。

## 1. 依據與交付

優先順序為第七輪 **L46**、01 §2.3／§6.2 與 03 R7-14–R7-18，其次 L42、L40、L41 與其他未被取代的裁定。L46 與本次指示已取代 01 尚未更新的「四輪缺值沒有共用行」；英文採本次指定的複數 `No readings yet`。只在停車畫面顯示，C03 未過或來源單位不明時整區留空。

| 檔案 | 本輪用途 |
|---|---|
| [tire-icon.html](frames/tire/tire-icon.html) | 單檔離線預覽，內嵌 Inter 600／Noto Sans TC 400、兩款車圖、共用模型與 DOM 自查 |
| [car-glass.svg](frames/tire/car-glass.svg)、[car-ceramic.svg](frames/tire/car-ceramic.svg) | 既有玻璃／陶瓷車身與舊三個相容 SVG 均未改 |
| [export-pngs.sh](frames/tire/export-pngs.sh)、[export-pngs.py](frames/tire/export-pngs.py) | 102 張 2× PNG；SVG 模式以共用模型和實際 TTF 量測，Chrome 模式另執行 DOM 自查 |
| [r7-export-audit.json](frames/tire/r7-export-audit.json)、[r7-spec-audit.json](frames/tire/r7-spec-audit.json) | PNG 檔名／版型量測，以及 L46 規格檢查紀錄；明示瀏覽器驗證限制 |
| `r7-*.png` | 第七輪 L46 有效預覽；368 × 576／330 × 544／560 × 576 |

入口：`tire-icon.html?state=fresh&size=184&lang=zh`。`size=165/184/280`；`lang=zh/en`，兩語固定 psi；`style=glass/ceramic`。舊 `contour/wireframe/sculpted` 查詢映射 glass/ceramic/ceramic。`scale=1/1.1/1.3/1.5/2` 檢查五種縮放，`xl=1` 相容 150%，不強制清單；`end=1` 捲到四輪清單尾端。`await window.tireReady` 後可執行 `window.tireAudit()`，或用首頁「檢查排版」。

## 2. 外部參考與沿用範圍

下列均於 2026-10-18 查閱。表內「借用」是本稿的設計選擇；不代表本 app 具備來源產品的資料能力。只借資訊結構，不重製車型、品牌標誌、警告邏輯或介面素材。

| 參考與 URL | 已查到的內容 | 可以借用的點與限制 |
|---|---|---|
| [Tesla 車主手冊，Displaying tire pressures](https://www.tesla.com/ownersmanual/model3/en_gb/GUID-94F63B13-EA2C-45D9-83AB-5DCA6295D587.html) | 車輛圖旁顯示各輪數值及最後量測時間，可選 bar／psi，也可由手機 app 查看 | 本輪只沿用車輪與數值的空間對應；時間依 L42 共用、顯示固定 psi，車身自行繪製，不採其建議胎壓或警告 |
| [Ford 車機手冊，Viewing the tire pressures](https://www.fordservicecontent.com/Ford_Content/vdirsnet/OwnerManual/Home/Content?ProcUid=G2546872&Uid=G2137067&buildtype=web&countryCode=USA&div=f&languageCode=en&moidRef=G2126716&userMarket=USA&vFilteringEnabled=False&variantid=9547) | 胎壓 app 的專用畫面與圖例連結 | 將胎壓視為獨立車況摘要，車輪位置固定。本稿用停車右欄，沒有加入操作按鈕 |
| [Ford／Lincoln 手機 app 改版](https://www.fromtheroad.ford.com/us/en/articles/2025/redesigned-essential-your-new-ford-and-lincoln-apps) | 手機 app 的車況項目包含胎壓、電量／燃油、油液等 | 胎壓放在車況資訊脈絡，和主駕駛讀數分開。此來源只支持資訊架構，不拿來證明四象限細節 |
| [Polestar 2，See tyre pressure status in the centre display](https://www.polestar.com/uk/manual/polestar-2/2023/article/dad85f37681fb73bc0a801512f2fa17a) | 由 Car status 入口查看胎壓狀態；該頁說明 indirect TPMS | 借用獨立車況入口的分組方式。這是間接式系統，不能借來推定本 app 有數值或使用其健康狀態顏色 |
| [Hyundai Kona 車主手冊，PDF 第 355 頁，TPMS](https://www.hyundai.com/content/dam/hyundai/in/en/data/connect-to-service/owners-manual/kona.pdf#page=355) | PDF 的胎壓章節有車輛／四輪 LCD 圖例，並列壓力顯示單位 | 車頭朝上的位置關係和簡化車身。本稿每輪都標單位，不採低壓告警或門檻；PDF 截圖工具逾時，引用以可讀取的 PDF 文字與圖例索引為限 |

## 3. 造型與排法

| 方向 | 本輪處理 | 決定 |
|---|---|---|
| A 青藍玻璃轎跑 | 沿用青藍漸層、分離前後窗／實體車頂、光條及膠囊輪胎 | 未選(保留參考)；原推薦方向，視覺較安靜 |
| B 冷紫陶瓷轎跑 | 沿用冷紫車漆、板件與分段光條，不調整 SVG 顏色 | 已選；L49 的速度表 C 搭配此款，R6-10 由 visual 在稿裡用車圖濾鏡調暗，SVG 不改 |

本輪採**四角讀值、無引線**。前兩輪的值在前輪膠囊外上方，後兩輪在後輪膠囊外下方，與膠囊垂直淨距 8 pt；左右位置對稱。短標籤不再需要引線和端點來穿過多行文字。若改成輪胎正左／正右三欄，165 寬仍會迫使車圖縮小或讓單位貼著輪胎，因此保留四角，但每角只留一行數字和單位。這讓車圖能比第六輪更大，同時留下標題、輪子與時間之間的空間。

兩款仍是一般流線轎跑、車頭朝上，無車廠標誌，不描摹特定 Tesla 車型。光條、膠囊的冷色與亮度不跟胎壓、缺值或時間變化，不代表正常／異常。車身在下、實色字底板及文字在上。沒有外部引線、端點、警告圖形或新增背景裝飾。

## 4. 狀態、共用時間與讀屏

先判斷 C03／來源單位閘門，再判斷是否**確認不支援**，最後呈現四輪。四個 null 不能推定不支援；缺值不補 0、不帶 psi。來源單位已知且換算經 flutter 驗證後才顯示 psi。

### 4.1 共用時間六種情況

只納入有讀值的輪子。量測時間只用車子的 `tpmsLastSeenPressureTime*`；僅有收到、查詢或重連時間，仍算時間未知。已知的車子量測時間距今 **≤15 分鐘**新鮮，**>15 分鐘**舊；不使用上層任意 stale 旗標取代這個門檻。未知時間優先於任何已知時間。

| 有值輪的情況 | 繁中範例 | 英文範例 | 哪些輪變暗 |
|---|---|---|---|
| 全部 ≤15 分鐘 | 不顯示 | hidden | 無 |
| 全部 >15 分鐘 | 18 分鐘前 | 18 min ago | 所有有值輪 |
| 部分新鮮、部分 >15 分鐘 | 部分讀值 5 小時前 | Some readings 5 hr ago | 只有 >15 分鐘的輪 |
| 全部沒有車子量測時間 | 時間未知 | Time unknown | 所有有值輪 |
| 部分沒有車子量測時間 | 部分讀值時間未知 | Some readings: time unknown | 未知輪及其他已知但 >15 分鐘的輪 |
| 四輪都缺值 | 尚無讀值 | No readings yet | 無，四條 `—` 維持清楚 |

有時間時取有值輪中最舊的量測時間；有未知輪時顯示未知類句，不另外拼接已知時間。缺值不參與時間聚合。相對時間向下取整：<60 分鐘用 `N 分鐘前 / N min ago`，60–1439 分鐘用 `N 小時前 / N hr ago`，≥1440 分鐘用 `N 天前 / N day(s) ago`；例如 60 → 1 hr、1440 → 1 day、2880 → 2 days。每分鐘重算共用行、逐輪明暗及讀屏句。HTML 示範以頁面載入時的合成量測年齡為基準每 60 秒遞增；正式版用車子量測 timestamp 與目前時間相減。

共用行不變暗，≥12 pt、≥4.5:1、有實色底板、最多兩行；固定版在車圖下方，清單版固定在標題下方，不用捲動即可看見。

### 4.2 狀態與預覽入口

| 狀態／HTML state | 可見內容與共用行 | 逐輪明暗／讀屏例子 |
|---|---|---|
| `fresh` 四輪有值 | `42 / 42 / 41 / 42 psi`，無共用行 | 全亮；`左前,42 psi / Front left, 42 psi` |
| `missing` 一輪缺值 | 右後 `—`，其他新鮮，無共用行 | 缺值讀 `右後,尚無讀值 / Rear right, no reading yet`，不唸 `—` |
| `historical` 都舊 | `18 分鐘前 / 18 min ago` | 四個有值輪暗；各輪自己唸 `…,18 分鐘前 / …, 18 min ago` |
| `mixedages` 有新有舊 | `部分讀值 5 小時前 / Some readings 5 hr ago` | 只有右前暗；右前讀 `右前,42 psi,5 小時前 / Front right, 42 psi, 5 hr ago` |
| `days` 都舊兩天 | `2 天前 / 2 days ago` | 四個有值輪暗；逐輪唸自己的時間 |
| `unknown` 全部時間未知 | `時間未知 / Time unknown` | 四個有值輪暗；各輪讀 `…,時間未知 / …, time unknown` |
| `receivedonly` 僅有收到時間 | 收到時間 1 分鐘前，車子量測時間皆無；仍是 `時間未知 / Time unknown` | 不得假裝新鮮，四個有值輪暗 |
| `mixed` 新／舊／未知／缺值 | 左前新、右前 18 分鐘、左後未知、右後 `—`；`部分讀值時間未知 / Some readings: time unknown` | 只暗右前／左後；新鮮輪不唸時間、舊輪唸自身時間、未知輪唸時間未知、缺值唸完整句 |
| `allmissing` 四輪全缺 | 車圖、四個 `—`、`尚無讀值 / No readings yet` | 不用不支援文案；逐輪唸「輪位,尚無讀值」 |
| `unsupported` 確認不支援 | 只有「胎壓」與「這台車沒有提供胎壓資料」／`Tire pressure isn't available from this car`，說明可換行 | 沒有車圖、四輪或共用行；讀標題、說明 |
| `unitunknown`／`gateblocked` | 整區留空 | 整區排除於讀屏 |

固定版仍不顯示輪位、每輪時間或缺值句。大字清單是可見輪位的例外；四輪全缺的共用提示是缺值句的例外。免責留在 ux 規定的面板外流程。

讀屏順序為標題、左前、右前、左後、右後。每輪合成一個完整語意句：新鮮讀位置與值，舊值再唸**該輪自己的時間**，未知再唸「時間未知 / time unknown」，缺值唸位置與完整缺值句。車圖、小定位圖、重複的可見數字／輪位，以及共用行均 aria-hidden，避免共用最舊時間被套到每一輪或重複唸。

## 5. 尺寸、字體與大字

### 5.1 固定版座標

邏輯 pt，HTML 1 CSS px = 1 pt，SVG 匯出使用同一組 `geometryFor()`。外部位置沿 01：184 × 288 在 x 585–769、y 72–360；165 × 272 在 x 486–651、y 72–344；280 是單獨側欄寬度檢查，不更動主要版面。

| 項目 | 184 × 288 | 165 × 272 | 280 × 288 |
|---|---|---|---|
| 標題 | x 0、y 0，預設高 18 | 同左 | 同左 |
| 車圖 | x 40、y 30，104 × 208 | x 35.5、y 34，94 × 188 | x 86、y 26，108 × 216 |
| 左／右讀值欄寬 | 58.72 | 52.42 | 64 |
| 左欄右緣／右欄左緣 | 58.72／125.28 | 52.42／112.58 | 105.44／174.56 |
| 前輪文字 y，預設 24 高 | 37.52 | 37.72 | 35.04 |
| 後輪文字 y，預設 24 高 | 189.84 | 179.24 | 191.68 |
| 共用時間 | y 254，最多 32 高 | y 238，最多 32 高 | y 254，最多 32 高 |

前輪文字以底緣錨定在前膠囊上方 8 pt，放大後向上增高；後輪以頂緣錨定在後膠囊下方 8 pt。固定版不捲動。車圖／標籤寬高都從同一座標模型取得，不用一組為 HTML、一組為 PNG 的獨立常數。

### 5.2 字型與顏色

| 元素 | 預設規格 | 色碼／token |
|---|---|---|
| psi 數字、缺值 `—` | Inter 600，19 pt／24 行高，tabular-nums | `text.primary` #F2F5FA |
| psi 單位 | 12 pt，與數字同基線、間隔 3 pt，不與數字拆行 | 跟該輪數字同色，新鮮 #F2F5FA、舊／未知 #8A97AE |
| 共用時間 | 12–18 pt／14–21 行高，最多兩行，固定版置中、清單靠左，不變暗 | `text.secondary` #AEBCD4 |
| 標題 | 14 pt／18 行高，600 | 同上 |
| 不支援說明 | 14 pt／21 行高，自然換行 | 同上 |
| 舊值／時間未知那一輪的讀值 | 同字級、全不透明 | `hist.text` #8A97AE；共用時間承擔狀態文字，不只靠顏色 |
| 大字清單輪位名稱 | 12 × TextScaler pt／16 × TextScaler 行高；200% 為 24／32 | `text.secondary` #AEBCD4，不跟讀值變暗 |
| 每段文字底板 | #101B2E、100% 不透明 | L40，水平補色 2 pt、margin −2 抵銷佔寬；上下不外擴 |
| A／B 車身 | 原 SVG 漸層、青藍 #6FD8E2／冷紫 #B5B8FF 光條 | 局部造型，固定亮度；不修改 DESIGN.md |

繁中採 Noto Sans TC 400 fallback；本頁仍內嵌原始 TTF 與 OFL 授權。正式 Flutter 打包實際字重，不靠系統替代字型。底板跟隨文字自然換行與縮放增高，不固定高度截字，包含數字、單位與共用時間。數字與單位逐輪一起變暗，只影響 >15 分鐘及時間未知的輪；新鮮輪、缺值 `—`、標題、位置名稱、共用行均不暗。數字最低 15 px，單位最低 12 px，本稿使用 19／12 並隨大字設定放大。

### 5.3 對比

以 #101B2E 作背景，沿 WCAG sRGB 相對亮度算法：#F2F5FA **15.77:1**、#AEBCD4 **8.98:1**、#8A97AE **5.84:1**。最低仍 ≥4.5:1。實色底板是前提，車身漸層與發光不進入文字背景；不以降低整區 opacity 作舊值效果。新鮮 #F2F5FA 與暗值 #8A97AE 的相對亮度比為 **2.98:1**，高於 R7-15 的 2:1；這是亮度比，與文字／背景對比不同。色碼計算不取代最差像素與實機驗收。

### 5.4 量測式清單門檻

先按實際字型、字重、語言、TextScaler 和欄寬排版，符合任一條件即改清單：

- 任一輪 `42 psi` 的自然寬超過該欄寬，或實際高 >32 pt。數字與單位整組不拆行、不縮字、不截斷。
- 共用行實際高 >32 pt，或需要第三行。未顯示時高度 0。
- 標題實際高 >24 pt，或文字與其他讀值／車圖標記互相壓到。

沿用已審過的 32／32／24 pt 高度預算，加入 01 §7.4 的寬度檢查。預設讀值行高 24，前輪文字以底緣錨定，最多向上增高 8 pt；標題與前輪文字仍留約 5.5 pt。固定版時間從底部預留 34 pt，32 高後留 2 pt。HTML 使用 Range 量文字內容外框，排除底板補色；寬高僅容許 0.01 pt 浮點誤差，不以固定縮放比例切換。

共用行使用獨立縮放 `12 × min(TextScaler, 1.5)`，行高 `14 × min(TextScaler, 1.5)`，即 12–18 pt。這讓 165 寬英文的完整 `Some readings: time unknown` 在 200% 仍能維持兩行與固定可見，無省略、沒有縮到 12 以下。數字、單位與位置名稱照系統字級繼續放大至 200%；清單中時間最多 42 pt 高。Flutter 應以實際打包字型驗兩行，不用 maxLines 截掉內容。

內附 TTF 的樣本：100%／110% 四角可容納；130% 的 165 寬帶 psi 樣本因整組寬度切清單，部分雙行時間也因 >32 高切清單；四個 `—` 的版型仍依實測決定。150%／200% 因讀值或標題高度切清單。這是樣本結果，不能把比例寫成切換規則。

清單順序為標題與 24 × 48 小車圖、共用行、左前、右前、左後、右後。**每列必須顯示輪位文字**，繁中「左前／右前／左後／右後」、英文 `Front left / Front right / Rear left / Rear right`，隨 TextScaler 放大與自然換行；文字下方是同樣放大的整組 `42 psi` 或 `—`。保留 24 × 40 定位圖作輔助，實心膠囊只表示該列輪位，不表示正常／有值。

標題與共用行固定在上方，只有四輪列在原有 288／272 高內捲動，捲軸位於列區；字底板保留。`refreshTireLayouts()` 先移除清單樣式，量未裁切的讀值、共用行及標題，抵銷外部縮放後決定版型；單位不換行，量自然寬度時排除底板左右補色。ResizeObserver 與字型載入完成時重測，清單捲動位置保留，回固定版時歸零。`end=1` 只移動四輪列，時間行不隨之消失。

## 6. Flutter 交接

- 車身依 L41 用 `CustomPainter`、`RepaintBoundary`，不加 flutter_svg；文字用原生 Text／RichText、tabularFigures，不用 Canvas path 畫字。
- 資料層提供驗證過的 psi 整數／缺值、來源單位、支援能力和**各輪車子量測 timestamp**。先換 psi 再取整，樣本不代表來源轉換已通過 C03。缺值不補 0、不帶單位。
- 以現在時間減車子量測時間，≤15 分鐘新鮮、>15 分鐘舊；無量測時間算未知，receivedAt／查詢／重連時間不可代替。每分鐘更新，回到畫面時立即重算。只有舊／未知輪的數字及單位改 hist.text，其他輪不受影響。
- 依 §4 六種情況聚合，共用行缺值排除、未知優先、已知取最舊。中英文 min／hr／day(s) 格式與邊界照 §4；四輪缺值顯示「尚無讀值 / No readings yet」，確認不支援才隱藏車圖。
- 用 LayoutBuilder／TextPainter 在同一幀量自然寬、高與行數；套用相同字重／locale／TextScaler／行高。依欄寬及 32／32／24 預算切清單，不用 FittedBox 或先截斷再量。讀值整組不可拆行，數字 ≥15、單位 ≥12。
- 清單每列原生 Text 寫可放大的輪位名稱，再排讀值；定位圖 ExcludeSemantics。標題與共用行放固定區，四輪用剩餘空間的 ListView，兩行時間在捲到最後仍可見。共用行獨立 12–18 pt，位置、讀值照 TextScaler 放大。
- Semantics 每輪一句，順序左前／右前／左後／右後；舊輪唸自己的時間，未知輪唸時間未知，缺值唸完整句不唸 `—`。共用行及重複文字 ExcludeSemantics，避免重複唸或套錯時間。
- Golden／實機涵蓋 165／184／280、100／110／130／150／200%、雙語與系統粗體；驗六種聚合、15 分鐘邊界、只收到時間、分鐘／小時／天、逐輪明暗、最差像素對比、1.5 倍輪位距離、底板與大字捲動。切離停車畫面即隱藏，沒有新增操作入口。

### 6.1 沿用的發光與漸層畫法

依 L41 用同一個 `CustomPainter` 畫車子材質，依 `100 × 200` 座標等比縮放。文字維持一般 `Text`／`RichText`，在另一層，不加入濾鏡。SVG 內 `feGaussianBlur` 是設計效果依據，實作將相同 `Path`、`RRect`、色階交給 painter，以 `MaskFilter.blur` 畫柔光；不使用 `flutter_svg`。

繪製順序為車圖範圍裁切、局部車底光暈、車身外輪廓淡光、輪胎柔光、輪胎清晰膠囊、車漆、玻璃／實體車頂、光條柔光與細高光。最上層為文字底板／文字，本輪不畫外部引線或端點。不要把整個胎壓 `Stack` 放進 blur 或降低 opacity。

```dart
// 概念片段，座標為 SVG 的 100 × 200；不是已整合的產品程式。
final tire = RRect.fromRectAndRadius(
  const Rect.fromLTWH(5, 38, 12, 30), const Radius.circular(6),
);
final glow = Paint()
  ..color = const Color(0x596FD8E2)
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
canvas.drawRRect(tire, glow); // 柔光底層
canvas.drawRRect(tire, Paint()
  ..shader = ui.Gradient.linear(
    const Offset(5, 53), const Offset(17, 53),
    const [Color(0xFF17384E), Color(0xFF6FD8E2), Color(0xFF14283E)],
    const [0, .5, 1],
  )); // 清晰膠囊，不對文字使用 maskFilter

final shellPaint = Paint()..shader = ui.Gradient.linear(
  const Offset(14, 100), const Offset(86, 100),
  const [Color(0xFF163E57), Color(0xE04A8B9E), Color(0xFF234A65),
         Color(0xFF15304B), Color(0xE65C9AA9)],
  const [0, .24, .49, .73, 1],
);
canvas.drawPath(bodyPath, shellPaint);
```

- `MaskFilter.blur` 的 sigma 是 Gaussian 標準差，本稿輪胎／光條取 SVG 座標 2.2，主版等比縮放後約 1.98 logical px；地面淡光用 4，主版約 3.6。它們只影響局部圖形，sigma 與 opacity 均不可跟胎壓變化。[Flutter MaskFilter.blur](https://api.flutter.dev/flutter/dart-ui/MaskFilter/MaskFilter.blur.html)，2026-10-18 查閱。
- 車漆用橫向五個 stop，玻璃用斜向四個 stop；透明色仍畫在深藍車身之上，不依賴系統 backdrop。`Paint.shader` 接 `ui.Gradient.linear`，stop 要與色數一致且遞增。車底可用 `RadialGradient.createShader(ovalBounds)` 畫淡色橢圓。B 換同一組 painter 的材質參數與板件 path，不需要 shader 程式或新套件。[Flutter Gradient.linear](https://api.flutter.dev/flutter/dart-ui/Gradient/Gradient.linear.html)，2026-10-18 查閱。
- 文字每一行獨立包實色 `ColoredBox` 或以正常 `TextStyle.backgroundColor` 背景處理，不把整欄塗滿；若做同 HTML 的水平補底色 2 px，另畫局部背景，不增加文字佔寬；上下不可外擴蓋住前後行。車身不得在最後一層蓋過字。
- 預設不使用 `BlendMode.plus` 放大亮度，不對整區 `saveLayer`。blur 有成本，將靜態車圖放進 `RepaintBoundary`；尺寸、方向或材質未變時 `shouldRepaint` 回 false，量測時間變動只更新文字。低效能模式先移除淡光，保留漸層、清晰輪胎與光條，不能縮字或降低對比。[Flutter CustomPainter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)，2026-10-18 查閱。

以上是實作建議與概念片段，未編譯、未評估 GPU 成本。Flutter 需比對 iOS／Android 的 shader 色階、邊界裁切和 2×／3× 實機渲染，不能把 SVG 本體渲染當成 app 實測。

## 7. 自查、PNG 與限制

| 檢查 | 結果 |
|---|---|
| 模型與 HTML 輸出 | 12 狀態 × 3 寬 × 2 語系 × 2 車身 × 5 縮放 = **720 組**；六種共用行、整數 psi／無單位缺值、逐輪明暗與讀屏、清單輪位、來源閘門、不支援判斷、唯一 SVG ID、腳本語法通過 |
| 時間與亮度 | 15／15.001 分鐘、59／60／1439／1440／2880 分鐘邊界、收到時間不當量測、缺值排除與未知優先通過；亮暗亮度比 2.977、暗字對比 5.843 |
| 實際 TTF／向量幾何 | 同 720 組：326 固定、274 清單、120 隱藏；寬高、最多兩行、面板範圍、膠囊淨距、讀值離自己輪至少近 1.5 倍、大字清單寬度均 0 回報。這是 TTF／向量檢查，並非 Chrome DOM |
| 實際版型與時鐘函式 | 12 個寬高邊界／外部縮放／捲動／隱藏案例及 600 組可見狀態 TTF 量測驅動 `refreshTireLayouts()` 通過；以可控時鐘執行真正的每分鐘 callback，跨越 15 分鐘後共用行、逐輪明暗與讀屏同步更新 |
| HTML DOM 自查 | 已加入逐輪顏色、數值／單位下限、清單輪位縮放、兩行時間／固定可見、實色底板、輪位距離；沿用 T4 的文字 run 外框量法，排除底板補色。待 visual 在 Chrome 實頁執行，未宣稱 DOM 0 回報 |
| PNG | **102 張**，皆為正確 2× 尺寸，SVG／TTF 匯出 0 回報；檔名／版型／明暗輪與量測見 r7-export-audit.json，規格紀錄見 r7-spec-audit.json |
| 造型與歷史檔案 | 兩款 SVG、舊三個相容 SVG、HTML 內嵌車圖均未改；68 張非 r7 舊 PNG 位元組未改。本輪 84 張既有 r7 圖全數覆寫，新增 18 張 |
| 視覺檢視 | 165 英文新／舊混合、165 英文 200% 清單頂／尾、184 中文全缺；新鮮輪維持亮、只有舊／未知暗，完整輪位可讀，共用行固定且沒有單位截斷 |
| 瀏覽器／實機 | 本次指定 SVG 模式，沿用前次 Chrome 退出 134 的環境限制；未重試瀏覽器。Chrome DOM、Flutter、系統粗體及 C03 實機驗收仍待接續 |

匯出：`bash docs/design/frames/tire/export-pngs.sh --renderer svg` 可重現本批。auto 會預檢 Chrome，失敗在報告註明轉向量；`--renderer chrome` 需要可執行的 Chrome，逐頁等待字型與 DOM 自查完成，有回報即停止。SVG 模式需要 Pillow、Node、rsvg-convert，Fontconfig 暫時指向內附 TTF，不安裝到系統。

| 檔名 | 數量 | 本輪用途 |
|---|---:|---|
| `r7-{state}-{165/184/280}-{zh/en}.png` | 72 | 十二狀態、三寬、雙語；新增 mixedages／receivedonly／days 各六張 |
| `r7-ceramic-{165/184/280}-{zh/en}.png` | 6 | 陶瓷 mixed；保留兩款配色 |
| `r7-mixed-{150/200}-{165/184/280}-{zh/en}-{top/end}.png` | 24 | 兩種大字清單，頂／尾同時顯示固定時間行 |

**舊版(保留參考)**：未加 `r7-` 的 `fresh-*`、`unknown-*`、`historical-*`、`missing-*`、`mixed-*`、`unsupported-*`、`allmissing-*`、`unitunknown-*`、`gateblocked-*`、`mixed-xl-*-top/end`、`ceramic-184-*` 共 68 張，仍保留第六輪逐輪文案，不能用於第七輪。不刪,留著參考。請重新載入相同 r7 檔名，勿沿用第一版快取。

## 8. 待確認與整合

| 項目 | 本輪採用 | 接續責任／失效條件 |
|---|---|---|
| 時間與文案 | 已依 L46／01 定稿：≤15 新鮮，六種共用行、逐輪明暗；全缺複數 No readings yet 依本次指示 | ux 更新 01 殘留的全缺「不顯示」；測試門檻為 A20，實車 Q30 若改再同步 |
| 來源單位與 psi | 來源未知整區隱藏，樣本是合理整數 psi | flutter 驗來源轉換、車子量測 timestamp 與 C03 |
| 免責與陶瓷 | 面板外免責由 ux 負責；L49 已選速度表 C，使用陶瓷車身，SVG 不改 | visual 在稿裡用車圖濾鏡處理 R6-10，亮度不超過玻璃款；夜間只調暗車圖、文字不動。玻璃款依 L54 未選(保留參考) |
| 主要稿 | 102 張 r7 PNG 已更新；四角幾何與兩款車身保留 | visual 同步逐輪 dim、六種共用行、清單輪位與固定時間區；Chrome 執行 DOM 自查後再整合主稿 |
| 驗收 | 本輪有模型、實際 TTF／向量、版型／時鐘函式與 PNG 檢視 | Chrome／Flutter／粗體／最差像素／C03 實機仍待驗；不更新 wiki 或產品程式碼 |

## 9. 修訂沿革

第六輪曾完成第二版玻璃／陶瓷車圖、T1–T3 行框／引線修正、T4 補色誤報修正，以及 L40 的四輪缺值／每輪 68 pt／免責 42 pt 清單。上述車身與實色底板保留；逐輪可見文案、引線、免責位置與高度預算已由 L42 取代；第一版的整面板變暗、無清單輪位與暫行時間聚合已由 L46 取代。第六輪 PNG 僅作歷史存檔。
