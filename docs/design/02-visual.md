# 02 — 視覺設計(visual)

> 階段:**第八輪 — 老闆選定 C 和側光條,主要設計稿照 C 重畫(L49–L54)**(見 §9;第七輪見 §8、第六輪見 §7)。更新:2026-10-20 17:43(§9 第一段、第二段;收尾 §9.6;§9.7 DESIGN.md 已更新)。§1–§6 和附錄是第五輪收尾的內容,第六輪新增 §7、第七輪新增 §8、A25–A28、Q41–Q44。
> **主要設計稿改成 `docs/design/frames/landscape-mockups.html`**,PNG 在 `docs/design/frames/landscape/`(L28)。直式稿 `frames/stage2-mockups.html` 和 `frames/S*.png` 保留不刪,標「已取代」(附錄 A)。`.pen` 沒有改。
> **§2 是最終畫面表(橫式)**:每張稿都有 01 的畫面 ID、PNG 和狀態。
> **第六輪見 §7**:`docs/design/frames/gauge-variants.html`(最上面是「給老闆比較」),PNG 在 `docs/design/frames/gauge-variants/`;老闆比較用的合成圖是 `gauge-variants/compare.png`。主要設計稿這一輪不改(L32)。

## 重點結論

- **第八輪(§9)**:老闆選了速度表 C「扇形」和測速提醒「側光條」。比較頁的側光條放到 C 上、改成一行「此路段限速 60 公里」,自查 16 種 0 問題,沒選上的設計都標「未選(保留參考)」(§9.1)。主要設計稿 58 張照 C 重畫(舊稿備份在 `frames/archive-r5/`),另加兩張英文、一張夜間:速度表置中、細數字、`P R N D`、左下角電量 / 續航、psi 胎壓、第一次看到胎壓的說明卡、S07 右欄面板;整套顏色換成 C 的槍灰。29 張 HUD 自查 0 問題、胎壓 8 面板 0 問題;陶瓷車身調暗後平均亮度 0.109,不比玻璃款(0.113)亮(§9.2)。

- **第七輪(§8)**:四個速度表的數字都改細(現在 Inter 320、A Jost 340、B Exo 2 320、C Barlow 400),照 03 實量直筆(1、4、0 的左右)≥9.5、最細處(7 的斜筆、0 的上下)≥9.0、三位數字高 844 寬 106 / 667 寬 101–106、對比白天 ≥11.8、夜間 ≥7.09。數字正上方加 `P R N D`(目前檔位粗 + 底線),離數字 13,四個版本都放得下(A 數字下移 6)。照 03 的對比量法,高速三位數時紅色標記、亮燈格、紅針會貼到數字,已改(現在的版本標記改成環上缺口、B 燈格變短、C 填色和紅針外移),0–240 逐速檢查都 >9 px。新定夜間最暗預設;細字加發光會糊(8.55 → 1.42:1),不加。胎壓換成 tire 第七輪版(只有 psi),Chrome 自查 32 面板 0 問題,R7-19 截圖 12 張。測速提醒畫了 3 個簡約版本(純字、側光條、數字欄)+ 現在的版本,64 種組合自查 0 問題,手機上一個一個往下看。PNG 共 82 張(§8.4)。
- **第六輪收尾(§7.8.7)**:tire 照 L40 改的胎壓版型(四輪都沒值照樣畫車圖、放不下時量高度換清單版、清單版免責放標題下、缺值讀屏不唸「—」)已帶進比較頁。Chrome 自查:比較頁 16 個面板和匯出的 13 個畫面都是 0 個問題,tire 頁面 56 個面板也是 0。重新匯出後,比較頁 13 張和上一版完全相同(預設字級的畫面本來就不變);tire 的 68 張裡變的是「四輪都沒值」6 張和大字清單 12 張。
- **第六輪第四段(§7.8.3)**:tire 修好的 T1–T3 已帶進比較頁的胎壓面板(字底板不再往上蓋字、引線起點改成依實際文字位置擺)。用 headless Chrome 檢查四個版本的停車畫面(844、667)、「胎壓圖示」小段和老闆比較的縮圖,標籤沒被切、起點沒藏在字下;280 寬只出現在 tire 的頁面,也檢查過,起點都貼著字。tire 的 68 張和比較頁受影響的 13 張 PNG 已重新匯出。tire 的自查另外回報「右欄文字超出」,實際是右欄字底板多補的 2 pt 被面板裁掉,畫面看不出來,交給 tire 判斷(T4)。
- **第六輪第三段(§7.8)**:停車畫面(844 和 667)的胎壓區換成 tire 第二版的車子圖示。車圖用 tire 的 SVG 原檔,排版照 tire 的 HTML,每個版本只調顏色:現在的版本用玻璃款原色、A 用玻璃款黑白、B 用陶瓷款原色、C 用陶瓷款槍灰,胎壓文字對比都 ≥5.84:1。比較頁加了「胎壓圖示」小段(有值、時間未知、歷史值、單輪缺值),「給老闆比較」每版加上停車縮圖和安全排序(A > 現在 > B > C,四個都通過)。L39 已照改:B 沒資料改隔段細點、C 數字下移 4 px、行程數字等寬,三位數字高都達到 844 寬 ≥105、667 寬 ≥100。幫 tire 匯出 68 張 PNG;tire 的 audit 沒有問題,但看到 3 個問題交給 tire(位置標籤字下緣被蓋、前輪引線起點藏在字下、280 寬引線浮空),tire 已修,第四段已同步,見 §7.8.3。
- **第六輪第二段(§7.7)**:四個版本(現在、A、B、C)都放進 01 §7.4 的置中版面,各畫行車一般、行車 + 附近提醒、行車沒資料、停車、667×375 小螢幕 5 張完整畫面,加 300×300 特寫 4 張,共 36 張 PNG + 1 張給老闆的比較圖。A、B、C 各有自己的配色、數字字型和質感(A 黑白 Jost、B 電光藍 Exo 2、C 槍灰金屬 Barlow Semi Condensed),都照 L38:數字對比 ≥15:1、等寬數字、字重 ≥600,不用琥珀 / 橙 / 紅當主色。全部放得進 300×300 和 280×280,三位數都 ≥140。safety R6-01、R6-02、R6-05 和 ux 16:15 的版面修改都已照改;胎壓區先放佔位框,等 tire。
- **第六輪第一段(§7.1–§7.6)**:找了 13 個參考,提出三個方向:A「直讀數字」、B「點陣環」、C「扇形」。三個方向加上現在的版本,各畫 88、128、沒資料、0 停車四種狀態,並放進 844×390 和 667×375 的正中間檢查(L31),共 24 張 PNG。文字對比都 ≥5.33:1。等老闆選定方向後,才改主要設計稿(L32)。
- **橫式共 58 張 PNG**(行車 13、無車速 4、停車 8、表單和流程 33),01 列出的畫面都有橫式版;S02 只有系統對話框,被拒狀態是 S05-b;S26、S27 網頁照指示不畫。直式稿全部保留,標「已取代」(附錄 A)。
- **第五輪收尾改了 4 項 safety P1**:R5-01 S14 鍵盤上方補「‹ 返回」和「收起鍵盤」,鍵盤的「下一步」跟著停用變灰;R5-02 列出的連結、返回列、「移除這台車」都改成 ≥48;R5-03 停車畫面來源標示回到左上(和行車同位置),右欄頂端固定車況狀態行,右欄裁在安全線 y 369 以內;R5-04 捲動提示改成實心裁切帶,不再用漸層壓暗文字。
- **ux 15:01**:S24 按鈕分三類(完成 / 關閉 + 重試 / 關閉),新增兩張對話框稿;S08 一律兩欄,另補一張無障礙大字的單欄 S08。
- **安全區(flutter Q32)**:左右兩側都用 max(左, 右) + 16,翻轉方向時版面不跳;稿上的 59 是 iPhone 15 示意值。
- **鏡像全部拿掉(L29)**;§4.0 寫了 `DESIGN.md`、`PRODUCT.md` 刪 mirror mode、只做橫式的改法。Pencil 沒有重試,`.pen` sha1 維持 `e5ff1a…`。

---

## 1. 現況盤點(第一階段,保留)

### 1.1 檔案層級

| 項目 | 現況 |
|---|---|
| 頂層節點 | 8 個 390×844 畫面 frame,加 2 個零散文字節點(§1.6) |
| Variables / themes | **0**(`get_variables` 回傳空值) |
| Reusable 元件 | **0**。toggle、segmented、來源 chip、電量列都是各畫面各自手做的 |
| 字型 | 只有 Inter(400/500/600/700)。中文字由系統 fallback 補,`DESIGN.md` 沒寫中文字型 |
| 圖示 | lucide:`settings`、`battery-medium`、`chevron-left`、`arrow-big-left/right`、`lightbulb`、`navigation` |
| 背景 | 放射漸層 `#101B2E`→`#070B14`(中心 y 0.36–0.4;設定頁 0.2) |
| 現有畫面 PNG | `docs/design/frames/current-*.png`(1x,390×844) |

### 1.2 畫面清單

| 節點 ID | 畫面 | 角色 | 內容摘要 | PNG |
|---|---|---|---|---|
| `ztGMQ` | A — Precision Instrument | 探索稿(未採用) | 青綠弧和白指針、`64 km/h`、頂部「GPS · STRONG」、BATTERY/RANGE 顯示「—」、底部齒輪 | `frames/current-A-precision-instrument.png` |
| `PYNWq` | B — Typographic HUD | 探索稿(未採用) | 全琥珀數字(172/700)和琥珀弧 | `frames/current-B-typographic-hud.png` |
| `7DS4v` | C — Ambient Adaptive | 探索稿(未採用) | 靛藍弧、橘色高速段、指針、中心光暈 | `frames/current-C-ambient-adaptive.png` |
| `Bt6YY` | D — Tesla Cluster | parked(**舊版**) | 刻度錶盤(7 主刻度 + 18 副刻度 + 0–240 標籤)、紅指針、中心 `120`(88/700)、青色電量弧和 `82%`、方向燈/燈號列、日期膠囊 | `frames/current-D-tesla-cluster.png` |
| `za9HJ` | D2 — Drive Mode (distilled) | drive | 細環 track、青色 active 弧和端點、`120`(158/700/-5)、`km/h`、左上綠點「GPS FIX」、右上齒輪、`82% · 312 km` 電量列 | `frames/current-D2-drive-mode.png` |
| `ZpCpT` | D3 — Mirror Preview | 鏡像 | D2 的內容,整個 frame 設 `flipX` | `frames/current-D3-mirror-preview.png` |
| `Q62be` | E — Settings | 設定 | 6 列:單位、鏡像 HUD 模式、行駛自動切換極簡、畫面亮度、螢幕恆亮、強調色;底部隱私說明 | `frames/current-E-settings.png` |
| `bcZC0` | F — Waiting GPS | 等待/無讀值 | 只剩 track、暗色「– –」、琥珀點「搜尋 GPS 訊號…」、電量列隱藏 | `frames/current-F-waiting-gps.png` |
| `BwQnM` / `N1tDcE` | (無名稱文字) | 雜訊 | `603049` / `163325`,黑字 12px,位置 (0,0) | — |

### 1.3 逐畫面:之後要改的元素(第二階段的處理寫在「→」後)

第二階段改寫時精簡了這張表,只留主要節點。完整的子節點 ID,等 Pencil 連回來後用 `batch_get` 查。

| 畫面 | 元素(節點) | 問題 | 第二階段處理 |
|---|---|---|---|
| D2 | 來源 chip `srQfk` | 「GPS FIX」只靠綠點,寬度固定 120 | → 形狀 + 文字,寬度隨內容(S04) |
| D2 | 電量列 `gklxM` | GPS 畫面顯示電量 | → GPS 版拿掉;藍牙版改成狀態列(S04-b) |
| D2 | 觸發區 | 沒有 | → y 522 固定位置(S04-e/f) |
| D2 | 車速 `aub3i` | 只有白字 | → 琥珀 + ▲(S04-f)、「—」(S05) |
| D2 | 齒輪 `xiIO8` | `#3C5160` 2.30:1 | → `#6E7E8C`,44×44 點擊區 |
| D | 指示燈列 `Yneip` | 方向燈等圖示,本版不提供 | → 不沿用;S12 說明頁 |
| D | 指針、軸心、刻度錶盤 | 壓住數字,DESIGN.md 已退役 | → S06 改用 D2 細環 |
| D | 車速 `eDjlU` | 寫 120 / 預設 0 | → 有效才顯示,否則「—」(S06-a) |
| D | 日期膠囊 `pBP0o` | 含溫度(需藍牙,延後) | → 只留日期時間,移到量表上方(S06) |
| D3 | 整個 frame `flipX` | — | → 沿用做法(S04-f 鏡像檢查) |
| E | 行駛自動切換極簡 `CnhPZ` | 和 P 檔自動切換衝突 | → 刪除(S08) |
| E | 強調色琥珀 | 和超速琥珀撞色 | → 拿掉(S08) |
| E | segmented 未選 `#7A8794` | 4.47:1 | → `#8F9CB0` 5.90:1(S08) |
| E | 隱私說明 `fNrbJ` | 3.25:1、只講 GPS | → 移到 S25(下一批) |
| F | 「– –」`BYXDy` | 和 brief「—」不一致 | → 單一「—」(S05) |

### 1.4 `.pen` 和 `DESIGN.md` / `design/index.html` 的差距

| 規格 | `DESIGN.md` | `design/index.html` | `.pen` |
|---|---|---|---|
| 來源 chip | `TESLA` / `GPS` | 「已連線 · TESLA」等 | 只有「GPS FIX」 |
| parked 儀表 | 和 drive 同樣的細環,數字 158 | 細環 | 舊刻度錶盤 + 指針,數字 88 |
| 檔位 `P R N D` | 數字上方 chip | 有 | 沒有 |
| 超速 | 數字轉琥珀(只靠顏色) | 同左 | 沒有 |
| 速限標記 | 弧外中性標記 | 有 | 沒有 |
| 行程列 / 斷線 / 無資料 / 充電 / 示範 | 有 | 有 | 沒有 |
| 橫式 | — | 有 | 沒有 |

### 1.5 第一階段的色彩問題

不在 token 裡的 hex(`#3C5160`、`#1E2A40`、`#46505E`/`#3C4654`、`#7A8794`、`#06101A`、`#0E1A24`/`#2C5A66`、`#3C7A82`、`#D7DEEC`),以及 4 組對比不及格(齒輪 2.30、隱私說明 3.25、segmented 未選 4.47、F 單位 1.99)。第二階段的處理見 §3。

### 1.6 檔案狀態和工具

| 時間 | 事件 |
|---|---|
| 開工前 | 工作目錄的 `.pen` 已有未 commit 的變更:version 2.13→2.14、`fNrbJ` 加 `fontWeight`、根層 `BwQnM`、`fileToken`(不是 visual 造成) |
| 第一階段 | `export_nodes` 一次匯出多個節點失敗後,app 裡多了 `N1tDcE`;磁碟 sha1 維持 `7f8b69b6…` |
| 11:24 | Pencil 自動更新(ShipIt)。關 app 時存檔,`N1tDcE` 寫進磁碟;sha1 變成 **`e5ff1aeccbb61d365b7c712dfc4b7701f8a8cc03`**。用 `git diff` 確認這次存檔**只多了 `N1tDcE`** |
| 11:24 之後 | app 改名成 `/Applications/Pen.app`(1.2.18,bundle id 仍是 `dev.pencil.desktop`)。`~/.claude.json` 已指向新路徑,但這個 session 的 MCP server 還是舊版,呼叫一律回「No handler found」 |
| 第二階段中途 | 主持人裁定:不重連,HTML 為主稿。刪 `BwQnM`(使用者已同意)和 `N1tDcE` 只在 Pencil 剛好連得上時做 |
| 11:55 | 再試一次 `get_editor_state`,仍然「No handler found」→ **兩個節點都還沒刪**。要刪的話:使用者在 visual 的 session 執行 `/mcp` 重連 pencil,再用 `batch_design` 的 `Delete` 刪除 |
| 第三階段開工(約 12:13) | 使用者在 visual 的 session 跑了 `/mcp`,但 `get_editor_state` 仍回「No handler found」→ 照 L4,零散節點這次也沒刪。`.pen` sha1 維持 `e5ff1a…` |
| 第四階段前半 | 沒有再試 Pencil(主持人要求不花時間重連);`.pen` sha1 維持 `e5ff1a…` |
| 第四階段收尾 | 同上,沒有再試;sha1 維持 `e5ff1a…` |
| 第五輪 | 同上,沒有再試;sha1 維持 `e5ff1a…` |
| 第五輪收尾 | 同上 |

---

## 2. 最終畫面表(橫式,第五輪)

> **第八輪(§9)**:58 張已照 C 重畫,檔名不變,另外新增 3 張(`S04-b-min-667x375-en.png`、`S06-b-min-667x375-en.png`、`S06-b-parked-night.png`)。下表的錨點和檔名照舊可用;說明欄是第五輪寫的,行車、停車、S07 的畫法以 §9.2 為準。第五輪的舊稿保留在 `frames/archive-r5/`。

**主要設計稿:`docs/design/frames/landscape-mockups.html`**。直接開啟會看到全部畫面和說明;加 `?screen=<錨點>` 只顯示一張。PNG 由 `docs/design/frames/export-landscape.sh` 匯出到 `docs/design/frames/landscape/`(2x)。`.pen` 節點 ID 全部是「—」:還沒同步回 `.pen`。

- 畫布 844×390(iPhone 14/15 橫式);兩張「最小尺寸」是 667×375。粉紅虛線和粉紅小字是給團隊看的標示(SafeArea、條件列、商店價格、可捲動、一屏底線),不在 app 上。
- **狀態**:「v1」= v1 正式稿;「條件稿」= 條件成立才出現;「參考」= 尺寸檢查或團隊對照,不是使用者會看到的畫面。
- 表單和長文案頁的 PNG 只畫第一屏(實際尺寸),下面還有內容的地方標「↓ 可捲動」;完整文案以 01 §6 為準。

| `.pen` 節點 ID | 01 畫面 ID | HTML 錨點 | 名稱 | PNG(`frames/landscape/`) | 狀態 |
|---|---|---|---|---|---|
| — | S04-a | `?screen=S04a` | 行車・GPS | `S04-a-gps.png` | v1 |
| — | S04(§4.1 第 2 步) | `?screen=S04aSetup` | 行車・齒輪旁「待完成設定」小圓點 | `S04-a-setup-pending.png` | v1 |
| — | S04-b | `?screen=S04b` | 行車・車輛藍牙 + 車況(三位數 112) | `S04-b-ble.png` | v1 |
| — | S04-c | `?screen=S04c` | 行車・車輛藍牙 + 純車速 | `S04-c-ble-speed-only.png` | v1 |
| — | S04-e(附近模式) | `?screen=S04e` | 行車・附近有測速點(GPS) | `S04-e-nearby-gps.png` | v1 |
| — | S04-e(附近模式) | `?screen=S04eBle` | 行車・附近有測速點 + 狀態列(車輛藍牙) | `S04-e-nearby-ble-status.png` | v1 |
| — | S04-e(附近模式,mph) | `?screen=S04eMph` | 行車・附近有測速點,mph | `S04-e-nearby-mph.png` | v1 |
| — | S04-d | `?screen=S04d` | 行車・藍牙失效,剛改用 GPS | `S04-d-switched-to-gps.png` | v1 |
| — | S04-g | `?screen=S04g` | 行車・回前景 / 冷啟動(—) | `S04-g-cold-start.png` | v1 |
| — | S04-h | `?screen=S04h` | 行車・車輛藍牙有效 + 拒絕定位 | `S04-h-ble-location-denied.png` | v1 |
| — | S04-i | `?screen=S04i` | 行車・P 檔過期,剛離開停車畫面 | `S04-i-p-stale-left-parked.png` | v1 |
| — | S04 大字 | `?screen=S04XL` | 行車・大字與高對比 | `S04-XL-large-text.png` | 條件稿:美國上架前加入 |
| — | S04-b(最小尺寸) | `?screen=S04min` | 行車・667×375 檢查 | `S04-b-min-667x375.png` | 參考:尺寸檢查 |
| — | S05 | `?screen=S05` | 無有效車速(兩個來源都無效) | `S05-no-speed.png` | v1 |
| — | S05 | `?screen=S05s` | 無有效車速・搜尋 GPS | `S05-searching-gps.png` | v1 |
| — | S02 拒絕態(呈於 S05) | `?screen=S05b` | 定位被拒、沒有藍牙:一行字 + 前往系統設定 | `S05-b-location-denied-no-car.png` | v1 |
| — | S05 + 閘門提示 | `?screen=S05c` | 沒有資料又沒配對:到收得到 GPS 的地方… | `S05-c-gate-no-gps-unpaired.png` | v1 |
| — | S06-b | `?screen=S06b` | 停車・藍牙 P(新鮮 P + 有效 0;來源標示在左上) | `S06-b-parked-ble-p.png` | v1(胎壓區:06 C03 通過才有) |
| — | S06-f | `?screen=S06f` | 停車・新鮮 P,車速缺值(「P 檔」) | `S06-f-parked-p-no-speed.png` | v1 |
| — | S06-a | `?screen=S06a` | 停車・只有 GPS,已知停車後手動進入 | `S06-a-parked-gps-manual.png` | v1 |
| — | S06-c | `?screen=S06c` | 停車・等待車輛(右欄頂端固定「◌ 等待車輛…」) | `S06-c-parked-waiting-car.png` | v1 |
| — | S06-d | `?screen=S06d` | 停車・只有 GPS 的手動停車 + 舊電量(右欄頂端固定「◐ 藍牙中斷」) | `S06-d-parked-gps-old-battery.png` | v1 |
| — | S06-e | `?screen=S06e` | 停車・未解鎖(試用已結束) | `S06-e-parked-locked.png` | v1 |
| — | S06 大字 | `?screen=S06XL` | 停車・大字與高對比(右欄在安全線內捲動) | `S06-XL-large-text-scroll.png` | 條件稿:美國上架前加入 |
| — | S06-b(最小尺寸) | `?screen=S06min` | 停車・667×375 檢查 | `S06-b-min-667x375.png` | 參考:尺寸檢查 |
| — | S01 | `?screen=S01` | 首次開啟:選行車畫面(預覽卡左右並排) | `S01-first-run-layout.png` | v1 |
| — | S03 | `?screen=S03` | 固定測速照相提醒(首次,台灣) | `S03-camera-alerts-intro.png` | v1 |
| — | S28 | `?screen=S28` | 安裝提醒 | `S28-mounting-tips.png` | v1 |
| — | S07 | `?screen=S07` | 停車確認(對話框在右半邊) | `S07-parked-confirm.png` | v1 |
| — | S08 | `?screen=S08` | 設定・顯示(兩欄) | `S08-settings-display.png` | v1 |
| — | S08 | `?screen=S08alert` | 設定・提醒(含定位權限列) | `S08-settings-alerts.png` | v1 |
| — | S08 | `?screen=S08car` | 設定・車輛 | `S08-settings-car.png` | v1 |
| — | S08(無障礙大字) | `?screen=S08ax` | 設定・顯示,AX 大字單欄 | `S08-settings-display-ax-single.png` | v1(第五輪收尾新增) |
| — | S09 | `?screen=S09` | 行車畫面設定(設定右欄) | `S09-driving-screen-settings.png` | v1 |
| — | S10 | `?screen=S10` | 固定測速照相提醒設定・有效(設定右欄) | `S10-camera-alert-settings.png` | v1 |
| — | S10(已過期) | `?screen=S10b` | 固定測速照相提醒設定・已過期 | `S10-b-camera-data-expired.png` | v1 |
| — | S19 | `?screen=S19` | 車輛藍牙(設定右欄,一台車) | `S19-car-bluetooth.png` | v1 |
| — | S19 移除確認 | `?screen=S19b` | 移除這台車(置中對話框) | `S19-b-remove-confirm.png` | v1 |
| — | S19 改配對確認 | `?screen=S19c` | 改配對另一台車(置中對話框) | `S19-c-repair-confirm.png` | v1 |
| — | S19 改配對沒完成 | `?screen=S19d` | 改配對沒有完成:訊息 | `S19-d-repair-not-completed.png` | v1 |
| — | S12 | `?screen=S12` | 本版本不提供 | `S12-not-in-this-version.png` | v1 |
| — | S25 | `?screen=S25` | 關於與聲明 | `S25-about.png` | v1 |
| — | S13 | `?screen=S13` | 配對:開始前 | `S13-pair-start.png` | v1 |
| — | S14 | `?screen=S14` | 配對:輸入 VIN(鍵盤打開,有返回和收起鍵盤) | `S14-pair-vin-keyboard.png` | v1 |
| — | S15 | `?screen=S15` | 配對:尋找並連線 | `S15-pair-searching.png` | v1 |
| — | S16 | `?screen=S16` | 配對:感應鑰匙卡 | `S16-pair-key-card.png` | v1 |
| — | S17 | `?screen=S17` | 配對:完成 | `S17-pair-done.png` | v1 |
| — | S18-c | `?screen=S18c` | 配對失敗:找不到你的車 | `S18-c-pair-car-not-found.png` | v1 |
| — | S18-h | `?screen=S18h` | 已暫停配對 | `S18-h-pair-paused.png` | v1 |
| — | S20(iOS) | `?screen=S20ios` | 領取 7 天免費試用 | `S20-ios-trial-claim.png` | v1 |
| — | S20(Android) | `?screen=S20and` | 開始 7 天免費試用 | `S20-android-trial-start.png` | v1 |
| — | S21 | `?screen=S21` | 免費試用已結束 | `S21-trial-ended.png` | v1 |
| — | S22 | `?screen=S22` | 解鎖(台灣) | `S22-unlock-tw.png` | v1 |
| — | S23 | `?screen=S23` | Support development(美國 B,英文) | `S23-support-us-b.png` | 條件稿:美國 B 勝出才上 |
| — | S24 | `?screen=S24` | 購買結果・成功類(完成) | `S24-purchase-result-dialog.png` | v1 |
| — | S24 | `?screen=S24retry` | 購買結果・可以重試(關閉 + 重試) | `S24-purchase-result-retry.png` | v1(第五輪收尾新增) |
| — | S24 | `?screen=S24close` | 購買結果・其他(關閉) | `S24-purchase-result-close.png` | v1(第五輪收尾新增) |
| — | S24 | `?screen=S24all` | 購買結果訊息一覽 | `S24-purchase-results-board.png` | 參考:給團隊對照 |

**已取代或刪除**

| 項目 | 狀態 | 依據 |
|---|---|---|
| `frames/stage2-mockups.html` 和 `frames/S*.png`(直式 58 張) | 已取代,保留不刪(附錄 A) | L28 |
| 直式的前方模式條件稿(S04-e 前方、S04-f 超過、英文、mph) | 已取代;前方模式 v1 不開,啟用前再畫橫式(§2.3) | L28、L8 |
| 鏡像:S11 鏡像預覽、`S04-f-mirror-check.png`、`S11-mirror-preview.png`、S08 的「鏡像 HUD 模式」列、S21「仍免費」裡的鏡像模式 | 功能刪除(L29);直式 PNG 保留在 `frames/`,不再使用;沒有橫式版 | L29 |
| 直式的 S04-L、S06-L、S04-XL、S06-XL | 已取代,由本表的橫式稿重做 | L28 |
| `frames/current-*.png`(`.pen` 舊稿) | 第一階段盤點用,早已不是現行設計 | — |

### 2.1 橫式版面決定

> 第八輪:下表「量表在左」「右欄提醒卡 / 狀態列」「停車右欄」幾列已被 L31(置中)和 L49(C)取代,新的版面見 §9.2 和 01 §7.4;表格保留參考(L54)。

| 項目 | 決定 | 依據 |
|---|---|---|
| 方向 | 只有橫式,左右兩個方向都支援;內容永遠正立、量表永遠在畫面左邊。稿上只畫一個方向,另一個方向版面相同 | L28、01 §7.1 |
| 安全區 | 左右兩側都用 max(左, 右) + 16(flutter Q32;稿上 max = iPhone 15 的 59);底部手勢區 21。翻轉時版面不跳。無瀏海小手機 SafeArea 0 | 01 §7.1、flutter Q32、safety O03 |
| 量表 | 844×390 時圓心 (250,205)、外徑 150,車速 158(三位數 140 / -6);667×375 時圓心 (182,197)。純車速、沒有提醒時也不置中 | L25、L26 |
| 來源標示 / 齒輪 | 來源標示在左上 (75,16),第二行(展開或閘門提示)在 (75,44);齒輪 48×48 在右上 | 01 §7.2 |
| 右欄(行車) | x 470、寬 299;提醒卡固定在 y 96,狀態列固定在 y 214,兩者出現或消失都不推動其他元素。S05-b 的一行說明 + 按鈕放在提醒卡位置 | 01 §7.2、L13 |
| 右欄(停車) | 量表和來源標示都和行車同位置(來源標示在左上 (75,16),不隨右欄捲動)。右欄頂端固定車況狀態行(「◌ 等待車輛…」「◐ 藍牙中斷」「◐ 藍牙資料過期」,沒有狀態時不佔位),下面是檔位 / 電量 + 時間、行程、胎壓 2×2、日期膠囊、佔位或通知列;第一列避開右上齒輪。右欄高度到安全線 y 369 為止,超出時在右欄內捲動 | 01 §7.2、§11 Q30、R5-03、L24 |
| 大字與高對比 | 車速不放大;來源 18、單位 28、提醒卡 19/36、狀態列 21、胎壓 22;行車畫面右欄放得下不捲動,停車畫面右欄捲動 | L19、L24、01 §7.3 |
| 表單頁 | 標題列 56 固定在上;內容單欄寬 ≤600 置中,長文案 ≤540(約 36 個全形字);按鈕列固定在下方、避開手勢區,次要動作在左、主要在右 | 01 §7.2 |
| 設定 | 一律兩欄(667 寬也是):左欄群組 190 寬,右欄是群組內容;S09、S10、S19 在右欄打開,右欄的「‹ 標題」返回列高 48。只有右欄 <360 pt,或系統字級到無障礙大字(iOS AX1 以上 / Android ≥200%)才改單欄、點進去換頁(S08 AX 稿:標籤在上、控制在下) | 01 §11 Q31 |
| 確認框 | 置中對話框,寬 ≤460,按鈕同一列(取消 / 關閉在左、主要在右);S07 放在右半邊(寬 352),左邊的錶和來源標示仍看得到。S24 三類:成功類只有「完成」;可以重試的「關閉」+「重試」;其他只有「關閉」 | 01 §7.2、§11 Q29 |
| 配對 | 兩欄:左欄步驟和插圖,右欄說明、進度和讀值;S17 三格讀值橫排 | 01 §7.2 |
| 鍵盤(S14) | 鍵盤高約 198;鍵盤上方只留一列(‹ 返回 48×48、步驟 1/4、標題、在哪裡找到 VIN?、收起鍵盤)、VIN 欄(一行 17 碼 + 字數)+「下一步」、欄位下錯誤;VIN 不合格時鍵盤的確認鍵和畫面上的「下一步」一樣是停用灰色 | 01 §7.2、R5-01 |
| 購買 | 兩欄:左欄標題和功能清單,右欄價格、說明、付費文案(右欄內捲動);主要按鈕和恢復購買固定在右下;價格用粉紅虛線標「從商店取得」 | 01 §7.2、L14 |
| 鏡像 | 不存在:新 HTML 沒有任何左右翻轉,也沒有鏡像設定或說明 | L29 |
| 點擊區 | 全部 ≥48:S06-e「車輛資料試用已結束 ›」、S22 三個說明連結、設定右欄返回列、「移除這台車」、S14 的連結和收起鍵盤都已改 | R5-02 |
| 捲動提示 | 稿上用底部 18px 的實心「↓ 可捲動」裁切帶,下面的內容是被裁掉而不是被壓暗(R5-04)。實作不要用會壓暗文字的漸層;捲動內容底部留白:單欄長文案至少「固定按鈕高度 + 24」,兩欄頁 24–32,停車右欄 ≥16 | R5-04、R5-03 |

### 2.2 畫布、尺寸和匯出

| 項目 | 規格 |
|---|---|
| 畫布 | 844×390 邏輯 px;最小尺寸檢查 667×375;S24 一覽 844×640 |
| PNG | 2x,`docs/design/frames/landscape/` |
| 字型 | Inter + Noto Sans TC(L15) |
| 點擊區 | ≥48(齒輪、按鈕、設定列、群組列、對話框按鈕) |
| 匯出方法 | `docs/design/frames/export-landscape.sh [ID...]`(不帶參數 = 全部 58 張) |

### 2.3 還沒畫的(橫式)

| 類別 | 畫面 |
|---|---|
| 條件稿 | 前方模式(前方距離、超過點位資料速限、琥珀 ▲ 在量表內),等前方模式要啟用時再畫 |
| 變體 | S04 / S06 的英文版、S10 更新失敗 / 部分點位停用、S17 讀取中、S18 a/b/d/e/f/g、S19 空狀態和「取代完成」、S20 iOS 恢復原試用 / 原試用已結束、S08「行為」「說明」群組、S08 在 667 寬的兩欄稿 |
| 新頁 | 隱私說明頁(等實際資料流,R4-08);S02 只有系統對話框,不畫 app 頁 |
| 尺寸 | 表單和流程畫面的 667×375 檢查(含 S14 開鍵盤)、系統大字下的其他表單(R5-05 列入 T02 實機驗收) |
| 網頁 | S26、S27(L12:只畫草稿,不架站) |
| `.pen` | 新畫面同步回 `.pen`(等使用者決定)、刪除 `BwQnM` 和 `N1tDcE` |

## 3. Token 變更

### 3.1 新增(都已用在 HTML 稿)

| Token | 值 | 用在哪 | 來源 |
|---|---|---|---|
| `gauge.track` | `#1E2A40` | 量表底環 | `.pen` D2 寫死的值 |
| `pill.bg` / `pill.border` | `#0E1A24` / `#2C5A66` | 日期膠囊、觸發卡片、狀態列檔位框 | `.pen` D 寫死的值 |
| `speed.unavailable` | `#8A97AE` | 「—」車速 | 新增;F 的 `#46505E`(2.33:1)太暗 |
| `icon.chrome` | `#6E7E8C` | 齒輪等 HUD 圖示 | 取代 `#3C5160`(2.30:1) |
| `over.cardBg` | `#2A1F0A` | 超過點位速限的卡片底色 | 新增 |
| `border.control` | `#243042` | 卡片、膠囊、未選 toggle 外框 | `design/index.html` 寫死的值 |
| `seg.inactiveText` | `#8F9CB0` | segmented 未選文字 | 取代 `#7A8794`(4.47:1) |
| `sheet.bg` | `#121C2B` | 底部確認框、結果卡片 | 第二批新增 |
| `danger.text` / `danger.border` | `#FF8A9B` / `#6A2C39` | 「移除」等危險動作 | 第二批新增(7.68:1) |
| ~~`dim.opacity`~~ → `hist.text` | `#8A97AE`(完整不透明);膠囊填色 `#4C586D` | 停車畫面的舊電量、舊胎壓數值和單位 | L21:舊值仍要 ≥4.5:1,「舊」靠時間表達 |
| `speed.d3` | 140px / 字距 -6 / 700 | 三位數車速 | L26 |
| `hc.*`(高對比覆寫) | `text.secondary` `#E3EAF4`、`unit` `#C2D2EA`、`pill.border` `#4F8796`、`gauge.track` `#33476A`、`icon.chrome` `#AEBCD4` | 大字與高對比模式 | 第四階段新增(L19) |
| `type.xl`(大字比例) | 次要文字約 ×1.3–1.4;車速 158 不變 | 大字模式 | 第四階段新增(L19) |
| `font.cjk` | Noto Sans TC(打包) | 所有中文字 | L15 |
| `source.ok` / `source.degraded` | `#3DE0A8` / `#F5B53C` | 來源形狀記號(● / ◐ ▲) | 由 `gps.fix` / `gps.searching` 改名,因為現在也用在「車輛藍牙」 |

### 3.1b 橫式版面 token(第五輪新增)

| Token | 值(844×390) | 用途 |
|---|---|---|
| `layout.safeSide` | max(左, 右),左右兩側都套用(iPhone 15 = 59);內容再 +16 | 翻轉時版面不跳(flutter Q32) |
| `layout.safeBottom` | 手勢區(iPhone 15 = 21) | 按鈕不放在這裡 |
| `layout.pad` | 16 | 內容和安全區的距離 |
| `gauge.center` | (250, 205);667×375 時 (182, 197) | 量表固定在左 |
| `hud.col` | x 470,寬 = 畫面寬 − safeSide − 16 − 470(= 299) | 右欄 |
| `hud.cardTop` / `hud.statusTop` | 96 / 214 | 提醒卡、狀態列固定位置 |
| `form.maxWidth` / `text.maxWidth` | 600 / 540(約 36 個全形字) | 表單和長文案 |
| `dialog.maxWidth` | 460(S07 在右半邊用 352) | 確認框 |
| `settings.navWidth` | 190(可到 240) | 設定左欄;右欄 <360 pt 或 AX 大字時改單欄 |
| `parked.colTop` / `parked.colBottom` | 16 / 安全線(390 − 21 = 369) | 停車右欄範圍;頂端固定車況狀態行,其餘在範圍內捲動 |
| `hit.min` | 48 | 所有點擊區 |

### 3.2 修改或限制

| Token | 改法 | 理由 |
|---|---|---|
| `text.dim` `#5A6675` | 只能用在裝飾和非必要元素,不能用在必要文字 | 3.25:1([03 S06]) |
| 來源標示文字 | `text.tertiary` 12/600 → `text.secondary` 13/600 | 小字在反射和漸層亮處要看得到 |
| 強調色選項 | 拿掉琥珀 `#FFB638`,只留青、靛 | 琥珀是超速/測速專用([06 C06]) |
| `hub` `#D7DEEC` | 刪除 | 指針已退役 |
| toggle 旋鈕 | `.pen` 的 `#06101A` 統一成 `bg.base` | 和 DESIGN.md 一致 |

### 3.3 新稿對比(以漸層中心 `#101B2E` 計算,比 `bg.base` 嚴格)

| 元素 | 前景 / 背景 | 對比 | 門檻 |
|---|---|---|---|
| 來源標示文字 | `#AEBCD4` / `#101B2E` | 8.98 | 4.5 |
| 齒輪 | `#6E7E8C` / `#101B2E` | 4.13 | 3.0 |
| 單位、註記、群組標題 | `#8A97AE` / `#101B2E` | 5.84 | 4.5 |
| 「—」 | `#8A97AE` / `#101B2E` | 5.84 | 3.0(大字) |
| 琥珀數字 | `#FFB638` / `#101B2E` | 9.85 | 3.0 |
| 超過卡片文字 | `#FFB638` / `#2A1F0A` | 9.24 | 4.5 |
| 前方卡片文字 | `#AEBCD4` / `#0E1A24` | 9.18 | 4.5 |
| segmented 未選 | `#8F9CB0` / `#16202E` | 5.90 | 4.5 |
| 連結 | `#6FD8E2` / `#101B2E` | 10.34 | 4.5 |
| 主按鈕文字 | `#0A101C` / `#2BD4E0` | 10.51 | 4.5 |
| 胎壓時間 | `#8A97AE` / `#141E2C` | 5.69 | 4.5 |
| 佔位虛線框 | `#5A6675` / `#101B2E` | 約 3.0 | 裝飾(框內文字另外 ≥4.5) |
| 危險動作文字 | `#FF8A9B` / `#101B2E` | 7.68 | 4.5 |
| 停用列文字 | `#8F9CB0` / `#101B2E` | 6.20 | 4.5 |
| 「GPS 不可用」「電量最後更新」 | `#AEBCD4` / `#101B2E` | 8.98 | 4.5 |
| VIN 錯誤文字 | `#FFB638` / `#101B2E` | 9.85 | 4.5 |
| 舊電量(歷史色) | `#8A97AE` / `#101B2E` | 5.84 | 4.5(L21;原本 38% 的 2.40:1 已取消) |
| 舊胎壓(歷史色) | `#8A97AE` / `#141E2C` | 5.69 | 4.5 |
| 高對比次要文字 | `#E3EAF4` / `#101B2E` | 14.23 | 4.5 |
| 高對比單位 | `#C2D2EA` / `#101B2E` | 11.25 | 4.5 |
| 高對比卡片框線 | `#4F8796` / `#101B2E` | 4.30 | 3.0(元件邊界) |
| 高對比量表底環 | `#33476A` / `#101B2E` | 1.85 | 裝飾(數值看數字,不看底環) |
| 「車速暫不可用」(數字下方) | `#AEBCD4` / `#101B2E` | 8.98 | 4.5 |

---

## 4. 建議的 `DESIGN.md` 改法

### 4.0 第五輪:只做橫式、拿掉鏡像(優先於下面各段)

下面 4.1 之後的改法是直式時代寫的;其中講到「數字下方」「y 522 / y 640」「底部狀態列」等直式位置的地方,一律以這一段的橫式規則為準。

**`DESIGN.md` Design principles**
```diff
- - Mirror mode = horizontal flip (`Transform.scale(scaleX: -1)`) of the drive screen so the windshield reflection reads upright.
+ - **Landscape only** (00-rulings L28): the app is locked to landscape and supports both landscape directions; content always stays upright and the gauge is always on the screen's left. There is no portrait layout.
+ - **No mirror mode** (L29): the HUD is never flipped; there is no mirror setting, preview or copy.
```

**`DESIGN.md` Gauge spec**
```diff
- - **Mirror mode**: render the drive screen flipped horizontally.
+ - **Landscape layout** (844×390 reference, 667×375 minimum): gauge fixed on the left (center 250,205 / radius 150 at 844×390);
+   source chip top-left, settings gear top-right; right column (x 470, width = screen − side safe area − 16 − 470):
+   alert card slot at y 96, status bar slot at y 214 — both fixed, nothing moves when they appear.
+   Both sides reserve the larger of the two notch safe areas so rotating 180° doesn't shift the layout; content = SafeArea + 16.
+ - **Parked (landscape)**: same gauge position and size as drive, and the source chip stays top-left like drive (it never scrolls).
+   Right column: an optional pinned car-status line on top (◌ 等待車輛… / ◐ 藍牙中斷 / ◐ 藍牙資料過期), then gear / battery + own time,
+   trip, tires 2×2, date pill, placeholder or notice row. The column ends at the bottom safe-area line and scrolls inside it.
+ - Horizontal safe area: both sides use max(left, right) of the device insets, plus 16, so a 180° rotation never shifts the layout.
```

**`DESIGN.md` New element specs**
```diff
- - **Power / regen bar (drive, P2)**: a thin vertical bar at the screen edge (mirror-safe).
+ - **Power / regen bar (drive, v1.x)**: a thin vertical bar at the screen edge; landscape placement to be designed when the feature is scheduled.
```

**`DESIGN.md` Screen inventory**
```diff
- - `Bt6YY` D — Parked cluster · `za9HJ` D2 — Drive mode · `ZpCpT` D3 — Mirror preview · `Q62be` E — Settings · `bcZC0` F — Waiting GPS.
+ - Main design: `docs/design/frames/landscape-mockups.html` (PNG in `docs/design/frames/landscape/`).
+ - Superseded references: `.pen` frames D / D2 / E / F, the portrait mockups `docs/design/frames/stage2-mockups.html`.
+   `.pen` D3 (Mirror preview) is obsolete — mirror mode was removed (L29).
```

**`DESIGN.md` 新增段落:Forms & flows (landscape)**
```diff
+ ## Forms & flows (landscape)
+ - Title bar 56 fixed; single-column content ≤600 wide, long text ≤540 (~36 CJK chars per line); button row fixed at the bottom,
+   outside the home-indicator area — secondary action left, primary right.
+ - Settings: always two columns (group list 190–240 + content), detail pages open in the right column; single column only when the
+   right column would be < 360 pt or the system text size is an accessibility size (iOS AX1+ / Android ≥ 200%).
+ - Every tap target ≥ 48. Scroll hints must not dim text; leave bottom padding so the last item clears fixed buttons and the safe area.
+ - Confirmations: centered dialog ≤460 wide, ≤80% height, buttons in one row (cancel left, primary right); no bottom sheets.
+   S07 over the HUD sits in the right half so the gauge and source chip stay visible.
+ - Pairing and purchase: two columns; price and primary buttons stay fixed at the bottom right.
+ - VIN keyboard: only step, VIN field (17 chars + counter), inline error and Next stay above the keyboard.
```

**`PRODUCT.md`**
```diff
- - The speed numeral and primary controls must be legible at a glance and when horizontally mirrored.
+ - The speed numeral and primary controls must be legible at a glance in landscape, in either landscape direction.
```

### 4.1 直式時代的改法(第一到第四階段)

只是建議,`DESIGN.md` 沒有動。以下 `-` 是現在的寫法(節錄),`+` 是建議的寫法。

**Design principles**
```diff
- One accent (cyan) carries state; crimson is reserved for the parked-mode needle.
+ One accent (cyan) carries state; crimson is the current-value marker on the arc (drive + parked).
+ State is never color-only: every status pairs color with a shape (● ◐ ◌ ▲) and a word.
+ Amber is reserved for the Taiwan fixed-camera "over listed limit" state; it is not an accent option.
```

**Color tokens**
```diff
- `gps.fix` `#3DE0A8` (green) · `gps.searching` `#F5B53C`, label `#D7A23E`.
+ `source.ok` `#3DE0A8` (● valid, GPS or Car Bluetooth) · `source.degraded` `#F5B53C` (◐ fallback/connecting, ▲ no valid speed).
- `text.tertiary` `#6E7E8C` · `text.dim` `#5A6675`.
+ `text.tertiary` `#6E7E8C` · `text.dim` `#5A6675` (decorative only — never required text; 3.25:1).
+ `gauge.track` `#1E2A40` · `pill.bg` `#0E1A24` · `pill.border` `#2C5A66` · `border.control` `#243042`.
+ `speed.unavailable` `#8A97AE` (the `—` numeral) · `icon.chrome` `#6E7E8C` (HUD chrome icons, ≥3:1).
+ `over.cardBg` `#2A1F0A` · `seg.inactiveText` `#8F9CB0`.
- `hub` `#D7DEEC` (legacy, now unused).
- cyan `#2BD4E0` (default) · amber `#FFB638` · indigo `#6E7BFF`.
+ cyan `#2BD4E0` (default) · indigo `#6E7BFF`.
```

**Typography**
```diff
- Family: **Inter** (cross-platform; system fallback acceptable).
+ Family: **Inter** for Latin and numerals + **Noto Sans TC bundled with the app** for CJK (00-rulings L15). No system CJK fallback.
- | Speed numeral — parked center | 158 (= drive) | 700 | -5 |
+ | Speed numeral — parked center | 158 (= drive, same position; no "128/100 preview px") | 700 | -5 |
- | GPS status label | 12 | 600 | 2 |
+ | Source chip label | 13 | 600 | 1 | `text.secondary`
+ | Trigger card: label / limit / distance | 15 / 28 / 22 | 600 / 700 / 600 | 0 |
+ | Status bar: gear letter / values | 17 / 16 | 700 / 500 | 0 / 0.3 |
```

**Gauge spec — Drive dial**
```diff
- A neutral speed-limit marker (`limit.marker`) + numeric label sits just outside the arc band.
- **Over-speed = number is the sole warning**: when speed > limit the numeral turns `over` amber …
+ No speed-limit marker on the arc in v1 (road limits deferred; a camera point limit on the arc would read as the road limit).
+ **Over listed limit (Taiwan fixed-camera alerts only)**: when the 01 §5.3 conditions hold, the numeral turns `over` amber
+ AND a ▲ mark appears above the numeral AND the trigger card switches to ▲ + "超過點位資料速限 N". Arc and markers stay neutral.
- Top-left GPS status, top-right settings gear. **Gear selector sits just above the speed numeral** (`P R N D` …)
- Battery is a capsule bar … centered below the numeral.
+ Top-left source chip (shape + word: ● GPS / ● 車輛藍牙 / ◐ GPS · 藍牙連線中… / ▲ 車速暫不可用), top-right settings gear (44×44 hit area).
+ Below the numeral: a fixed trigger zone (empty until an alert; the numeral never moves), then a one-line status bar
+ shown only with valid Car Bluetooth data and layout "車速 + 車況": current gear letter │ battery capsule + `72% · 315 km`.
+ No P R N D selector. No power bar in v1 (v1.x, default off).
```

**Gauge spec — Parked**
```diff
- **Resting state = 0** (arc empty, track only), consistent with gear `P`
+ The numeral shows a value only for a valid, fresh speed (a fresh Bluetooth 0 shows `0`); otherwise `—`. Never a hard-coded 0.
- **Parked carries the same active-source chip as drive** (top-left `TESLA`/`GPS`)
+ **Parked carries the same source chip as drive** (`車輛藍牙` / `GPS` + shape mark)
- Gear selector just above the center numeral, inside the gauge … Bottom date/time/temp pill (cyan-bordered).
+ Status row `P │ 72% · 315 km` directly under the numeral (same component as drive). Date/time pill above the gauge, no temperature.
+ Then trip strip (+ "由手機 GPS 計算"), then tire pressure (only if 06 C03 passes): per wheel value + "最後量測 N 分鐘前",
+ missing wheel `—` + "量測時間未知", note "僅供參考,請以車上的胎壓警示為準"; no "normal" color or check mark.
- plus charging status (BLE) when plugged in.
+ Charging status is v1.x (01 A16).
```

**Waiting/no-fix 和 Hardened states**
```diff
- **Waiting/no-fix**: active arc + tip hidden; numeral shows dimmed `– –`; GPS dot → `gps.searching` amber with "搜尋 GPS 訊號…"
+ **No valid speed** (drive + parked): numeral `—` in `speed.unavailable`; active arc, tip and crimson marker removed (not dimmed);
+ trigger card removed immediately; chip ▲ with the reason (車速暫不可用 / 搜尋 GPS 訊號… / 未取得定位權限).
- the source chip flips to **amber `連線中斷`** and a **`最後更新 · N 分鐘前`** timestamp appears
+ the source chip always names the CURRENT speed source (◐ GPS · 藍牙中斷 / ◐ GPS · 車輛休眠 / ▲ 車速暫不可用) — 00-rulings L9.
+ Battery and tire values carry their own "最後更新 / 最後量測" times; never one shared "last updated" for the whole screen.
+ Old values are NOT dimmed by opacity: they use `hist.text` #8A97AE (≥4.5:1) with their own "最後更新 / 最後量測 N 分鐘前" (00-rulings L21). The chip and timestamps keep full contrast. Gear shows P only when fresh; otherwise the gear box shows "—".
+ Auto-parked returns to drive when P goes stale (S04-i); with no valid source the screen falls back to the minimal HUD (S05), never a parked summary.
+ Speed and gear never show last-known values; only battery/range/tire may, dimmed and timestamped (parked only).
- chip shows amber **`等待車輛`**
+ chip shows **◌ 等待車輛**
```

**Information architecture 和 Data-source reality**
```diff
- | ⊕ Active-source / connection status | BLE / GPS | drive | top-left chip: `TESLA` (BLE, full cluster) vs `GPS` …
+ | Source / connection status | Car Bluetooth / GPS | drive + parked | `車輛藍牙` / `GPS` + shape mark; cannot be hidden by any layout setting |
- | Speed-limit marker + over-speed numeral | BLE/GPS + map | drive | numeral is the sole warning |
+ | Taiwan fixed-camera alert (trigger card) + over-listed-limit state | phone GPS + NPA dataset 7320 | drive | amber + ▲ + text; US hidden |
- | ⊕ Power / regen bar (kW) | BLE* / OBD | drive | …
+ | Power / regen bar (kW) | BLE* / OBD | v1.x | default off; not in v1 |
- A composite source coordinates them: **speed = freshest of {BLE, GPS}**
+ A composite source coordinates them: **speed = Car Bluetooth while valid, else GPS while valid, else `—`;
+ switch back to Bluetooth after 2 consecutive valid readings** (01 §3.3).
```

**Screen inventory**
```diff
+ - (第五輪起由 §4.0 取代)主要設計稿是 `docs/design/frames/landscape-mockups.html`;直式的 `stage2-mockups.html` 和 `.pen` D/D2/D3/E/F 都是已取代的參考。
```

**Component states**
```diff
- Toggle: off `surface.raised` knob `text.secondary` / on `accent` knob `bg.base`.
+ Toggle: off `surface.raised` + `border.control` outline, knob left / on `accent`, knob right (position differs, not only color).
+ Every tappable target ≥44×44. A settings row has one tap target (no toggle + chevron in the same row).
+ Buttons: primary `accent` fill + `bg.base` text, radius 16, height 52 / secondary `pill.border` outline / text button `accent.text`.
+ Destructive: `danger.text` #FF8A9B + `danger.border` #6A2C39. Confirmations use a bottom sheet (`sheet.bg` #121C2B, top radius 24, grab handle).
+ Hit areas: iOS ≥44×44 pt, Android ≥48×48 dp, measured per target (each swatch, each segmented option), not per row.
```

**Over listed limit 和無有效車速(L18)**
```diff
+ Over (ahead mode only): amber numeral + ONE ▲ above the numeral. The card has no ▲; it reads 「超過點位資料速限 60 km/h」.
+ Card units follow the user's unit setting (60 km/h ↔ 37 mph); comparison stays in km/h internally.
+ No valid speed: 「—」 with 「車速暫不可用」 directly under it (in the unit position), plus the ▲ chip.
+ Fresh P but no speed value (parked): 「P 檔」 at 110/700 + 「車速暫不可用」; no arc, no 0.
```

**Landscape 和大字與高對比(L19,新段落)**
```diff
+ Landscape (844×390): gauge fixed on the left (center 250,195), right column for alert card + status bar (drive)
+ or date, status, trip, compact tire tiles (parked). The gauge never moves when an alert appears. 60px side safe area.
+ Large text & high contrast: the speed numeral stays 158; secondary text scales ~1.3–1.4×
+ (chip 18, unit 28, card 19/36, status 21). High-contrast overrides: secondary text #E3EAF4, borders #4F8796, track #33476A.
+ Parked may scroll in large-text mode (L24): gauge and chip stay fixed, the data area scrolls; drive never scrolls.
+ Landscape margins = device SafeArea + 16 (not a fixed 60).
+ Three-digit speed: 140px, tracking -6, weight 700 so the numeral stays inside the ring (L26).
```

**Taiwan fixed-camera alert(L8,新段落)**
```diff
+ Two modes share one card position (y 522; the numeral never moves):
+ - **Nearby (v1 default)**: two-line card「附近有測速點 / 點位資料速限 60 km/h」. No distance, never amber.
+ - **Ahead**: distance + amber "over" state. Ships only after road matching and data validity are field-validated (00-rulings L8).
+ The limit is compared in km/h internally and shown in the user's unit. The card always says 「點位資料速限」 + unit; never a round speed-limit sign.
+ Data carries a version and a last-validated date; past its validity window, amber and definite limit wording stop.
```

**Location permission(L9,新段落)**
```diff
+ Denying location only disables GPS speed and camera alerts. A valid Car Bluetooth speed stays on screen;
+ the chip adds a second line 「GPS 不可用」. The full explanation lives in Settings, not on the HUD.
```

---

## 5. 假設

| # | 假設 | 理由 |
|---|---|---|
| A1 | `.pen` D2(`za9HJ`)是新 drive 畫面的幾何和色彩底稿;D(`Bt6YY`)只沿用色彩 | 主持人指示;DESIGN.md 已退役指針錶盤 |
| A2 | 狀態規格以 01 為準;01 沒寫的看 `DESIGN.md` 和 `design/index.html` | 01 是這次的流程規格 |
| A3 | **HTML 稿是主要設計稿**;PNG 是它的匯出,兩者不一致時以 HTML 為準 | `00-rulings.md` L5(使用者已確認) |
| A4 | HTML 從 Google Fonts 載入 Inter 和 Noto Sans TC(L15),headless Chrome 已確認兩者都有載入;實作要隨 app 打包 Noto Sans TC | L15 |
| A5 | 畫面一律用台灣設定:km/h、km、bar、繁中;S04-f 另附一張英文 | 第一批的範圍;美國版放下一批 |
| A6 | 示意車速:GPS 72、藍牙 112(三位數)、前方 58、超過 68(點位速限 60) | 涵蓋二位數、三位數和琥珀狀態 |
| A7 | S22、S08 的長頁會捲動;匯出時拉長畫布,按鈕畫在內容最下方 | 01 §7.1 寫明設定類可捲動 |
| A8 | 觸發區平常不畫任何東西,PNG 上看不到「保留位置」;位置固定在 y 522–582 | 01 A15「不畫空框」 |
| A9 | 第二批照 `00-rulings.md`;和 01 衝突時照裁定(例如 S03、S10 只講附近模式,S02-b 的文案方向) | 00-rulings 開頭「以這份為準」 |
| A10 | L9 的三張停車狀態稿畫在停車畫面(L9 的來源規則是針對停車畫面);S04-h 畫在行車畫面,因為它要證明定位被拒不會抹掉行駛中的藍牙車速 | L9、[03 R2-09] |
| A11 | 表單類畫面用同一套版型(標題 24/700、內文 15、按鈕高 52、底部固定),不另外畫插圖;S15 用通用圖示 | 主持人「表單和列表類畫面可以簡單一點」 |
| A12 | S23 畫英文(美國 B 只在美國上線);其他畫面一律繁中 | [01 §6] 一屏一種語言 |
| A13 | ~~橫式行車畫面的量表一律固定在左側~~ → L31 改成置中、行車和停車同位置;主要設計稿等老闆選定方向後一起改(L32) | L25 → L31 |
| A14 | mph 時,前方距離暫用 mi(0.2 mi);前方模式 v1 不上,啟用前再訂 | L27 |
| A15 | PNG 檔名和 HTML 錨點維持 visual 標籤,不改名;產品狀態以 01 畫面 ID 為準(§2 對照) | 04 第四階段;避免 03、04 的引用失效 |
| A16 | 已取代的 6 張舊稿 PNG 不刪、不重新匯出;HTML 圖庫裡的舊稿是用目前樣式重畫,和舊 PNG 可能略有差異 | 主持人指示保留舊稿 |
| A17 | 價格、到期時間是示意值(NT$290、10/25 11:10),實作從商店和試用紀錄取得 | L14、ux 12:22 補充 |
| A18 | 橫式參考畫布用 iPhone 14/15(844×390,SafeArea 59 / 59 / 21),另用 667×375 檢查最小尺寸;實作讀裝置的 SafeArea | 01 §7.1、04 第四階段 |
| A19 | 停車畫面的來源標示照 01 §7.2 放在右欄最上方(行車畫面在左上);量表位置兩者相同 | 01 §7.2 |
| A20 | 表單和長文案頁的 PNG 只畫第一屏並標「↓ 可捲動」,完整文案以 01 §6 為準 | 實際尺寸比較能檢查版面 |
| A21 | 前方模式(距離、琥珀)v1 不開,這輪不畫橫式版 | L8、ux 14:41 第 3 項 |
| A22 | 第一段用 360×330 的比較畫布,放在畫布扣掉底部 SafeArea 後的正中間;第二段改用 01 §7.4 的量表區(844 寬 300×300、667 寬 280×280),四個版本放在同一個位置 | L31、L35、01 §7.4 |
| A23 | 刻度上限沿用 240 km/h;mph 版等方向選定後再畫 | `DESIGN.md` Gauge spec |
| A24 | ~~「P 停車」晶片~~ → ~~L36:檔位改成 40×32 的字母方塊~~ → L43:檔位改成數字正上方的 `P R N D` 一排;原本檔位格的位置(844 (422, 318)、667 (333, 302))改給 ▲(L46,§8.1) | 01 §7.4、L43、L46 |

| A25–A28 | 第七輪的假設見 §8.6 | — |

## 6. 待確認問題

| # | 問題 | 給誰 |
|---|---|---|
| Q1 | ~~能不能刪零散節點~~ → 已裁定可刪 `N1tDcE`、`BwQnM`;等 Pencil 連得上再刪 | lead(已裁定,待執行) |
| Q2 | ~~檔位放哪~~ → 照 01 §8 放狀態列 | 已解決 |
| Q3 | ~~「行駛自動切換極簡」~~ → 01 刪除 | 已解決 |
| Q4 | ~~中文字型~~ → L15:Inter + 打包 Noto Sans TC,已套用 | 已解決 |
| Q5 | 新畫面要不要同步回 `.pen`?要的話需要先重連 Pencil MCP | 使用者 |
| Q6 | ~~觸發卡片要不要加單位~~ → L18:要,跟著設定換算;S04-e/f/n 都已加,另有 mph 三張 | 已解決 |
| Q7 | ~~琥珀時兩個 ▲~~ → L18:只留數字上方一個;S04-f 已改 | 已解決 |
| Q8 | ~~狀態列位置~~ → L18:暫留 y 640 | 已解決 |
| Q9 | ~~「—」可讀性~~ → L18:保留「—」,下方加「車速暫不可用」;S05 已改(S06-h 等第二批一起改)。強光和反射下的辨識仍要實測(03 T03/T06) | 已解決(待實測) |
| Q10 | ~~S06 的長來源文字會不會和日期膠囊擠在一起~~ → L9 後來源標示改成「◐ GPS · 藍牙中斷」這類短字串;S06-g/h/i 已畫,和膠囊(y 96)沒有重疊 | 已解決 |
| Q11 | ~~舊值變暗~~ → L21:舊值 ≥4.5:1,用歷史色 + 時間;已套用 | 已解決 |
| Q12 | ~~S04-h 第二行~~ → 01 §6.1 合成一行「● 車輛藍牙 · GPS 不可用」;已套用 | 已解決 |
| Q13 | ~~附近卡兩行~~ → 01 §11:維持兩行 | 已解決 |
| Q14 | ~~S02-b 文案~~ → 01 §11:S05 上一行 + 按鈕,完整說明移 S08;已套用(S05-b、S08) | 已解決 |
| Q15 | ~~S07 依據~~ → L20 文案;已套用 | 已解決 |
| Q16 | ~~S18-h 按鈕~~ → 「重新檢查並繼續」+「稍後」;已套用 | 已解決 |
| Q17 | ~~S19 改配對~~ → 只確認一次,加沒完成訊息;已套用(S19-c、S19-d) | 已解決 |
| Q18 | ~~S10 停用列~~ → 不顯示;已拿掉 | 已解決 |
| Q19 | ~~已用過試用~~ → L14 / 04:Android 不畫已用過;iOS 恢復 / 已結束狀態列在 §2.3 | 已解決 |
| Q20 | ~~最後驗證~~ → L23 / 04:開發者本人發布前對照與實地抽查;S10 已加說明 | 已解決 |
| Q21 | ~~檔位資料已過期~~ → 01 §11:停車畫面不顯示過期 P(改 S04-i);手動停車寫藍牙實際狀態;已套用(S06-d) | 已解決 |
| Q22 | ~~mph 距離~~ → L27:暫用 mi | 已解決 |
| Q23 | ~~大字停車捲動~~ → L24:可以;已標一屏底線 | 已解決 |
| Q24 | ~~橫式量表位置~~ → L25:固定在左;第六輪 L31 改成置中 | 已解決 |
| Q25 | ~~三位數~~ → L26:縮字級和字距;已改 140 / -6(最小字級見 Q28) | 已解決 |
| Q26 | S10-b 的「前往 App Store 更新」(Android 是 Google Play)是照 04 建議加的入口,01 文案表沒有這一列 | ux |
| Q27 | S09 沒連車提示用了 safety R4-09 的文案,01 §6.4 還是舊句「行車時只會顯示車速」,需要同步 | ux |
| Q28 | ~~三位數 140px 是否通過~~ → safety 12:49:140 / 700 / 字距 -6 通過靜態版面,暫作下限;實機視距、強光、夜間仍待測 | 已解決(待實測) |
| Q29 | ~~S24 關閉按鈕~~ → 01 §11:成功類「完成」、可重試「關閉 + 重試」、其他「關閉」;已畫三張 | 已解決 |
| Q30 | ~~停車畫面來源標示位置~~ → ux 和 safety 都裁定回左上 (75,16);右欄頂端固定車況狀態行;已改 | 已解決 |
| Q31 | ~~設定改單欄的寬度~~ → 一律兩欄;右欄 <360 pt 或 AX 大字才單欄;已補 S08 AX 稿 | 已解決 |
| Q32 | ~~兩側安全距離~~ → flutter:max(viewPadding.left, viewPadding.right) + 16,兩側套用 | 已解決 |
| Q33 | S14 鍵盤上方的「收起鍵盤」是 visual 照 R5-01 加的,01 文案表沒有這個字 | ux |
| Q34 | 速度表要用哪個方向(現在的版本 / A / B / C)?選定後才改 `landscape-mockups.html` 和 `DESIGN.md` | 老闆(經 lead) |
| Q35 | ~~A、C 的檔位位置~~ → L36、R6-01:四個版本都放量表區內、數字下方同一個位置;A 放在速度條下方(§7.7.4) | 已解決 |
| Q36 | B 的 41 段在強光下、C 的扇面填色在夜間,實機看起來會不會太暗或太亮?(靜態對比已通過) | safety(實測) |
| Q37 | ~~新方向比 300×300 大~~ → L35:量表區不變,錶縮進去;四個版本都放得進 300×300 和 280×280(§7.7.3) | 已解決 |
| Q38 | ~~A 的 ▲ 會壓到數字~~ → L39:選 A 時 ▲ 放數字正上方 → L46:四個版本都改放數字正下方(§8.1.3) | 已解決 |
| Q39 | ~~沒資料要不要留虛線軌道~~ → L39:保留低對比(<3:1)的虛線 / 點線空軌道,不畫填色、標記、刻度數字、檔位;B 改成隔段細點(R6-06) | 已解決 |
| Q40 | ~~三位數看字級還是字高~~ → L39:看實際字高,844 寬 ≥105、667 寬 ≥100(字級 ≥140 為輔);四個版本都合格(§7.8.4) | 已解決 |
| Q41–Q44 | 第七輪的問題見 §8.6 | — |

## 7. 第六輪:速度表參考和三個方向

> 2026-10-18,第六輪第一段(`00-rulings.md` L31、L32)。比較頁:`docs/design/frames/gauge-variants.html`(不帶參數看全部;`?screen=<ID>` 看單張);PNG 在 `docs/design/frames/gauge-variants/`(2x,24 張)。`landscape-mockups.html` 和 `frames/landscape/` 沒有改;`frames/tire/` 沒有碰。

### 7.1 重點

- 找了 13 個參考(量產車 9、手機 HUD app 2、設計作品 2),共同結論:**看一眼就讀得到的儀表,都是「數字最大、圖形只負責量感」**;多錶並列、3D 場景、發光細字是常見的反例。
- 三個新方向:**A「直讀數字」**(不畫錶盤,數字加一條橫向速度條)、**B「點陣環」**(封閉分段 LED 環)、**C「扇形」**(上半圓實心扇面)。三者的圖形語言不同(線 / 環形點陣 / 實心面積),不是同一個弧形換顏色。
- 四個版本(含現在的版本當對照)都畫了 88、128、沒資料、0 停車四種狀態;三位數都 ≥140 px;放進 844×390 和 667×375 的正中間都放得下。
- 硬規則都守住:沒資料是「—」+「車速暫不可用」,軌道改虛線、沒有填色和標記,不畫成 0;數字不做補間;沒有 TESLA 字樣或車廠標誌;停車用「P 停車」文字晶片,不只靠顏色。

### 7.2 參考

查閱日期都是 2026-10-18。「讀不讀得到」指一眼(約 0.3 秒)能不能讀到車速。

| # | 參考 | 類型 | URL | 核心想法 | 可以借用 | 要避開 |
|---|---|---|---|---|---|---|
| 1 | Porsche Taycan 儀表 | 量產車 | [Porsche Newsroom](https://newsroom.porsche.com/en/products/taycan/interior-design-18552.html)、[Motor1](https://www.motor1.com/news/366633/porsche-taycan-interior-revealed-official/) | 中央「錶」是功率環包著數位車速;Pure 模式只剩車速、路標和導航箭頭 | 環包數字(B);只留車速的模式(A) | 三錶並列時,兩側的錶會搶注意力 |
| 2 | BMW iDrive 8 曲面螢幕 | 量產車 | [J.D. Power](https://www.jdpower.com/cars/shopping-guides/what-is-the-bmw-curved-display)、[BMWBlog](https://www.bmwblog.com/2021/09/16/bmw-idrive-8-is-the-best-bmw-infotainment-system-ever/) | 圖形錶其實只是在「視覺化一個數字」;Calm 模式只顯示車速 | 數字為主、圖形為輔(A) | 反向或不規則的錶形,單看圖形判讀不準 |
| 3 | Mercedes MBUX 駕駛顯示 | 量產車 | [AutoGuide](https://www.autoguide.com/auto/manufacturers/mercedes-benz/2023-mercedes-benz-glc-300-exploring-the-mbux-driver-displays-44607835)、[Mercedes-Benz](https://group.mercedes-benz.com/innovation/digitalisation/connectivity/mbux-hyperscreen.html) | Understated 模式:數位車速 + 兩側細錶;Sport 模式:大中央錶 + 紅色元素 | 細、低調的圖形(A、B) | 大量紅色(本案紅色只給目前值標記) |
| 4 | Polestar 2 駕駛顯示 | 量產車 | [Driving Electric](https://www.drivingelectric.com/polestar/2/interior) | 可切換「Minimalistic」主題,只留最重要的行車資訊 | 少即是多的主題 | — |
| 5 | Lucid Air Glass Cockpit | 量產車 | [TechCrunch](https://techcrunch.com/2021/05/26/lucid-motors-reveals-all-the-tech-inside-its-all-electric-air-sedan) | 中央儀表只放車速和續航,畫面乾淨 | 車速 + 續航的組合(呼應 L33) | 輔助駕駛啟用時整個儀表換成 3D 場景 |
| 6 | Rivian R1T 駕駛顯示 | 量產車 | [Unreal Engine](https://www.unrealengine.com/spotlights/rivian-s-r1t-features-state-of-the-art-hmi-designed-developed-and-deployed-in-unreal-engine)、[Rivian Forums](https://www.rivianforums.com/forum/threads/driver-screen-settings-did-you-know.26088/post-539646) | Unreal 即時 3D 場景;車主抱怨車速不夠大、希望放中間 | 反例教訓:車速要大、要置中(L31) | 卡通化周圍車輛佔掉大片面積 |
| 7 | 小米 SU7 | 量產車 | [CarNewsChina](https://carnewschina.com/2024/02/08/xiaomi-su7-official-interior-details-and-winter-testing/)、[Wikipedia](https://en.wikipedia.org/wiki/Xiaomi_SU7) | 7.1 吋小儀表 + 大型 HUD,車速放在視線中央 | 置中、大數字 | AR 疊圖太多 |
| 8 | Hyundai Ioniq 5 | 量產車 | [Hyundai](https://www.hyundai.com/worldwide/en/eco/ioniq5-2022/design)、[國土交通省召回 PDF](https://www.mlit.go.jp/en/jidosha/content/001998660.pdf) | 無遮罩 12.3 吋儀表;召回案例:儀表軟體重啟時車速不顯示 | 教訓:「沒資料」要有明確畫法,不能空白或卡住舊值 | — |
| 9 | NIO ET7 | 量產車 | [CarNewsChina](https://carnewschina.com/2022/03/10/nio-et7-flagship-first-review-test-drive-best-ev-up-to-date/) | 10.2 吋極簡儀表 + HUD | 克制的資訊量 | 小儀表上的小字 |
| 10 | 新一代 Apple CarPlay(Porsche、Aston Martin) | 量產車介面 | [Motor Authority](https://www.motorauthority.com/news/1141817_next-generation-apple-carplay-coming-to-porsche-and-aston-martin)、[MacRumors](https://www.macrumors.com/2024/04/11/next-generation-apple-carplay-details/) | 品牌化的錶:Aston 用極簡錶 + 單一品牌色描邊;Porsche 是三錶 | 單一強調色的描邊(C 的扇面邊) | 雙類比錶並列分散注意力 |
| 11 | ustwo 儀表概念 | 設計作品 | [ustwo](https://ustwo.com/blog/ustwo-reimagines-the-in-car-cluster/) | 「指針指著數字真的最好嗎?」改用長條;車速是主角,降低視線離開路面的時間;選人文主義字體 | 長條代替錶盤(A);縮短注視時間 | 只靠顏色表示超速(本案要形狀 + 文字) |
| 12 | 手機 HUD app(HUDWAY Go、Speedometer One 等) | 手機 HUD | [App Store:HUDWAY Go](https://apps.apple.com/us/app/hudway-go-navigation-with-hud/id1080193989)、[HUDWAY Speedometer](https://hudway.co/apps/speedometer)、[App Store:Speedometer One](https://apps.apple.com/us/app/digital-gps-mph-speedometer/id1351828788) | 大數字 + 少量資訊,很多有鏡像模式 | 數字優先 | 鏡像(L29 已拿掉);霓虹細字對比不足 |
| 13 | Dribbble 的 EV 儀表作品 | 設計作品 | [apostol:Automotive](https://dribbble.com/apostol/collections/6668468-Automotive)、[klimevtushenko:Speedometer](https://dribbble.com/klimevtushenko/collections/3083635-speedometer) | 發光環、分段 LED、動態掃描 | 分段點陣環(B) | 發光模糊、細字、掃針補間動畫 |

### 7.3 三個方向

> 第一段的概念。第二段(L37、L38)換了各自的配色和字型,數字大小也改了,見 §7.7.2、§7.7.3。

| 方向 | 一句話概念 | 參考 | 為什麼一眼就讀得到 |
|---|---|---|---|
| **A「直讀數字」** | 不畫錶盤,數字本身就是錶:數字放到最大,底下一條橫向速度條(0–240)和紅色目前值標記 | 1(Pure)、2(Calm)、3(Understated)、11、12 | 數字最大(兩位數 200 px、字高約 146 px,比現在的 158 px 大約 27%);周圍沒有環和數字搶位置;速度條只在餘光提供量感 |
| **B「點陣環」** | 封閉的 300° 分段 LED 環(41 段、每 60 km/h 一段長刻度),亮到目前速度,最前一段最亮並加紅色標記 | 1(功率環)、3(Sport)、13 | 亮段和暗段對比 9.5:1,餘光看「亮了多少」就知道快慢;數字 150 px 仍在環中央;離散的段比細弧容易在強光下辨認 |
| **C「扇形」** | 上半圓實心扇面,填色面積代表速度,單一強調色描邊;數字擺在扇面前方 | 10(類比掃描感)、1、5、9 | 面積比線條更容易被餘光看到;數字壓在扇面上仍有 10.2:1;只用一個顏色,沒有多錶並列 |
| 對照:現在的版本 | 250° 細環 + 端點 + 紅色目前值標記;數字 158 px | — | — |

### 7.4 尺寸、狀態和對比

> 這一節是**第一段**(360×330 特寫、統一配色)的量測。第二段的尺寸、顏色和對比見 **§7.7**;檔位位置已由 L36 裁定,見 §7.7.4。

**數字大小與放入檢查**(特寫區塊 360×330,放在畫布正中間)

| 版本 | 兩位數 | 三位數(L26 ≥140) | 844×390 | 667×375 |
|---|---|---|---|---|
| 現在 | 158 / 字距 -5 | 140 / -6 | 放得下 | 放得下(區塊上下各留 22) |
| A 直讀數字 | 200 / -6 | 168 / -7 | 放得下 | 放得下 |
| B 點陣環 | 150 / -5 | 140 / -7 | 放得下 | 放得下 |
| C 扇形 | 170 / -6 | 150 / -7 | 放得下 | 放得下 |

**和 01 §7.4 量表區的尺寸對照**(用 headless Chrome 量實際外框:圖形含筆畫寬、文字用字框、含「P 停車」晶片;四種狀態取最大)

01 §7.4 的量表區是 844 寬 300×300、667 寬 280×280,而且是照現在的錶外徑定的(01 A25)。特寫稿用 360×330 畫,所以新方向放進 01 的量表區時要縮小,或者量表區要放大。

| 版本 | 外框 寬 × 高 | 放進 300×300 | 放進 280×280 | 建議 |
|---|---|---|---|---|
| 現在 | 300 × 281 | 剛好 | 要縮約 7% | 和 01 的假設一致 |
| A 直讀數字 | 305 × 304(數字字框;實際墨跡較窄) | 寬差 5、高差 4 | 寬差 25 | 最寬的是三位數字框:三位數改 164、整組上移 4 就放得進 300;280 時三位數改 152、速度條縮到 260 寬(仍 ≥140) |
| B 點陣環 | 321 × 301 | 寬多 21 | 寬多 41 | 環縮到外徑 148 / 內徑 127(300 寬);280 寬時環要變細(外 138 / 內 124),三位數 140 才放得進內圈 |
| C 扇形 | 343 × 301 | 寬多 43 | 寬多 63 | 縮到 R 150 / r 106 就放得進 300(數字本來就壓在扇面上);或量表區改成寬 344 × 高 300 的長方形,側欄每邊少 22 |

> 連帶影響:量表區每寬 2,側欄就各少 1(01 A25)。選 C 又不縮的話,胎壓區從 184 寬變成約 162 寬,會影響 tire 的 Q27。第二段畫完整畫面時,會照老闆選的方向重算。

**檔位放在量表底部缺口(回答 01 Q28)**

| 版本 | 底部有沒有缺口 | 檔位放哪(稿上的位置) |
|---|---|---|
| 現在 | 有,250° 錶留 110° 缺口(兩端距離約 240) | 缺口正中間,錶中心下方 120,和 01 §7.4 的 (422, 318) 一致 |
| B 點陣環 | 有,300° 環留 60° 缺口(內圈兩端距離約 136) | 缺口正中間,錶中心下方 128;寬 ≤ 80 的晶片放得下 |
| C 扇形 | 沒有缺口;底邊是平的 | 單位下方、兩個扇腳之間,錶中心下方 88;和數字同一眼,需要 ux 確認 |
| A 直讀數字 | 沒有錶盤 | 數字上方(稿上 top 8);01 把前方模式的 ▲ 也放在數字上方,兩者同時出現時要再排(前方模式 v1 不開),需要 ux 確認 |

**狀態畫法**(四個版本共通)

| 狀態 | 畫法 |
|---|---|
| 88 km/h | 數字白色;圖形填到 88/240;紅色目前值標記 |
| 128 km/h | 三位數縮字級和字距,留在區塊內;字重不變 |
| 沒資料 | 「—」(`#8A97AE`)+ 下一行「車速暫不可用」;軌道改虛線(A 點線、B 段落變暗、C 虛線外框),**沒有填色、沒有紅色標記**,所以不會被看成 0 |
| 0 km/h 停車 | 數字「0」+ 紅色標記停在 0;加一個「P 停車」文字晶片,就是 01 §7.4 的檔位(A 放數字上方,其他放底部缺口 / 單位下方,見下方檔位表)。只在新鮮的 P 時顯示 |

數字更新一律直接跳(不補間);填色和亮段也直接切換,減少動態時不做任何動畫。

**對比**(以漸層中心 `#101B2E` 計算)

| 元素 | 前景 / 背景 | 對比 | 門檻 |
|---|---|---|---|
| 數字 | `#F2F5FA` / `#101B2E` | 15.77 | 4.5 |
| 數字壓在扇形填色上(C) | `#F2F5FA` / `#1B3F53` | 10.21 | 4.5 |
| 數字壓在扇形底環上(C) | `#F2F5FA` / `#182338` | 14.38 | 4.5 |
| 「—」 | `#8A97AE` / `#101B2E` | 5.84 | 3.0(大字) |
| 單位、刻度數字 | `#8A97AE` / `#101B2E` | 5.84 | 4.5 |
| 刻度數字壓在扇形底環上(C) | `#8A97AE` / `#182338` | 5.33 | 4.5 |
| 「車速暫不可用」 | `#AEBCD4` / `#101B2E` | 8.98 | 4.5 |
| 「P 停車」晶片文字 | `#AEBCD4` / `#0E1A24` | 9.18 | 4.5 |
| 點陣環亮段(圖形) | `#2BD4E0` / `#101B2E` | 9.52 | 3.0 |
| 速度條填色 vs 底軌(圖形) | `#2BD4E0` / `#1E2A40` | 7.94 | 3.0 |
| 紅色目前值標記(圖形) | `#E8344F` / `#101B2E` | 4.13 | 3.0 |
| 沒資料虛線(裝飾) | `#33476A` / `#101B2E` | 1.85 | 不需要(狀態由「—」和文字表達) |

### 7.5 PNG 清單

**第二段(第三段更新後)**:`docs/design/frames/gauge-variants/`,共 45 張(第三段新增 8 張,見 §7.8.6),由 `docs/design/frames/export-gauges.sh` 匯出(2x)。版本 = `cur`(現在)、`A`、`B`、`C`。

| 檔名 | 尺寸 | 內容 |
|---|---|---|
| `compare.png` | 1760×1400 | 給老闆比較:四個版本的行車一般 + 停車縮圖,各配一行白話說明和安全排序(第三段更新) |
| `<版本>-drive.png` | 844×390 | 行車一般:車輛藍牙 88 km/h、檔位 D、左下 `72% / 315 km` |
| `<版本>-alert.png` | 844×390 | 行車 + 附近測速提醒卡(58 km/h,點位資料速限 60) |
| `<版本>-nodata.png` | 844×390 | 行車沒資料:「—」+「車速暫不可用」,來源「▲ 搜尋 GPS 訊號…」,沒有檔位和電量 |
| `<版本>-parked.png` | 844×390 | 停車:0 km/h、檔位 P、日期膠囊、左欄行程、左下電量、右欄胎壓圖示(第三段換掉佔位框,第四段帶進 T1–T3 修正) |
| `<版本>-drive667.png` | 667×375 | 小螢幕行車一般(量表區 280×280) |
| `<版本>-parked667.png` | 667×375 | 小螢幕停車(胎壓 165×272)(第三段新增) |
| `tire-<狀態>.png` | 184×288 | 胎壓圖示:有值、時間未知、歷史值、單輪缺值(第三段新增) |
| `<版本>-88 / -128 / -na / -0.png` | 300×300 | 量表區特寫(88 D、128 D、沒資料、0 P) |

**第一段(已取代)**:360×330 特寫和 `fit844`、`fit667` 共 24 張,搬到 `docs/design/frames/gauge-variants/part1/` 保留。

### 7.6 建議改法(老闆選定方向後才寫進 `DESIGN.md`)

新的候選 token(只在被選中的方向用到時才採用):

| Token | 值 | 用在 |
|---|---|---|
> 第二段更新:每個方向有自己的一組 token(§7.7.2),選定後只採用那一組;下表是各方向共用的部分。

| Token | 值 | 用在 |
|---|---|---|
| `gauge.trackNoData` | 各方向的「沒資料」色(§7.7.2),虛線 / 點線 | 沒資料時的軌道;不畫填色、標記和刻度 |
| `gauge.area` | 844 寬 300×300、667 寬 280×280(01 §7.4、L35) | 量表區 |
| `gear.box` | 40×32、圓角 8、`card` 底 + `cardBd` 框,字母 19 / 700;中心在量表區底部往上 32(300)/ 28(280) | 檔位 D / P(L36),取代第一段的「P 停車」晶片 |
| `speed.hero` | 現在 158 / 140;A 196 / 150;B 172 / 150(280 寬 142);C 176 / 148(280 寬 144)(兩位數 / 三位數;第三段依 L39 更新) | 被選中的方向 |
| `speed.minDigitHeight` | 三位數實際字高:844 寬 ≥105、667 寬 ≥100(L39,取代只看字級 ≥140) | 換字型時的檢查標準 |
| `speed.digits` | 一律 `tabular-nums`(L38);字重 ≥600 | 車速、電量、提醒卡數字 |

**字型**(都是 SIL Open Font License 1.1,可以隨 app 打包;只打包被選中方向的那一套,Flutter 用 `FontFeature.tabularFigures()`):

| 方向 | 字型 | 用到的字重 | 等寬數字 | 來源 |
|---|---|---|---|---|
| 現在 | Inter | 500、700 | 有 | 已在 L15 採用 |
| A | Jost | 500、600 | 有 | [Google Fonts:Jost](https://fonts.google.com/specimen/Jost) |
| B | Exo 2 | 600、700 | 有 | [Google Fonts:Exo 2](https://fonts.google.com/specimen/Exo+2) |
| C | Barlow Semi Condensed | 500、600 | 有 | [Google Fonts:Barlow Semi Condensed](https://fonts.google.com/specimen/Barlow+Semi+Condensed) |

中文(原因文字、提醒卡)一律 Noto Sans TC(L15),不跟著方向換。試過但沒用的:Lexend、Rajdhani(沒有等寬數字,速度跳動時寬度會變)、Share Tech Mono(只有 400 字重,不符合 L38 的 ≥600)。

`DESIGN.md` Gauge spec 的改法(以 A 為例;選 B 或 C 時換掉圖形描述):
```diff
- - Sweep: `startAngle = 215°`, total sweep `-250°` (CW). ...
+ - Gauge is centered on screen (00-rulings L31) in the gauge area from 01 §7.4 (resized for the chosen direction); it never moves when alerts appear or between drive and parked.
+ - Direction A "Direct numeral": no dial. Jost 600, tabular figures; numeral 196 (3 digits 150); a 224-wide horizontal speed bar
+   below the unit (ticks at 60/120/180, no tick numbers), filled near-white, current value = a taller white bar. The numeral is the gauge.
+ - Gear letter (D / P) in a 40×32 box inside the gauge area, below the numeral, same place in drive and parked (00-rulings L36).
+ - No data: "—" + "車速暫不可用"; dotted `gauge.trackNoData` track; no fill, no marker, no ticks, no gear — never drawn as 0, never a frozen old value.
+ - Values update instantly (no tween); reduced motion changes nothing else. Speed digits contrast ≥7:1 (L38).
```

### 7.7 第二段:四個速度表放進置中版面(L35–L38)

> 2026-10-18,第六輪第二段。依據:L35(量表區大小)、L36(檔位位置)、L37(三個方向要更不一樣)、L38(safety R6-01–R6-05 照單全收)、01 §7.4、ux 16:15。比較頁 `docs/design/frames/gauge-variants.html`:最上面是「給老闆比較」,下面是每個版本的 5 張完整畫面和 4 張特寫。`landscape-mockups.html`、`frames/landscape/`、`frames/tire/` 都沒有改。

#### 7.7.1 給老闆比較

合成圖:`docs/design/frames/gauge-variants/compare.png`。四張都是行車一般(車輛藍牙 88 km/h、D、`72% / 315 km`);除了中間的速度表,其他東西的位置都一樣。

| 版本 | 頁面上的白話說明 | 適合的感覺 |
|---|---|---|
| 現在 | 青色細圓環加紅色指標,就是現在 app 的樣子。 | 熟悉、穩定 |
| A 直讀數字 | 只留一個大數字和一條細線,黑白配色,最安靜,看一眼就走。 | 極簡、安靜(Porsche Pure、BMW Calm) |
| B 點陣環 | 一圈短短的燈格隨車速亮起來,電光藍色,像電動車的科技儀表。 | 科技、未來感 |
| C 扇形 | 半圓金屬錶盤加紅色指針,槍灰銀色,像傳統跑車的指針錶。 | 經典、機械感 |

#### 7.7.2 三個方向各自的配色、字型和質感(L37、L38)

| | 現在(對照) | A 直讀數字 | B 點陣環 | C 扇形 |
|---|---|---|---|---|
| 背景 | 深藍漸層 `#101B2E → #070B14` | 中性黑 `#171717 → #060606`,平面 | 深靛藍 `#10143A → #03040E`,疊 6 px 細點陣 | 槍灰 `#1D1F23 → #0A0B0D` |
| 車速數字 | Inter 700,`#F2F5FA` | Jost 600,`#F7F7F5` | Exo 2 700,`#F0F3FF` | Barlow Semi Condensed 600,`#F5F7FA` |
| 量表圖形 | 250° 細環,填色 `#2BD4E0` | 224 寬的細速度條,填色 `#E6E6E3`、底軌 `#2C2C2C` | 41 段短 LED,亮 `#6F88FF`、暗 `#232A5C` | 半圓刻度帶(金屬漸層 `#3A3E45 → #26292E`),銀白填色 30%、外緣亮線 `#E1E6EC` |
| 目前值 | 紅色短標記 `#E8344F` + 端點圓 | 比速度條高的白色直條(形狀) | 最前一段最亮 `#E4E9FF`、最粗(形狀) | 紅針 `#E8344F`,只在外弧帶裡(半徑 120–144),下墊深色描邊 |
| 質感 | 細線、漸層 | 平面、沒有裝飾、沒有刻度數字 | 點陣底紋、分開的燈格;不用發光模糊(R6-02) | 金屬錶面,每 10 一小格、每 40 一大格;不放刻度數字(R6-02) |
| 次要文字 | `#AEBCD4` | `#C9C9C6` | `#C7CDEF` | `#CDD2D9` |
| 卡片底 / 框 | `#0E1A24` / `#2C5A66` | `#121212` / `#3B3B3B` | `#0E1230` / `#3F4EA8` | `#15171A` / `#4A4F57` |

- **各方向不換的語意色**:來源綠點 `#3DE0A8`、GPS 搜尋三角 `#F5B53C`、電池綠、超速琥珀 `#FFB638`(這裡沒出現)、紅色目前值標記 `#E8344F`(現在的版本和 C)。
- **版面位置四個版本完全一樣**(L35):來源標示、齒輪、提醒卡、電量、胎壓區、檔位。
- **L38 不用暖色**:C 的主色 `#E1E6EC` 色相 213°、彩度 0.05,琥珀 `#FFB638` 色相 38°、彩度 0.78;C 的類比感靠刻度帶、金屬漸層和紅針表現。B 的 `#6F88FF` 色相 230°,在 safety 列的「冰藍 / 電光藍」範圍。

#### 7.7.3 尺寸(L35):四個版本都放得進量表區

用 headless Chrome 量實際外框(圖形含筆畫寬、文字用墨跡、含檔位方塊),四種狀態都量過:

| 版本 | 300×300 外框(x / y) | 280×280 外框(x / y) | 兩位數字級(300 / 280) | 三位數字級(300 / 280) | 三位數字高(300 / 280) | 數字和量表圖形的距離 |
|---|---|---|---|---|---|---|
| 現在 | 0–300 / −2–285(128 附近端點圓點超出上緣 2,原設計) | 0–280 / −2–269 | 158 / 147 | 140 / 140 | 105 / 105 | 細環內緣半徑 142(280 寬 133) |
| A | 36–269 / 33–285 | 28–259 / 30–269 | 196 / 183 | 150 / 150 | 109 / 109 | 沒有錶盤 |
| B | 1–300 / 1–285 | 1–280 / 1–269 | 172 / 161 | 150 / 140(第三段改 142) | 107 / 100(第三段 101) | 內徑 137 / **128**,內淨寬 274 / **256**(R6-01、R6-02);三位數墨跡角落離內圈 4.6 / 4.5(第三段 4.6 / 2.2,§7.8.4) |
| C | 1–299 / 8–285 | 1–279 / 7–269 | 176 / 164 | 146 / 140(第三段改 148 / 144) | 105 / 101(第三段 107 / 104) | 數字整個在內圈裡(內圈半徑 118 / 110),角落離內圈 6.3 / 3.7(第三段 8.0 / 2.6,§7.8.4);紅針不穿過數字 |

沒有縮不進去的方向。B、C 在 280 寬時三位數字級 140 合格,但換了字型後字高比現在的版本矮(見 Q40;第三段依 L39 改看字高,見 §7.8.4)。

**數字位置**:現在的版本、B、C 的數字墨跡中心在量表區中心往上 10(第三段 C 改成往上 6,R6-06)(844 寬畫面 y 190、667 寬 y 180),和 01 §7.4 一樣。**A 的數字中心比 01 高 36**(量表區內 y 104,844 寬畫面 y 154;667 寬內 y 97、畫面 y 147),因為 A 的單位、速度條和檔位都排在數字下方。結果是 A 的數字頂端到量表區 y 33,會壓到 01 規定的 ▲ 位置(見 Q38)。

#### 7.7.4 檔位(L36、R6-01)

- 四個版本都放在量表區底部往上 32(300)/ 28(280)的同一個位置:844 寬中心 (422, 318)、667 寬 (333, 302),和 01 §7.4 一樣。方塊 40×32,字母 19 / 700。
- 行車畫 D、停車畫 P,位置相同,切換時不跳(R6-01 第 2 點)。
- **現在的版本、B**:在底部缺口正中間。B 在 280 寬時,方塊左緣離最左下的燈格約 44(R6-01 第 3 點)。
- **A**:放在速度條下方,數字上方留給 ▲(R6-01)。
- **C**:放在單位下方、兩個扇腳之間;底緣在量表區內(300 寬 y 284、280 寬 y 268)。
- 沒資料時不畫檔位(不是新鮮資料)。

#### 7.7.5 照 safety 和 ux 改了什麼

| 來源 | 要求 | 怎麼改 |
|---|---|---|
| L38、R6-02 | 數字對比 ≥7:1、等寬數字、字重 ≥600;不用琥珀 / 橙 / 紅當主色 | 數字對比 15.4–16.7:1;四套字型都有等寬數字,而且都打開;A Jost 600、B Exo 2 700、C Barlow 600;C 改成槍灰金屬,不用暖色 |
| R6-01 | A 的 P 不放數字上方;行車稿補 D | A 的檔位移到速度條下方;所有行車稿和特寫都畫 D |
| R6-01、R6-02 | B 在 280 寬內徑 ≥128、內淨寬 ≥256 | 燈格改短(含圓頭 300 寬約 12、280 寬約 11),內端含圓頭剛好 128;最前一段改成變粗,不再往內伸 |
| R6-02 | C 的紅針不穿過數字;拿掉外圈刻度數字 | 紅針只在外弧帶裡(半徑 120–144,含描邊也不超出量表區);數字整個縮進內圈;刻度數字全部拿掉 |
| R6-02 | 不用強烈外發光 | B 拿掉發光模糊,改用點陣底紋和燈格形狀 |
| R6-05 | 沒資料時隱藏刻度數字 | 四個版本沒資料時都沒有刻度數字;A、C 連刻度線也不畫 |
| ux 16:15 (2) | 提醒卡第一行圖示 +「附近有測速點」,第二行「點位資料速限 60 km/h」15–16 pt | 照改;844 寬一行放得下,667 寬只會在「點位資料速限」和「60 km/h」之間換行 |
| ux 16:15 (3) | 停車頂列:來源短字 ≤160、日期膠囊 ≤140、高 ≤30、兩者相隔 ≥16 | 「● 車輛藍牙」約 75 寬;膠囊高 26、約 137 寬;兩者相隔約 200 |
| ux 16:15 (4) | 電量 16–18 pt、等寬數字;行車保留兩行、停車保留三行;只有一行時貼底 | 17 px 等寬;一行時貼在保留區底部(844 寬 y 343–369),行車和停車同一條線,切換不跳 |
| 主持人 | 胎壓區先放佔位框 | 「胎壓圖示 tire 製作中」+ 184 × 288,位置照 01 §7.4(x 585–769、y 72–360) |

#### 7.7.6 對比(L38)

文字(背景用漸層中心色;C 另算錶面中心 `#22252A`):

| 元素 | 現在 | A | B | C | 門檻 |
|---|---|---|---|---|---|
| 車速數字 / 底 | 15.77 | 16.71 | 16.03 | 15.38(錶面 14.32) | 7 |
| 「—」/ 底 | 5.84 | 8.63 | 9.44 | 8.65 | 4.5(現在的版本照舊,safety 第六輪已通過) |
| 單位、行程標籤 / 底 | 5.84 | 7.00 | 8.02 | 7.22 | 4.5 |
| 原因、來源、電量 / 底 | 8.98 | 10.80 | 11.33 | 10.86 | 4.5 |
| 檔位字母 / 方塊 | 16.12 | 17.46 | 16.53 | 16.73 | 4.5 |
| 提醒卡說明 / 卡 | 9.18 | 11.29 | 11.68 | 11.82 | 4.5 |
| 提醒卡 60 / 卡 | 16.12 | 17.46 | 16.53 | 16.73 | 4.5 |
| 提醒卡 km/h / 卡 | 5.97 | 7.32 | 8.27 | 7.86 | 4.5 |
| 設定圖示 / 底(圖形) | 4.13 | 5.32 | 5.75 | 5.40 | 3 |

圖形:

| 版本 | 對比 |
|---|---|
| 現在 | 填色 / 底軌 7.94;紅標記 / 底 4.13 |
| A | 速度條填色 / 底軌 11.17;目前值白條 / 底 17.93;刻度 / 底 3.31 |
| B | 亮段 / 底 5.61;亮段 / 暗段 4.27;最前一段 / 底 14.7(和亮段只有 2.62,靠粗細區分) |
| C | 外緣亮線 / 刻度帶 8.56;大刻度 / 刻度帶 6.39;銀色填色 / 刻度帶 2.16–2.38(輔助,讀值靠外緣亮線和紅針)。紅針 / 填色只有 1.19–1.47,所以紅針下墊深色描邊 `#0D0E10`:描邊 / 填色 3.14–3.88、紅針 / 描邊 4.63 |
| 沒資料虛線(裝飾) | 現在 1.85、A 2.02、B 1.91、C 2.57;狀態由「—」和「車速暫不可用」表示 |

#### 7.7.7 這一段沒畫的

- **S06-f**(新鮮 P 但沒有車速,中央寫「P 檔」):R6-05 第 2 點要求確認底部缺口不重複出現 P。這一段的任務沒列,選定方向後改主要設計稿時一起畫。
- **S07 右欄面板**(ux 16:15 (1))、**大字(XL)**、**英文版**:選定方向後一起畫。
- **胎壓車子圖示**:等 tire 完成,主持人通知後再放進停車畫面。


### 7.8 第三段:胎壓車子圖示放進停車畫面,加上 L39 的修改

> 2026-10-18,第六輪第三段。依據:tire 第二版(team-board 16:35、`05-tire-icon.md`「第二版修訂」、`frames/tire/tire-icon.html`)、L39(03「第六輪(畫面)」R6-06、R6-07)、ux 16:30(Q38、Q39)。`landscape-mockups.html`、`frames/landscape/` 沒有改;tire 的 SVG、HTML 和 05 都沒有改,只在 `frames/tire/` 寫入匯出的 PNG(主持人這次例外同意)。

#### 7.8.1 胎壓圖示怎麼放進四個版本

- **車子造型**:直接用 tire 的 SVG 原檔(`frames/tire/car-glass.svg`、`car-ceramic.svg`,和 `tire-icon.html` 內嵌的完全相同),不重畫。
- **四象限排版**:照 `tire-icon.html` 的 `panel()`(繁中、一般字級)移植:讀值位置、引線和端點的算法、文案、字級都一樣,只把顏色換成各版本的顏色。停車畫面用「有值」狀態;844 寬 184×288、667 寬 165×272,位置照 01 §7.4。
- **第四段**:改成 tire 修正後的排版:每輪三行的高度 16 / 24 / 28(位置、讀值、兩行時間,共 68),後輪標籤上移到 176(165 寬 160);引線起點在字型載入後依實際文字位置擺(`refreshTireLeaders`,`.panel` 對應比較頁的 `.tp`)。車圖、字級、顏色都沒變。

| 版本 | 車款 | 車子調色(只改顏色) | 字底板 / 讀值 / 標籤 / 歷史值 | 引線和端點 |
|---|---|---|---|---|
| 現在 | A 青藍玻璃(tire 推薦款) | 不調色 | tire 原色:`#101B2E` / `#F2F5FA` / `#AEBCD4` / `#8A97AE` | `#6FD8E2`(tire 原色) |
| A 直讀數字 | A 青藍玻璃 | 去飽和成黑白(`saturate(0) brightness(1.08)`),配合黑白主題 | `#171717` / `#F7F7F5` / `#C9C9C6` / `#A2A29F` | `#D6D6D3` |
| B 點陣環 | B 冷紫陶瓷 | 不調色(冷紫本來就和電光藍搭) | `#10143A` / `#F0F3FF` / `#C7CDEF` / `#A3ACDC` | `#B5B8FF`(tire 原色) |
| C 扇形 | B 冷紫陶瓷(切角板件比較有機械感) | 幾乎去飽和成槍灰(`saturate(.12) brightness(1.05)`) | `#1D1F23` / `#F5F7FA` / `#CDD2D9` / `#A6ACB5` | `#C3C8CF` |

- 都不用暖色(L38);光色不隨胎壓或資料狀態改變(和 tire 的規則一樣)。
- 實作時,調色可以用 Flutter 的 `ColorFilter.matrix`,或請 tire 輸出各版本配色的 SVG。
- **667 寬的日期膠囊只顯示「11:10」**:「10月18日 · 11:10」約 137 寬,超過 667 寬的上限 120,所以照 ux 16:15 (3) 的規則只顯示時間。844 寬仍顯示完整日期(約 137,上限 140)。

**胎壓文字對比**(字底板就是胎壓區的底色;門檻 4.5):

| 文字 | 現在 | A | B | C |
|---|---|---|---|---|
| 讀值(2.9) | 15.77 | 16.71 | 16.03 | 15.38 |
| 位置、時間、免責說明 | 8.98 | 10.80 | 11.33 | 10.86 |
| 歷史值、單位 bar | 5.84 | 7.00 | 8.02 | 7.22 |

- **注意**:胎壓區照 tire 的規格是實色底,四個版本的背景是漸層,所以胎壓區看起來是一塊顏色稍淺的方形。如果要讓它和背景融在一起,要請 tire 改成透明底、只留字底板。
- 比較頁的字型從 Google Fonts 載入;tire 的 HTML 只內嵌 Inter 600 和 Noto Sans TC 400,所以「胎壓」標題和「bar」的字重可能有細微差異。

#### 7.8.2 比較頁的「胎壓圖示」小段

`gauge-variants.html` 最下面加了「胎壓圖示」,放 tire 推薦款(A 青藍玻璃,tire 原色)的四個主要狀態:

| 狀態 | 白話說明 | PNG |
|---|---|---|
| 有值 | 四個輪胎都有讀值,各自寫最後量測時間。 | `gauge-variants/tire-fresh.png` |
| 時間未知 | 有讀值,但不知道是什麼時候量的,寫「量測時間未知」。 | `gauge-variants/tire-unknown.png` |
| 歷史值 | 讀值超過一小時,數字變灰,寫幾小時前。 | `gauge-variants/tire-historical.png` |
| 單輪缺值 | 右後輪還沒有讀值,顯示「—」和「尚無讀值」,其他三輪照常。 | `gauge-variants/tire-missing.png` |

「給老闆比較」每個版本除了行車一般,再加一張停車(含胎壓)的縮圖,也加上安全排序(見 §7.8.5)。合成圖 `compare.png` 改成 1760×1400。

#### 7.8.3 幫 tire 驗證和匯出

> **第四段(2026-10-20)**:tire 在 10-18 16:58 修好 T1–T3(只改 `tire-icon.html` 和 05,SVG 沒變)。visual 把修正(CSS、`tireLeaderStart` / `refreshTireLeaders` 定位函式、`tireReady` 初始化、`tireAudit` 自查)帶進 `gauge-variants.html` 的 `.tp`,在 Chrome 檢查後重新匯出 tire 的 68 張和比較頁的 13 張。tire 的 SVG、HTML、05 都沒改。胎壓圖示的安全審查和可行性評估由主持人另外補做(safety、flutter 額度用完),這一段不用等。

**第三段的結果**:

| 項目 | 結果 |
|---|---|
| 匯出 | 跑 `frames/tire/export-pngs.sh`,68 張全部成功(9 種狀態 × 3 種寬度 × 中英文 54 張、大字 12 張、陶瓷款 2 張),沒有空白檔,都在 `frames/tire/` |
| tire 自己的檢查 `tireAudit()` | 56 個面板,Inter 和 Noto Sans TC 都有載入,0 個問題 |
| 字底板 | 每個字的底板顏色都和面板底色相同,0 個問題 |
| 引線和端點 | 有問題,見下表 |

**看到的問題(交給 tire,visual 沒有改)**:

| # | 問題 | 在哪裡 | 怎麼看出來 | 第四段 |
|---|---|---|---|---|
| T1 | **四輪位置標籤的字下緣被蓋掉**:讀值那一行的字底板(含 2 px 外框)往上蓋住位置標籤文字框的最下面 4 px,中文最下面的筆畫、英文的下伸部分看不到(「左前」的「左」像少了最下面一橫,「Front right」「No reading」的 g 少了尾巴) | 所有寬度、中英文、四個輪子 | headless Chrome 量位置標籤和讀值字底板的重疊;3x 放大截圖確認 | **已修**:字底板只在自己那一行裡,同一輪的字底板互相重疊 0 處;位置標籤的字框底部離讀值字底板還有 1;放大截圖「左前」「左後」最下面一橫、「Front right」「18 min ago」的 g 都完整 |
| T2 | **前輪引線的起點藏在時間文字底下**,端點圓點看不到,引線像從字裡長出來 | 165 寬中文的左前、右前;184 和 165 寬英文的左前、右前 | 起點座標落在「18 分鐘前」「18 min ago」的字框內 | **已修**:起點圓點外緣離任何字底板都是 3.0,沒有藏在字下 |
| T3 | **280 寬的引線起點離文字太遠**(28–41 pt),端點像浮在空中,看不出連到哪一個讀值 | 280 寬中英文的四個輪子 | 起點到最近文字框的距離 | **已修**:280 寬起點圓點離自己的字都是 3.0(引線長 21.7–78.8,線長但起點貼字);引線最短 8.0 |

**第四段的檢查**(headless Chrome,字型載入、`await window.tireReady` 之後跑自查,再加量起點和字的距離):

| 頁面 | 面板 | 結果 |
|---|---|---|
| `tire/tire-icon.html`(tire 的頁面,含 280 寬) | 56 個(有引線的 34 個) | T1、T2、T3 都是 0;34 個面板的引線都有畫出來;起點離自己的字 3.0;引線 ≥8 |
| `gauge-variants.html` 總覽頁 | 16 個(四版停車 844、667,老闆比較縮圖 0.5 倍,胎壓圖示 4 種狀態) | T1、T2、T3 都是 0;縮放過的面板也一樣;距離和引線長度和 tire 的頁面完全相同(184 寬:8.6 / 8.7 / 32.4 / 32.4;165 寬:8.0 / 8.0 / 26.7 / 26.7) |
| 匯出用的 13 個畫面(`?screen=`) | 各 1 個(`compare` 4 個) | 同上,T1–T3 都是 0 |

比較頁沒有 280 寬的面板,所以「280 寬不浮空」是在 tire 的頁面檢查的。

**T4(新,交給 tire,visual 沒有改)**:tire 的自查在右欄(右前、右後)每輪報 3 個「horizontal text overflow」(tire 頁面共 204 個,比較頁每個面板 6 個)。原因是字底板左右各補 2 pt,右欄靠右對齊,所以字底板會超出面板右緣 2 pt;字本身剛好停在面板右緣,沒有超出。超出的 2 pt 被面板裁掉,而且和面板同色,畫面上看不出來。照 CSS 推算,左欄也一樣往左超出 2 pt,只是自查量不到往左的超出。建議 tire 決定要調整自查,還是讓右欄字底板不往外補。**已修**:tire 10-20 00:05 改成逐段量文字,收尾時在 Chrome 複驗,tire 頁面和比較頁都是 0(§7.8.7)。

#### 7.8.4 L39 的修改

| 來源 | 要求 | 怎麼改 |
|---|---|---|
| R6-06 / Q39 | B 沒資料不要用「全部燈格熄滅」(和 0 km/h 太像) | 沒資料時只畫隔段的細點(41 段畫 21 段、粗細一律 3、不分長刻度),對比 <3:1;0 km/h 仍是 41 段全畫 + 最前一段 |
| R6-06 / Q40 | C 的數字中心下移 3–4 px,讓 280 寬的三位數字高到約 104 | C 的數字中心改成量表區中心往上 6(比 01 低 4);三位數字級 148 / 144,字高 107 / 104 |
| Q40 | 三位數改看實際字高:844 寬 ≥105、667 寬 ≥100 | B 在 280 寬的三位數從 140 改 142(字高 100 → 101);其他版本原本就合格,見下表 |
| R6-07 | 停車行程數值補等寬數字 | `.trip .v` 加 `tabular-nums` |
| Q39 | 沒資料保留低對比虛線空軌道,不畫填色、標記、刻度數字、檔位 | 四個版本原本就是這樣;B 改成隔段細點 |
| Q38 | 選 A 時 ▲ 放數字正上方、量表區上緣 | 記下來;前方模式 v1 不開,這一段沒畫 ▲ |

**三位數字高檢查(L39 的標準)**:

| 版本 | 844 寬(量表區 300) | 667 寬(量表區 280) | 數字角落離量表圖形 |
|---|---|---|---|
| 現在 | 105 ✓(140 px) | 105 ✓(140 px) | 細環內緣 142 / 133 |
| A | 109 ✓(150 px) | 109 ✓(150 px) | 沒有錶盤 |
| B | 107 ✓(150 px) | 101 ✓(142 px) | 離內圈 4.6 / 2.2 |
| C | 107 ✓(148 px) | 104 ✓(144 px) | 離內圈 8.0 / 2.6 |

B、C 在 280 寬時數字角落離內圈只剩 2.2 / 2.6 px。這是量墨跡外框的角落;「1」和「8」的實際筆畫離內圈更遠。

#### 7.8.5 安全排序(L39,給老闆參考)

safety 的排序是 **A 直讀數字 > 現在的版本 > B 點陣環 > C 扇形**,四個都通過,可以照喜好選。「給老闆比較」每個版本的說明後面都加了這一句,例如「安全排序第 1(A > 現在 > B > C,四個都通過)」。

#### 7.8.6 PNG

`gauge-variants/` 現在共 45 張:

- 第二段的 37 張已依 L39 重新匯出(`compare.png` 改成 1760×1400)。
- 新增 `<版本>-parked667.png` 4 張(667×375 停車,胎壓 165×272)。
- 新增 `tire-fresh / -unknown / -historical / -missing.png` 4 張(184×288)。

tire 的 68 張在 `frames/tire/`。

**第四段**:帶進 T1–T3 修正後重新匯出受影響的 13 張:`<版本>-parked.png`、`<版本>-parked667.png`(各 4)、`tire-*.png`(4)、`compare.png`;其他 32 張沒有胎壓面板,沒有重新匯出。tire 的 68 張用 `bash frames/tire/export-pngs.sh` 全部重新匯出(腳本沒有執行權限,沒有改它的權限),沒有空白檔。

#### 7.8.7 第六輪收尾(L40、L41)

2026-10-20:照 tire 10-20 00:22 的修正,把量高度換清單的函式(`refreshTireLayouts`)、字級跟著放大倍數走的字底板 CSS、標題和車圖一組 + 清單版免責移到標題後的 DOM 順序、缺值讀屏句和新的自查帶進 `gauge-variants.html` 的 `.tp`;在 `await window.tireReady` 之後用 headless Chrome 自查,比較頁 16 個面板(四版停車 844 / 667、老闆縮圖、胎壓圖示 4 狀態)和匯出的 13 個畫面都是 0 個問題,預設字級全部是四象限;把比較頁的面板放大到 1.5 倍測試,會換成清單版、免責排在標題後面、引線隱藏,高度和 tire 頁面一樣(184 寬每輪 102、免責 42),放回 1 倍就恢復;tire 頁面在 Chrome 也是 56 個面板 0 個問題。重新匯出 tire 68 張(變的是 `allmissing-*` 6 張、`mixed-xl-*` 12 張,其他 50 張相同)和比較頁 13 張(和上一版逐位元相同)。比較頁只有繁中、預設字級,沒有「四輪都沒值」「不支援」狀態,所以這兩個狀態和英文短句看 tire 的頁面和 PNG。清單版的分隔線 `#44526A` 是 tire 的顏色,以後要在主要稿畫清單版時再換成各版本的顏色。R6-10(陶瓷車身調暗)照 L40 等老闆選 B 或 C 再做,這次沒改。

---

## 8. 第七輪:細數字、P R N D、胎壓只顯示 psi、測速提醒(L42–L46)

> 2026-10-20,第七輪。依據:`00-rulings.md` L42–L46;01 第七輪修訂和 L46 補充(ux 11:28、12:40);03「第七輪(規格)— 主持人代審」R7-01–R7-18、「第七輪(胎壓畫面)」R7-19;tire 12:42 版 05 和 `frames/tire/tire-icon.html`。只改了 `frames/gauge-variants.html`、`frames/gauge-variants/` 和本檔;`landscape-mockups.html`、`frames/landscape/`、tire 的 SVG / HTML / 05、`.pen`、`DESIGN.md` 都沒動。匯出用 `export-gauges.sh` 同樣的 Chrome 參數(在 scratchpad 跑,`export-gauges.sh` 本身沒改,這一輪新加的畫面 ID 不在它的清單裡)。

### 8.1 第一段:四個速度表(L43、L44)

#### 8.1.1 數字字重(L44、R7-01、R7-02)

| 版本 | 字型 | 原本 | 第七輪 | 三位數字級(844 / 667) |
|---|---|---|---|---|
| 現在 | Inter | 700 | **320** | 146 / 140(844 寬原本 140) |
| A | Jost | 600 | **340** | 150 / 150 |
| B | Exo 2 | 700 | **320** | 154 / 147(原本 150 / 142) |
| C | Barlow Semi Condensed | 600 | **400**(這套字只有整百) | 152 / 144(844 寬原本 148) |

- Inter、Jost、Exo 2 改從 Google Fonts 載入可變字重(300–700),先量過 300 / 320 / 340 的直筆寬確實不同,不是被換成整百字重。
- 數字不加發光、外框、漸層,白天和夜間同字重(R7-02)。
- **三位數字級為什麼變大**:03 §2.2 改用「147」量字高(沒有圓字上下溢出),原本的字級量出來只有 102–103,低於 844 寬 ≥105。844 寬放大到上表;667 寬的下限 100 原本就夠(B 的 142 量到 98,也放大到 147)。

**筆畫實量**(03 §2.2:2 倍圖、半高門檻、÷2;`?screen=m-<版本>-<147|80>-<844|667>-<day|night>` 是量的畫面,`-nonum` 是同一張不畫數字當背景)。白天和夜間字重相同,量到的筆畫一樣;差在對比。

| 版本 | 寬 | 三位數字高(147) | 1 / 4 / 7 直筆 | 0 左右 / 上下(80) | 下限:直筆 / 最細處 | 對比 白天 / 夜間 |
|---|---|---|---|---|---|---|
| 現在 | 844 | 106 | 10.5 / 10.5 / 9.9 | 11.0 / 10.0–10.5 | 9 / 7.2 | 15.77 / 8.65 |
| 現在 | 667 | 102 | 10.0 / 10.0 / 9.8 | 10.0 / 9.5 | 8.5 / 6.8 | 15.77 / 8.65 |
| A | 844 | 106 | 10.0 / 10.0 / 9.0 | 13.0 / 12.5 | 9 / 7.2 | 16.71 / 8.63 |
| A | 667 | 106 | 10.0 / 10.0 / 9.0 | 12.0–12.5 / 11.0–11.5 | 8.8(字高 ÷ 12)/ 7.1 | 16.71 / 8.63 |
| B | 844 | 106 | 10.5 / 10.0 / 10.0 | 11.5 / 10.5 | 9 / 7.2 | 14.36 / 8.56 |
| B | 667 | 101 | 10.0 / 9.5 / 9.4 | 11.0 / 10.0 | 8.5 / 6.8 | 14.36 / 8.56 |
| C | 844 | 106 | 10.5 / 10.5 / 10.9 | 12.0–12.5 / 10.5–11.0 | 9 / 7.2 | 11.97 / 7.19 |
| C | 667 | 101 | 10.0 / 10.0 / 9.9 | 11.5 / 10.0 | 8.5 / 6.8 | 11.80 / 7.09 |

- 7 的斜筆已乘 cos(斜角)(現在、A 約 26°,B、C 約 19°)。全部過下限;最緊的是 A 的 7(9.0,下限是最細處 7.2,直筆 10.0 ≥ 9)。
- 對比是數字對筆畫外側 9 px(圓形)內最亮的背景;B 含點陣底紋,C 含錶面和刻度帶。
- 三位數字高:844 寬都是 106(≥105),667 寬 101–106(≥100)。

**數字外側 9 px 的亮圖形(R7-02,這一輪新發現、已改)**:照 03 的對比量法,數字旁邊 9 px 內只要有亮的圖形(紅色標記、亮的燈格、銀色填色),數字就低於 7:1。逐個車速 0–240 截圖檢查(2 倍、每格一個車速),第一次在三位數的高速段不合格:現在的版本 175–237、B 200–240、C 200–240(紅色標記、亮燈格、紅針離數字 0–8 px);A 沒有問題。改法:

| 版本 | 改了什麼 |
|---|---|
| 現在 | 數字移到量表中心(下移 10);紅色標記從環的內側(半徑 118–136)改成**環上一道紅色缺口**(只在環的寬度內,兩側留 1.5 底色);拿掉端點圓;三位數字距 −10(667 寬 −12) |
| B | 數字移到量表中心(下移 10);燈格內端往外到 300 寬 139、280 寬 132(R6-01 的下限是 137 / 128),燈格變短;三位數字距 −12(667 寬 −14) |
| C | 數字下移 8;銀色填色和紅針從內圈往外 10 才開始,內圈外留一圈深色;拿掉內圈裝飾細線 |
| 共用 | 數字左右置中補正:`text-anchor="middle"` 會把最後一個字後面的字距也算進去,字距 −10 時整串往右偏 5(第六輪就有)。x 加回字距的一半 |

**字距收緊後數字會不會黏在一起**:量了「200、208、188、100、240」在 844 / 667 的數字之間的空隙(墨跡左右投影,比實際空隙保守),最小 B 667 寬「240」4.0 px(4 的橫筆和 0),其他 A 6.0、C 6.0、現在 8.5 px 以上;都 ≥3 px,字懷照舊分得開(R6-02)。

改完再掃一次 0–240(白天、夜間、300 和 280 都掃):數字旁最近的亮圖形 現在 13.2 / 11.4、A ≥13.5、B 10.5 / 11.5、C 14.7 / 12.5 px(300 / 280),全部 >9,沒有不合格的車速。

**夜間最暗預設**(這一輪新定;R7-01 要夜間也量):只改顏色,字重和位置不變。數字約 8.6:1,單位約 4.6:1,說明約 5.2:1,量表亮色調暗約一半,來源綠點和電量填色也調暗。色碼在 `gauge-variants.html` 的 `NIGHT`,建議改法見 §8.5。

**細字加發光會不會糊(L44)**:會。現在的版本夜間 88 加兩層發光後,筆畫旁 9 px 內最亮的地方從底色變成光暈,對比從 8.55:1 掉到 1.42:1,細筆畫的邊緣糊掉。所以四個版本都不加發光(R7-02)。比較圖:`gauge-variants/night-glow-rejected.png`(左採用、右不採用,只為比較)。

#### 8.1.2 `P R N D` 一排(L43、R7-03–R7-06)

- **樣子**:四個字母各佔固定一格(18 寬),整排置中在數字正上方。目前檔位 700 字重 + 底線(2 粗、基線下 3、比字母墨跡寬 2),其他三個 400 字重、暗色。字母墨跡高 13(12–16)。用各版本自己的數字字型,沒有底塊。
- **位置**:底線最下緣離兩位數最高的墨跡 13(≥12),比字母之間的空隙(6.4–9.4)大。位置照兩位數最高的墨跡算好就固定,所以幾位數、有沒有這一排,數字都不動(自查:有 / 沒有檔位排,數字那一行完全相同)。
- **什麼時候畫**:行車畫 D、停車畫 P;沒資料、只有 GPS 時整排不畫(四個版本的「沒資料」稿)。
- **灰階**:轉成灰階看過,四個版本都一眼看得出目前檔位(粗 + 底線)。

| 版本 | 寬 | 檔位排墨跡 y(畫面座標) | 離數字 | 離量表圖形(0–240 最近) | 離日期膠囊 |
|---|---|---|---|---|---|
| 現在 | 844 / 667 | 110–128 / 104–122 | 13 | 46.2 / 40.4 | ≥62 |
| A | 844 / 667 | 58–76 / 55.5–74 | 13 | 沒有錶盤(速度條在下面) | 15.8 / 13.5 |
| B | 844 / 667 | 107.5–125.5 / 101–119 | 13 | 40.8 / 37.0 | ≥59 |
| C | 844 / 667 | 108–126 / 102–120 | 13 | 13.6 / 10.2 | ≥60 |

- **A 放得下嗎**:A 沒有錶盤,數字原本離量表區上緣只有約 33。數字、單位、速度條一起往下移 6,檔位排就放得下,數字字級沒有縮小(L43)。667 寬時檔位排離日期膠囊 13.5(≥12),速度條離 ▲ 14.3(≥12),兩邊都只剩 1.5–2.3 的餘裕。
- **沒有哪個版本放不下**,也沒有為了放檔位排縮小數字。

| 對比(對最亮的底:B 含點陣、C 用錶面中心) | 目前檔位 白天 / 夜間 | 其他三個 白天 / 夜間 | 亮度比 白天 / 夜間 |
|---|---|---|---|
| 現在 | 15.77 / 8.65 | 4.20 / 3.60 | 3.76 / 2.40 |
| A | 16.71 / 8.63 | 4.23 / 3.61 | 3.95 / 2.39 |
| B | 14.50 / 8.64 | 4.23 / 3.62 | 3.43 / 2.38 |
| C | 14.32 / 8.61 | 4.20 / 3.60 | 3.41 / 2.39 |

門檻:目前檔位 ≥7、其他 ≥3、亮度比 ≥2(R7-04)。底線和目前檔位同色,≥7:1。

#### 8.1.3 ▲ 的新位置(R7-08)

- 每個版本畫一張 300×300 特寫:前方模式超速 72(v1 不開),數字琥珀,▲ 24×20 在數字正下方(844 畫面 (422, 318),= 量表區內 (150, 268);667 是 (140, 252))。
- ▲ 離數字和單位的墨跡:現在 14.5 / 15.1、A 46.7 / 44.2、B 16.6 / 16.3、C 12.8 / 13.2(300 / 280,≥12)。
- ▲ 離量表圖形:A 的速度條 14.3(≥12);其他版本 ≥51。
- 這些數字由頁面的 `gaugeAudit()` 量(`await window.tireReady` 後在 Chrome 跑,0 個問題)。

#### 8.1.4 「給老闆比較」

四個版本的行車和停車縮圖都換成新樣子(細數字、P R N D、胎壓 psi),說明文字也改了;合成圖 `compare.png` 仍是 1760×1400。

### 8.2 第二段:胎壓只顯示 psi(L42、L46、R7-14–R7-19)

- **帶進來的**:tire 12:42 版的資料模型(15 分鐘內算新鮮、只有收到時間算「時間未知」)、幾何(四角、沒有引線、車圖放大到 104×208 / 94×188)、共用時間行(六種情況 + 四輪都「—」寫「尚無讀值」)、只暗舊的那幾輪、量了才換清單(讀值高 >32、讀值寬超過欄寬、時間行 >32、標題 >24)、清單版的小車定位圖和輪位名稱、讀屏句、新自查。第六輪的引線、每輪時間、免責都拿掉了。
- **顏色**:每個版本只換字底板、讀值、標題、暗值的顏色(和第六輪一樣),清單版小車定位圖也換成該版本的顏色。車圖還是用 `frames/tire/car-*.svg`(tire 這一輪沒改,雜湊相同)。
- **沒帶進來的**:tire 頁的「每分鐘更新 N 分鐘前」時鐘(比較頁是靜態稿)。
- **免責(R7-16)**:照 01 §6.2,在現在的版本畫了「第一次看到胎壓」的停車畫面(844、667 各一張):左欄捲動區第一項是說明卡「胎壓僅供參考,請以車上的胎壓警示為準。」和「知道了」按鈕(44 高),行程往下排。其他停車稿是按過「知道了」之後的樣子。

**Chrome 實頁自查(R7-19)**:`await window.tireReady` 後跑 `tireAudit()`(照 tire 12:42 版,顏色改成比對各版本自己的變數):

| 頁面 | 面板數 | 問題 |
|---|---|---|
| 比較頁(四版停車 844 / 667、老闆縮圖、胎壓圖示 6 種、R7-19 的 12 張、第一次看到胎壓 2 張) | 32 | 0 |
| 同上,字級放大 110% / 130% / 150% / 200% | 32 | 0;130% 時 165 寬換清單,150% 以上全部換清單;改回 100% 又全是四角 |
| tire 的 `tire-icon.html`(唯讀,沒改) | 102 | 0(tire 這次沒跑 Chrome,這是第一次在 Chrome 跑) |

**R7-19 截圖**(165 寬、tire 原色,Chrome 實頁 2 倍截圖,不是 tire 的向量 PNG):

| 檔名(`gauge-variants/`) | 內容 | 看到的 |
|---|---|---|
| `tire165-mixed-zh.png`、`tire165-mixed-en.png` | 混合:左前新鮮、右前 18 分鐘前、左後時間未知、右後缺值 | 只暗右前和左後;車圖下面「部分讀值時間未知」/「Some readings: time unknown」(英文兩行) |
| `tire165-allmissing-zh.png`、`tire165-allmissing-en.png` | 四輪都沒值 | 照樣畫車圖,四輪「—」,下面「尚無讀值」/「No readings yet」 |
| `tire165-mixed-zh-150-top.png`、`-150-end.png` | 150% 清單第一屏 / 最後一屏 | 標題和小車圖、共用時間行固定在上面;每輪有定位圖 + 輪位名稱;最後一屏看得到「右後 —」 |
| `tire165-mixed-zh-200-top.png`、`-200-end.png` | 200% 清單 | 同上,只捲四輪 |
| `tire165-mixed-en-150-top.png`、`-150-end.png`、`-200-top.png`、`-200-end.png` | 英文清單 | 「Tire pressure」換兩行,「Some readings: time unknown」兩行固定;輪位「Front left」等完整 |

- 截圖裡字底板都是實色(自查也比對了顏色),車光沒有透出來;時間行一直看得到;輪位名稱沒有被切。
- 舊的 `tire-unknown.png`、`tire-historical.png`、`tire-missing.png`、`tire-fresh.png` 已換成第七輪的樣子;另加 `tire-mixedages.png`(只有一輪舊)、`tire-allmissing.png`。

### 8.3 第三段:測速提醒(L45、L46)

#### 8.3.1 參考(2026-10-20 查閱)

| # | 參考 | 看到的 | 學到什麼 |
|---|---|---|---|
| 1 | [Waze 說明:Manage camera alerts](https://support.google.com/waze/answer/15758855) | 地圖上畫相機圖示;開「行車時提醒」才會跳出提醒和語音;沒超速時只在地圖上看得到,不出聲 | 提醒分「看得到」和「打斷你」兩層。附近模式只要安靜地看得到,不出聲、不閃 |
| 2 | [Waze wiki:Camera](https://waze.com/wiki/USA/Camera) | 相機圖示上的紅點指向它監測的方向 | 圖示要簡單到一眼認得。我們 v1 沒有方向資料,所以不畫方向、不加紅點 |
| 3 | [Highways Magazine:Google Maps 加入測速照相](https://www.highwaysmagazine.co.uk/news/trade-bodies/google-maps-adds-speed-camera-feature)、[9to5Google:Google Maps 速限](https://9to5google.com/2019/01/19/google-maps-speed-limits-rollout/) | 地圖上畫相機標記、接近時語音;速限畫成路標放在角落 | 導航 app 的速限長得像路標,這正是我們不能學的:我們的數字是點位資料,不是路邊的速限(R7-09) |
| 4 | [9to5Mac:Apple Maps 測速照相](https://9to5mac.com/2021/03/29/apple-maps-speed-camera-locations/) | 只告訴你前面有測速照相,不說是哪一種,也不顯示速限;評測覺得不夠清楚 | 只有「有相機」不夠,要寫出數字和它從哪來,所以「點位資料速限 60 km/h」整句保留 |
| 5 | [Garmin DriveSmart 手冊:Red Light and Speed Cameras](https://www8.garmin.com/manuals/webhelp/drivesmart55-65/EN-US/GUID-631255CE-F378-41A9-BA8A-9D5839D8B806.html) | 接近時提醒;資料庫要更新;Garmin 聲明不保證資料正確 | 專用導航機也把「資料可能不準」講清楚。對應「點位資料」的說法,和資料過期就整張不出現(L16) |
| 6 | [WardsAuto:BMW 速限辨識](https://wardsauto.com/bmw/new-speed-reading-system-to-debut-on-bmw-7-series) | 真車在儀表或 HUD 用路標圖案顯示路邊的速限,只是資訊、不介入駕駛 | 車上的儀表會用路標圖案顯示路邊速限。我們不用圓形或路標外形,免得和車上的速限顯示混在一起 |
| 7 | [Polestar 2 手冊:通知](https://www.polestar.com/au/manual/polestar-2/2026/article/bb88651d8781d5d6c0a8015151398e7a/)、[Polestar 1 手冊:儀表主題](https://www.polestar.com/uk/manual/polestar-1/2020/article/6a6627988a488686c0a801511cfe0c74/) | 三種通知:要動作的上方橫幅、要立刻注意的視窗、只出現幾秒、沒有按鈕的簡短橫幅;儀表有「Minimalistic」主題 | 純資訊用最輕的那一種,沒有按鈕、不用點。車廠也提供極簡模式,簡約是被接受的方向 |
| 8 | [Android for Cars:Visual principles](https://developers.google.com/cars/design/design-foundations/visual-principles) | 文字、圖示對比 ≥4.5:1;夜間要深底淺字;字太長會讓視線停太久;字好讀才能縮短看一眼的時間 | 簡約不是把字變小,而是字少、對比夠、排得清楚 |
| 9 | [Android for Cars:Design principles](https://developer.android.com/design/ui/cars/guides/foundations/design-principles) | 駕駛要能在 2 秒內讀懂內容和狀態 | 每個版本最多兩到三行、只有一個重點數字 |
| 10 | [Apple CarPlay 人機介面指南](https://developer-mdn.apple.com/design/human-interface-guidelines/technologies/carplay/introduction)、[WWDC20 CarPlay](https://developer.apple.com/videos/play/wwdc2020/10635/) | 資訊要少、看一眼就懂;偏好不打斷的狀態訊息,少用跳出的警示 | 提醒可以像狀態一樣安靜地出現,所以版本 1、2 不用卡片 |
| 11 | [道路交通標誌標線號誌設置規則 第 55-2 條](https://law.moj.gov.tw/LawClass/LawSingle.aspx?pcode=K0040014&flno=55-2) | 「警52」測速取締標誌:用來警告前方常有測速取締,一般道路在取締路段前 100–300 公尺設置;它是警告標誌,一般道路上的警告標誌是紅邊三角形(樣式出自法院判決引用的規定,條文頁沒有列) | 台灣路邊的測速標誌是紅邊三角形,所以提醒不用紅色、不用三角形、不像路標(▲ 和琥珀另外留給前方模式) |

#### 8.3.2 四個提醒版本

四個都放在「現在的版本」的速度表上(第一段改好的細數字 + `P R N D`,行車 58 km/h、D),只畫附近模式。用字照 01 §6.1(L46 之後):中文第一行用文字寫測速點,第二行完整的「點位資料速限」;英文截圖用最長的一句「Camera nearby / Camera data limit 60 km/h」。

| 版本 | 頁面上的白話說明 | 差在哪裡 | 用字 |
|---|---|---|---|
| 現在的版本 | 底卡 + 外框 + 相機圖示,兩行字,當對照 | 一張卡片(底色 `#0E1A24`、外框 `#2C5A66`、圓角 14) | ① 附近有測速點 / 點位資料速限 60 km/h |
| 提醒 1「純字」 | 只有兩行字,沒有底卡、外框和圖示,靠右對齊在設定按鈕下面,像錶旁邊的一行註記。最安靜 | 沒有任何容器;靠右;數字 22 px | ② 附近測速點 / 點位資料速限 60 km/h |
| 提醒 2「側光條」 | 沒有底卡,左邊一條細細的青色光條加上相機圖示,一眼就知道「這是一則提醒」,但不像一張卡片 | 3 寬的青色細條(形狀記號,不是圖示欄)+ 20 px 相機圖示;數字 20 px | ② 同上 |
| 提醒 3「數字欄」 | 像儀表上的資料欄:「附近測速點」、一條細線、說法、再一行比較大的「60 km/h」 | 三行,數字自成一行(26 px,大字最多 32 px);標題和數字之間 1 px 細線 | ③ 中文同 ②;英文可以改用 `Listed limit`(第一行是 `Camera nearby`),截圖用最長的 `Camera data limit` |

- 四個都在右欄上半:844 寬 x 584–769、667 寬 x 485–651,從 y 72 開始,離量表區 12。平常最低到 y 165(844 / 667 都是);第二行只在「點位資料速限」和數字之間換行(667 寬的現在版本和側光條會換)。
- 都不用暖色、不畫路標外形、沒有距離、沒有 ▲;出現、消失只改透明度 ≤200 ms(靜態稿沒有動畫,交給 flutter),出現後不動。讀屏四個都唸「附近有測速照相,點位資料速限每小時 60 公里」。
- **速度表不動**:提醒出現時,速度表那一塊(數字、環、檔位排)的 HTML 和同速度的行車畫面完全相同(自查比對)。

**對比**(沒有底卡的版本對漸層中心 `#101B2E` 算,這是右欄最亮的底):

| | 現在的版本(對卡片) | 純字 / 側光條 / 數字欄(對底) | 門檻 |
|---|---|---|---|
| 速限數字 | 16.12 | 15.77 | 7 |
| 文字「附近測速點」「點位資料速限」 | 9.18 | 8.98 | 4.5 |
| 單位 km/h | 5.97 | 5.84 | 4.5 |
| 相機圖示(現在、側光條)、側光條 | 10.57 | 10.34 | 3 |
| 數字欄的細線 `#2C5A66` | — | 2.27(裝飾,不帶意思) | — |

**自查 `alertAudit()`**(Chrome,`await window.tireReady` 後):4 版本 × 844 / 667 × 繁中 / 英文 × km/h / mph × 字級 100% / 130% = 64 種,**0 個問題**。項目:在右欄裡、離量表區 ≥12、從 y 72 開始、平常到 y 200 內(大字到 300 / 290)、最多 4 行、數字和單位不拆行、字不超出、速限數字 ≥16 px 且字高 ≤26 / 25(實際 12.0–23.9)、文字 ≥15 px、提醒出現時速度表不變。

- 第一次跑時有 10 個問題,已改:① 130% 英文時現在的版本和側光條排到 5 行(第二行改成一般行內排版,「limit 60 km/h」可以接在同一行);② 數字欄 130% 時速限數字字高 25.3 > 25(數字最大 32 px)。
- 現在的版本(對照)本身在 130% 英文也會排到 5 行,這是第二行排法的問題,四個版本一起改了。

**手機上看**:比較頁「給老闆比較」下面新增 `#alerts` 一段。每個版本一塊:標題、一兩句說明、一張放大的特寫(844 畫面的右上角),再來是 844、667、英文三張完整畫面。375 和 440 寬的手機上都是一個一個往下排,沒有左右捲動(用 iframe 實測,頁面寬 = 螢幕寬);「給老闆比較」也改成手機上一欄。桌機上和原本一樣。

> 第八輪:老闆選了側光條(L52),用字改成一行「此路段限速 60 公里」(L53),放到 C 上的新圖見 §9.1。上表四個版本和這裡的用字都保留參考(L54)。

#### 8.3.3 這一段沒畫的

- 只畫在「現在的版本」上(L45);老闆選定速度表後再套到選定的版本。**選 B 時要注意**:B 的背景有點陣底紋,純字、側光條、數字欄沒有底卡,字底下要加實色底或那一塊不畫點陣(R7-11)。
- 前方模式(距離、琥珀、▲)v1 不開,沒畫提醒卡;▲ 只畫在第一段的特寫。
- mph 和 130% 大字只在自查裡量,沒有另外匯出 PNG。

### 8.4 PNG(`frames/gauge-variants/`,共 85 張,含 §8.7 收尾的 3 張)

全部用 Chrome 2 倍匯出(`?screen=<ID>`,參數和 `export-gauges.sh` 一樣)。

| 類別 | 檔名 | 張數 | 這一輪 |
|---|---|---|---|
| 給老闆比較 | `compare.png`(1760×1400) | 1 | 更新 |
| 四版完整畫面 | `{cur,A,B,C}-{drive,alert,nodata,parked}.png`(844×390)、`{版本}-{drive667,parked667}.png`(667×375) | 24 | 更新(細數字、P R N D、胎壓 psi;`-alert` 是現在的提醒卡放在各版本上) |
| 四版特寫 | `{版本}-{88,128,na,0}.png`(300×300) | 16 | 更新 |
| **新**:夜間最暗預設 | `{版本}-night.png`(844×390) | 4 | 新增 |
| **新**:▲ 新位置 | `{版本}-over.png`(300×300,前方模式超速 72,v1 不開) | 4 | 新增 |
| **新**:細字加發光比較 | `night-glow-rejected.png`(左採用、右不採用) | 1 | 新增 |
| 胎壓圖示 | `tire-{fresh,historical,mixedages,unknown,missing,allmissing}.png`(184×288) | 6 | 4 張更新、`mixedages`、`allmissing` 新增 |
| **新**:R7-19 實頁截圖 | `tire165-{mixed,allmissing}-{zh,en}.png`、`tire165-mixed-{zh,en}-{150,200}-{top,end}.png`(165×272) | 12 | 新增 |
| **新**:第一次看到胎壓 | `cur-parked-first.png`(844)、`cur-parked667-first.png`(667);收尾加 `cur-parked667-first-en.png`(英文)、`cur-parked667-first-en-130.png`(英文大字)、`cur-parked667-first-end.png`(左欄捲到底) | 5 | 新增(§8.7) |
| **新**:測速提醒 | `alert-{now,plain,rule,stack}-{844,667,en}.png`(`en` 是 667×375 英文) | 12 | 新增 |

> 第八輪(§9.1):上面 12 張提醒全部保留參考,不刪(L54):`alert-rule-*` 是老闆選的側光條改用字、換到 C 之前的樣子,標「舊版(保留參考)」;`alert-{now,plain,stack}-*` 標「未選(保留參考)」。已選的新圖是 `alert-rule-C-*`(§9.1)。`{cur,A,B,C}-alert.png` 是 13:54 匯出的,比 14:10 的提醒排法修正早,卡片第二行比現在的 HTML 高約 2 px,其他一樣;保留原檔,沒有重匯。

`gauge-variants/part1/` 是第一段的舊圖,沒動。量筆畫用的測試畫面(`?screen=m-…`)和 0–240 逐速截圖只放在 scratchpad,沒放進資料夾。

### 8.5 建議的 `DESIGN.md` 改法(老闆選定方向後才寫進去)

| 段落 | 現在寫的 | 建議改成 | 依據 |
|---|---|---|---|
| Gauge numeral | Huge numeral(各方向原本 600–700) | 車速數字用細字重:現在的版本 Inter 320、A Jost 340、B Exo 2 320、C Barlow Semi Condensed 400;不加發光、外框、陰影、漸層,白天夜間同字重;三位數 844 寬 146 / 154 / 152(A 150)、667 寬 140 / 147 / 144(A 150);下限照 R7-01 實量 | L44、R7-01、R7-02、§8.1.1 |
| Gear selector(drive、parked 兩段) | `P R N D`, active gear in a filled `accent` chip with `bg.base` glyph, others `text.dim` | `P R N D` 一排在數字正上方,每個字母固定一格(18);目前檔位用數字色、700、加 2 px 底線(基線下 3);其他三個 400、`gear.off`(約 4.2:1);沒有底塊;離數字 ≥12、離量表圖形 ≥6;只在藍牙檔位新鮮時顯示 | L43、R7-03–R7-06 |
| Drive dial 的紅色標記 | crimson current-value marker sitting just *inside* the arc band + tip dot | 紅色標記改成環上的一道缺口(只在環的寬度內,兩側留 1.5 底色);拿掉端點圓。理由:環內側的標記在三位數高速時會碰到數字(R7-02) | R7-02、§8.1.1 |
| Over-speed ▲ | 數字上方 | 數字正下方、原本檔位格的位置(844 (422, 318)、667 (333, 302)),24 × 20 | L46、R7-08 |
| 新 token | — | `gear.off` `#747E8E`(現在的版本;A `#7B7B79`、B `#7E8298`、C `#83868A`) | R7-04 |
| 新 token:夜間最暗預設 | — | `night.num` `#B5B8BB`、`night.unit` `#798599`、`night.sec` `#838EA0`、`night.gearOff` `#6A7382`、`night.fill` `#1B949D`、`night.tip` `#63A1A7`、`night.mark` `#C32A41`(現在的版本;A / B / C 的值在 `gauge-variants.html` 的 `NIGHT`)。只改顏色:數字約 8.6:1、單位約 4.6:1、說明約 5.2:1 | L44、R7-01 |
| 測速提醒卡 | 底卡 + 外框 + 圖示 | 等老闆從 §8.3 的四個版本選一個;選 2 側光條時光條用 `accent.text` `#6FD8E2`;沒有底卡的版本放在 B 上要加實色字底 | L45、R7-11 |
| Parked:胎壓 | 2×2 格子 / 第六輪四象限 | 照 tire 05 第七輪:每輪只顯示整數 psi 或「—」、四角、沒有引線、共用時間行、只暗舊的那幾輪、量了才換清單;免責移到左欄一次性說明列 | L42、L46 |

### 8.6 假設和待確認問題

| # | 假設 | 依據 |
|---|---|---|
| A25 | 夜間最暗預設由 visual 先定(只改顏色),實際亮度要 T03 夜間實測 | L44、R7-01;`DESIGN.md` 沒有夜間 token |
| A26 | R7-02「數字外側 9 px」照 03 的寫法套用到所有車速(0–240),不只 147 / 80;所以改了現在的版本的紅色標記、B 的燈格長度、C 的填色和紅針起點 | 03 第七輪 §2.1 |
| A27 | 三位數字高照 03 §2.2 改用「147」量(沒有圓字溢出),844 寬三位數字級因此放大;667 寬不變(B 例外,142 → 147) | 03 §2.2、L39 |
| A28 | 測速提醒的英文截圖用 667 寬(最窄)和最長的一句;844 英文、mph、130% 只在自查裡量 | L45 指示「加一張英文(最長的那句)」 |

| # | 問題 | 給誰 |
|---|---|---|
| Q41 | ~~現在的版本紅色標記改成環上缺口、B 燈格變短、C 填色和紅針外移,要不要接受~~ → L48:接受 | 已解決 |
| Q42 | 夜間最暗預設要不要寫進 `DESIGN.md`(§8.5 的 token),還是等實測 | ux、主持人 |
| Q43 | 測速提醒四個版本請老闆選一個;選定的版本和選定的速度表一起套進主要設計稿 | 主持人(老闆) |
| Q44 | ~~第一次看到胎壓的說明卡把行程擠到左欄下面~~ → L48:可以接受;補英文(R7-20)和左欄可捲(R7-21),見 §8.7 | 已解決 |

### 8.7 第七輪收尾:R7-20、R7-21(L48)

> 2026-10-20 14:22。safety(Codex)「第七輪(畫面)」:四個速度表、四個提醒、psi 胎壓都通過,Q41 三項接受;只改說明卡的兩件事。只改了 `gauge-variants.html`、`gauge-variants/`、本檔和 board。

- **R7-20 英文說明卡**:停車畫面的文字改成跟著語言,不再寫死中文(英文照 01 §6.2):
  - 說明「Tire pressure is for reference only. Rely on your car's tire pressure warnings.」+「Got it」。
  - 行程「Trip / Avg / Max」「Calculated from phone GPS」,時間「11:10 AM」,胎壓面板也換成英文。
  - 新增最窄的 667 寬英文 `cur-parked667-first-en.png`:說明卡從 y 84 到 262,整張(含 44 高按鈕)在左欄第一屏(到 y 282)裡,不用捲動。
  - 左欄右緣離量表區 12,不遮車速。
- **大字**:說明和按鈕跟著字級放大、不縮字(說明 14 × 字級、按鈕 15 × 字級,按鈕 ≥44 高)。示意圖 `cur-parked667-first-en-130.png`。
  - 130% 英文時說明卡比左欄高,要往下捲才看得到「Got it」;預設字級不用捲(R7-16 第 2 條只要求預設字級)。
  - 中文 130% 在 844 和 667 都還在第一屏。
- **R7-21 左欄可以捲**:`.scrollcol` 從裁切改成直向捲動,內容照原本的高度排,不會被壓扁。新增捲到底的示意 `cur-parked667-first-end.png`,看得到「最高 72 km/h」和「由手機 GPS 計算」。
- **自查**(Chrome,`await window.tireReady` 後):
  - `noticeAudit()`(新):844 / 667 × 中英 × 100 / 130 / 150%,12 種,0 個問題。檢查預設字級第一屏、不縮字、字不超出、不碰量表區、捲得到底、行程不被壓扁。
  - `tireAudit()` 35 面板(多了 3 張說明卡畫面裡的胎壓)、`alertAudit()` 64 種、`gaugeAudit()` 8 組,都是 0。
- **PNG**:
  - 新增 3 張(上面三個檔名)。
  - 重新匯出 `cur-parked-first.png`、`cur-parked667-first.png`:左欄改成可捲,畫面和原本一樣是第一屏。
  - 其他停車畫面、`compare.png`、`tire-fresh.png` 重新算過,和上一版逐位元相同,沒有覆寫。
  - `gauge-variants/` 共 85 張。

## 9. 第八輪:老闆選定 C 和側光條(L49–L54)

> 2026-10-20 開始。老闆選了速度表 C「扇形」(L49)、左下角「電量 / 續航」(L50)、測速提醒「側光條」(L52),提醒用字改成一行「此路段限速 60 公里」(L53)。沒選上的設計全部保留參考(L54)。這一輪分兩段:§9.1 比較頁的提醒放到 C 上;§9.2 起主要設計稿照 C 重畫。

### 9.1 第一段:側光條放到 C 上(L51–L54)

照 L52 縮小範圍:比較頁 `frames/gauge-variants.html` 的「測速提醒」一段,只把老闆選的側光條放到 C 上,用 L53 的一行字;第七輪的四個版本放在下面,保留參考。

- **畫法**:沒有底卡、外框;左邊 3 寬的青色光條 + 20 px 相機圖示(都是 `accent.text` `#6FD8E2`,照 01 §5.2 ③,不跟 C 的銀色換)+ 一行字。
  - 中文「此路段限速 60 公里」:字 15 px / 600、數字 20 px / 600、單位 15 px / 500。英文「Speed limit 60 km/h」;mph「此路段限速 37 英里」/「Speed limit 37 mph」。
  - 讀屏唸「此路段限速每小時 60 公里」/「Speed limit 60 kilometers per hour」。
- **一行放得下嗎**(Chrome 實量,含圖示和間距):中文要 170.7,844 寬右欄可用 172,剛好一行(只差 1.3,實作換字型時可能變兩行);667 寬可用 153,排兩行。英文要 182.5,844 和 667 都排兩行。換行都只在「此路段限速 / Speed limit」和「60 公里 / 60 km/h」之間,圖示留在第一行開頭,第二行從左邊開始(不做左圖示、右兩行字),照 01 §5.2「換行」。
- **頁面**:「測速提醒」一段最上面是「側光條(C 扇形,L53 用字)」標「已選」,有 844 右上角特寫、844、667 中文、667 英文。下面第七輪的四個版本照舊,側光條標「舊版(保留參考)」,卡片、純字、數字欄標「未選(保留參考)」。速度表 A、B、現在的版本也都標「未選(保留參考)」,C 標「已選」。頁首說明改成第八輪。`compare.png` 不加標籤,維持老闆當時看到的樣子(重算後和上一版逐位元相同)。
- **自查 `alertAudit()`**(Chrome,`await window.tireReady` 後):現在預設真的跑在 C 上,量側光條 + L53 用字。844 / 667 × 繁中 / 英文 × km/h / mph × 字級 100% / 130%,**16 種,0 個問題**。
  - 照舊查:在右欄裡、離量表區 ≥12、從 y 72 開始、平常到 y 200 內(大字到 300 / 290)、最多 4 行(實際 1–2 行)、數字和單位不拆、字不超出、速限數字 ≥16 px 且字高 ≤26 / 25(實際 14.9;130% 時 19.4)、文字 ≥15 px。
  - **提醒出現時速度表不動**:C 的錶那一塊的 HTML 和同速度、沒有提醒的畫面完全相同。
  - **新增**:提醒和 C 實際畫出來的錶(扇形帶、填色、紅針;車速 15 / 58 / 120 / 240 都量)的像素距離:844 寬 25.6–45、667 寬 22.4–28.5,都 ≥12,不碰錶盤。
  - **新增**:相機圖示一定在、≥20 px(130% 時 26)、在第一行開頭;「此路段限速」「Speed limit」不被拆開。
  - `alertAudit({ legacy: true })` 是第七輪四個版本放在現在的版本上:64 種,0 個問題(保留參考,沒改)。
  - 同一頁的 `tireAudit()` 35 面板、`noticeAudit()` 12 種、`gaugeAudit()` 8 組也重跑,都是 0。
- **對比**(對 C 右欄最亮的底 `#1D1F23`):數字 `#F5F7FA` 15.38、「此路段限速」`#CDD2D9` 10.86、單位 `#A6ACB5` 7.22、光條和圖示 `#6FD8E2` 9.90;門檻 7 / 4.5 / 4.5 / 3。
- **PNG**(新檔名,舊的不覆寫):`alert-rule-C-844.png`、`alert-rule-C-667.png`、`alert-rule-C-en.png`(667 英文)、`alert-rule-C-zoom.png`(844 右上角特寫,330×180)。`gauge-variants/` 共 89 張。
- **給 safety**:▲ 和 C 的紅針會不會被看成同一件事,見 §9.3。附近模式本來就沒有 ▲,這四張圖裡沒有 ▲。
- **手機上看**:「測速提醒」一段在 375、440 寬的 iframe 裡都在螢幕內(右緣 344 / 409),一個一個往下看。頁面下面各版本的圖庫(第六、七輪就有)縮圖寬 523,手機上整頁仍可以左右捲(寬 539),這一輪沒動。

### 9.2 第二段:主要設計稿照 C 重畫(L51)

**備份**:動手前把第五輪的 `frames/landscape-mockups.html` 和 `frames/landscape/` 整個複製到 `frames/archive-r5/`(HTML 1 份 + PNG 58 張,逐檔雜湊和原檔相同)。舊稿完整保留參考(L54),打開 `archive-r5/landscape-mockups.html?screen=<ID>` 還是第五輪的樣子。

**做法**:C 的量表、數字、`P R N D`、▲、側光條、胎壓面板的程式從比較頁複製到 `landscape-mockups.html`,數值一字不改。驗證:同樣的車速(0、58、88、112、147、240、沒資料)× 300 / 280 × 檔位(無、D、P)畫出來的 SVG 字串,兩頁完全相同(雜湊都是 2052949918),所以第七輪 safety 審過的筆畫實量(§8.1.1,C 直筆 ≥9.5、最細處 ≥9.0、夜間對比 ≥7.09)直接適用。三位數字高(03 §2.2 用「147」量):844 寬 106.4、667 寬 100.8,過 L39 的 105 / 100。另外直接量了匯出的 PNG:`S04-b-ble.png`(844)「112」字高 107、「1」的直筆 10.5;`S04-b-min-667x375.png`(667)字高 102、直筆 10.0,都過 R7-01 的 9 / 8.5 和字高 ÷ 12(8.9 / 8.5)。**兩份程式要一起改**:以後改比較頁的 C,主要設計稿也要跟著改。

| 項目 | 改成什麼 | 依據 |
|---|---|---|
| 速度表 | C「扇形」放在畫面正中間:844 寬量表區 300×300 在 (272, 50),667 寬 280×280 在 (193, 50);行車、停車同位置,提醒出現時錶不動 | L31、L49 |
| 車速數字 | Barlow Semi Condensed 400、等寬;兩位數 176 / 164 px,三位數 152 / 144 px;不加發光、外框、漸層 | L44、R7-01、R7-02 |
| `P R N D` | 數字正上方,目前檔位 700 + 底線;只在藍牙檔位新鮮、版面 = 車速 + 車況時出現(S04-b、S04-e 藍牙、mph、S04-h、XL、667、S06-b、S06-XL、S06-min 等);只有 GPS、P 過期(S04-i)、藍牙過期(S04-d)、沒資料、S06-f(中央已寫 P 檔)整排不畫 | L43、L46、R7-03 |
| ▲ | 58 張裡沒有前方模式超速,所以沒有 ▲;位置照第七輪留在數字正下方 | L46、R7-08 |
| 左下角 | 「72% / 315 km」(mph 時 196 mi),17 px、等寬;行車保留 48 高、停車保留 69 高,一行時貼底;大字換兩行(第一行 72%、第二行 315 km);舊值變暗 + 下面一行「12 分鐘前」;等待車輛時「—% / — km」;沒有藍牙資料時留空 | L33、L50、L21、01 §7.4 |
| 來源標示、齒輪 | 左上 (75, 16) / (16, 16),高 28;齒輪右上 48×48,x 721 / 603 | 01 §7.4 |
| 測速提醒 | 側光條 + 一行「此路段限速 60 公里」(mph「37 英里」),右欄上半 y 72 起;大字 ×1.27 換兩行 | L52、L53 |
| 停車 | 上方正中間日期膠囊「10/18(六)14:05」(667 寬和大字只寫「14:05」);左欄 y 52 車況狀態行(固定)、y 84 起捲動區(說明卡、行程、佔位);右欄胎壓面板 184×288 / 165×272 | 01 §7.4、§6.2 |
| 胎壓 | 每輪只有 psi,四角、沒有引線,共用時間行;S06-b / S06-f 新鮮、S06-c 四輪「—」+「尚無讀值」、S06-d 都舊「18 分鐘前」、S06-min 有新有舊「部分讀值時間未知」;S06-a、S06-e(未配對、未解鎖)不畫 | L42、L46、R6-08 |
| 第一次看到胎壓 | S06-b 左欄第一項是說明卡「胎壓僅供參考,請以車上的胎壓警示為準。」+「知道了」(44 高),在左欄第一屏(y 84–202,左欄到 296),不擋車速;其他停車稿是按過之後的樣子 | 01 S06、R7-16、R7-20 |
| S07 | 從左半的對話框改成右欄面板(x 584–769、y 16–369,蓋住齒輪、不往左擴),兩顆 48 高按鈕上下排在底部 | 01 §7.4、R6-07 |
| S05-b | 提醒的位置放一行說明 +「前往系統設定」(用滿欄寬、48 高,y 72–174) | L13、01 §7.4 |
| S01、S09 預覽,S03、S10 示範 | 預覽卡裡的 HUD 換成 C;示範的提醒換成側光條;S03、S10 的說明照 01 §6.3(L53)改成「顯示相機圖示和『此路段限速 60 公里』(數字來自測速點資料)」 | L53 |
| 顏色 | 整套換成 C 的槍灰中性色(背景、卡片、文字、分隔線);青色 `#2BD4E0` / `#6FD8E2` 只留給主要按鈕、開關、選取、連結和側光條;語意色(GPS 綠、搜尋和警告琥珀、紅色指針、危險紅)不變。見 A29 | L37、L49、01 §5.2 ③ |

**第八輪新增 3 張**(不在原本 58 張裡):
- `S04-b-min-667x375-en.png`、`S06-b-min-667x375-en.png`:R6-07 要求選定版本後補英文稿。最窄的 667 寬,英文提醒「Speed limit 60 km/h」排兩行;英文說明卡和「Got it」在左欄第一屏(y 84–262,左欄到 282)。
- `S06-b-parked-night.png`:夜間最暗預設的停車畫面,給 R6-10 的夜間調暗看。

**R6-10 陶瓷車身調暗**(L49):只用車圖的 CSS 濾鏡,`tire` 的 SVG 沒改。白天 `saturate(.12) brightness(.8)`,夜間 `saturate(.12) brightness(.5)`(再暗 37.5%,03 建議 30–40%)。量法照 03 R6-10:844 停車 PNG 的車圖範圍(x 625–729、y 102–310),WCAG 相對亮度。

| | 平均亮度 | 亮度 >0.3 的像素 |
|---|---|---|
| 玻璃款(比較頁 `cur-parked.png`,目標) | 0.113 | 7.7% |
| 陶瓷款、第七輪 C(`C-parked.png`,調暗前) | 0.182 | 24.1% |
| **陶瓷款、第八輪白天**(`S06-b-parked-ble-p.png`) | **0.109** | **4.2%** |
| **陶瓷款、第八輪夜間**(`S06-b-parked-night.png`) | **0.052** | 1.4% |

- 白天不比玻璃款亮。夜間只調暗車圖:白天和夜間兩張的胎壓面板,車圖範圍以外的 125,440 個像素(字、字底板、標題、時間行)完全相同,字不動。
- 比較頁的 `C-parked*.png` 是老闆選的時候看的樣子,保留參考,沒有調暗。

**自查**(Chrome,`await window.ready` 後,在 scratchpad 跑,沒有寫進頁面):29 張行車、無車速、停車、S07 畫面,**0 個問題**;胎壓 `tireAudit()` 8 個面板 0 個問題。項目:
- 字都在畫面裡;量表在 (272, 50) / (193, 50) 沒有移動;數字字型、字重、字級對。
- `P R N D`、電量、提醒、胎壓「該出現的出現、不該出現的不出現」(照上表逐張對)。
- 左欄、電量、胎壓離量表區 ≥12;電量每一行都在保留的空間裡(第一次跑時 S04-XL 兩行 56 高超出 48,已把大字行高改成 23,兩行剛好 48)。
- 來源標示寬度(行車 ≤270、停車 ≤160);來源標示和第二行提示離錶實際畫出來的像素:最近是 S05-c 的閘門提示 17.1,其他 ≥97。
- 日期膠囊 ≤140 / 120 寬、離來源標示 ≥16、離 `P R N D` 54–60。
- 提醒:在右欄、y 72 起、到 y 102–143、離錶的像素 25–44、相機圖示 ≥20、「此路段限速」不被拆開、速限數字字高 14.9(大字 19.0)≤26 / 25、光條是 `#6FD8E2`。
- 說明卡和「知道了」在左欄第一屏;S07 面板在右欄、不溢出、按鈕 48;S05-b 面板到 y 174、按鈕 48。

**對比**(對最亮的底 `#1D1F23` 或實際的卡片底):

| 文字 | 對比 | 門檻 |
|---|---|---|
| 來源標示、電量、狀態行、說明 `#CDD2D9` | 10.86(卡片上 11.82) | 4.5 |
| 電量舊值 `#8F949B`(和新值亮度比 2.18) | 5.40 | 4.5 |
| 行程標籤、單位 `#A6ACB5` | 7.22 | 4.5 |
| 行程數字、胎壓讀值 `#F5F7FA` | 15.38 | 4.5 |
| 胎壓舊值 `#A6ACB5`(和新值亮度比 2.27) | 7.22 | 4.5 |
| S07 標題 / 說明(面板 `#1A1C20`) | 15.90 / 11.22 | 4.5 |
| 主要按鈕字(`#0A0B0D` on `#2BD4E0`) | 10.87 | 4.5 |
| 連結、側光條、相機圖示 `#6FD8E2` | 9.90 | 4.5 / 3 |
| 表單:列文字 / 次要 / 單位 / 圖示 | 13.04 / 10.86 / 7.22 / 5.40 | 4.5 / 3 |
| 分段未選、停用按鈕字 `#9EA3AA` on `#24272C` | 5.90 | 4.5 |
| 高對比:次要 / 單位 / 電量舊值 | 14.56 / 11.09 / 6.89 | 4.5 |
| 夜間:次要 / 單位、電量舊值 | 5.62 / 4.94 | 4.5 |

速度表本身(數字、檔位、扇形)和第七輪相同:白天數字 15.38、夜間 ≥7.09;目前檔位 ≥8.6、其他三個 ≥3.6(§8.1)。

### 9.3 照 01 畫不出來或有疑問

- **「P 檔但在動」**:58 張裡沒有這個狀態的畫面,檔位排的規則照 R7-03 寫在程式和 S04 說明裡(有移動證據時整排不畫),沒有另外加一張。四種隱藏檔位列的狀態裡,「沒資料」是 S04-g / S05、「只有 GPS」是 S04-a / S04-e、「資料舊」是 S04-d / S04-i。
- **前方模式、琥珀色**:58 張裡本來就沒有(第五輪橫式只畫附近模式,前方模式的直式稿已被 L28 取代),所以沒有要換錶的。▲ 只在比較頁的 `C-over.png`。
- **給 safety:▲ 和 C 的紅針**:▲ 是琥珀 `#FFB638` 的實心三角形 24×20,在數字正下方 (422, 318) / (333, 302),只在前方模式超速時和琥珀數字一起出現;紅針是紅色 `#E8344F` 的短直線(外面一圈深色描邊),只在上半圓的外弧帶裡(離錶心 130–144),永遠在錶的底線(畫面 y 207 / 197)以上。兩者顏色、形狀、位置都不同,任何車速下 ▲ 離扇形帶和紅針都 ≥137 px(第七輪 `gaugeAudit`,C 300 / 280)。v1 不開前方模式,58 張都不會同時出現。
- **S06-a、S06-e 的佔位要捲動**:01 把佔位排在行程後面,844 寬時「連接車輛」「查看解鎖方式」在左欄第一屏下面,要往下捲才看得到(稿上用「↓ 可捲動」裁切帶標出來)。見 Q46。S06-b 的行程也要捲動才看得到「最高」,但裁切帶會壓到「平均」那一列字,所以 S06-b 不畫裁切帶(R7-21 已接受行程要捲動)。
- **提醒一行放不下**:中文在 844 寬剛好一行(要 170.7,有 172);667 寬和英文都排兩行,照 01 §5.2 只在「此路段限速」和「60 公里」之間換。實作換字型時 844 中文也可能變兩行,這是允許的。
- **夜間胎壓字比車速亮**:R6-10 要求夜間只調暗車圖、字不動,所以夜間胎壓讀值仍是 `#F5F7FA`,比夜間的車速數字 `#C0C2C4` 亮。停車時車速不是主角,但要不要讓胎壓字也跟著夜間顏色走(仍 ≥4.5:1),見 Q47。
- **大字胎壓**:S06-XL 字級 ×1.3,照 tire 的量法四角還放得下,不用換清單(150% 以上才換,比較頁 R7-19 有截圖)。
- **大字時錶不放大**:車速數字和單位都在錶裡,字級固定(01 §7.3 只說不拿掉單位);來源標示、提醒、電量、左欄、胎壓跟著放大。
- **沒資料的「—」**:Barlow 的長橫線在 176 px 時看起來像一條粗橫桿,和第七輪比較頁的 C 一樣(safety 已審過)。

### 9.4 建議的 `DESIGN.md` 改法(只針對 C;只寫建議,不改 `DESIGN.md`)

§8.5 四個版本的寫法保留不動。以下是老闆選定 C 之後的版本:

| 段落 | 現在寫的 | 建議改成 | 依據 |
|---|---|---|---|
| 色彩:底色 | `bg.base` `#0A101C` 深藍漸層 | 槍灰:`bg.base` `#0A0B0D`、漸層中心 `#1D1F23`;`surface.raised` `#24272C`;`divider` `#2A2D32`;卡片 `card` `#15171A`、外框 `card.border` `#4A4F57`(取代 `pill.border` `#2C5A66`) | L49、§9.2 |
| 色彩:文字 | `text.primary` `#F2F5FA`、`text.secondary` `#AEBCD4`、`unit` `#8A97AE`、`text.tertiary` `#6E7E8C` | `#F5F7FA`、`#CDD2D9`、`#A6ACB5`、`#8E949C`;`text.row` `#E1E5EA`;`text.dim` `#6B7078`(只用在裝飾線) | 對比見 §9.2 |
| 色彩:強調 | `accent` `#2BD4E0` 也用在量表 | `accent` / `accent.text` 保留,只用在主要按鈕、開關、選取、連結和側光條;量表不用青色 | 01 §5.2 ③ |
| Drive dial | 250° 細環 + 紅色標記 | C「扇形」:上半圓刻度帶(300 寬外半徑 148、內半徑 118,漸層 `#3A3E45` → `#26292E`),每 10 一小格(`#60656D` 1.5)、每 40 一大格(`#C3C8CF` 2.5),沒有刻度數字;填色 `rgba(225,230,236,.30)` 和外緣亮線 `#E1E6EC` 從內半徑 +10 開始;紅針 `#E8344F` 5 寬 + `#0D0E10` 深色描邊,只在外弧帶裡;沒資料時只留 `#5A5F67` 虛線外框 | L49、R6-02、R7-02 |
| Gauge numeral | Inter 700 | Barlow Semi Condensed 400(隨 app 打包,OFL),等寬;兩位數 176 / 164 px、三位數 152 / 144 px,字距 −1 / −6;墨跡中心比量表區中心低 2;單位 Barlow 500、23 px、`#A6ACB5`;不加發光、外框、漸層,日夜同字重 | L44、R7-01、R7-02、§8.1.1 |
| Gear selector | 底部膠囊 | `P R N D` 在數字正上方,每格 18、字母墨跡高 13;目前檔位 `#F5F7FA` 700 + 2 px 底線;其他三個 `#83868A` 400;離兩位數墨跡 13 | L43、R7-04、R7-05 |
| Over-speed ▲ | 數字上方 | 數字正下方 (422, 318) / (333, 302),24×20,`over` `#FFB638`(前方模式才有) | L46、R7-08 |
| 夜間最暗預設 | — | 數字 `#C0C2C4`、單位和「—」`#888D94`、次要 `#93979C`、其他檔位 `#777B7F`、外緣亮線 `#9DA1A5`、大格 `#8F9298`、紅針 `#C32A41`、填色 `.18`;胎壓車圖 `brightness(.5)`,胎壓字不變 | L44、R6-10 |
| 測速提醒 | 底卡 + 兩行 | 側光條:左邊 3 寬 `#6FD8E2` 光條 + 20 px 相機圖示 + 一行「此路段限速 60 公里」(15 px / 600,數字 20 px / 600,單位 15 px / 500);沒有底卡、外框;只在說法和數字之間換行 | L52、L53 |
| Battery / range | 狀態列 `72% · 315 km` | 左下角 `72% / 315 km`,17 px / 500、等寬;舊值 `#8F949B` + 下面一行時間;大字換兩行 | L33、L50、L21 |
| Parked | 右欄摘要 | 左欄:車況狀態行(固定)+ 捲動區(第一次看到胎壓的說明卡、行程、佔位);上方正中間日期膠囊;右欄胎壓面板(陶瓷車身 `saturate(.12) brightness(.8)`,字底板 `#1D1F23`、讀值 `#F5F7FA`、舊值 `#A6ACB5`、標題和時間行 `#CDD2D9`) | L42、L46、R6-10 |
| 字型 | Inter + Noto Sans TC | 加上 Barlow Semi Condensed(只用在車速、單位、`P R N D`) | L15、L49 |

### 9.5 PNG、假設和待確認問題

**PNG**(`frames/landscape/`,Chrome 2 倍,檔名和 `export-landscape.sh` 的表一樣):58 張全部照原檔名覆蓋(舊的在 `archive-r5/landscape/`),加上第八輪新增 3 張,共 61 張。L55 之後新增的 3 張(`?screen=S04minEn`、`S06minEn`、`S06night`)已加進 `export-landscape.sh`;§9.6 再加 5 張英文,不帶參數跑一次就匯出全部 66 張。

| # | 假設 | 依據 |
|---|---|---|
| A29 | 「照 C 重畫」包括整個 app 的顏色:背景、卡片、文字換成 C 的槍灰中性色;青色只留給互動元件和側光條(01 §5.2 ③ 指定光條用青色)。如果主持人只要換錶、其他頁面維持深藍,改回來只要換頁首的顏色變數。**L55 已確認** | L37、L49、L55 |
| A30 | 第一次看到胎壓的說明卡畫在 S06-b(藍牙停車、有胎壓讀值),其他停車稿是按過「知道了」之後的樣子 | 01 S06、R7-16 |
| A31 | 夜間胎壓字照 R6-10 不調暗 | R6-10、L49 |
| A32 | 比較頁 C 的停車畫面(`C-parked*.png`)保留老闆選的時候的樣子(車圖沒調暗),調暗只做在主要設計稿 | L49、L54 |

| # | 問題 | 給誰 |
|---|---|---|
| Q45 | ~~表單和設定頁跟著換成槍灰(A29)可以嗎?~~ → L55:接受,整個 app 一套槍灰,青色只留給按鈕、開關、選取、連結和側光條 | 已裁定 |
| Q46 | S06-a、S06-e 的佔位(「連接車輛」「查看解鎖方式」)照 01 排在行程後面,844 寬要捲動才看得到;要不要改排在行程前面? | L56:照 safety 建議不改(行程在前、捲動取得;第一次看到胎壓的說明仍在最上面) |
| Q47 | 夜間時胎壓讀值比車速數字亮(R6-10 規定字不動),要不要讓胎壓字也用夜間顏色(仍 ≥4.5:1)? | L56:不改,維持 R6-10;夜間實測(T03)刺眼再議 |
| Q48 | ~~新增的 3 張 PNG(兩張英文、一張夜間)要不要加進 `export-landscape.sh` 的表?~~ → L55:接受,已加進去(S04minEn、S06minEn、S06night),表裡共 61 張 | 已裁定 |

### 9.6 第八輪收尾:R8-01、R8-02(L56)

> 2026-10-20 17:31。safety(Codex)「第八輪(畫面)」有條件通過(0 P0 / 1 P1 / 1 P2)。Q46、Q47 照 safety 建議不改。只改了 `landscape-mockups.html`、`landscape/`、`export-landscape.sh`、本檔和 board。

- **R8-01 胎壓說明(06 C03 通過才有,粉紅框標條件)**,用字照 01 §6.4、§6.6:
  - S20 iOS / Android、S22 的功能清單加第 5 項「停車時查看胎壓」,下面小字「僅供參考，請以車上的胎壓警示為準」(13.5 px)。S21「沒有解鎖的話,你會失去」的清單也列這一項和小字。
  - S25 在「測速資料來源與授權」下面加「胎壓」一段:最後回報的讀值、僅供參考、可能不是最新的、以車上的胎壓警示為準、「—」表示這個輪胎目前沒有讀值、app 不判斷胎壓是否正常。
  - 放不下就捲動,不縮字、不擠:S21、S22、S25 和英文的 S20 左欄用「↓ 可捲動」裁切帶標出來;中文 S20 左欄剛好放得下(251 / 251),不標。
  - **英文**:新增 5 張 `S20-ios-trial-claim-en.png`、`S20-android-trial-start-en.png`、`S21-trial-ended-en.png`、`S22-unlock-en.png`、`S25-about-en.png`。英文用 01 的英文;價格用美國 A 的 US$9.99 示意(粉紅虛線 = 從商店取得)。
- **R8-02 靜態的勾改成中性色**:功能清單的勾改用 `text.secondary` `#CDD2D9`(10.86:1);S13 準備清單的圓點也改成同色。S21 的「—」本來就是中性 `#8E949C`(5.40:1)。青色只留給按鈕、開關、選取(S01 / S09 選中的卡片)、連結和側光條;成功圖示、配對進度條、轉圈、S15 / S16 插圖是狀態或插圖,照 03 R8-02「成功 / 警告狀態保留各自圖示」不動。
- **中文標點**:新的中文用全形「，」「；」,和這一頁其他中文一致;S06-b 說明卡「胎壓僅供參考,請以…」的半形逗號也改成全形(01 用字表本身是半形)。
- **01 寫得不夠、先照假設畫的**(board 也寫了):① S20 說明句「試用結束後,車輛藍牙車速、檔位、電量與續航需以 {價格} 一次解鎖」在 06 C03 通過時沒有提到胎壓,先照 01 原句不改;② S21「你會失去」的清單 01 沒單獨列,先用同一份功能清單(含胎壓和小字);③ S25 胎壓一段的小標題 01 沒寫,先用「胎壓 / Tire pressure」;④ S25「隱私說明」01 沒有英文列名,先用「Privacy」;⑤ 英文購買頁的價格用美國 A 的 US$9.99。
- **自查**(Chrome,在 scratchpad 跑):
  - 新的檢查 0 個問題:8 張購買 / 試用頁(中英)第 5 項的字和 01 一樣、小字 ≥13 px、功能清單沒有青色的勾、放不下的欄都有「可捲動」標記、沒有橫向超出;S25 中英的胎壓一段包含 01 的 7 個重點;S13 的點是中性色。
  - 第八輪的 HUD 自查重跑:29 張 0 個問題;胎壓 8 個面板 0 個問題。
- **PNG**:`export-landscape.sh` 加上 5 張英文,表裡共 66 張,不帶參數跑一次全部匯出。和上一版比:
  - 改了 10 張:S06-b(全形逗號)、S13(圓點顏色)、S20 iOS / Android、S21、S22、S25,和背景是 S22 的 S24 三張對話框。
  - 新增 5 張英文;其他 51 張逐位元相同。
  - S12 和 S06-e 的畫法沒變,但這次重新匯出時 S12 的字反鋸齒略有不同(34,021 個像素差一點,只有 4 個像素差超過 40 階),S06-e 有 2 個像素差 2 階;原因沒查到(同一份舊 HTML 重畫 S12 還是舊的樣子),所以放回上一版的檔案。之後用腳本重跑時這兩張可能會出現同樣的小差異。

### 9.7 `DESIGN.md` 已更新

> 2026-10-20 17:43。使用者同意把定案的設計寫進 repo 根目錄的 `DESIGN.md`(這一次只有它例外可以改;`PRODUCT.md`、`.pen`、程式碼沒動)。結構、語氣(英文)和格式照原本的;每條規則後面標來源(`Lnn`、`02 §x`、`01 §x`、`R7-nn` / `R8-nn`)。

**改了哪些段**(116 行 → 217 行):

| 段落 | 改成什麼 |
|---|---|
| 開頭 | 說明這是第八輪定案(C「扇形」、只做橫式);來源縮寫的意思;參考稿改成 `landscape-mockups.html`(`.pen` 改列為舊參考) |
| Design principles | 只做橫式、沒有鏡像;槍灰中性色、青色只給能按的東西和側光條;狀態不只靠顏色;沒資料是「—」不是 0 |
| Color tokens | 整套換成 §9.4 的槍灰 token(含對比值);C 的錶盤、紅針、沒資料、`P R N D` 顏色;語意色;胎壓面板;高對比 |
| Typography | Inter + Noto Sans TC + Barlow Semi Condensed(只給車速、單位、`P R N D`),都隨 app 打包、等寬數字;字級表;車速數字的下限(筆畫、無發光、≥7:1、三位數字高 105 / 100,含 C 的實量) |
| Spacing & radius | 安全區 max(左, 右) + 16;圓角照主要設計稿 |
| **新增** Layout (landscape) | 01 §7.4 的座標表(量表區、來源標示、齒輪、提醒、電量 / 續航、日期膠囊、左欄、胎壓、右下角) |
| Gauge spec | 換成 C 的完整畫法(幾何、刻度、填色和紅針外移、數字位置、`P R N D` 規則、▲ 位置、沒資料、S06-f「P 檔」、夜間預設) |
| **新增** Speed-camera alert | 側光條、L53 用字和「這是 06 C06 的例外、使用者已接受風險」、換行、大小和對比、出現 / 消失、什麼時候不出現 |
| **新增** Parked screen | 左欄順序、第一次看到胎壓的說明卡、psi 胎壓(共用時間行、清單版、讀屏)、陶瓷車身調暗(白天 0.109 / 夜間 0.052)、三處免責 |
| Hardened states | 來源標示永遠寫目前車速來源、舊值不靠透明度、等待車輛、沒資料、充電標 v1.x、邊界值 |
| Information architecture | 表格照現在的範圍重寫(拿掉 `TESLA` 標示、速限標記、溫度等;加提醒、胎壓、日期);組合來源規則照 L7 |
| New element specs | 行程改成左欄三列;功率條 v1.x;0–100、能耗延後 |
| Screen inventory | 主要設計稿 66 張和匯出腳本;比較頁(保留參考,L54);第五輪、直式、`.pen` 都是舊參考 |
| Component states | 開關、分段、按鈕、點擊區、靜態清單記號(R8-02)、捲動提示;**新增** Forms & flows(橫式表單、確認框和 S07 右欄面板、大字) |

**沒寫進去的建議和原因**:
- §4.0 的「量表永遠在左」、右欄提醒卡 y 96 / 狀態列 y 214:被 L31(置中)取代。
- §4.1 直式時代的寫法:數字下方的狀態列和「沒有 `P R N D`」(被 L43 取代)、▲ 在數字上方(被 L46 取代)、兩行提醒卡「附近有測速點 / 點位資料速限」(被 L53 取代)、每輪「最後量測 N 分鐘前」和 bar(被 L42 取代)、底部拉起的確認面板(被橫式的置中對話框和 S07 右欄面板取代)、Inter 700 / 158 的數字(被 L44、L49 取代)。
- §7.6 的「字重 ≥600」和數字下方的檔位方塊:被 L46(細字)和 L43 取代。
- §8.5 四個版本的寫法:只留 C(L49);其他版本在 `DESIGN.md` 只用一句帶過,指到 `gauge-variants.html`(L54)。
- 原本 `DESIGN.md` 的舊 token(`dial.cap`、`limit.marker`、`hub`、琥珀強調色)和鏡像、`TESLA` 標示:被 L3、L29、L49、L55 取代,刪掉。

**寫了但要確認的**(board 也列了):
- 夜間最暗預設的 token 標成「暫定」:Q42 一直沒有裁定(02 A25),等 T03 實測。
- 設定裡的「強調色」(青色 / 靛藍,01 §6.4):L55 說青色只留給能按的東西和側光條,但沒說使用者換成靛藍時,按鈕和側光條要不要跟著換;01 §5.2 ③ 把光條寫死成 `#6FD8E2`。先寫成「有這個選項,光條照 01 用 `accent.text`」。
- mph 時錶盤仍照 km/h 畫(只換數字和單位):這是 02 §9.2 稿上的畫法,沒有裁定。
- 停車畫面拿掉溫度等次要資訊:01 S06 的元素清單本來就沒有,所以在資訊架構表裡標「延後」。
- `PRODUCT.md` 還有鏡像的寫法(02 §4.0 有建議改法),這次不能改,留給主持人。

## 附錄 A. 直式稿(第一到第四階段)— 已被 L28 取代

**【已取代】** 這一節是直式稿的紀錄。00-rulings L28 改成只做橫式後,直式稿和 `frames/stage2-mockups.html` 全部保留不刪,但不再使用;現行稿見 §2。原說明:主要設計稿是 `docs/design/frames/stage2-mockups.html`。直接開啟會看到全部畫面和說明(依 drive / 前方條件稿 / 無車速 / 停車 / 首次開啟 / 設定 / 配對 / 付費 / 已取代分組);加 `?screen=<錨點>` 只顯示一張。`.pen` 節點 ID 全部是「—」:還沒同步回 `.pen`。

- **01 畫面 ID** 是產品狀態的正式 ID(04 第四階段要求);**visual 標籤**是 PNG 檔名和 HTML 錨點用的舊標籤,為了不讓 03、04 的引用失效,檔名不改。最容易混淆的兩個:visual 的 `S04-n` = 01 的 **S04-e(附近模式)**;visual 的 `S04-e` = 01 的 **S04-e2(前方模式)**。
- **狀態**:「v1」= v1 要用的正式稿;「條件稿」= 條件成立才會出現(前方模式、鏡像驗收、美國上架、美國 B);「已取代」= 舊稿只留作對照。
- 粉紅虛線和粉紅小字是給團隊看的標示(條件列、商店價格、SafeArea、一屏底線),不在 app 上。

**現行稿(52 張)**

| `.pen` 節點 ID | 01 畫面 ID | visual 標籤 | 名稱 | HTML 錨點 | PNG | 狀態 |
|---|---|---|---|---|---|---|
| — | S04-a | S04-a | 行車・GPS(平常) | `?screen=S04a` | `frames/S04-a-drive-gps.png` | v1 |
| — | S04(§4.1 第 2 步) | S04-a(待完成設定) | 行車・齒輪旁「待完成設定」小圓點 | `?screen=S04aSetup` | `frames/S04-a-setup-pending.png` | v1(第四階段收尾新增) |
| — | S04-b | S04-b | 行車・車輛藍牙(三位數 112,L26 縮成 140) | `?screen=S04b` | `frames/S04-b-drive-ble.png` | v1 |
| — | S04-h | S04-h | 行車・藍牙有效 + 拒絕定位(L9) | `?screen=S04h` | `frames/S04-h-ble-location-denied.png` | v1(已更新:來源合成一行) |
| — | S04-i | S04-i | 行車・P 檔過期,剛離開停車畫面 | `?screen=S04i` | `frames/S04-i-p-stale-left-parked.png` | v1(新增,取代 S06-i) |
| — | S04-e(附近模式) | S04-n | 行車・附近有測速點 | `?screen=S04n` | `frames/S04-n-camera-nearby.png` | v1 |
| — | S04-e(附近,mph) | S04-n(mph) | 行車・附近有測速點,mph | `?screen=S04nMph` | `frames/S04-n-camera-nearby-mph.png` | v1 |
| — | S04 橫式 | S04-L | 行車・橫式 844×390 | `?screen=S04L` | `frames/S04-L-drive-landscape.png` | v1(已更新:SafeArea) |
| — | S04 大字 | S04-XL | 行車・大字與高對比 | `?screen=S04XL` | `frames/S04-XL-drive-large-text.png` | 條件稿:美國上架前加入 |
| — | S04-e2(前方模式) | S04-e | 行車・前方 300 m | `?screen=S04e` | `frames/S04-e-camera-ahead.png` | 條件稿:前方模式,v1 不開 |
| — | S04-e2(前方,mph) | S04-e(mph) | 行車・前方 0.2 mi | `?screen=S04eMph` | `frames/S04-e-camera-ahead-mph.png` | 條件稿:前方模式,v1 不開 |
| — | S04-f | S04-f | 行車・超過點位資料速限 | `?screen=S04f` | `frames/S04-f-over-limit.png` | 條件稿:前方模式,v1 不開 |
| — | S04-f(英文) | S04-f(英文) | 同上,英文 | `?screen=S04fEN` | `frames/S04-f-over-limit-en.png` | 條件稿:前方模式,v1 不開 |
| — | S04-f(mph) | S04-f(mph) | 同上,mph | `?screen=S04fMph` | `frames/S04-f-over-limit-mph.png` | 條件稿:前方模式,v1 不開 |
| — | S04-f(鏡像) | S04-f(鏡像) | 同上,鏡像檢查 | `?screen=S04fMirror` | `frames/S04-f-mirror-check.png` | 條件稿:前方模式 + 鏡像驗收 |
| — | S05 | S05 | 無有效車速(兩個來源都無效;也取代 S06-h) | `?screen=S05` | `frames/S05-no-speed.png` | v1 |
| — | S02 拒絕態(呈於 S05) | S05-b | 定位被拒、沒有藍牙:一行字 + 前往系統設定(L13) | `?screen=S05b` | `frames/S05-b-location-denied-no-car.png` | v1(已更新:「—」下寫 GPS 不可用) |
| — | S05 + 閘門提示 | S05-c | 沒有資料又沒配對:到收得到 GPS 的地方…(L17) | `?screen=S05c` | `frames/S05-c-gate-no-gps-unpaired.png` | v1(新增) |
| — | S06-b | S06-b | 停車・藍牙 P(新鮮 P + 有效 0) | `?screen=S06b` | `frames/S06-b-parked-ble-p.png` | v1(胎壓區:06 C03 通過才有) |
| — | S06-f | S06-f | 停車・新鮮 P,車速缺值(中央「P 檔」) | `?screen=S06f` | `frames/S06-f-parked-p-no-speed.png` | v1 |
| — | S06-a | S06-a | 停車・只有 GPS,已知停車後手動進入 | `?screen=S06a` | `frames/S06-a-parked-gps-manual.png` | v1 |
| — | S06-d | S06-d | 停車・只有 GPS 的手動停車 + 舊電量 | `?screen=S06d` | `frames/S06-d-parked-gps-manual-old-battery.png` | v1(新增,取代 S06-g) |
| — | S06 橫式 | S06-L | 停車・橫式 844×390 | `?screen=S06L` | `frames/S06-L-parked-landscape.png` | v1(已更新:SafeArea) |
| — | S06 大字 | S06-XL | 停車・大字與高對比(會捲動) | `?screen=S06XL` | `frames/S06-XL-parked-large-text.png` | 條件稿:美國上架前加入 |
| — | S01 | S01 | 首次開啟:選行車畫面 | `?screen=S01` | `frames/S01-first-run-layout.png` | v1 |
| — | S03 | S03 | 固定測速照相提醒(首次,台灣) | `?screen=S03` | `frames/S03-camera-alerts-intro.png` | v1(已更新:附近模式說明、示範標) |
| — | S28 | S28 | 安裝提醒 | `?screen=S28` | `frames/S28-mounting-tips.png` | v1 |
| — | S07 | S07 | 停車確認(只有 GPS) | `?screen=S07` | `frames/S07-parked-confirm.png` | v1(已更新:L20) |
| — | S08 | S08 | 設定(長頁 390×1380) | `?screen=S08` | `frames/S08-settings.png` | v1(已更新:定位權限列、試用列) |
| — | S09 | S09 | 行車畫面設定 | `?screen=S09` | `frames/S09-driving-screen-settings.png` | v1(已更新:R4-09) |
| — | S10 | S10 | 固定測速照相提醒設定・有效 | `?screen=S10` | `frames/S10-camera-alert-settings.png` | v1(已更新) |
| — | S10(已過期) | S10-b | 固定測速照相提醒設定・已過期(L16、L22) | `?screen=S10b` | `frames/S10-b-camera-data-expired.png` | v1(新增) |
| — | S11 | S11 | 鏡像預覽 | `?screen=S11` | `frames/S11-mirror-preview.png` | 條件稿:鏡像驗收通過才開 |
| — | S12 | S12 | 本版本不提供 | `?screen=S12` | `frames/S12-not-in-this-version.png` | v1 |
| — | S25 | S25 | 關於與聲明 | `?screen=S25` | `frames/S25-about.png` | v1(已更新:拿掉佔位;隱私頁未畫) |
| — | S13 | S13 | 配對:開始前 | `?screen=S13` | `frames/S13-pair-start.png` | v1(已更新:第 4 條 GPS) |
| — | S14 | S14 | 配對:輸入 VIN(錯誤狀態) | `?screen=S14` | `frames/S14-pair-vin-error.png` | v1 |
| — | S15 | S15 | 配對:尋找並連線 | `?screen=S15` | `frames/S15-pair-searching.png` | v1 |
| — | S16 | S16 | 配對:感應鑰匙卡 | `?screen=S16` | `frames/S16-pair-key-card.png` | v1 |
| — | S17 | S17 | 配對:完成 | `?screen=S17` | `frames/S17-pair-done.png` | v1 |
| — | S18-c | S18-c | 配對失敗:找不到你的車 | `?screen=S18c` | `frames/S18-c-pair-car-not-found.png` | v1 |
| — | S18-h | S18-h | 已暫停配對(L10) | `?screen=S18h` | `frames/S18-h-pair-paused.png` | v1(已更新:按鈕) |
| — | S19 | S19 | 車輛藍牙管理(一台車) | `?screen=S19` | `frames/S19-car-bluetooth.png` | v1(已更新) |
| — | S19 移除確認 | S19-b | 移除這台車:確認框 | `?screen=S19b` | `frames/S19-b-remove-confirm.png` | v1 |
| — | S19 改配對確認 | S19-c | 改配對另一台車:確認框 | `?screen=S19c` | `frames/S19-c-repair-confirm.png` | v1(新增) |
| — | S19 改配對沒完成 | S19-d | 改配對沒有完成:訊息 | `?screen=S19d` | `frames/S19-d-repair-not-completed.png` | v1(新增) |
| — | S20(iOS) | S20 iOS | 領取 7 天免費試用 | `?screen=S20ios` | `frames/S20-ios-trial-claim-tw.png` | v1(新增,取代 S20) |
| — | S20(Android) | S20 Android | 開始 7 天免費試用 | `?screen=S20and` | `frames/S20-android-trial-start-tw.png` | v1(新增,取代 S20) |
| — | S21 | S21 | 免費試用已結束 | `?screen=S21` | `frames/S21-trial-ended-tw.png` | v1(已更新:L14、{價格}) |
| — | S22 | S22 | 解鎖(台灣) | `?screen=S22` | `frames/S22-unlock-tw.png` | v1(已更新:{價格}) |
| — | S23 | S23 | Support development(美國 B,英文) | `?screen=S23` | `frames/S23-support-us-b.png` | 條件稿:美國 B 勝出才上 |
| — | S24 | S24 | 購買結果(11 種訊息一覽) | `?screen=S24` | `frames/S24-purchase-results.png` | v1(已更新:L14) |

**已取代的舊稿(6 張,PNG 保留不刪,也不再重新匯出)**

| `.pen` 節點 ID | 01 畫面 ID(新稿) | visual 標籤 | 名稱 | HTML 錨點 | PNG(保留不刪) | 狀態 |
|---|---|---|---|---|---|---|
| — | S02(app 說明頁) | S02 | 定位權限說明頁 | `?screen=S02` | `frames/S02-location-permission.png` | 已取代 → 01 改成直接跳系統對話框,不畫 app 頁(R4-02) |
| — | S02 拒絕態 | S02-b | 定位被拒說明頁 | `?screen=S02b` | `frames/S02-b-location-denied.png` | 已取代 → S05-b(L13、R4-02);完整說明移到 S08「定位權限」列 |
| — | S06-d | S06-g | 停車・GPS 備援 + 舊電量(舊版) | `?screen=S06g` | `frames/S06-g-parked-gps-old-battery.png` | 已取代 → S06-d(L21 歷史色、來源 ● GPS、藍牙狀態寫在車況區) |
| — | S05 | S06-h | 停車・兩個來源都無效 | `?screen=S06h` | `frames/S06-h-parked-no-source.png` | 已取代 → S05(R4-01:沒有資料退回最小 HUD) |
| — | S04-i | S06-i | 停車・P 檔過期 | `?screen=S06i` | `frames/S06-i-parked-p-stale.png` | 已取代 → S04-i(R4-01:P 過期回 drive) |
| — | S20 | S20 | 試用開始(共用版) | `?screen=S20` | `frames/S20-trial-start-tw.png` | 已取代 → S20 iOS / S20 Android(L14、R4-06) |

S26、S27(美國方案測試網頁)照指示不畫。

### A.1 各畫面的設計決定(第一批)

第四階段改過的列,以 §2.1c、§2.1d 為準。

| 畫面 | 決定 | 依據 |
|---|---|---|
| S04 共用 | 量表照 `.pen` D2:圓心 (195,340)、外徑 150、環寬 7.5、215° 起掃 -250°、滿刻度 240。保留 D2 的端點圓點,另加 DESIGN.md 的紅色目前值標記(環內 118–136)。不加刻度 | `.pen` D2、DESIGN.md Drive dial、[03 S10]「優先移除刻度」 |
| S04 共用 | 來源標示 (24,38):形狀 12px + 文字 13/600、字距 1、`text.secondary`。● 綠 = 有效;◐ 琥珀半實心 = 備援或連線中;◌ 虛線環 = 等待;▲ 琥珀 = 沒有有效車速 | [01 §3.4]、[03 S06 S07] |
| S04 共用 | 齒輪換成 `#6E7E8C`(4.13:1),點擊區 44×44 | [03 S11]、WCAG 1.4.11 |
| S04-b | 狀態列放在觸發區下方 y 640,不貼底:一個掃視就看得到「車速 → 提醒 → 狀態」。內容只有目前檔位(方框字母)、電池膠囊、`72% · 315 km` | [01 §8] 狀態列、[10 §drive] 草圖順序;位置見 Q8 |
| S04-e | 觸發卡片:`pill` 底色和框線、相機圖示、「點位資料速限」15/600 + `60` 28/700 + `300 m` 22/600。數字仍是白色 | [01 §6.1]、[06 C06] |
| S04-f | 琥珀時三個非顏色記號:① 數字上方 ▲(30px,y 214,左右對稱,鏡像也一樣);② 卡片圖示換成 ▲;③ 文字換成「超過點位資料速限」。卡片 2px 琥珀框 + 深琥珀底。弧形和紅色標記維持中性。不閃爍 | [01 §5.3]、[03 S05]、[06 C06] |
| S04-f 英文 | 「● Car Bluetooth」「Over listed limit 60」寬度都放得下 | [01 §6.1] |
| S04-f 鏡像 | 整個 HUD 翻轉;▲ 和形狀記號翻了還是一樣;狀態列和卡片文字反過來,要靠反射讀正 | [01 §7.2] |
| S05 | 數字換成單一「—」(158/700,`speed.unavailable #8A97AE`,5.84:1)。active 弧、端點、紅色標記**拿掉**,不是變暗。觸發區和狀態列都不出現 | [01 §3.4]、[03 S03 P0] |
| S06-b | 量表、數字大小和位置**和 drive 完全相同**,切換時不跳。`0` 是新鮮藍牙車速。數字下方是同一種狀態列 `P │ 72% · 315 km`。下面依序是行程(加「由手機 GPS 計算」)和胎壓 | [01 §2.2]、[03 S01 P0] |
| S06-b 胎壓 | 四輪各自顯示值和「最後量測 N 分鐘前」;缺值的輪子顯示「—」+「量測時間未知」;標題旁「僅供參考,請以車上的胎壓警示為準」;沒有正常色或勾號。**06 C03 沒過就整區拿掉** | [01 §6.2]、[03 S09]、[06 C03] |
| S06 共用 | 日期膠囊移到量表上方(y 96),只留日期時間(溫度需要藍牙、延後),讓出底部給胎壓 | [10 §parked] D18 延後 |
| S06-a | 車速「—」+ ▲ 車速暫不可用;車況是虛線佔位「連接車輛後可顯示檔位與電量」+「連接車輛 ›」;沒有胎壓 | [01 §2.2 S06-a]、[06 C09] |
| S01 | 兩張卡上下排,左邊是迷你預覽(標「示範」);車況預覽只有虛線「連接車輛後顯示」,不放假值。選取狀態 = 2px 青框 + 打勾圖示(不只靠顏色)。主按鈕「繼續」;次要按鈕「現在連接車輛」 | [01 §4.1 §6.3]、[06 C01] |
| S16 | 步驟 3/4 進度條 + 抽象中控台、感應區(虛線框)、卡片、感應波紋;不用車廠外觀或標誌。等待時間未知,只放轉圈 +「等待感應…」,不放倒數 | [01 §4.2 Q1] |
| S12 | 4 項功能列表,統一用 ⊘ 圖示(不畫成車上指示燈);C02 文案照 06 原文;底部獨立開發聲明 | [06 C02]、[01 §6.4] |
| S22 | 價格 `NT$290` + 「一次付費,不是訂閱。」;功能清單 1–4(胎壓沒列);06 C07 付費文案(**待實車通過後才能用**);三個連結;底部固定「以 NT$290 購買」+「恢復購買」 | [01 §6.6]、[06 C07] |
| S08 | 依 01 的 5 個群組。「測速照相提醒」整列點進 S10、右邊顯示「開啟 ›」,不在同一列放開關和箭頭兩個點擊目標。「鏡像 HUD 模式」顯示「關閉 ›」進 S11。強調色只剩青、靛 | [01 §6.4]、[03 S08] |
| 全部 | 畫面上的中文用全形標點(，；？：)。06 原文是全形,01 轉錄時變成半形 | 台灣排版慣例 |

### A.1b 各畫面的設計決定(第二批)

第四階段收尾改過的列(S04-h、S06-g/h/i、S02/S02-b、S03、S07、S09、S10、S18-h、S19、S20、S21、S24、S25)以 §2.1d 為準。

| 畫面 | 決定 | 依據 |
|---|---|---|
| L9 停車狀態稿共用 | 同一個停車版型:來源標示寫**目前車速**的來源;檔位框新鮮 P 才寫 `P`,否則 `—`,下方再加一行「檔位資料已過期」(不只靠框裡的「—」,文案見 Q21);電量舊值變暗 38%,下一行「電量最後更新 N 分鐘前」不變暗;胎壓每輪用自己的量測時間 | L9、[01 §2.2 §2.3]、[03 R2-09] |
| S04-h | ● 車輛藍牙 + 下方第二行「GPS 不可用」(定位關閉圖示,12.5/600,`text.secondary`);觸發區不出現;狀態列照常 | L9;文案照 [03 R2-09] |
| S06-g | 有效 GPS 0 + ◐ GPS · 藍牙中斷;電量和胎壓變暗、各自標時間 | L9 |
| S06-h | 「—」+ ▲ 車速暫不可用,弧形和標記拿掉;檔位 `—`;電量、胎壓變暗並標時間;行程註記「由手機 GPS 計算(最後一趟)」 | L9、L6-3 |
| S06-i | 藍牙還連著但 DriveState 過期:◐ GPS · 藍牙資料過期;檔位 `—`;電量還在自己 60 秒的有效期內,所以正常顯示、不變暗 | L9、[01 §3.2] |
| S04-n | 兩行卡片(01 的文案是一行用「・」連接,改成兩行是 visual 的排版,字沒有改):第一行「附近有測速點」,第二行「點位資料速限 **60** km/h」;相機圖示;沒有距離、不轉琥珀;位置和前方模式相同(y 522),數字不動 | L8-1、[01 §6.1] |
| S02 | 首次開啟、沒有資料時唯一能打開的入口(L6-3);只有用途說明和「允許定位」 | L6-3、[01 §6.3] |
| S02-b | 標題「GPS 不可用」,說明定位只影響 GPS 車速和測速提醒、不影響藍牙車速 | [03 R2-09];文案見 Q14 |
| S03 | 只介紹附近模式,範例卡片和 S04-n 同一個元件;資料聲明照 06;開關預設開;「繼續」+「返回」 | L8、[01 §6.3] |
| S28 | 三條提醒用編號,不用氣囊或方向盤圖示(避免像車上警示燈);補充說明放卡片;「知道了」+「略過」 | [01 §6.4]、[03 S12] |
| S07 | 底部確認框蓋在 HUD 上;多一行依據「GPS 車速 0 km/h ・ 已靜止 10 秒」;沒有「不再詢問」 | L6-1;依據文案見 Q15 |
| S09 | 重用 S01 卡片;提醒開著時,預覽裡加一張迷你附近卡片;沒連車提示 +「連接車輛 ›」;「固定測速照相提醒另外設定:開啟中 ›」 | [01 §2.1 四種組合]、[03 S08] |
| S10 | 開關;「會顯示什麼」放附近卡片;「前方距離和超過提示」是停用列 + 🔒「尚未開放」;資料區:來源、版本 + 最後驗證日期、授權、聲明 | L8-1、L8-2;Q18、Q20 |
| S11 | 預覽是翻轉後的 S04-b(縮 0.42);開關預設關;說明 + 限制;「安裝提醒」「畫面亮度」入口 | [01 §6.4 §7.2] |
| S25 | 版本、獨立開發聲明卡片、三列連結;隱私列是佔位 | [01 §6.4]、01 Q18 |
| S13 | 準備清單(圓點,不用打勾,避免看起來像已完成)+「我們會用到」三項;取消在左上,底部只有「開始」 | [01 §6.5]、[06 C10] |
| S14 | 錯誤狀態:2px 琥珀框 + ▲ + 文字;「下一步」停用(灰底);範例 VIN 是假的 | [01 §6.5] |
| S15 | 兩行進度:目前步驟轉圈,下一步用編號圓圈;手機—藍牙—車輛的通用圖示 | [01 §4.2] |
| S17 | 三格真實讀值(車速、檔位、電量)+ 來源標示預覽;只有「完成」 | [01 §4.2 #8] |
| S18 | 共用版型:琥珀圖示框 + 原因 + 做法 + 按鈕。這批畫了 c(找不到車)和 h(暫停) | [01 §6.5]、L10 |
| S19 | 一張車輛卡片(形狀 + 文字狀態、最後連線、重新連線);「改配對另一台車」並說明會取代;「移除這台車」紅字;S19-b 底部確認框 | L12;Q17 |
| S20 / S21 | 功能清單 1–4;S21 用減號列出會失去的,仍免費的放卡片;兩者都不會自動跳出 | [01 §6.6]、L11 |
| S23 | 美國 B 只在美國上線,所以畫英文;「All car data features are free.」放最上面 | [06 C08] |
| S24 | 9 種結果用同一種卡片(圖示 + 文字);卡片內的灰字是給團隊的情境說明,不在 app 上 | [01 §6.6] |
| 新元件 | 底部確認框:底色 `#121C2B`、上方圓角 24、拉把;危險動作用 `#FF8A9B` 字 + `#6A2C39` 框 | S07、S19-b |

### A.1c 第四階段的修正與新增

| 畫面 | 改了什麼 | 依據 |
|---|---|---|
| S06-a(P0) | 改成只有 GPS 的已知停車(有效 GPS ≤1 km/h 持續 10 秒 + S07 確認)後,點車速區手動進入:有效 GPS 0、● GPS、未配對佔位、行程。說明拿掉「地下室」路徑;沒有有效資料時留在 S05。「連接車輛」入口按下去要重新檢查操作許可 | R3-01、L6-3、L6-5 |
| S04-e | 卡片改成兩行:「前方 **300 m**」/「點位資料速限 **60** km/h」,和附近模式同一個元件 | R3-02、R3-03、L18 Q6 |
| S04-f / 英文 / 鏡像 | 只留數字上方一個 ▲;卡片拿掉 ▲,保留「超過點位資料速限 60 km/h」/「Above camera data limit 60 km/h」 | R3-09、L18 Q7 |
| mph 三張 | 車速和卡片速限都換算(58→36、68→42、60→37 mph);狀態列續航改 mi;內部仍用 km/h 比較 | R3-03、L8-3 |
| S05 | 「—」下方的單位位置改寫「車速暫不可用」(18/600,`text.secondary`) | L18 Q9 |
| S05-b | 來源 ▲ GPS 不可用;觸發區位置只放一行字 + 一顆「前往系統設定」(打開作業系統設定);文案照 01 §6.3 | L13 |
| S06-b | 用和 L9 狀態稿同一個停車版型;電量下方「電量最後更新 20 秒前」;胎壓左後「量測時間未知」(有值、變暗)、右後「尚無讀值」(沒有值) | R3-04、R3-05 |
| S06-f | 中央「P 檔」(110/700)+「車速暫不可用」,弧形和標記拿掉,不畫 0 | R3-04、[01 §2.2]、[06 C09] |
| S01 | 有資料、已知停車後才出現;加「返回」「略過」;純車速說明加提醒;兩張預覽都畫示範附近卡;試用說法拿掉,等 ux 照 L14 定稿 | R3-07、L6-3、L14 |
| S08 | 提醒列改名「固定測速照相提醒」;加「大字與高對比」「安裝提醒」;鏡像列和大字列加粉紅虛線框(條件標示,只給團隊看,不在 app 上) | R3-08、[01 §6.4] |
| 點擊區(全域) | 齒輪 48×48;色票每個 48×48;分段選項高 42(含外框 48);文字按鈕、連結高 48 | R3-06、[01 §7.3] |
| 字型(全域) | Inter(拉丁字、數字)+ Noto Sans TC(中文,隨 app 打包);不再寫 PingFang TC | L15 |
| S04-L | 量表固定在左(圓心 250,195),右欄放提醒卡和狀態列;提醒出現或消失時量表不動。左右各留 60 安全區 | L19、[01 §7.1];Q24 |
| S06-L | 量表和 S04-L 同位置;右欄:日期、狀態列 + 電量時間、行程、胎壓精簡格(每格一行數值 + 一行時間) | L19、[01 §7.1] |
| S04-XL / S06-XL | 車速 158 不放大(01 §7.3);放大來源標示 18、單位 28、提醒卡 19/36、狀態列 21、行程 23、胎壓 25;高對比:次要文字 `#E3EAF4`、框線 `#4F8796`、底環 `#33476A`。停車畫面放大後超出一屏,改成可捲動 | L19、[01 §7.3];Q23、Q25 |

### A.1d 第四階段收尾的修正與新增

| 畫面 | 改了什麼 | 依據 |
|---|---|---|
| S06-h → S05 | 兩個來源都無效時退回最小 HUD,不留電量、行程、胎壓摘要;舊稿標已取代 | R4-01(P0)、01 §11 Q21 |
| S06-i → S04-i(新) | 自動停車畫面在 P 不再新鮮時回 drive。來源 ◐ GPS · 藍牙資料過期,下方展開 4 秒「P 檔資料已過期」;狀態列檔位「—」,電量還在自己的有效期內照常顯示 | R4-01(P0)、01 §2.1、§11 Q21 |
| S06-g → S06-d(新) | 只在只有 GPS 的已知停車(GPS ≤1 km/h 持續 10 秒 + S07)後手動進入;來源 ● GPS;檔位框「—」;下一行「◐ 藍牙中斷 ・ 電量最後更新 12 分鐘前」;舊值用歷史色 | R4-01、R4-03、L21、01 §2.2 |
| S02、S02-b → S05-b | S02 不畫 app 頁(直接跳系統對話框);拒絕後是 S05 上一行字 + 一顆「前往系統設定」;S05-b 的「—」下方改寫「GPS 不可用」;完整說明移到 S08 新增的「定位權限:未開啟」列(只在被拒時顯示) | R4-02(P0)、L13、01 §11 Q14 |
| 舊值(全域) | 舊電量、舊胎壓不再降透明度,改用歷史色 `#8A97AE`(5.84:1;胎壓卡上 5.69:1),電池膠囊改灰;「舊」靠自己的「最後更新 / 最後量測 N 分鐘前」表達 | L21、R4-03 |
| S07 | 說明改 L20:「GPS 車速讀值持續 10 秒低於 1 km/h。app 無法確認是否安全停車,請自行確認。」;拿掉「0 km/h · 已靜止 10 秒」徽章 | L20、R4-04 |
| S10 / S10-b(新) | 拿掉停用的前方模式列;加「狀態」和「最後驗證」說明一行;範例卡片標「示範」;S10-b 是過期版:琥珀狀態卡(L22 條件版文案)+「前往 App Store 更新」入口,沒有範例卡 | R4-05、L16、L22、01 §11 Q18 Q20 |
| S20 → S20 iOS / Android(新) | iOS 寫「領取」、從 App Store 確認領取起算;Android 寫「開始」、此安裝的本機試用,多一張試用紀錄說明卡;不寫「每帳號一次」 | L14、R4-06、01 §6.6 |
| S21、S22、S24、S08 | S21 標題「免費試用已結束」+ 說明;價格和按鈕都是「以 {價格} …」,用粉紅虛線標「從商店取得」;S24 改「免費試用至 {到期時間}」並加 iOS 領取未完成、期限無法確認兩則;S08 車輛資料列改「免費試用至 {到期時間}」 | L14、ux 12:22 第 12 項與補充 |
| S25 | 拿掉畫面上的「〔依實際資料流填寫,Q18〕」;隱私說明是另一頁,內容等 flutter 查完資料流再寫 | R4-08 |
| S09 | 沒連車提示改「目前未連接車輛,車況資料暫不顯示;提醒依開關顯示。」(01 還是舊句,見 Q27) | R4-09 |
| S04-h | 來源標示合成一行「● 車輛藍牙 · GPS 不可用」,13px 和來源字級一致 | 01 §6.1、03 Q12 |
| S03 | 說明改附近模式版「…不顯示距離,車速也不會因此變色。」;範例卡片標「示範」 | 01 §6.3、03 S03 記錄 |
| S13 | 準備清單加第 4 條「在收得到 GPS 的地方進行(地下室可能收不到)」 | L17、ux 12:22 第 11 項 |
| S18-h | 按鈕「重新檢查並繼續」+「稍後」 | 01 §11 Q16 |
| S19 / S19-c / S19-d(新) | S19 拿掉「改配對」下方小字;S19-c 是改配對確認框(只確認一次,文案照 01 §6.5);S19-d 是「配對沒有完成,繼續使用原本的車輛。」訊息 | L12、01 §11 Q17 |
| S05-c(新) | 沒有資料又沒配對時,點齒輪顯示 3 秒「到收得到 GPS 的地方停好車,再設定或配對」 | L17、01 §6.1 |
| S04-a(待完成設定)(新) | 首次開啟先進 HUD,齒輪旁實心小圓點表示還有設定沒完成;S01 不自己跳出 | 01 §4.1 第 2 步 |
| 三位數車速(全域) | 三位數時車速改 140px、字距 -6,留在量表內;字重不變(S04-b、S04-XL、S11 預覽) | L26 |
| S04-L / S06-L | 邊距改成「裝置 SafeArea + 16」,粉紅虛線是 iPhone 15 橫式示意(59 / 59 / 21);右欄寬度跟著縮 | 04 第四階段、L25 |
| S06-XL | 量表和來源標示固定,下方資料區捲動;粉紅虛線標一屏底線 | L24、04 第四階段 |
| 第一批檢查 | 受影響而重新匯出的:S04-b(三位數)、S06-b / S06-f / S06-L / S06-XL(舊值歷史色)、S08、S22、S04-L、S06-L;其他第一批畫面內容不變 | — |

### A.2 畫布、尺寸和匯出(回應 03 S10、S11)

| 項目 | 規格 |
|---|---|
| 畫布 | 390×844 邏輯 px(iPhone 14/15 尺寸);長頁 S03 / S09 / S20 Android 390×900、S06-XL 390×930、S13 390×1040、S10-b 390×1080、S11 / S22 390×1010、S24 390×1130、S10 390×1140、S08 390×1380,實機捲動;橫式 844×390,邊距用裝置 SafeArea + 16 |
| PNG | 2x(780 寬),由 HTML 匯出 |
| 最小字級 | 註記、單位、群組標題 12 px(`#8A97AE`,≥5.84:1);來源標示 13 px(`text.secondary`);設定列名 17 px |
| 車速 | 158/700,drive 和 parked 同位置(readout 框 300×300,左上 45,190) |
| 點擊區 | iOS ≥44×44 pt、Android ≥48×48 dp;稿上一律畫到 ≥48(齒輪 48、色票 48、分段選項含外框 48、文字按鈕和連結 48、主按鈕 52、設定列 ≥56) |
| 字型 | Inter + Noto Sans TC(L15)。HTML 從 Google Fonts 載入兩者,實作要隨 app 打包 Noto Sans TC |
| 匯出方法 | `docs/design/frames/export-pngs.sh [ID...]`(不帶參數 = 全部現行稿,**跳過已取代的 6 張**,舊稿 PNG 不會被覆蓋;加 `--all` 才連舊稿一起重畫)。用 macOS 的 Google Chrome headless,需要網路載入 Inter、Noto Sans TC 和 lucide 圖示 |

還沒做到的:最小支援尺寸(例如 375×667)、其他畫面的橫式、英文全套。

### A.3 還沒畫的

| 類別 | 畫面 |
|---|---|
| 畫面變體 | S04-c(藍牙 + 純車速)、S04-d(來源剛切換,展開 4 秒)、S04-g(回前景 / 冷啟動,◌ 等待車速訊號)、S05 的「搜尋 GPS」(不含 L17 閘門提示的版本)、S06-c 等待車輛(◌ 等待車輛… 在車況區)、S06-e 未解鎖(含試用結束通知列)、S10 更新失敗 / 部分點位停用、S17 讀取中、S18 a/b/d/e/f/g、S19 空狀態和「取代完成」訊息、S20 iOS 恢復原試用 / 原試用已結束、S08 toggle 關閉狀態 |
| 新頁 | 隱私說明頁(等 flutter 的實際資料流,R4-08) |
| 跨畫面 | S05 和設定類的橫式、美國版(psi、S22 美國 A)、設定類的系統大字、英文全套、最小支援尺寸 |
| 網頁 | S26、S27(L12:只畫草稿,不架站) |
| `.pen` | 新畫面同步回 `.pen`(等使用者決定)、刪除 `BwQnM` 和 `N1tDcE` |

### A.4 待改清單

第一批和第二批到這一輪為止的已知修正都已完成(§2.1c、§2.1d)。剩下的只有 §2.3 還沒畫的稿,以及 §6 的待確認問題。

---
