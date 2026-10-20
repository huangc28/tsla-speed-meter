# Flutter 實作可行性盤點

## 重點結論

- 第六輪依 L31–L39、`01-flows.md` §7.4、`02-visual.md` §7.5–§7.8 與 `05-tire-icon.md` 第二版完成：速度表置中（`300×300`／`280×280`，M），左下角 `72% / 315 km` 固定保留槽位不跳動（S）。
- 三方向新字型（A `Jost 600`、B `Exo 2 700`、C `Barlow Semi Condensed 600`）皆為 **SIL OFL 1.1** 可隨 App 打包（`115–210 KB`）、支援 `tabularFigures`，設 `fontFamilyFallback: const ['NotoSansTC', 'Inter']` 即數字用新字型、中文維持 Noto Sans TC（S）。
- 三方向新質感與工作量：**A 純黑底＋無字橫條最容易（S）**；**B 電光藍＋6px 點陣底紋（`ImageShader` 硬體平鋪零重繪）＋無模糊 41 段次之（S–M）**；**C 槍灰金屬雙漸層錶盤＋外弧雙層紅針（刪外圈數字並收進內圈後降為 S–M，仍為步驟最多）**。
- 停車胎壓車圖第二版（L34）：因 `car-glass.svg`／`car-ceramic.svg` 含 `<feGaussianBlur>`（`flutter_svg` 不支援 SVG filter），**建議直接用 `CustomPainter`（`TireCarPainter`）**；車圖包 `RepaintBoundary` 靜態快取（停車 0 重繪），上疊四象限原生 `Text`（統一底層繪製實色字底板＋動態錨定引線起點，順手根治 `02 §7.8.3` 的 T1／T2／T3），大字時切換 `24×48` 縮圖＋單欄捲動清單，UI 工作量 **S–M**。
- 胎壓圖示詳細評估見文末「第六輪(胎壓圖示)— 主持人代寫」(Claude 代 flutter,2026-10-19)。仍用 `CustomPainter`,`flutter_svg` 會把光暈畫成硬邊,四版只換調色盤。上一點有三處要修正:①「停車 0 重繪」只對 UI 執行緒成立,Impeller 約每秒仍重算模糊,成本小;② T1–T3 已由 tire 修好,Flutter 是照搬做法;③ UI 工作量改為 **M**。另外,05 的固定行框只剩約 2 pt,四象限實際只在預設字級成立,和 01 §7.4 的大字規則有落差,列待確認。
- 整體規模維持 N1／N2 L、BLE（含胎壓資料流 N4）L、附近點庫 L（S10 M）、IAP L、橫式鎖定＋鏡像刪除 S、共用 UI M；保留第一至五輪全部證據。

## 現況盤點

### 範圍、版本與證據

| 項目 | 本次基準 |
|---|---|
| 盤點日期／角色 | 2026-10-18／flutter；第六輪依 L31–L39、`01-flows.md` §7.4、`02-visual.md` §7.5–§7.8 與 `05-tire-icon.md` 第二版完成速度表置中、左下角 `/` 電量列、A／B／C 三方向字型與質感、以及停車胎壓車子圖示第二版評估；保留第一至五輪證據 |
| 主程式 | `main`，`8b4acb5c9cf8232bdb97540fd23b70a81ac0f19d`；盤點時工作目錄的 `lib/`、`test/`、`pubspec.yaml`、iOS／Android 與 main 無差異 |
| BLE | 本地遠端追蹤 ref `origin/feature/goal-2-ble`，`914b7c1b0f7150b2fc88988e37d1d4c245a834ea`；以 `git show` 核對程式與 proto，搭配 `git grep`／`git ls-tree`／`git diff` 搜尋，未 fetch、未切分支 |
| 引用 | 下文未標分支的 `path:line` 均指 main；`BLE · path:line` 均指上述 BLE commit |
| 需求優先序 | `docs/design/00-rulings.md` L1–L39 優先於 01–05；其次 brief。研究引註 `[10 §…]`、`[06 C…]`、`[09 §…]`、`[11 §…]` 指 `docs/market-research/` 的同編號報告 |
| 設計沿用 | `DESIGN.md` 的深藍與 gauge 家族；來源字樣、失效、parked 行為與 L28–L39（只做橫式、刪除鏡像、速度表置中與三方向、停車胎壓車圖）依 brief／06 Part C／裁定。`PRODUCT.md` 的 Fleet API Phase 2 描述已過時 |

### main 畫面與資料流

`main → SettingsStore.load → _Bootstrap → AppShell → HudController → GpsSource.readings()`；controller 同時更新 `SpeedProcessor`、`TripStats`、`ModeController`，再由 AppShell 選 drive／parked。沒有額外狀態管理套件，也沒有多頁路由框架。

| 區塊 | 已有實作 | 對 v1 的限制／證據 |
|---|---|---|
| 啟動與定位權限 | 載入設定後直接進 HUD；檢查定位權限，denied 時提出系統請求 | 沒有首次選擇、預覽、拒絕後說明、永久拒絕或定位服務關閉的獨立畫面；權限請求沒有阻擋 HUD 建立。`lib/main.dart:9`、`lib/main.dart:49`、`lib/main.dart:58` |
| DriveScreen | 大字速度、單位、GPS 色點＋文字、設定齒輪；無 fix 時顯示 `– –`，隱藏 active arc／marker | 沒有觸發區、BLE 狀態列、點位速限或琥珀條件。`lib/src/ui/drive_screen.dart:34`、`lib/src/ui/drive_screen.dart:104` |
| ParkedScreen | 靜止 gauge、本趟距離／均速／最高速、手機時間、GPS chip、設定入口 | 速度硬寫 `0`，來源 chip 永遠顯示綠色 GPS；沒有讀值有效性、檔位、電量、續航、胎壓。`lib/src/ui/parked_screen.dart:106`、`lib/src/ui/parked_screen.dart:137`、`lib/src/ui/parked_screen.dart:205` |
| 時間與行程 | 時間是 build 時呼叫 `TimeOfDay.now()`；TripStats 以速度乘樣本時間差累計，平均值為距離／首末樣本經過時間 | 未顯示日期、行程耗時，沒有獨立時鐘 timer、持久化或畫面上的重設入口。controller 有 `resetTrip()`；跨斷訊時間差可能算進距離，來源切換時需檢查。`lib/src/ui/parked_screen.dart:186`、`lib/src/trip/trip_stats.dart:13`、`lib/src/trip/trip_stats.dart:21`、`lib/src/ui/hud_controller.dart:55` |
| 設定頁 | 以 Navigator push；單一 ListView，修改即通知並保存 | 任何模式都能開啟，沒有行駛操作限制。`lib/src/ui/app_shell.dart:61`、`lib/src/settings/settings_panel.dart:31` |
| 開發畫面 | screenshots entry 使用樣本值展示 drive／parked／waiting／settings 與 parked 橫式 | 不是正式 onboarding 或產品預覽；不能把樣本資料當即時資料。`lib/screenshots_main.dart:1`、`lib/screenshots_main.dart:37` |

### drive／parked 與 GPS 有效性

| 狀態／判定 | 現在怎麼做 | v1 必須補的行為 |
|---|---|---|
| 初始版面 | `ModeController` 預設 parked，與是否有定位無關。`lib/src/trip/mode_controller.dart:6` | GPS 初始／等待定位維持速度 HUD 的未知狀態，不先顯示固定 0 的 parked。[10 §parked 畫面建議] |
| 自動切版面 | 平滑速度 ≥2 m/s 切 drive，≤0.5 m/s 切 parked，中間保留原模式。`lib/src/trip/mode_controller.dart:18` | GPS 零速不自動切 parked；只有新鮮有效 BLE P 作自動切版條件。版面與允許操作必須分開判定。[06 C09] |
| 正常 GPS | geolocator 用 `bestForNavigation`；轉成速度、精度、經緯度、timestamp。`lib/src/data/gps_source.dart:19` | 不把設定精度當成每次讀值的品質保證，沒有固定更新率保證 |
| 速度處理 | 預設 EMA 係數 0.3，≤0.5 m/s 歸零；沒有 speed 時嘗試位置差／時間差。`lib/src/speed/speed_processor.dart:11`、`lib/src/speed/speed_processor.dart:36` | smoothing 與 gauge 動畫都會增加顯示延後；缺值、無法推算、真實零速需分開。不能讓無資料也變有效 0 |
| 低品質 GPS | 精度 >50 m 丟棄樣本，回傳上次速度；`hasValue` 只代表曾有可接受值。`lib/src/speed/speed_processor.dart:24`、`lib/src/speed/speed_processor.dart:33` | 曾定位成功後，差樣本仍可讓 HUD 保持 `hasFix=true`，甚至繼續累計行程。需有效期與樣本品質判定。[10 §drive 畫面建議] |
| Stream error | controller 設 `hasFix=false`，保留速度及版面。`lib/src/ui/hud_controller.dart:50` | drive 會顯示 placeholder；parked 不接收 hasFix，因此仍顯示 0／綠色 GPS。需所有版面共用失效狀態 |
| 無更新／stream 結束 | controller 沒有獨立時效 timer，也沒有 onDone 處理。`lib/src/ui/hud_controller.dart:39` | 即使沒有下一筆事件，也必須讓舊值到期；兩來源皆無有效速度時顯示 `—`，不凍結、不補 0 |

### DataSource 接口

- main 的 `DataSource` 只有 `Stream<Reading> readings()`，訂閱取消為停止契約。`lib/src/data/data_source.dart:5`。
- main 的 `Reading` 只有 nullable 速度、精度、經緯度及一個必要 timestamp。沒有來源 ID、連線狀態、資料品質或各欄位有效期。`lib/src/data/reading.dart:3`。
- `HudController` 只暴露非 nullable 速度、hasFix、版面與行程統計；目前「有 fix」無法表達 BLE 連線、速度已過期、電量仍可用等組合。`lib/src/ui/hud_controller.dart:29`。
- BLE 分支擴充 `Gear`、`batteryPercent`、`rangeMiles`、`powerKw`，但仍只有一個 timestamp。沒有 `TeslaBleSource implements DataSource`，也沒有 composite source。`BLE · lib/src/data/reading.dart:1`；分支 `lib/` 清單與 `lib/src/data/data_source.dart:5`。
- 建議沿用 stream 接口，補充來源／有效性與每組欄位時間資訊；速度採有效 BLE 優先、有效 GPS 備援，其他車況只來自有效 BLE。GPS 持續供測速定位，不能因速度改用 BLE 就停止 GPS。第二階段的建議責任見下方 N1／N4 與 5 題答覆，本次不改碼。[10 §drive 畫面建議]、[09 §BLE 輪詢頻率與限制]

### 設定項與實際生效程度

| 設定 | 預設與保存 | HUD 是否生效 |
|---|---|---|
| 單位 | km/h，可選 mph | drive 有轉換；parked 雖收 unit，仍硬寫 km、km/h。`lib/src/ui/drive_screen.dart:39`、`lib/src/ui/parked_screen.dart:124`、`lib/src/ui/parked_screen.dart:137` |
| 鏡像（L29 刪除） | 現況預設關；依 L29 刪除 | 現況 AppShell 對 drive／parked 整頁套 `Transform.flip(flipX: true)`（`lib/src/ui/app_shell.dart:87-89`）；依 L29 刪除 `Settings.mirror`、設定頁開關、Transform 與測試，舊 JSON 忽略 `mirror` 鍵（詳第五輪） |
| 日夜亮度 | auto／day／night，預設 auto | 只有 night 疊 28% 黑色 IgnorePointer；auto 與 day 同效果。沒有環境／時間自動判斷，也沒有改系統螢幕亮度。`lib/src/ui/app_shell.dart:90` |
| 行駛自動極簡 | 預設開 | 有控制項與保存，但 AppShell／ModeController 沒有讀取此設定，切版仍依速度。`lib/src/settings/settings_panel.dart:81`、`lib/src/ui/app_shell.dart:72` |
| 螢幕恆亮 | 預設開 | 使用 wakelock；store 更新時套用。`lib/src/ui/app_shell.dart:44`、`lib/src/ui/app_shell.dart:56` |
| 強調色 | cyan／amber／indigo，預設 cyan | 設定頁有勾選，gauge／HUD 色碼仍固定。`lib/src/settings/settings_panel.dart:178`、`lib/src/ui/gauge_arc.dart:42` |
| v1 新設定 | 尚無 | 純車速／車速＋車況、獨立測速開關與台灣預設、電量／續航選擇、藍牙裝置管理皆待補 |

設定模型及 defaults 在 `lib/src/settings/settings.dart:11`；`SettingsStore.update()` 先通知再保存，SharedPreferences 以一個 JSON blob 保存。`lib/src/settings/settings_store.dart:30`、`lib/src/settings/shared_prefs_settings_storage.dart:7`。增加設定可沿用此模式，不應把付費權益或手機私鑰當一般 UI 偏好保存。

### 橫式、鏡像（L29 已刪）與 gauge

| 項目 | 現況與可沿用部分 | L28／L29 後的變更與限制 |
|---|---|---|
| drive 橫式 | 現況同一個 SafeArea／Stack，固定 246×246 gauge 置中，無分欄。`lib/src/ui/drive_screen.dart:43`、`lib/src/ui/drive_screen.dart:58` | 依 L25／L28 改為唯一橫式版面：左欄固定量表（純車速也不置中），右欄上半觸發區、下半狀態列；`test/drive_screen_test.dart:62-77` 的置中斷言須改驗左置 |
| parked 橫式 | LayoutBuilder 判寬高；直式上下疊、橫式左 gauge＋右 280 寬統計／時鐘。`lib/src/ui/parked_screen.dart:40`、`lib/src/ui/parked_screen.dart:83` | 依 L28 刪 `lib/src/ui/parked_screen.dart:42`、`:58`、`:68-81` 直式分支，只留橫式左 gauge＋右可捲摘要（L24），右欄改彈性寬度並支援 `667×375` 最小尺寸與四輪胎壓 |
| gauge 幾何 | 起點 215°、sweep −250°、max 240；drive／parked 共用。`lib/src/ui/gauge_geometry.dart:3` | drive／parked 左欄量表同位置同大小；三位數依 L26 縮字距／字級（140 px／-6）留在量表內 |
| gauge 繪圖 | CustomPainter 畫軌道、cyan active arc、0／60／120／180／240 短刻度、crimson marker；fraction／geometry／active 改變才 repaint。`lib/src/ui/gauge_arc.dart:50`、`lib/src/ui/gauge_arc.dart:108` | 沒有速限 marker、超速變色或狀態語意；可延伸現有 painter，第一階段未做效能實測 |
| 動畫 | drive 用 250 ms easeOutQuart；disableAnimations 時零時長。`lib/src/ui/drive_screen.dart:35`、`lib/src/ui/drive_screen.dart:62` | 只動畫 arc，數字直接更新。高頻 BLE 接入後再驗刷新、資料年齡與動態減弱；左右橫式翻轉時不重播動畫 |
| 方向支援 | 現況 iOS 宣告直式與左右橫式；Android 接受 orientation／screenSize 變更，Dart 未鎖向。`ios/Runner/Info.plist:56-68`、`android/app/src/main/AndroidManifest.xml:14` | 依 L28 全 app 鎖定左右橫式：Flutter `setPreferredOrientations`、iOS `Info.plist` 兩陣列移除直式、Android 設 `sensorLandscape`；左右取對稱最大 SafeArea 防翻轉跳動（詳第五輪） |
| 字型／雙語 | 深藍 tokens 分散在畫面常數，無共用 Theme token 類；未宣告 Inter 字型資產或本地化委派。`lib/main.dart:23`、`pubspec.yaml:56` | 現有主要文案為繁中；新增英文需抽出字串，長文案橫式限每行約 36 全形字／70 英文字元。這次不改 DESIGN.md 或 token |

### BLE 分支做到哪裡

| 層級 | 已有程式 | 尚未完成／不能據此聲稱的能力 |
|---|---|---|
| 找車／配對入口 | spike 輸入 17 碼 VIN，推導廣播名稱，掃描、連線、找 GATT service、訂閱 notification。`BLE · lib/src/ui/spike_screen.dart:51`、`BLE · lib/src/ble/ble_transport.dart:28` | 是開發工具，沒有正式配對導引、已登記車輛清單或自動重連狀態機；連上 GATT 不代表金鑰已登記或車況有效 |
| 分段傳輸 | 2-byte 長度前綴、通知重組、MTU 分段送出。`BLE · lib/src/ble/ble_transport.dart:77`、`BLE · lib/src/ble/ble_transport.dart:96` | 目前送出用 `withoutResponse: true`；需依 [09 §介面存在、程式接通、資料夠新] 的協定查核再驗 write 模式。掃描逾時缺少 finally 清理、沒有 connectionState 訂閱，不足以驅動正式連線 UI |
| 手機金鑰 | 產生 P-256 key，SharedPreferences 保存私鑰；重啟沿用。`BLE · lib/src/ble/tesla_key_store.dart:23` | 單一全域 key，沒有正式安全儲存、車輛登記／移除管理；client 會 log session key，spike 可匯出 log，正式版須改。`BLE · lib/src/ble/tesla_ble_client.dart:79`、`BLE · lib/src/ui/spike_screen.dart:92` |
| 金鑰登記 | 送 VCSEC whitelist request，role 為 DRIVER，log 提醒感應卡片。`BLE · lib/src/ble/tesla_ble_client.dart:82` | 送出即返回，未實作卡片確認成功／拒絕／逾時的登記結果；不能做成「已送出＝配對成功」。keyFormFactor 目前寫 IOS_DEVICE，Android 行為待驗 |
| Session／請求加密 | SessionInfo 等候 10 秒；ECDH 派生 session key；組 AES-GCM metadata、簽章及 GetVehicleData。`BLE · lib/src/ble/tesla_ble_client.dart:49`、`BLE · lib/src/ble/tesla_ble_client.dart:104` | client 只有一組 session 欄位，登記 VCSEC 後須再取得 infotainment session；clockTime 是取得當下值，正式版需處理經過時間、過期與重建 |
| 回應解密 | 通用 `TeslaGcm.decrypt()` 已有，單元測試涵蓋 round-trip 與壞 tag。`BLE · lib/src/ble/tesla_gcm.dart:35`、`BLE · test/ble/tesla_gcm_test.dart:31` | **client 的 AES-GCM response 分支只 log nonce／counter／tag／ciphertext，未呼叫 decrypt，也未驗 response metadata。** `BLE · lib/src/ble/tesla_ble_client.dart:181` |
| 解析與輸出 | unsigned/plain 分支可嘗試 parse Response 並呼叫 mapper。`BLE · lib/src/ble/tesla_ble_client.dart:197` | 結果只進 log；`readVehicleData()` 永遠回 null，沒有 Reading stream／callback 或請求回應關聯。timestamp 是 parse 時 `DateTime.now()`，不代表車端量測時間。`BLE · lib/src/ble/tesla_ble_client.dart:147`、`BLE · lib/src/ble/tesla_ble_client.dart:201` |
| 輪詢 | spike 可發 20 次 drive＋charge 查詢，間隔 100 ms。`BLE · lib/src/ui/spike_screen.dart:75` | 這是發送頻率，沒有等有效資料返回；不能稱 10 Hz。沒有正式 DriveState 優先／慢欄位降頻排程、背景停止與不喚醒策略。[09 §BLE 輪詢頻率與限制] |
| HUD 串接 | 分支 Reading 加車況欄位；正式 `main.dart`、AppShell、HudController、DataSource 與 main 無差異 | 正式入口仍只有 GpsSource；無 BLE-primary／GPS fallback，所有 BLE 車況都未進畫面。`lib/main.dart:58`、`lib/src/ui/app_shell.dart:73` |

### mapper 欄位對照

下表都是「已寫映射，未證實實車可持續讀值」，不是已交付功能。mapper 的純資料測試在 `BLE · test/ble/tesla_reading_mapper_test.dart:10`。

| 資料 | mapper 行為 | 後續驗收 |
|---|---|---|
| 速度 D01 | 優先 speedFloat，否則 speed；mph ×0.44704 轉 m/s，兩者缺省為 null。`BLE · lib/src/ble/tesla_reading_mapper.dart:27` | 新鮮度、取整、來源切換、車型／韌體 |
| 檔位 D04 | P／R／N／D；缺省或 invalid 為 Gear.unknown。`BLE · lib/src/ble/tesla_reading_mapper.dart:33` | 舊 P 不觸發切版或解鎖；R 不代表倒車安全資訊 |
| 電量 D09 | 只有 batteryLevel，缺值 null。`BLE · lib/src/ble/tesla_reading_mapper.dart:20` | SOC 定義、與 usableBatteryLevel／車內顯示差異；有效期獨立於速度 |
| 續航 D10 | batteryRange，保留 miles。`BLE · lib/src/ble/tesla_reading_mapper.dart:22` | 顯示單位轉換與續航模型標示，不保證可達距離 |
| 功率 D11 | DriveState.power → nullable int kW。`BLE · lib/src/ble/tesla_reading_mapper.dart:18` | v1 延後，不因已有 mapper 就排入首發 |
| 胎壓 D15 | **未映射、未請求、Reading 無欄位**；只有四輪值與 last-seen schema | `BLE · protocol/protobuf/vehicle.proto:649`、`BLE · protocol/protobuf/car_server.proto:93`；需各輪最後量測時間、缺值／過期狀態、單位及排程。[06 C03] |
| 其他 | 充電狀態、導航摘要、溫度、門窗等均未映射 | 本輪 brief 已延後，不據 schema 存在擴充首發承諾。[09 §可行性總表] |

方向燈、盲點、AP/FSD、下一轉彎不做新資料管線。本次依 repo 研究快照採「本版本不提供」說明，不重新聲稱所有技術路徑皆不可能。[11 §結論與信心]、[06 C02]

### 既有驗證與本次驗證界線

- 已閱讀現有測試。main 涵蓋 GPS mapping、速度處理、模式遲滯、行程、設定保存、鏡像、gauge 幾何、waiting、橫式與減少動態；沒有實車或購買整合測試。
- 舊測試明確要求低速切 parked 與差定位保留車速，未來依 v1 修正時需同步改驗收，不能為維持綠燈而保留舊行為。`test/hud_controller_test.dart:38`、`test/speed_processor_test.dart:60`。
- 設定頁「44pt」測試只量 accent-cyan，不代表每個控制項都已達標；segmented 子項 minHeight 36。`test/settings_panel_test.dart:71`、`lib/src/settings/settings_panel.dart:124`。
- BLE 測試集中在純協定／密碼／mapper；沒有 transport／client 端到端測試，不能用通用 GCM 測試代替實車回應解密驗收。
- 第一、二階段為靜態查核；第三、四階段逐張看共 40 張 PNG、讀 HTML／CSS／SVG，補查 Apple、Google、Flutter 及點庫官方文件。未執行 Flutter test／analyze、裝置操作、配對或效能測試，不宣稱測試通過或車輛已可連線。沒有改程式碼或切換分支。

## S01–S27 畫面／狀態可行性表

ID 與名稱依 `01-flows.md §2`；第五輪依 L29 刪除 S11 鏡像預覽，加計第二階段新增的 S28 後共 **27 個畫面**（S01–S10、S12–S28），表內保留 S11 編號供對照。已有＝正式 app 已完成該項；部分＝有可沿用的正式畫面或 spike 元件；全新＝沒有產品實作。這 27 項沒有整項可標「已有」，但 S04 車速、S06 行程、S08 設定基礎等子項已接進 app。

工作量含整合與驗證：S＝局部畫面；M＝跨 model／controller／UI；L＝協定、交易或資料管線加裝置驗證。不是天數，各列共享依賴，不可相加。第五輪含 L15 字型、雙語、對稱 SafeArea、L28 全橫式版面與 L19 大字橫式；全域操作閘門 N2 另為 L，共用於所有非 HUD 頁，僅保留 L13 最小例外。`新增` 是建議責任範圍，檔名尚未存在，本次沒有建立它們。

### 共用新增模組

| 代號 | 建議檔案／責任 | 依據與界線 |
|---|---|---|
| N1 | `lib/src/data/source_coordinator.dart`、`lib/src/data/freshness_policy.dart`；來源仲裁、每欄時間／有效性、到期事件 | 改 `lib/src/data/reading.dart:3`、`lib/src/ui/hud_controller.dart:39`；沿用 DataSource stream，不讓 widget 自行判時效 |
| N2 | `lib/src/ui/operation_gate.dart`；進入、移動中止、回前景重新確認 | 改 `lib/src/ui/app_shell.dart:61`；版面與可操作狀態分開 |
| N3 | `lib/src/onboarding/`、`lib/src/ui/layout_preview.dart`；首次進度、共用示意卡、權限畫面、雙語字串 | 改 `lib/main.dart:49`、`lib/src/settings/settings.dart:11`；與 S09 共用卡片 |
| N4 | `lib/src/vehicle/`、`lib/src/data/tesla_ble_source.dart`；單車配對狀態機、登記、取消、實際狀態續接與重連 | 整合 BLE 分支，不能直接把 `spike_screen.dart` 當正式流程 |
| N5 | `lib/src/cameras/`、`assets/cameras/`；點庫 manifest／loader／索引、台灣位置資格及附近提醒；發布檢核與驗證紀錄 | 最終交付 L，頁面另 M；L16 過期整卡隱藏，無驗證／期限不啟用。L8 v1 無距離／琥珀；前方另 L 延後 |
| N6 | `lib/src/purchases/`；商品、平台端驗證、權益、平台各自的試用／計時、app 級交易 listener | L11 無自家後端；商店結果不能隨 route dispose 遺失 |
| N7 | `lib/src/ui/about_screen.dart`、本地化與聲明資源 | 隱私依下文 Q18 的實際資料流，不能複製未實現的宣稱 |
| N8 | S26／S27 產品外頁面草稿 | L12 只畫稿，不架站、不接事件／email、不收資料；沒有 Flutter route 或網頁服務開發工作 |

### 逐項評估

| ID／畫面 | 現況 | 要動的既有檔案／新增模組 | 量 | 可行性、風險與驗收 |
|---|---|---|---|---|
| S01 首次選行車畫面 | 全新 | `lib/main.dart:49`、`lib/src/settings/settings.dart:11`；N2／N3 | M | L6 已知停車才選版面；橫式兩張預覽卡左右並排、底部固定按鈕避開手勢區。偏好／進度分存；示範卡不訂閱真來源；配對完成不自動領試用 |
| S02 定位權限 | 部分，只有系統權限請求 | `lib/main.dart:49`、`lib/src/data/gps_source.dart:27`；N2／N3 | M | 首次直接系統定位框；拒絕且未配對時依 L13 在 S05 右欄觸發區放一行＋一顆 OS 設定按鈕，不能開長文內頁。權限／服務狀態分開、返回重查，成功打開設定不等於已授權。L9 拒定位不抹除有效 BLE 車速 |
| S03 台灣測速說明 | 全新 | `lib/src/settings/settings.dart:11`、`pubspec.yaml:56`；N3／N5 | S，依賴 N5 L | L12 有效手機定位在台灣才出現，非 locale／商店國家。長文案單欄限寬捲動、右下固定按鈕；附近點位參考無距離／琥珀；示意卡明標示範 |
| S04 drive，a–i（含 e2） | 部分，大字車速／gauge／GPS 已有 | `lib/src/ui/drive_screen.dart:34`、`lib/src/ui/gauge_arc.dart:50`、`lib/src/ui/gauge_geometry.dart:3`、`lib/src/ui/hud_controller.dart:60`；N1／N5／N6 | L；純視覺 M | L25／L28 橫式左邊量表固定不動，右欄上半觸發區、下半狀態列；L7 冷啟動一筆、備援恢復兩筆、空窗 —；h 拒定位保留 BLE，i 舊 P 回 drive。L16 到期整卡隱藏，L18 ▲ 在量表內數字上方；L26 三位數縮字距／字級 |
| S05 無有效車速 | 部分，只有 no-fix 外觀 | `lib/src/ui/drive_screen.dart:39`、`lib/src/ui/hud_controller.dart:50`、`lib/src/speed/speed_processor.dart:33`；N1／N2 | M | 單一 `—`＋失效原因，立即隱藏 active arc／紅標記／測速提示；靜默也到期。visual S06-h 改對照此態。L13 只准右欄觸發區最小 OS 設定入口；L17 無 GPS 且未配對不能開設定／配對 |
| S06 parked，a–f | 部分，行程／時鐘／橫式已有 | `lib/src/ui/parked_screen.dart:83`、`lib/src/trip/mode_controller.dart:6`、`lib/src/trip/trip_stats.dart:21`、`lib/src/ui/hud_controller.dart:60`；N1／N2／N4／N6；BLE mapper | L，含條件式胎壓；排版 M | L28 刪直式分支（`:68-81`），左 gauge 與 drive 同位同大小，右欄可捲動（L24），來源標示與失效文字置右欄頂部。新鮮 P 自動只開摘要，操作另過 N2；速度來源、電量／胎壓時間分開，舊 P 不留 |
| S07 停車確認 | 全新 | `lib/src/ui/app_shell.dart:61`；N2 | M；共用閘門 L | L28 改為右半邊對話框（寬 ≤460 pt、高 ≤80%），露出左邊量表與來源標示。L6 兩筆不同依序 fresh P，或 GPS-only ≤1 km/h 持續 10 秒＋主動確認；移動立即關操作、不自動重開 |
| S08 設定 | 部分，清單與偏好已有 | `lib/src/settings/settings_panel.dart:63`、`lib/src/settings/settings.dart:11`、`lib/src/settings/settings_store.dart:30`、`lib/src/ui/app_shell.dart:87`；N2／N4／N6 | M | L28 改兩欄（左群組、右內容），窄手機退單欄；L29 刪 `mirror` 與鏡像列、刪 `autoMinimal`、補版面／車況／單車。測速列按手機定位在台灣顯示；舊 amber 偏好須明確遷移 |
| S09 行車畫面設定 | 全新，共用卡片可重用 | `lib/src/settings/settings_panel.dart:63`、`lib/src/settings/settings.dart:11`；N3 | S，依賴 S01／N2 | 與 S01 共用橫式示意卡；單欄頁時寬度上限約 600 pt；即時套用加偏好保存，不以 autoMinimal 的舊布林值推定新選擇 |
| S10 測速提醒設定 | 全新 | `lib/src/settings/settings_panel.dart:63`、`lib/src/settings/settings.dart:11`、`pubspec.yaml:56`；N5 | 頁面 M，含 N5 發布驗證為 L | v1 建議內建點庫，列版本／來源／實際最後驗證日／有效性與更新方式；L16 過期整卡隱藏，已知錯誤點停用。依 01 §11 不畫前方停用列；單欄寬上限約 600 pt |
| S11 鏡像預覽（已刪除） | **已刪除（L29）** | `lib/src/ui/app_shell.dart:87-89`、`lib/src/settings/settings.dart:13,21,29,37,47,60`、`lib/src/settings/settings_panel.dart:78-79`、`test/app_shell_test.dart:23-62` | —（原 M 刪除，清理 S） | 依 L29 拿掉鏡像：刪除 S11 預覽頁、S08 鏡像開關、`AppShell` 的 `Transform.flip(flipX: true)` 與 3 個鏡像測試；舊設定 JSON 忽略 `mirror` 鍵，不再做玻璃反射驗收（詳第五輪） |
| S12 本版本不提供 | 全新 | `lib/src/settings/settings_panel.dart:85`；N7 | S | 橫式長文案單欄（每行 ≤36 全形字／70 英文字元）可捲動，右下固定按鈕；S01／S22 共用；沿用 C02 本版能力範圍 |
| S13 配對前說明／權限 | 全新，spike 沒有產品說明頁 | `BLE · lib/src/ble/tesla_ble_client.dart:82`、`BLE · ios/Runner/Info.plist:71`、`BLE · android/app/src/main/AndroidManifest.xml:4`；N2／N4 | M | 橫式兩欄（左步驟與插圖、右文字與按鈕）。文案必須匹配實際 key role；monitor 協定可行但尚未實車；不默默升回 DRIVER |
| S14 輸入 VIN | 部分，spike 只有長度檢查 | `BLE · lib/src/ui/spike_screen.dart:51`、`BLE · lib/src/ble/ble_constants.dart:22`；N4 VIN 表單／登記資料 | M | 橫式鍵盤開啟時收斂為步驟、一行 17 碼 VIN＋`12/17`、錯誤與「下一步」，插圖／說明收成連結；停用 Android 全螢幕輸入；移動立即收鍵盤回 HUD（詳第五輪） |
| S15 尋找並連線 | 部分，有 transport | `BLE · lib/src/ble/ble_transport.dart:28`、`BLE · lib/src/ble/tesla_ble_client.dart:41`；N4 | L，含 transport 整理 | 橫式兩欄；掃描 timeout 與等候 timeout 分別 20／22 秒；連線 20 秒、session 10 秒是各步而非整段 SLA。取消／離頁／移動需清理 scan、訂閱及遲到結果 |
| S16 感應鑰匙卡 | 部分，只有送出 whitelist 請求 | `BLE · lib/src/ble/tesla_ble_client.dart:84`、`BLE · protocol/protobuf/vcsec.proto:202`；N4 | L；靜態插圖 S | 橫式左欄鑰匙卡插圖、右欄說明與按鈕。WAIT／OK／ERROR 需 parse，不以送出當成功。L10 中斷後查登記狀態，已加 key 不再感應 |
| S17 讀取驗證／完成 | 部分，mapper 有、client 未接通 | `BLE · lib/src/ble/tesla_ble_client.dart:104`、`BLE · lib/src/ble/tesla_ble_client.dart:181`、`BLE · lib/src/ble/tesla_reading_mapper.dart:10`；N4／N1 | L，先決阻擋 | 橫式三格讀值（車速、檔位、電量）橫排。完成 response metadata／驗證解密、有效欄位與來源時間後才成功；驗證連線不代表已領試用 |
| S18 配對失敗，a–h | 全新，spike 只有 raw log | `BLE · lib/src/ble/tesla_ble_client.dart:161`、`BLE · lib/src/ble/ble_transport.dart:43`；N4 錯誤對映 | M，依賴 S15–S17 | 橫式兩欄；按協定／權限證據分類，不猜車睡著。L10 移動中止用指定暫停文案；續接查 key、車上登記與 session，不固定重走卡片步驟 |
| S19 車輛管理 | 全新 | `BLE · lib/src/ble/tesla_key_store.dart:23`、`BLE · lib/src/ble/tesla_ble_client.dart:214`；N4 | M，原多車 L 降級 | 單欄寬上限約 600 pt，改配對／移除確認用置中 460 pt 對話框。L12 僅一台；新配對成功並保存後取代舊登記，失敗保留舊車 |
| S20 試用開始 | 全新 | `pubspec.yaml:30`、`lib/main.dart:23`；N6 | iOS L／Android M；共享 N6 為 L | 橫式兩欄（左標題與已交付清單、右價格／條款捲動與底部固定按鈕）。L14 已定案：iOS 零價非消耗型原始交易起算；Android 此安裝本機起算 |
| S21 試用結束 | 全新 | `lib/src/ui/hud_controller.dart:60`、`lib/src/ui/app_shell.dart:73`；N6／N2 | M，依賴 S20 | 橫式兩欄；L29「仍免費」拿掉鏡像模式。無永久權益時，試用到期即撤車輛 live 值／停付費輪詢，僅有效 GPS 接手，否則 — |
| S22 解鎖 | 全新 | `pubspec.yaml:30`、`lib/src/settings/settings_panel.dart:85`；N6／N7 | L，含購買整合 | 橫式兩欄，右欄價格與主要按鈕／恢復購買固定底部不捲出畫面，長付費文案於右欄內限寬捲動。頁面價格取商店商品結果 |
| S23 支持開發者 | 全新 | `pubspec.yaml:30`、`lib/src/settings/settings_panel.dart:85`；N6 | M，共用 S22 服務 | 橫式兩欄；美國 B 僅顯示支持者 badge，可用一次性非消耗型以便恢復；不因未付款封 BLE、不主動彈出 |
| S24 購買結果 | 全新 | `lib/main.dart:23`、`lib/src/ui/app_shell.dart:61`；N6 | M，依賴交易驗證 | 橫式置中卡片（寬 ≤460 pt、高 ≤80%）。app 級 listener 驗證、冪等交付、完成交易；pending 不解鎖。回呼先保存結果再重查閘門 |
| S25 關於與聲明 | 全新 | `lib/src/settings/settings_panel.dart:85`；N7／N5 metadata | S | 單欄寬上限約 600 pt、長文限寬可捲動；加字型授權、點庫版本／驗證日期。Q18 明列商店處理交易，無自家後端 |
| S26 美國方案 A／B 網頁 | 全新，產品外 | N8；不新增 Flutter route 或服務 | S，原部署／追蹤 M 移出 | L12 只畫兩組可比文案和意向 CTA，照一般響應式網頁，不實際分流、埋追蹤、導流或付款 |
| S27 確認與告知網頁 | 全新，產品外 | N8；不新增 Flutter route 或服務 | S，原收集／儲存 M 移出 | L12 只畫確認與告知狀態；表單是示意，不送 email、不記事件；不估網站、資料庫與刪除管道實作 |

### 審查期間新增的 S28

01 第二階段新增安裝提醒 S28，仍屬靜態說明，另補評估，不更改原 S01–S27 ID（刪 S11 後共 27 個畫面）。

| ID／畫面 | 現況 | 要動的既有檔案／新增模組 | 量 | 可行性、風險與驗收 |
|---|---|---|---|---|
| S28 安裝提醒 | 全新 | `lib/main.dart:49`、`lib/src/settings/settings_panel.dart:85`；N3／N7 | S | 橫式單欄寬上限約 600 pt、長文每行 ≤36 全形字可捲動，右下固定主要按鈕；首次完成狀態獨立保存；只在操作閘門後閱讀 |

### 第二階段問題依最終裁定的處理

| 編號／影響畫面 | 採用規則 | 判定 |
|---|---|---|
| R1／全部非 HUD、S06／S07 | L6 兩筆合格 P，或 GPS 靜止 10 秒＋確認；移動／矛盾優先，未知無繞過。兩筆 P 可開操作，不要求額外 S07；刪 <10 手動 parked 與退出等到 10 的舊建議 | 已裁定；N2 共用 L |
| R2／S04–S06 | L9 BLE／GPS 權限分開、速度來源／SOC／TPMS 時間分開；新鮮 P 才顯示。補四種來源與欄位組合稿 | 已裁定；N1 |
| R3／來源切換／時間 | L7 一筆冷啟動、恢復兩筆、空窗 —；只有接收時間不啟用可信速度／P 操作／琥珀。固定 3 次／30 秒移除 | 已裁定；時間語意仍需實車 |
| R4／S03、S04-e/f、S10 | L8 v1 附近模式無距離／琥珀；重下載不能重設最後驗證日；L16 過期整卡不出現。前方另等道路匹配與有效期實地驗證 | 最終 N5 含發布驗證 L；前方另 L 延後 |
| R5／S20–S24 | L11／L14 平台分開、無後端；iOS 商店原始交易／Android 此安裝本機試用，不加帳號服務 | 機制已裁定；Q19 已補，sandbox 尚未驗證 |
| R6／S15–S19 | L10 查車上登記狀態續接，不一律再感應；睡眠只在有協定證據時命名 | 已裁定；N4 |
| R7／S03、S08、S10、S19、S26／27 | L12 手機有效定位在台灣才顯測速、單車、網頁僅草稿。L8 內部 km/h，顯示隨單位換算、切單位重算並重設 dwell | 已裁定；台灣邊界／定位有效期由 UX 補規則 |

## UX 留言板 5 題答覆

### 1. Q2：ROLE_VEHICLE_MONITOR 可否讀 GetVehicleData？

**協定層可以，這個 app 尚未實車證明。** `git show` 確認分支 enum 已有 monitor＝5、driver＝3；PermissionChange 接受 Keys.Role，client 目前硬寫 DRIVER。`BLE · protocol/protobuf/keys.proto:7`、`BLE · protocol/protobuf/vcsec.proto:104`、`BLE · lib/src/ble/tesla_ble_client.dart:89`。單憑 enum 不能推定權限，所以補查官方固定版本文件。

Tesla 官方 `protocol.md §Roles` 明列 Vehicle Monitor 可讀車況、不能授權改變車輛狀態；官方 `state.go GetState()` 將讀取分類組成 GetVehicleData。據此建議先改用 monitor，實車驗證 drive／charge／胎壓的實際權限與支援，不必預先要求 DRIVER。[官方 Roles](https://github.com/teslamotors/vehicle-command/blob/a4b43c1eff0e09d77deb9f2dce97031141fe8c8a/pkg/protocol/protocol.md#roles)、[官方 GetState](https://github.com/teslamotors/vehicle-command/blob/a4b43c1eff0e09d77deb9f2dce97031141fe8c8a/pkg/vehicle/state.go)，2026-10-18 查閱。

- 先完成現有回應解密與驗證，再比較角色；不能把目前解密缺口誤判為 monitor 權限不足。登記後讀 whitelist 結果／角色，取得 infotainment session，驗有效 drive／charge 與錯誤碼；不要發動車輛控制來測試「只讀」。
- 不靜默降級 DRIVER。若支援範圍內 monitor 確有不相容，停在 S18 說明；若產品決定提供 DRIVER fallback，須另行明確說明並由車主重新確認。
- 只有實際登記並驗證 monitor 後，S13 才用 monitor 文案。現在分支仍用 01 的 DRIVER 版。登記金鑰本身會改變車上鑰匙清單，不應說「配對全程完全唯讀／零風險」。[06 C10]

| S13 情境 | 繁中建議文案 | English |
|---|---|---|
| 實際 monitor，驗證通過後 | 新增一把權限為「車輛監看」的金鑰，用來讀取車輛資料，不授權車輛控制。你可在車上的鑰匙清單移除。 | Adds a key with Vehicle Monitor access to read vehicle data. It does not authorize vehicle controls. You can remove it from the car's key list. |
| 現有 DRIVER | 沿用 01 §6.5 的「駕駛」權限說明，不能標為只讀金鑰；「app 只用它讀資料」與「金鑰只能讀」分開 | Keep the Driver-access wording in 01 §6.5. Saying the app only reads data does not make the key read-only. |

### 2. A1：DriveState 2 秒、ChargeState 60 秒是否合理？

**可作開發起測上限，不能當已證實安全門檻。** 1–2 Hz 的 DriveState 以 2 秒判 stale 可容少數延遲，但不代表可以把 P95 ≤1 秒目標放寬成 2 秒；ChargeState 每 5–15 秒查詢，以 60 秒到期可作慢變數起點，drive 可能顯示近一分鐘舊電量，需實車核對並視結果收緊。[09 §BLE 輪詢頻率與限制]、[10 §待驗證問題]

| 項目 | 實作判定與風險 |
|---|---|
| 分欄時間 | DriveState 有 timestamp；ChargeState 也有 timestamp＝44，須驗存在性與語意後保留；胎壓另有每輪 last-seen。不能把新的 drive 回應刷新 charge cache。`BLE · protocol/protobuf/vehicle.proto:178`、`BLE · protocol/protobuf/vehicle.proto:359`、`BLE · protocol/protobuf/vehicle.proto:656` |
| 來源時間與接收時間 | 保存 source timestamp、request ID、送出／收到的單調時間；先驗車端／手機時鐘偏差。TTL 依已驗來源年齡加接收後經過時間，收到舊快取不續命。timestamp 缺失、時鐘無法核對時標未知／降低能力，不能以 `DateTime.now()` 冒充量測。現有問題在 `BLE · lib/src/ble/tesla_ble_client.dart:201` |
| 邊界 | 依 01，age ≤2 秒／≤60 秒才有效，超過即到期；負 age、非有限速度、缺 speed、gear unknown／invalid 分別處理。gear unknown 不推 P；只有 charge 來包不能延長速度有效期 |
| 靜默到期 | coordinator 排到最近的 expiry deadline，即使 stream 沒有下一筆也發失效事件；到期即撤數字／gear／琥珀，回前景先判年齡再畫。monotonic timer 與 source clock 各司其職，不用系統改時鐘延長 TTL |
| GPS 與測速 | GPS 2 秒／≤50 m 只能起測；負速度、NaN、無法推算也無效。測速 ≤20 m／≥15 km/h 不保證道路歸屬，還需航向信心及 C06 條件；停用定位時立即撤測速 |
| parked cache | 舊電量／續航可以只在 S06 顯示最後值＋時間；不能將此 cache 再送進 live 仲裁。胎壓「最後量測」另看每輪，不由 60 秒 ChargeState 門檻代判正常 |

需重播驗證 1.999／2.000／2.001 秒與 59.999／60／60.001 秒、無更新、舊包重送、亂序、缺欄、前背景切換／改系統時間，以及真實資料年齡 P50／P95／最大值。這是後續驗收項，本階段未跑裝置測試。

### 3. BLE 有效優先＋切回 2 筆如何實作？

**同意取代 freshest。** main／BLE 分支都尚無 composite，因此可在 N1 集中實作，UI 不各自訂閱兩來源。保留 GPS 供測速與 GPS 行程。現有單一 `_processor` 不能跨來源混算 EMA 或位置差。`lib/src/ui/hud_controller.dart:19`、`lib/src/ui/hud_controller.dart:60`、`lib/src/speed/speed_processor.dart:28`。

1. 每個來源維持自己的最新合格速度與期限，gear／charge 是獨立欄位；BLE 還需合法解密驗證、回應關聯、授權可用。沒有 speed 的 DriveState 不計恢復筆數，但有效 P 可獨立計切版筆數。
2. 正在用 BLE 時，只要 BLE 速度有效便保留它，GPS 更新較新也不搶來源。BLE 過期／斷線／權益停用立刻切有效 GPS，否則輸出 S05；不為等重連保留舊車速。
3. GPS 備援後恢復 BLE，要 2 筆不同請求、合格且依序到達的速度樣本，兩筆之間不可跨過 2 秒失效空窗；重送／重播／cache 不計數。來源 timestamp 不得倒退，若只有秒精度，不能要求每包 timestamp 嚴格遞增，須再用已驗證的請求關聯辨識新回應。GPS 事件不影響 BLE 計數；壞包、缺 speed、斷線或到期清零。
4. 冷啟動無有效 GPS 時，依 L7 由第一筆合格 BLE 進入；**曾進入 GPS 備援後**，若 GPS 在第二筆 BLE 前失效，先顯示 `—`，第二筆到才切回。這是 L7 明定的空窗，不能用 NoSpeed 路徑繞過兩筆規則。
5. 切換時數字立即採新來源、重設跨來源 smoother；arc 補間不能延長 sample 期限。4 秒來源說明是另一個 UI timer，任何時候失效仍立即顯示原因；持續同來源更新不重啟這 4 秒。減少動態時不補間。
6. 依 L7 刪除固定「60 秒失效 3 次／冷卻 30 秒」機制與例外。先實作有效性與兩筆恢復，是否需額外防抖由實車數據決定。
7. P 的 2 筆去抖與速度的 2 筆恢復是兩個計數器；unknown gear、非 P、gear 到期清 P 計數，第一筆有效非 P 立即退 drive。用新鮮 P 切 S06 摘要；N2 兩筆 P 閘門仍先檢查 L6 移動／矛盾優先條件。[06 C09]

最小重播序列應證明：GPS 比 BLE 更新不切、BLE 到期立即 GPS、只回一筆不切、第二筆切、壞包重計、GPS 在兩筆之間過期輸出 `—`、charge-only 不計數、重複回應不計數、換車／回前景清候選，以及行程不因雙來源或 expiry timer 重複累計。

### 4. Settings.autoMinimal 能否刪除？

**可以，建議刪除；不需要依舊值改變使用者新選擇。** 對 main／BLE ref 的 `git grep autoMinimal` 只命中 Settings 的建構、欄位、copyWith、toMap／fromMap，以及設定頁 toggle；AppShell／ModeController 沒讀它。證據為 `lib/src/settings/settings.dart:14`、`lib/src/settings/settings.dart:45`、`lib/src/settings/settings.dart:56`、`lib/src/settings/settings_panel.dart:81`。

- 移除上述成員／序列化鍵與 toggle，新增有明確語意的版面 enum；版面只控制 drive 的內容，P 的切版策略固定由 mode controller 管。
- 舊 JSON 留有 autoMinimal 時忽略它，其他 unit／mirror／brightness／keepAwake／accent 必須保留；下一次寫入新版 map 自然移除該鍵。不清空整個 SharedPreferences、不改 `settings` 儲存鍵。`lib/src/settings/shared_prefs_settings_storage.dart:9`。
- 舊 true／false 都不能可靠表示「純車速」或「車速＋車況」，採 01 A5 的預設，或下次安全停車時選擇。後續加有舊鍵 true／false／缺鍵的保存回歸案例。`test/settings_store_test.dart:25`、`test/settings_store_test.dart:37`。

### 5. Q18：隱私資料流

以下是 `git show` 的程式事實與字串／依賴搜尋結果，沒有做封包側錄或第三方原生 SDK 全面稽核。「未見自動上傳」限目前 repo，不能擴張為 OS／備份／商店均不處理資料。

| 資料／入口 | 現有流向、保存與外送 | 證據／對 S02、S25 的影響 |
|---|---|---|
| 手機定位、速度 | geolocator → Reading → controller／processor／TripStats；位置與行程暫存記憶體，未寫定位歷史檔、未見 app 自動上傳 | `lib/src/data/gps_source.dart:19`、`lib/src/ui/hud_controller.dart:60`、`lib/src/trip/trip_stats.dart:3`。目前沒有完整路線紀錄或 GPS 雲端服務程式 |
| 顯示偏好 | SharedPreferences 的 `settings` JSON，留在 app 儲存區 | `lib/src/settings/shared_prefs_settings_storage.dart:7`。這不是資料絕不進 OS 備份的證明 |
| 完整 VIN | main 無 VIN 功能；spike 的輸入框／client 記憶體使用，現未獨立持久化 VIN。VIN 在本機用來算目標廣播名稱與簽章 metadata；client 未把完整 VIN 當獨立欄位直接送車／網路，VIN 參與驗證不等於直接送出字串。完整 VIN 會進 log，分享可外送 | `BLE · lib/src/ui/spike_screen.dart:51`、`BLE · lib/src/ble/ble_constants.dart:22`、`BLE · lib/src/ble/ble_transport.dart:30`、`BLE · lib/src/ble/tesla_ble_client.dart:119`。S19 重連會新增本機 VIN registry，不能說不保存 VIN |
| 長期手機私鑰／公鑰 | 私鑰 hex 現存 SharedPreferences；從本機派生公鑰，用公鑰登記／handshake。沒有看到直接傳送長期私鑰的呼叫 | `BLE · lib/src/ble/tesla_key_store.dart:23`、`BLE · lib/src/ble/tesla_ble_client.dart:56`、`BLE · lib/src/ble/tesla_ble_client.dart:87`。正式版需遷安全儲存、定每車生命週期／備份排除；不能說已用 Keychain |
| Session key、車況、車端回應 | session key 原在記憶體，但 client 會寫入 log；原始 TX／RX、明文回應及解析車速／gear／SOC／range 也記錄。DriveState 請求可能連帶取得路線摘要，不等於 app 只接收三個數值 | `BLE · lib/src/ble/tesla_ble_client.dart:79`、`BLE · lib/src/ble/tesla_ble_client.dart:187`、`BLE · lib/src/ble/tesla_ble_client.dart:206`、`BLE · lib/src/ble/ble_transport.dart:78`、`BLE · protocol/protobuf/vehicle.proto:184` |
| Spike log 匯出 | 記憶體 log → temporary directory 的 txt → 系統分享選單；外送由使用者選分享目標。未見自動寄送，但可含 VIN／session key／原始車況，亦未見匯出檔清理 | `BLE · lib/src/ui/spike_screen.dart:28`、`BLE · lib/src/ui/spike_screen.dart:92`。開發匯出不是正式產品功能；正式版刪敏感 log，不把這份匯出併入「絕不離機」 |
| 分析／錯誤回報 | 目前 lib、pubspec 未見 Firebase／Sentry／analytics／自家 HTTP telemetry 或自動 crash upload。錯誤在 controller 處理或 spike log | `pubspec.yaml:30`、`BLE · pubspec.yaml:30`、`lib/src/ui/hud_controller.dart:50`。Android debug／profile 的 INTERNET 宣告供 Flutter 工具，不能據權限存在就判有業務上傳 |
| v1 商店、點庫、研究稿 | 尚未實作。IAP 透過 Apple／Google；試用與驗證不加自家後端。建議點庫隨 app 更新，位置比對在手機；S26／S27 按 L12 僅畫稿、不收事件或 email | 商店仍是交易資料處理者，不能說所有資料都不離機。若以後加點庫下載，另告知下載來源，但不需上送 GPS／VIN |

正式版建議採「不由 app 自動上傳定位／VIN／金鑰」、手機端安全儲存 key、無敏感 log；這是待實作及驗證的目標。OS 定位服務、使用者備份與系統診斷不在這個靜態結論裡。正式 key 儲存／backup 設定完成後再定刪除／重裝文案，車上的公鑰不會因 app 移除自動撤銷。

| 適用情境 | 繁中草案 | English draft |
|---|---|---|
| S02 定位用途 | 本 app 用手機定位計算 GPS 車速與行程；在台灣也用來提供測速提醒。 | This app uses your phone's location for GPS speed and trip calculations and, in Taiwan, speed camera alerts. |
| S25 目前正式 main 的靜態查核範圍 | 目前版本的定位與行程計算在手機上進行；app 未設分析或錯誤回報自動上傳。 | In the current version, location and trip calculations run on your phone. The app has no automatic analytics or error-report uploads. |
| S25 未來 v1，實作符合後才採用 | app 不會自動把定位、VIN 或金鑰傳給我們。購買由 App Store／Google Play 處理；測速點位資料隨 app 版本更新。 | The app does not automatically send your location, VIN, or keys to us. Purchases are handled by the App Store or Google Play. Camera data is updated with app releases. |

若保留診斷分享，須另有分享前預覽、去識別與清理行為，不能直接沿用 spike。L11 v1 不新增後端試用／收據驗證；以後變更資料流再修隱私說明。[06 C10]

## 第三階段：第一批畫面實作審查

### 審查範圍與判定

已查看第一批全部 14 張 PNG：S01、S04-a／b／e／f、S04-f 英文／鏡像、S05、S06-a／b、S08、S12、S16、S22；並查 HTML 的 CSS、SVG、畫面函式與匯出腳本。一般 PNG 是 780×1688，S08 是 780×2220，S22 是 780×2020；對應 2 倍匯出的 390×844／1110／1010 設計座標，不是 Flutter logical pixel 的硬性畫布。

本節保留第三階段第一批 14 張的逐張基準；當時正在追加的第二批 26 張，已在下方第四階段逐張補審。兩輪都只看圖與原始碼，沒有量到裝置幀率、耗電或玻璃反射可讀性。

| 畫面／項目 | 難度與實作方式 | 必須處理的差異／要動檔案 |
|---|---|---|
| S04-a／b、S05、S06-b gauge | M。延伸現有 CustomPainter，軌道、active 弧、cyan 端點與紅色內標記均為少量向量；數字與單位保留 Text。無需 gauge 套件或整張 HUD 點陣圖 | 現有 246 方框、線寬 5、有短刻度；稿為 300 方框、中心線半徑 146.25、線寬 7.5、外半徑 150，無短刻度。HTML 註解「外徑 150」應為外半徑。改 `lib/src/ui/gauge_arc.dart:50`、`lib/src/ui/gauge_geometry.dart:3`，並共用 drive／parked 的 readout |
| gauge 角度 | M，屬幾何校正，不是效能問題。HTML 用 `y = CY - r*sin(a)`，Canvas 正角向畫面下方 | 原 main 的 215°／−250° 直接送 Canvas 會開口朝上，與 PNG 開口朝下不同。換成 Canvas 起點 −215°，等價 145°，sweep +250°；marker 也用同一轉換。不能只改 arc 而忘掉端點／紅標記。依 `lib/src/ui/gauge_arc.dart:55`、`:89` 與 [Canvas.drawArc](https://api.flutter.dev/flutter/dart-ui/Canvas/drawArc.html)，2026-10-18 查閱 |
| S04-e／f、英文、鏡像 | 卡片外觀 S，點位／道路資格另算 N5。Row、邊框、圖示、條件文字即可，無特殊 shader | L8 第一批距離／琥珀是條件啟用稿，不能預設交付。HTML 已加前方模式標記與 S04-n；v1 接附近卡、限速附顯示單位，無距離／琥珀。內部 km/h 比較；單位或來源切換須重算，不拿畫面取整後數字比較 |
| S05、S06-a | S05 外觀 S；失效管線 M。無值時單一 `—`，撤 active、端點、紅標記及測速卡 | S06-a 的「地下室無資料過 S07 進 parked」違反 L6，不能照其說明做入口；應留最小 HUD。歷史摘要與可操作入口分離，無值不插入假 0。改 `lib/src/ui/drive_screen.dart:39`、`lib/src/ui/parked_screen.dart:106`、N1／N2 |
| S06-b 行程／車況／四輪胎壓 | 排版 M，TPMS 資料驗證 L。Row／Grid／時間標籤足夠，不需畫車輛輪廓 | 每輪缺值／量測時間各自處理，SOC 不隨速度刷新；P 過期撤除。畫面來源一直取目前速度來源。小螢幕與大字不能依 top 612 固定塞四輪；改 `lib/src/ui/parked_screen.dart:40`、`:137`、`:186` 及 N1／N4 |
| S01 選版面 | M。共用靜態示意 widget，卡片整塊可點，選中狀態帶語意 | 模擬值標示範；92×164 預覽不用再建 controller。L6 先取得有效停車證據再進 S01。下方兩按鈕需 SafeArea，短螢幕本文可捲。稿的「連接後免費試用」改成下文主動開始機制；N3、`lib/main.dart:49` |
| S08 設定 | M。ListView、標準 switch／segmented／導航列可做，無自訂繪圖需求 | 1110 高是長頁示意，實機不是拉高螢幕。車況三選項、英文與放大文字改上下列或獨立選項頁。30 大小色點要擴點擊範圍，補選取語意；iOS 至少 44、Android 至少 48 logical pixels。`lib/src/settings/settings_panel.dart:63`、`:124` |
| S12 說明、S22 解鎖 | 說明 S；S22 純排版 M、交易 L。可捲正文＋底部 SafeArea 操作列，文字不是圖片 | HTML `.pg` 絕對定位於固定高度、靠 spacer 推按鈕，並未實作原生的捲動／固定底列。需防英文／大字／鍵盤遮住正文與恢復入口；價格取商店 ProductDetails，不寫死 NT$290。N6／N7 |
| S16 卡片示意 | 插圖 S，流程 L。靜態 SVG 可轉 Flutter Path／CustomPainter，或以本地 SVG 資產加 flutter_svg；未必需要新依賴 | 中控台、卡片、幾條感應線不需 Lottie／連續大動畫。等待用標準 progress，支援減少動態。不能靠動畫判登記成功；L10 依實際登記狀態續接，已加 key 不再感應。N4、`BLE · lib/src/ble/tesla_ble_client.dart:82` |

### 02 Q4：中文字型答覆

L15 已定案打包 Noto Sans TC，搭配 Inter，兩平台共用字型檔與 weight 對應。`fontFamily: Inter`、`fontFamilyFallback: [NotoSansTC]` 是可行的 Flutter 路徑；中文 glyph 由後者提供。第三階段 HTML 僅透過 Google Fonts 載入 Inter；第四階段已補載 Noto Sans TC 並重匯出，但網頁載字不等於 Flutter 已打包資產，也不證明 Android 系統 fallback 相同。[Flutter TextStyle fallback](https://api.flutter.dev/flutter/painting/TextStyle-class.html)、[自訂字型資產](https://docs.flutter.dev/cookbook/design/fonts)，2026-10-18 查閱。

- 建議 `DESIGN.md` 日後改為「Latin／numerals: bundled Inter；繁中: bundled Noto Sans TC；system fallback 僅補未涵蓋 glyph」，不要寫「Android 預設一定是 Noto Sans TC」。本次不改 DESIGN.md。
- 對應稿用到的 400／500／600／700，保留字型授權；只包繁中字型所需版本，避免整套多語 CJK／所有字重。先量實際 APK／IPA 增量及首屏載入，再決定靜態檔或可變字型，不先報不存在的 MB／fps 數字。HUD 離線可用，不在執行時向 Google Fonts 取字。
- Noto Sans TC 與這批 macOS PNG 的 PingFang 字寬／基線會不同，visual 需用選定字型重新匯出。關鍵驗收字串是「車輛藍牙」「車速暫不可用」「點位資料速限」、最後量測時間與雙語長句；卡片允許內容增高，不靠縮小必要提示解決。
- 車速可用 `FontFeature.tabularFigures()` 固定數字寬度，但須核所選 Inter 檔的 tnum 效果。以 0／88／112／240／`—`、km/h／mph 驗定位；等寬數字可能讓第一批 112 比例改變，不能直接宣稱像素相同。[Flutter tnum](https://api.flutter.dev/flutter/dart-ui/FontFeature/FontFeature.tabularFigures.html)，2026-10-18 查閱。
- 字體設定放 Theme／共用 text styles，N3 字串走 l10n；來源圓／半圓／三角用繪圖或圖示，不依賴 Unicode 圖形字的 fallback。TextScaler 與系統文字放大保留，本文／設定容許換行；大字 HUD 依可用空間調整幾何，不全 app 關閉文字縮放。

字型與共用文字樣式為 M，與 S01／S04／S08 共用，不對每畫面重複加算；建議責任為 `pubspec.yaml:56`、`assets/fonts/`、`lib/main.dart:23` 與共用 UI 樣式。尚未加入字型資產。

### 鏡像（L29 已刪）、橫式版面（L28 唯一方向）與效能

| 項目 | 建議實作／估工 | 後續驗收界線 |
|---|---|---|
| 鏡像（已刪） | **已刪除（L29），清理 S**（原估 M 與反射驗證移出）。刪除 `lib/src/ui/app_shell.dart:87-89` 的 `Transform.flip(flipX: true)`、`lib/src/settings/settings.dart:13,21,29,37,47,60`、`lib/src/settings/settings_panel.dart:78-79` 與 `test/app_shell_test.dart:30-62`；S11 鏡像預覽刪除 | 舊 JSON 保留 `mirror` 鍵時於 `Settings.fromMap` 忽略，下次保存移除；`test/settings_store_test.dart:29,34,50` 改用其他設定欄位測保存與通知。不再需要玻璃反射實機驗收 |
| Drive 橫式 | M（L28 唯一方向）。對稱水平安全區 `max(padding.left, padding.right)` 後以 `LayoutBuilder`／`Row` 排版：左欄固定量表（`L25`，純車速也不置中），右欄上半觸發區、下半狀態列；卡片出入不搬動車速 | 最小基準 `667×375 pt`（如 `frames/landscape/S04-b-min-667x375.png`）與 `844×390`；左右翻轉 180° 時量表與文字不跳動；`lib/src/ui/drive_screen.dart:43` 現有置中 Stack 改左置 Row |
| Parked 橫式 | M（L28 唯一方向）。刪 `lib/src/ui/parked_screen.dart:68-81` 直式分支，沿用 `:83` 左 gauge（與 drive 同位置同大小）＋右欄彈性寬度與獨立 `SingleChildScrollView`（L24），來源標示與失效文字置右欄頂部 | 移除現有固定右欄寬 `280`（`:91`）與直式判斷（`:42,58`）；不要整頁等比縮小。左右橫式翻轉不重設 trip／pairing／trial；最小 `667×375` 與大字捲動（`S06-XL-large-text-scroll.png`）不裁切 |
| 操作頁橫式 | M，共用橫式頁殼。S08 兩欄（窄手機退單欄）；單欄表單頁寬上限 600 pt；長文案每行 ≤36 全形字／70 英文字元、右下固定按鈕；配對／購買兩欄；確認框改 460 pt Dialog；S14 鍵盤開啟時收斂為精簡可捲版面 | 依 `01-flows.md` §7.2 與 `frames/landscape/` 橫式稿實作；長頁與 1.0／1.3／2.0 文字縮放不溢出，底部按鈕避開手勢條；S14 停用 Android 全螢幕輸入並於偵測移動時立即收鍵盤（詳第五輪） |
| 重繪／動畫 | M 內含於 HUD；畫弧用 CustomPainter，數字與狀態用局部 listenable 更新。shouldRepaint 比較真正輸入；必要時以 RepaintBoundary 隔離動態 gauge，不預先把每塊卡片分層 | 既有 250 ms 只補間 arc。來源切換立即換數字；失效／回前景未知立即撤舊值，禁止 fade-out 留舊車速。減少動態與橫式翻轉時都不做動畫；不要把資料 timer 接到每幀動畫。[CustomPainter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)，2026-10-18 查閱 |
| 點庫／BLE／耗電 | 資料管線 L。點庫預處理與索引在載入時完成，必要時 isolate，不能每次 build 全掃。GPS／BLE 各一份訂閱，charge／TPMS 降頻；背景停止不必要輪詢，恢復先判 stale | 漸層／少量向量未見必須用重 shader 的理由，但不能由 PNG 宣稱效能合格。用代表性 iPhone／Android profile 量 UI／raster frame time、記憶體、持續 HUD 溫度／耗電；60 Hz 以每幀 16.7 ms、120 Hz 8.3 ms 作檢查預算，這不是已測結果 |

第一批直式稿已由第五輪 L28 標為「已取代」（新稿於 `frames/landscape/`）；先決阻擋仍是 L6／L7 的資料與路由狀態。第二批及橫式規則的檢查見下節與第五輪。

## 第三階段：L11 無後端試用機制

以下機制已由 L14 定案，尚未建立商店商品或跑 sandbox。採 01 的 7 天，即連續 168 小時；不加「安裝後 14 天」領取期限。試用只供需要付費的市場方案；美國 B 若資料全免費，就沒有車況試用到期鎖定。永久買斷商品與試用記錄分開，免費 GPS 始終可用。

### 平台機制與能力界線

| 項目 | iOS | Android |
|---|---|---|
| v1 實際方案 | 在 App Store Connect 建獨立、零價 Non-Consumable IAP，名稱依 Apple「7-day Trial」規則；買斷是另一個非消耗型商品。關閉試用商品的 Family Sharing | app 本機提供 7 天功能試用；開始時寫入安全儲存的 trialStartedAt／trialEndsAt／lastSeenAt／schemaVersion。試用沒有 Google Play 訂單，買斷才走非消耗型 INAPP |
| 何時開始 | S17 讀值驗證通過、N2 允許操作、使用者按領取；收到並驗證試用商品原始交易後，以該商品 originalPurchaseDate 起算，不能用按鈕時間或 restore 時間 | 同樣 S17 通過＋N2＋主動按開始；原子保存起訖時間成功才開車況試用。寫入失敗不假裝開始；重複按／重連／換配對車不重設 |
| 驗證方式 | iOS 15+ 用 StoreKit 2，僅接受 verified、正確 bundle／product、未撤銷的交易。保留 originalID／originalPurchaseDate，重啟查 currentEntitlements／updates，試用依 app 的 endsAt 判過期，不能因非消耗型仍持有就永久開功能 | 本機狀態機與安全儲存；沒有商店可驗證的試用資格。app 存活期間用單調時間計時，跨重啟用保存的 UTC 截止日及最大已見時間檢查倒退；不使用每天扣一天的 timer |
| 恢復／換裝置 | 透過同 Apple 商店帳號恢復原試用交易，只恢復剩餘期間，不送新 7 天。無交易／驗證失敗／無法連商店且無可信 cache 時，先不授試用，提供停車後重試；不阻擋 GPS | 同一次安裝有紀錄可續剩餘期間；清資料、重裝或換手機無法可靠恢復／辨認曾用，亦無法保證再次領取一定被拒。不能寫「每台一次」或「每商店帳號一次」 |
| 商店本身的限次 | 非消耗型同商品原有持有／恢復機制可避免普通重複領取，配合原始交易時間才不重算。這不是跨 Apple／Google 的身份服務，也不宣稱防換帳號／防竄改 | Play 的已購商品可綁商店帳號，但本機試用不是已購商品。obfuscatedAccountId 是 app 提供的識別，不能拿來取得 Google 帳號或判過去試用 |
| 離線／時鐘 | 已驗交易可留本機 cache；期限仍須校驗本機時間，商店簽章提供原始起點，不提供永遠可信的離線現在時間 | 可離線開始與續用；加密儲存與倒退偵測只能降低一般重設風險，不能防重裝、root、修改 app 或離線改時鐘 |
| 到期與購買 | 不自動轉買斷、不扣款；期限到只撤試用權益，保留已購買斷權益與車上已登記 key | 同左；本機試用不呼叫 BillingFlow，也不要求訂閱／付款資料。買斷可由 Play 恢復，與本機試用能否恢復分開 |

Apple 明文允許非訂閱 app 以 Tier 0 非消耗型做限時免費試用，開始前須說明期間、結束失去的功能與完整使用的費用。[Apple §3.1.1](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase)。StoreKit 提供自動交易驗證與原始交易日期；以上起算／恢復策略是依這些 API 設計的 app 邏輯。[VerificationResult](https://developer.apple.com/documentation/storekit/verificationresult)、[originalPurchaseDate](https://developer.apple.com/documentation/storekit/transaction/originalpurchasedate)、[currentEntitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements?changes=_7)，均於 2026-10-18 查閱。

Google 的非消耗型一次購買、訂閱 trial、限量 promo code 是不同機制。v1 採本機試用，沒有找到能直接套用此「非訂閱、所有人 7 天、按帳號限一次」需求的商店試用保證；這是對官方可用機制的判讀，不把 Google 所有優惠方案一概說成不存在。不要為取得試用限次把買斷改成自動續訂，也不把有限 promo codes 當一般領取服務。[一次性商品](https://developer.android.com/google/play/billing/one-time-products)、[訂閱試用](https://developer.android.com/google/play/billing/subscriptions)、[Promo codes](https://developer.android.com/google/play/billing/promo)，2026-10-18 查閱。

### Flutter／平台整合與必驗情境

- N6 以 app 級 purchase listener 收交易，平台 adapter 給驗證後的產品、原始起點、撤銷及權益；`in_app_purchase` 泛用 purchased／restored 狀態或 JSON decode 本身不等於完成驗證。StoreKit 2 wrapper 可讀交易 JSON，但沒有一個通用「試用還剩幾天」API；必要時加小型 Swift bridge，直接交付 verified 的 originalPurchaseDate／revocation 狀態。[Flutter IAP](https://pub.dev/packages/in_app_purchase)、[SK2Transaction](https://pub.dev/documentation/in_app_purchase_storekit/latest/store_kit_2_wrappers/SK2Transaction-class.html)，2026-10-18 查閱。
- 現有 iOS 最低版本是 13.0，`ios/Runner.xcodeproj/project.pbxproj:462`。StoreKit 2 自 iOS 15 才有；估工 L 包含 iOS 13／14 的 StoreKit 1 路徑與本機 app receipt 簽章／bundle／裝置驗證，讀試用商品原始購買時間，缺收據時停車後 refresh／restore。不能默默提高最低版本或把解析 receipt 當驗章；若產品日後明確限 iOS 15+，才能省掉這條相容路徑。[Apple API 選擇](https://developer.apple.com/documentation/storekit/choosing-a-storekit-api-for-in-app-purchases)、[裝置端收據驗證](https://developer.apple.com/documentation/appstorereceipts/validating-receipts-on-the-device)，2026-10-18 查閱。
- iOS S20 需先取得試用商品及買斷商品資訊，確認試用價格為零，才能領取並如實揭露後續價格；查不到不拿 NT$290 樣稿冒充可用價格。Android 本機試用可離線開始；若未取得商品價格，改用下表離線文案，購買入口等商店商品可用才啟用。
- Android 買斷以 Play 查詢已購、PURCHASED 狀態及原始購買資料／簽章做本機驗證，核 package／product 並以 token 冪等交付；不 consume 永久商品。交付後 completePurchase／acknowledge，pending 不交付。Google 建議後端驗證較可靠，但文件也有 client-only acknowledge 路徑；本次不加後端、服務帳戶私鑰或 Server API。[Purchase API](https://developer.android.com/reference/com/android/billingclient/api/Purchase)、[購買處理](https://developer.android.com/google/play/billing/integrate)、[驗證風險界線](https://developer.android.com/google/play/billing/security)，2026-10-18 查閱。
- 兩平台都在啟動／回前景刷新商店權益，處理取消、pending、退款／撤銷與未完成交易；無後端不能保證離線時立即知道退款。已付費者的暫時查詢失敗不可當明確撤銷；須保留已驗 cache 與待重查狀態。完成／acknowledge 不等使用者看完 S24，Android 要在商店要求的 3 天內完成。
- 試用時間異常／倒退無法確認時，先暫停試用權益，保留起點且不再發新期；停車後說明如何校正時間並重查，不能顯示成確定「已用完」。安全儲存寫入與 Android backup／restore 行為需驗，不能把存進 secure storage 當成防重裝證明。
- 商店框是 OS 控制，app 偵測移動時能關閉自家操作頁，不能保證強制收掉系統付款框。開始前過 N2；回呼仍保存／完成交易，重新檢查 L6 後才顯示結果，不能自動重開操作頁。iOS 交易可能在背景或移動中完成，7 天依商店起點計算，不宣稱回到 app 才起算。
- 必驗：iOS 首領／取消／pending 後核准／未驗證交易／原始日期恢復／重裝／同帳號第二台／iOS 13、14、15+；Android 本機重啟／重複按／保存失敗／清資料與重裝限制；共同驗到期跨背景、改時間、永久買斷優先、移動中回呼、試用結束不撤車上 key。這些尚未執行。

### 供 UX 使用的雙語文案

`{price}` 取商店當下格式化價格，`{endsAt}` 顯示使用者時區的完整截止日期／時間；不要只顯「剩 0 天」卻仍有效。下列非 HUD 字句全部受 N2 限制。

| 畫面／情境 | 繁中草案 | English draft |
|---|---|---|
| S01 共通短句 | 成功連接車輛後，可選擇開始 7 天免費試用。 | After connecting your car, you can choose to start a 7-day free trial. |
| S20 iOS 領取 | 領取 7 天免費試用。透過 App Store 確認領取後起算，不會自動扣款。試用結束後，車輛藍牙車速、檔位、電量與續航需以 {price} 一次解鎖；GPS 車速仍免費。 | Claim a 7-day free trial. It starts when the App Store confirms your claim. You won't be charged automatically. After the trial, Bluetooth vehicle speed, gear, battery and range require a one-time purchase of {price}. GPS speed remains free. |
| S20 Android 開始 | 在此安裝中開始 7 天免費試用，不會自動扣款。試用結束後，車輛藍牙車速、檔位、電量與續航需以 {price} 一次解鎖；GPS 車速仍免費。 | Start a 7-day free trial in this installation. You won't be charged automatically. After the trial, Bluetooth vehicle speed, gear, battery and range require a one-time purchase of {price}. GPS speed remains free. |
| Android 離線，尚無商品價格 | 在此安裝中開始 7 天免費試用，不會自動扣款。試用結束後，車輛藍牙資料需另行一次購買，價格以 Google Play 顯示為準；GPS 車速仍免費。 | Start a 7-day free trial in this installation. You won't be charged automatically. After the trial, Bluetooth vehicle data requires a separate one-time purchase at the price shown in Google Play. GPS speed remains free. |
| Android 試用說明 | 試用紀錄保存在此手機的 app 中。清除資料、重新安裝或換手機後，無法保證恢復剩餘期間。恢復購買只適用已購買的解鎖功能。 | Trial records are stored in the app on this phone. Remaining trial time may not be recoverable after clearing app data, reinstalling, or changing phones. Restore purchases applies to a purchased unlock. |
| iOS 恢復既有試用 | 已恢復原試用，截止時間為 {endsAt}。恢復不會重新開始 7 天。 | Your original trial has been restored. It ends at {endsAt}. Restoring does not start a new 7-day trial. |
| S08／S24 有效中 | 免費試用至 {endsAt}。不會自動扣款。 | Free trial ends at {endsAt}. You won't be charged automatically. |
| S21 到期 | 免費試用已結束。GPS 車速仍免費；你可以選擇一次付費解鎖車輛資料。 | Your free trial has ended. GPS speed remains free. You can choose a one-time purchase to unlock vehicle data. |
| 時間／紀錄未能確認 | 暫時無法確認試用期限，車輛資料試用已暫停。請安全停車後確認手機日期與時間，再重試。GPS 車速仍免費。 | We can't confirm your trial period right now, so the vehicle data trial is paused. Once safely parked, check your phone's date and time and try again. GPS speed remains free. |
| iOS 領取未完成 | 尚未完成 App Store 試用領取。請安全停車後重試或恢復購買。 | Your App Store trial claim is incomplete. Once safely parked, try again or restore purchases. |

UX 可在 iOS 的詳細資格說明提「恢復同一 Apple 商店帳號的原試用紀錄」，但 v1 不需要泛稱「每個商店帳號限一次」。Android 刪除「已使用過此商店帳號試用」變體；只在本機有確定到期紀錄時顯示已結束，未知不可偽裝成已用過。上述付費功能清單仍以實車已交付項目為準，不預先列胎壓。

## 第四階段：第二批 26 張 PNG 最終審查

### 範圍、畫面 ID 與共用成本

逐張查看 02 §2「第二批」列出的 26 張 PNG，並核對 `frames/stage2-mockups.html` 的畫面函式／樣本值；12:27 又核新字型重匯出的 26 張，另補看 L19 四稿。一般圖為 780×1688；S03／S09 為 780×1800、S13 為 780×2000、S11 為 780×2020、S10 為 780×2260，第二批皆為直式 2x 匯出（第五輪 L28 後直式稿標為「已取代」，橫式新稿移至 `frames/landscape/`）。下表保留第四階段 PNG 的 visual 標籤供找圖；產品狀態以 **01 的 ID** 為準，不新增一套 S06-g/h/i 路由。下列「必改」對應這 26 張交付圖，不把並行新增的另一個變體自動視為已替換原圖。

「外觀」量是新增 UI；「整合」量包含主表的共用模組，不能將 26 列相加。各列要動檔案見 S01–S27 主表與 N1–N7；本批沒有需要新 shader、複雜動畫引擎或整頁 Canvas 的畫面。

本輪結稿核對的 HTML SHA-256 為 `060d821fd0b8fed02321bc74b426b913088b5b1489543f0f91a48f7f2acefdf4`。並行後續改稿不自動視為本表問題已關閉；本次文件驗證確認 S01–S27 與第二批 26 張無漏項，211 處程式引用的路徑／行號以 `git show` 查核，未執行 app。

| PNG／visual 標籤 | 01 對照／外觀量；整合量 | 實作方式、依賴與必改處 |
|---|---|---|
| `S04-h-ble-location-denied.png` | S04-h；S／N1 L | 沿用 HUD，加第二行 GPS 不可用；仍顯有效 BLE 速度、車況，撤測速卡。`drive_screen`＋N1；不能強制跳 S05／權限長頁 |
| `S06-g-parked-gps-old-battery.png` | S06-d；M／N1、N2 L | 共用 parked。有效 GPS 速度可顯 0，舊電量／胎壓各標時間；只准重新符合 GPS 靜止＋S07 後手動查看，不能從過期 P 自動續留。檔位 `—` 配實際藍牙狀態，依 01 §11 Q21 |
| `S06-h-parked-no-source.png` | **S05**；S／N1、N2 L | 原圖保留整套 parked 歷史摘要不合 L6；兩來源皆無有效資料回最小 HUD，`—`＋原因，不提供 S07 或歷史摘要操作退路。不是再做一張失效 parked |
| `S06-i-parked-p-stale.png` | **S04-i**；S／N1 L | P 到期退出自動 parked，GPS 若有效繼續顯 GPS 速度；來源說明展開「P 檔資料已過期」。ChargeState 若仍有效可留狀態列，不能被新 drive 包續期；不把舊 gear 留在 drive |
| `S04-n-camera-nearby.png` | S04-e；S／N5 L | 兩行卡共用元件，保留「點位資料速限」與依設定換算的單位；無距離／琥珀。L16 過期整卡撤掉，不能留下第一行。英文／大字允許重排，不用縮字擠進固定高度 |
| `S02-location-permission.png` | S02；S／M | 首次無資料依 01 直接請求 OS 定位框；PNG 的完整 app 說明頁不能當 L6 例外。`lib/main.dart:49`＋N3；授權返回重查，不自動跳首次設定 |
| `S02-b-location-denied.png` | S02 拒絕態，呈於 S05；S／M | 照 L13 改成一行＋一顆「前往系統設定」，移除標題、長文與「先略過」的完整頁殼。只開 OS；完整說明移 S08。有效 BLE 不受影響 |
| `S03-camera-alerts-intro.png` | S03；S／N5 L | 可捲正文、switch 與靜態示範卡；只介紹附近模式。N3 共用預覽、N5 真實資格；範例明標示範，不能以樣本 60 假裝已載入有效點庫 |
| `S28-mounting-tips.png` | S28；S／S | 編號、說明卡與按鈕均用標準元件；本文可捲、底部 SafeArea。首次完成／略過進度分存，入口照 N2；安裝提示不是玻璃反射驗收 |
| `S07-parked-confirm.png` | S07；S／N2 L | 橫式（L28）改右半邊 460 pt Dialog（不用底部長面板）。移除取整 0 的認證感；依 safety 第四階段 R4-04，建議「GPS 低速讀值持續 10 秒／GPS low-speed readings for 10 seconds」，由 UX 統一。HUD 底圖仍即時更新；確認當下重查資格，失效／移動關框 |
| `S09-driving-screen-settings.png` | S09；S／N3 M | 重用 S01 兩張選擇卡與示範提醒，靜態預覽不再建 controller。保存偏好不重建資料來源；英文／大字改上下列，配對連結仍過 N2 |
| `S10-camera-alert-settings.png` | S10；M／N5 L | 可捲清單與資料狀態卡。依 01 §11 Q18 移除「前方距離和超過提示」鎖頭停用列；日期綁 manifest，禁止寫死圖中日期。L16 過期只顯狀態＋更新方式；Q20 詳下節 |
| `S11-mirror-preview.png` | **S11 已刪除（L29）**；— | 第五輪依 L29 拿掉鏡像：刪除 S11 預覽頁、S08 鏡像開關、`AppShell` 的 `Transform.flip` 與鏡像測試，不再需要玻璃反射驗收（原第四階段直式 PNG 保留並標已取代） |
| `S25-about.png` | S25；S／S | 標準版本／聲明／連結清單，補實際字型授權及 Q18 隱私內容。外部聯絡或分享需使用者主動操作；不沿用 spike 敏感 log、不暗接回報服務 |
| `S13-pair-start.png` | S13；S／N4 L | 準備清單用未完成圓點，不能當 app 已驗 P；依 L17 加「在收得到 GPS 的地方進行」。角色依實際登記，不提前宣稱 monitor；無 GPS 又未配對時不開此頁 |
| `S14-pair-vin-error.png` | S14；M／M | TextFormField＋格式錯誤／停用按鈕，不需畫假輸入框。橫式鍵盤開啟時收斂為步驟、一行 17 碼 VIN＋`12/17`、錯誤與「下一步」（見 `frames/landscape/S14-pair-vin-keyboard.png` 與第五輪）；完整 VIN 不進 log |
| `S15-pair-searching.png` | S15；S／N4 L | 標準進度圈及靜態通用圖示。狀態由真實掃描／連線／session 驅動，不虛構百分比或全程 SLA；取消／移動清理資源，以流程識別隔離遲到回應 |
| `S17-pair-done.png` | S17；S／N4、N1 L | 三格真實有效讀值，PNG 的 0／P／72 不可直接採用。成功需回應驗證／時間合格，缺欄顯未知，停留期間也到期；按完成再查 N2，不自動開始試用 |
| `S18-c-pair-car-not-found.png` | S18-c；S／M | 共用錯誤頁；找不到不等於已證實車休眠。重試建立新流程識別，清舊掃描／結果；做法僅在已知停車頁呈現，不能由 timeout 自動蓋住行駛 HUD |
| `S18-h-pair-paused.png` | S18-h；S／N4 L | 用「重新檢查並繼續」＋「稍後」。移動當下回 HUD，之後由使用者主動、重新過 N2 才開暫停頁；查 key／登記／session 從實際步驟續接，不保證重走感應卡 |
| `S19-car-bluetooth.png` | S19；M／N4 L | 單車卡、末六碼 VIN、狀態與重連；transport connected 不代表資料新鮮。已連線／處理中不重複連線。新車 S17 成功並保存才取代，失敗保留原車；配對車變更不重設試用／買斷 |
| `S19-b-remove-confirm.png` | S19 的確認態；S／M | 橫式（L28）改置中 460 pt Dialog，移除要防重複點及處理保存失敗；只清本機車輛連線／金鑰資料，不刪顯示設定或試用／買斷。01 §11 的改配對確認也可共用元件，但文案／動作需分開 |
| `S20-trial-start-tw.png` | S20；S／N6 L | 畫面模板可共用，iOS「領取」／Android「開始」分版；L14 原始交易／此安裝起算，商品價取商店。已用／未知／已解鎖依 Q19，不能一律顯首次領取 |
| `S21-trial-ended-tw.png` | S21；S／N6 M | 「免費試用已結束」，清單用已停止顯示的語意；GPS 免費不代表任意時刻有有效訊號。L29 拿掉鏡像模式說明；只列已交付功能，未開放胎壓不能承諾。不得自動彈出；買斷者不顯試用到期鎖 |
| `S23-support-us-b.png` | S23；S／N6 M | 標準英文說明／支持按鈕；所有車輛資料免費，支持只加 badge，不掛 S20／S21 到期邏輯。價格取商店；恢復支持標記與恢復台灣解鎖分商品 |
| `S24-purchase-results.png` | S24；S／N6 M | 9 卡是結果目錄，不是同時出現的 9 個彈窗；每次僅呈相關一則，灰色情境標籤不進產品。pending 要完成並驗證後才解鎖；app 級保存／完成交易不等 UI。Android 本機試用保存失敗不寫成商店連線失敗 |

### L13–L19 對實作與視覺的最終影響

- **L13／L17**：N2 只增明確的最小 OS 設定例外，不放行完整 S02-b／S07／S13。沿用 geolocator 的 `openAppSettings()`；返回 bool 只表示設定頁能否開啟，回 app 仍須重新檢查 permission、service、有效來源和操作閘門。`lib/main.dart:49` 現只處理請求，`lib/src/ui/app_shell.dart:61` 現無全域閘門，兩處仍要整合。地下室限制照 01 提示，不新增未知狀態手動配對退路。[Geolocator API](https://pub.dev/documentation/geolocator/latest/geolocator/Geolocator/openAppSettings.html)，2026-10-18 查閱。
- **L14／L15**：試用平台機制與字型選擇已裁定，不再列為等待決定；商品／原始交易驗證、字型資產／授權與字寬驗收仍待實作。HTML 的固定 390 寬、絕對座標與 spacer 不能直接移植；S10 長標題、S13 長頁、S14 鍵盤、S24 長結果字串共用可捲頁殼與 SafeArea。
- **L16／L18**：過期點庫整卡撤除，已知錯誤點也不以「附近」回退；失效車速 `—`＋原因，速限單位跟設定，前方琥珀延後且只留上方一個 ▲。y640 只作第四階段直式稿基準，第五輪 L28 全改橫式右欄下半狀態列。
- **L19（及 L28 橫式重套用）**：第四階段直式大字稿已由 `frames/landscape/S04-XL-large-text.png`、`S06-XL-large-text-scroll.png` 橫式大字稿取代。正式 UI 仍須用打包字型、三位數速度／mph、兩行附近卡、長來源與各輪胎壓時間驗證，另驗橫式長頁與鍵盤，不能整頁縮放過關。
- **效能／可讀性**：標準清單、少量向量沒有新增高成本繪圖需求（L29 已刪單層翻轉）；不要每個預覽重開 GPS／BLE，不對整張 parked 用 opacity 製造歷史態。safety R4-03／L21 已定舊值歷史色 `#8A97AE`（≥4.5:1），最後量測／失效原因不變暗。N1 到期事件局部更新，N5 索引不在 build 全掃；profile／耗電未測，仍列裝置驗收 L。

| L19 補稿（L28 後以橫式為準） | Flutter 判定／M 共用排版內含 | 尚待實作驗收 |
|---|---|---|
| `S04-L-drive-landscape.png`（及 `frames/landscape/S04-*`），1688×780 | 左 gauge 固定、右欄上半附近卡＋下半狀態列，可用 LayoutBuilder／Row；卡出入不搬速度。沿用同一資料管線 | 需驗 `667×375`（`S04-b-min-667x375.png`）、128／240 三位數、mph、英文／失效長來源、對稱水平 SafeArea `max(left, right)`；不能把固定 60 邊距當所有裝置安全區 |
| `S06-L-parked-landscape.png`（及 `frames/landscape/S06-*`），1688×780 | 左 gauge 與 drive 同位、右側摘要／四輪 grid 可做，日期與摘要由內容排版 | 右欄窄／大字時需捲動（L24），來源標示與失效文字固定右欄最上方；每輪時間／無值語意不能截掉，左右橫式翻轉不重設行程 |
| `S04-XL-drive-large-text.png`（直式已取代，改 `frames/landscape/S04-XL-large-text.png`） | 橫式大字／高對比樣式可共用，無額外繪圖難點 | 固定車速字級、先拿掉刻度裝飾、保留來源標示與單位；需驗 `667×375`、200% 文字與英文測量，drive 不靠捲動讀速度 |
| `S06-XL-parked-large-text.png`（直式已取代，改 `frames/landscape/S06-XL-large-text-scroll.png`） | 橫式左邊量表不捲動，右欄停車資料加大後超出一屏時由 `SingleChildScrollView` 捲動（L24） | 來源標示與失效文字留在右欄最上方可見；離開已知停車立即退 HUD，捲動位置不延長資料有效期 |

### 回答 02 Q19：S20「已用過試用」要畫哪些狀態？

L14 機制已定，沿用上文 168 小時與無後端界線。**有原試用、確定到期、狀態未知分開**；Android 沒有「此商店帳號已用過」狀態。以下字句供 visual／UX 作狀態稿，與 01 第四階段 S20／S24 文案一致；所有操作仍過 N2，永久買斷優先。

| 可證明的狀態 | iOS／Android 顯示與動作 | 繁中／English 文案 |
|---|---|---|
| 正在讀取或尚無法驗證 | 兩平台不先斷言未領過或已用完；重試／恢復入口按平台與錯誤提供，不再發新期 | 正在確認試用狀態。／Checking trial status.；查詢失敗：暫時無法確認試用狀態，請稍後重試。／We can't confirm your trial status right now. Try again later. |
| 可以開始，無有效既有紀錄 | iOS 領取零元商品，驗證後依原始日期；Android 此安裝保存成功才開始。Android 無本機紀錄不等於證明這個人從未試用 | iOS：領取 7 天免費試用／Claim a 7-day free trial；Android：在此安裝中開始 7 天免費試用／Start a 7-day free trial in this installation.；兩者：不會自動扣款。／You won't be charged automatically. |
| 原試用仍有效／已恢復 | S08 顯截止日，S20 改顯剩餘期間／返回 HUD，不再顯開始按鈕。iOS restore 沿用原始截止日；Android 只續同安裝本機紀錄 | 免費試用至 {endsAt}。／Free trial ends at {endsAt}.；iOS 恢復附：恢復不會重新開始 7 天。／Restoring does not start a new 7-day trial. |
| iOS 原交易已達 168 小時 | 可畫「原試用已結束」而非又領一次；導 S21／S22，恢復購買可找既有買斷。免費非消耗型仍持有不等於試用仍有效 | 原試用已於 {endsAt} 結束。／Your original trial ended at {endsAt}. |
| Android 本機紀錄確定到期 | S21「試用已結束」，可購買／恢復買斷；不可用 Play 帳號歷史封鎖試用。清資料／重裝後若紀錄缺失，無法判定過去是否用過，不畫已使用帳號變體 | 此安裝的 7 天試用已於 {endsAt} 結束。／The 7-day trial in this installation ended at {endsAt}. |
| 時鐘倒退／紀錄損壞，期限不能確認 | 暫停試用、保存既有起點，不重送 7 天；提示安全停車後校正／重查，不把未知顯成確定到期 | 暫時無法確認試用期限，車輛資料試用已暫停。／We can't confirm your trial period right now, so the vehicle data trial is paused. |
| iOS 取消／pending／未驗證；Android 保存失敗 | 尚未成功開始。iOS 等商店最終已驗交易；Android 重試原子保存，不顯 App Store 領取錯誤。pending 核准本身不代替交易驗證 | iOS：尚未完成 App Store 試用領取。／Your App Store trial claim is incomplete.；Android：未能儲存試用紀錄，試用尚未開始。／We couldn't save your trial record. Your trial hasn't started. |
| 已驗永久買斷／美國 B | 買斷顯已解鎖，不走試用到期頁；美國 B 資料免費，不設 S20／S21 付費閘門，S23 只自願支持 | 已解鎖／Unlocked；美國 B：所有車輛資料功能皆免費。／All car data features are free. |

`{endsAt}` 由已驗原始日期或本機紀錄計算，轉使用者時區顯示完整日期與時間；重連、換車、恢復按鈕都不能重算起點。Android 詳細說明與離線未取價格的版本沿用第三階段文案；恢復購買只恢復買斷，不承諾重裝後恢復本機試用。

### 回答 02 Q20：最後驗證由誰做、多久一次、過期寫什麼？

**由開發團隊負責點庫發布的人驗證並留紀錄，Flutter 程式只執行檢核與到期規則。** 依 01 §11 Q20，每次隨 app 發布新點庫前，對照主管機關公開資料並做實地抽查；記錄範圍、方法、差異、停用點與證據。lead 需指定實際負責人。這不是政府逐點認證，也不能由一次 JSON 解析成功自稱「已驗證」。警政署資料集標示**不定期更新**，沒有可直接採用的官方 30／90 天有效期；入口的 metadata 更新日期也不是每個點的驗證日。[警政署資料集 7320](https://data.gov.tw/dataset/7320)，2026-10-18 查閱。

**頻率的已定下限是每次點庫發布前驗一次；有效期到期前必須完成重新驗證，否則停用。** 實際相隔幾天、抽查覆蓋與可接受有效期仍由 01 Q24 實測決定，本輪沒有可負責任填入的天數。若有效期／證據未建立，就不啟用提醒；GPS／BLE HUD 不受點庫失效影響。收到可靠錯誤回報時先停用受影響點，不等下一次週期；內建資料無後端即時撤點能力，新發現錯誤需 app 資料更新，不能承諾即時遠端修復。

| 責任／資料 | 最終實作要求 |
|---|---|
| 發布者與證據 | 由點庫維護者產出驗證紀錄；至少含來源版本／取得日、比對及抽查範圍／日期、錯誤與停用點、驗證者、結論及有效期限依據。未實地驗證不能標示已做實地抽查 |
| N5 manifest | 保存 dataVersion、contentHash、lastValidatedAt、validUntil、validationMethod／validationReportId、停用點 ID、來源／授權；取得日與來源發布日分開，沒有來源發布日就留未知。不能把打包日、下載日或同版重下載當最後驗證日 |
| 啟用與到期 | 提醒需有效速度、合格手機位置／台灣資格、開關開、已驗 manifest、now < validUntil 且點未停用。到期即撤整張 live 卡；以 deadline timer＋回前景重查，不能等下一筆 GPS 才撤。時鐘異常致無法確認有效性時先不顯卡 |
| 同資料新版號 | 只改版本名／重新下載不重設期限；同 hash 要延長期限也需真實重新驗證紀錄及新發布，不靠 app 啟動時間自動續命 |
| v1 更新路徑 | 建議維持內建點庫＋app 發布，不新增下載後端；S10 提供前往 App Store／Google Play 更新的方式，照 N2 開操作。更新 app 後重讀 manifest，僅新資料已驗且未到期才能恢復；沒有有效新版就維持停用 |

| S10 狀態 | 繁中建議文案 | English |
|---|---|---|
| 有效 | 最後驗證：{date}。由開發團隊對照公開資料並實地抽查；不代表每個點位都已現場確認。有效至 {validUntil}。 | Last validated: {date}. The development team checked public records and spot-checked locations. Not every location was checked on site. Valid until {validUntil}. |
| 已過期 | 狀態：已過期。固定測速照相提醒已暫停。請更新 app；取得已驗證且未過期的新資料後才會恢復。 | Status: Expired. Speed camera alerts are paused. Update the app. Alerts resume only when validated, unexpired data is available. |
| 尚無有效新版 | 尚無已驗證的新版資料，提醒維持停用。 | No validated update is available yet. Alerts remain off. |
| 尚未驗證／無有效期 | 狀態：尚未驗證，提醒已停用。 | Status: Not yet validated. Alerts are off. |
| 部分停用 | 狀態：部分點位已停用，這些點位不會顯示提醒。 | Status: Some locations are disabled. Alerts won't appear for those locations. |

過期文案對 01 §11 的「更新 app 後會取得新資料」補上有效新版條件，避免承諾每次商店更新都有新點庫；供 UX 採用，本次未代改 01。S10 的 live 預覽到期改成狀態／更新說明，行駛 HUD 不另塞資料維護通知。若要另放範例必標示範，不能看起來是過期資料仍在提醒。資料發布驗證與到期整合列 N5 **L**，S10 排版仍 **M**；未完成實測不能將附近模式已畫好當成可上線。

## 套件與台灣點庫的建議，依 L6–L19 修訂

以下官方文件均於 2026-10-18 查閱；只決定能力與責任，未修改 pubspec／未安裝套件，版本待實作時配合 iOS／Android deployment target 鎖定。

| 範圍／畫面 | 套件或資料方式 | 需要的整合與限制 |
|---|---|---|
| IAP／S20–S24 | 新增 Flutter 維護的 [in_app_purchase](https://pub.dev/packages/in_app_purchase) | 商品查詢、purchaseStream、restorePurchases、驗證後交付與 completePurchase；必要時用對應 storekit／android 實作。退款／撤銷和離線 cache 仍須驗證策略；不是本機 bool 解鎖 |
| iOS 非訂閱試用／S20 | [Apple §3.1.1](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase) 的 Tier 0 非消耗型、命名 XX-day Trial | 不代表 store 自動安排 app 7 天期限；依上文驗原始交易、起算及恢復。Android 採本機試用、刪除每帳號承諾 |
| Key／S13–S19 | 新增 [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) | iOS Keychain／Android 安全儲存，處理現有 SharedPreferences key 遷移、寫入驗證後才刪舊值、備份排除與移除車輛。不需為讀值強制新增生物辨識步驟 |
| 定位／S02、S04、S05 | 沿用 [geolocator](https://pub.dev/packages/geolocator)，補 service／accuracy／permission 狀態與 heading | 不需另裝定位框架；GPS speed／camera position／trip 都訂閱同一位置管線。BLE 不可用與定位未授權是不同狀態 |
| 藍牙權限／S13、S18 | 沿用分支 flutter_blue_plus；若平台權限狀態不足，再加 [permission_handler](https://pub.dev/packages/permission_handler) | Android runtime scan／connect 與 iOS usage description 要一併接；永久拒絕／藍牙關閉可區分，不因需要一個設定入口就無條件加套件 |
| 本地化／全部 app 畫面 | Flutter SDK 的 flutter_localizations／產生字串資源；日期／數字 formatter | 目前沒有 l10n 委派；把 01 繁中／英文抽出，維持畫面 ID，新增狀態同時給兩語，不在 widget 拼字串 |
| 版本／S25 | 可由 build metadata 注入；需要 runtime 版本時再加 package_info_plus | 只顯版本不必新增網路服務；此套件未在本次選定或安裝 |
| 台灣點庫／S03、S04、S10、S25 | [警政署 7320](https://data.gov.tw/dataset/7320)，隨 app 放預處理 JSON／manifest 與索引 | 官方欄位含經緯度、direct、limit，授權為政府資料開放授權條款第 1 版、不定期更新。保留來源／版本／原始資料日期／下載日期／hash／授權；經緯度、limit、direct 驗證及去重後載入 |
| 點庫更新／S10 | v1 建議隨 app 更新，不新增 HTTP client；manifest 記版本／來源資料日／最後驗證日／有效期／hash 及驗證紀錄，不能只列打包日 | 手機以網格索引查附近點，未知位置／未驗證／過期撤整張卡；已知錯誤點停用。依 Q20 發布前驗證、到期停用，無有效新版不恢復。以後若加 HTTPS 更新另估；道路匹配未過不開前方與琥珀 |
| 研究網頁／S26、S27 | L12 僅畫草稿，不用 Flutter IAP、不架站 | 無分流、事件或 email 儲存；若日後授權上線，才另設資料用途／保留／刪除機制 |

## 建議的實作順序（最終版）

| 順序／量 | 實作範圍與依賴 | 完成條件 |
|---|---|---|
| 1／N1、N2 共用 L | L6／L7／L9 的有效性、來源仲裁、操作狀態與 lifecycle；先最小定位系統框、S05／GPS HUD，含 L13 一行＋OS 設定例外與 L17 地下室限制，再開操作頁。用可重播時鐘／來源事件驗規則 | 兩筆 P 或 GPS 靜止 10 秒＋確認；移動／非 P／矛盾優先；未知無 S07。冷啟動一筆、恢復兩筆、到期立即 —；舊 P 回 drive。系統返回／回呼不自動重開操作頁，不能把設定開啟成功當授權 |
| 2／橫式鎖定、鏡像清理 S＋字型、共用 UI、適應排版 M | 先鎖定 L28 左右橫式、刪 L29 鏡像與 `#10` 直式分支、打包 L15 Inter＋Noto Sans TC、修 Canvas 角度，共用對稱 SafeArea／左置量表 readout／卡片／單雙欄頁殼／460 pt 確認框；N3 與 S01／S08／S09／S12／S25／S28 可用示範資料先做，正式入口依第 1 步 | 套 `frames/landscape/` 橫式稿（含最小 `667×375` 與橫式大字稿 `S04-XL`／`S06-XL`）驗 drive／parked、S08 雙欄／窄螢幕單欄、600 pt 表單、S14 橫式鍵盤與英文。左右橫式翻轉版面不跳；失效速度不淡出留值，預覽不開第二份來源 |
| 3／N4 BLE 管線 L | 回應驗證解密／來源時間、登記結果、monitor 實車及單車；S13–S19 含安全儲存、取消清理、L10 續接，接第 1 步與共用 UI | S17 顯真實合格讀值，非樣本 0／P／72；已登記不重加。替換車成功保存才提交，失敗保留舊車；舊 session／回應隔離。未證實的角色／時間不進付費清單 |
| 4／N5 附近模式交付 L；S10 UI M | L8／L12 台灣位置資格、manifest／索引、驗證紀錄／發布檢核、S03／S10／S04 附近卡，含 L16；建議內建點庫，不新增下載服務。依第 1 步有效位置，速度可來自 BLE，不要求等 BLE 管線才開始開發 | 發布前比對／抽查且具有效期；未驗／過期整卡撤掉，已知錯誤點停用，無有效新版不恢復。切單位正確，拒定位保留 BLE。有效期天數與台灣邊界參數須實測，未過不啟用提醒 |
| 5／N6 L；iOS L、Android 本機試用 M | L14 已定，建零價 iOS 試用、兩平台買斷／支持商品、本機權益、恢復與 S20–S24；正式試用開始依第 3 步 S17 通過 | sandbox 驗 Q19 首領／剩餘／到期／未知、恢復不續期、pending／取消／撤銷／離線 cache、背景到期與移動回呼。含 iOS 13／14 收據驗證；Android 無帳號限次，買斷優先；完成交易不等 UI |
| 6／整合裝置與條件功能 L | 合併來源／操作／交易／到期／橫式左右兩向翻轉；實車 TPMS 各輪資料／時間／輪詢負載及長時間 HUD | profile 量性能／耗電與資料年齡，左右橫式翻轉不遺失 trip／配對／試用且量表不跳動。TPMS 未過 C03 整項隱藏並移出付費文案；不以 PNG 靜態審查替代裝置結果 |
| 後續，另 L | L8 前方模式：道路匹配、方向／接近狀態、資料有效期實地驗證，再開距離與琥珀。dwell 用單調時間，換點／速限／來源／資格／單位重設，低於速限立即撤超過字樣；1.5 秒僅試驗參數 | 新接近不受舊 cooldown 壓制，平行道路／高架／對向／資料舊版不誤判後，才能改正式功能旗標。保留設計不等於已交付 |
| 非 app，草稿 S | S26／S27 只供 visual／UX 畫稿，不依賴以上資料管線 | L12 不架站、不追蹤、不收 email；不列入 Flutter 開發排程 |

第五輪相較第四階段：依 L28 只做橫式、L29 拿掉鏡像，刪除 S11（原 M）與玻璃反射實機驗收，改為鎖定橫式與清理舊鏡像／直式分支（S），畫面總數由 28 減為 27（S01–S10、S12–S28）；共用 UI 維持 M，集中實作橫式對稱 SafeArea、S08 雙欄／600 pt 單欄表單、460 pt 對話框與 S14 橫式鍵盤收斂。N1／N2 L、N4 BLE L、N5 附近點庫交付 L（S10 頁面 M）、N6 試用與買斷 L、實車整合 L 維持不變。共用模組只各估一次，表內 S／M／L 不加總成工期。

## 第五輪(只做橫式、拿掉鏡像)

依 `00-rulings.md` L28（`00-rulings.md:132`）與 L29（`00-rulings.md:137`），以及 `01-flows.md` §7（`01-flows.md:930-976`），本節評估全 app 鎖定橫式、刪除鏡像、橫式鍵盤／對稱 SafeArea／表單版面，並列出核對後的檔案與行號。

### 1. 怎麼鎖定橫式：Flutter、iOS、Android 與 #10 直式分支清理

| 層級／檔案 | 現況（main／BLE 分支） | 改法與設定值 | 為什麼選這個值／注意事項 |
|---|---|---|---|
| Flutter 執行期：`lib/main.dart:9-14` | `main()` 呼叫 `WidgetsFlutterBinding.ensureInitialized()`（`:10`），未呼叫 `setPreferredOrientations` | 匯入 `package:flutter/services.dart`，在 `ensureInitialized()` 後、`runApp()`（`:13`）前 `await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);` | 支援左右兩個橫式方向（`[L28][01 §7.1]`），手機不論哪一側朝下架在儀表板上都能正立顯示；同時仍須改原生設定，避免啟動瞬間先出現直式閃屏 |
| iOS：`ios/Runner/Info.plist:56-68`（`BLE · ios/Runner/Info.plist:56-68` 同行號） | `:56-61` `UISupportedInterfaceOrientations` 含 `Portrait`（`:58`）、`LandscapeLeft`（`:59`）、`LandscapeRight`（`:60`）；`:62-68` `UISupportedInterfaceOrientations~ipad` 含 `Portrait`（`:64`）、`PortraitUpsideDown`（`:65`）、`LandscapeLeft`（`:66`）、`LandscapeRight`（`:67`） | **兩個陣列都要改**：刪 `:58` 的 `UIInterfaceOrientationPortrait`，以及 `:64-65` 的 `UIInterfaceOrientationPortrait`、`UIInterfaceOrientationPortraitUpsideDown`；兩陣列皆只留 `UIInterfaceOrientationLandscapeLeft` 與 `UIInterfaceOrientationLandscapeRight` | iOS 啟動畫面與 window scene 初始方向由 `Info.plist` 決定；若漏改 `~ipad` 或主陣列，啟動或 iPad 相容模式仍可能進直式 |
| Android：`android/app/src/main/AndroidManifest.xml:8-17`（`BLE · android/app/src/main/AndroidManifest.xml:11-20`） | `<activity android:name=".MainActivity">` 僅在 `:14` 宣告 `android:configChanges="orientation|keyboardHidden|keyboard|screenSize|..."`，未設 `android:screenOrientation` | 在 `.MainActivity` 加上 `android:screenOrientation="sensorLandscape"`，保留 `:14` 的 `configChanges` 與 `:16` 的 `android:windowSoftInputMode="adjustResize"` | `"landscape"` 只鎖單一橫向；`"userLandscape"` 在使用者關閉系統自動旋轉時可能鎖死單邊；`"sensorLandscape"` 由感測器在正向橫式與反向橫式間切換，手機正反橫放都能自動轉正，且不進直式 |

#### main 現有直式／橫式重排（#10，commit `67c8e95`）可刪除與需改寫項目

| 檔案與行號 | 現況 | L28 後的處置 |
|---|---|---|
| `lib/src/ui/parked_screen.dart:40-61` | `LayoutBuilder` 計算 `final landscape = constraints.maxWidth > constraints.maxHeight;`（`:42`），於 `:58` 分支 `if (landscape) _landscapeBody(context) else _portraitBody(context)` | 刪 `:42` 方向判斷與 `:58` 的 `_portraitBody(context)` 分支，只留橫式結構 |
| `lib/src/ui/parked_screen.dart:67-81` | `Widget _portraitBody(BuildContext context)` 直式上下堆疊（gauge 置中、底部 tripStrip 與 pill） | **整段刪除**（`:67-81`）。保留並改寫 `:83-104` 的 `_landscapeBody` 為唯一版面：移除固定右欄 `width: 280`（`:91`），改為左欄固定量表＋右欄彈性寬度與 `SingleChildScrollView`（L24） |
| `lib/src/ui/drive_screen.dart:43-100` | #10 維持單一置中 `Stack`（`:58` `Center` 放 246×246 `GaugeArc`、`:72` `Center` 放車速數字），無右欄 | 改寫為橫式雙欄骨架：左欄固定量表與車速（與 `ParkedScreen` 同位置同大小，`[L25]`），右欄上半觸發區、下半狀態列；純車速且無提醒時量表也固定在左邊不置中 |
| `lib/screenshots_main.dart:37-48` | `:37-44` 用 `320×692` 畫 4 個直式框（Drive、Parked、Waiting、Settings），`:45-47` 畫 1 個 `640×320` 橫式框 | 刪直式 `320×692` 外框，統一改為橫式尺寸（如最小基準 `667×375` 或 `844×390`） |
| `test/parked_screen_test.dart:29-51` | `landscape re-flows: gauge on the left, trip strip on the right` 設定 `Size(760, 360)` 驗左 gauge（`gaugeX < 380`）、右 trip（`tripX > 380`） | 保留左 gauge／右 trip 斷言作為唯一版面測試，並補最小橫式 `Size(667, 375)` 與右欄大字可捲動測試 |
| `test/drive_screen_test.dart:62-77` | `landscape: speed-only HUD centers the gauge (no overflow)` 於 `:76` 斷言 `expect(gaugeX, closeTo(380, 40), reason: 'gauge stays centered, no right column')` | **刪舊置中斷言**：依 L25 量表永遠固定在左邊，`:76` 必須改為斷言量表位於左半邊（`gaugeX < 380`，與 `ParkedScreen` 左欄量表同座標），不再置中 |

### 2. 鏡像刪除清單（L29）與舊設定遷移

已用 `git grep -n -i -E 'mirror|flipX|Orientation'` 於 `main` 與 `origin/feature/goal-2-ble` 逐行核對（BLE 分支的 `vehicle.pb.dart:8374` `sideMirrorHeaters` 為車外後視鏡加熱 protobuf 欄位，與 HUD 鏡像無關，保留不動）：

| 檔案與行號 | 現有程式碼 | 刪除／修改方式 |
|---|---|---|
| `lib/src/ui/app_shell.dart:87-89` | `if (s.mirror) { view = Transform.flip(flipX: true, child: view); }` | **刪除 `:87-89`**（`BLE · lib/src/ui/app_shell.dart:87-89` 同行號）；HUD 不再做水平翻轉 |
| `lib/src/settings/settings.dart:13,21,29,37,47,60` | 建構子 `this.mirror = false,`（`:13`）、欄位 `final bool mirror;`（`:21`）、`copyWith` 參數 `bool? mirror,`（`:29`）與 `mirror: mirror ?? this.mirror,`（`:37`）、`toMap()` 的 `'mirror': mirror,`（`:47`）、`Settings.fromMap` 的 `mirror: map['mirror'] as bool? ?? defaults.mirror,`（`:60`） | **全部刪除**（`BLE · lib/src/settings/settings.dart:13,21,29,37,47,60` 同行號） |
| `lib/src/settings/settings_panel.dart:78-79` | `_toggleRow('鏡像 HUD 模式', '水平翻轉,投影到擋風玻璃時讀正', s.mirror, () => _set(s.copyWith(mirror: !s.mirror))),` | **刪除 `:78-79`**（`BLE · lib/src/settings/settings_panel.dart:78-79` 同行號） |
| `test/app_shell_test.dart:23,26,30-33,36-62` | `_store` 的 `bool mirror = false` 參數與 `mirror: mirror`（`:23,26`）、`_isFlipped` helper（`:30-33`），以及 3 個鏡像 widget 測試（`:36-42`、`:44-50`、`:52-62`） | **刪除 `:30-33` 與 `:36-62` 三個鏡像測試**；`:23,26` 的 `_store` 移除 `mirror` 參數，保留 `keepAwake` 供 `:64-71` 的 `keep-awake setting is applied on launch` 測試使用 |
| `test/settings_store_test.dart:29,34,50` | `:25-35` 用 `copyWith(unit: SpeedUnit.mph, mirror: true)` 與 `expect(b.settings.mirror, isTrue)` 測持久化；`:45-52` 用 `copyWith(mirror: true)` 測 listener 通知 | **保留這兩個測試案例**，將 `:29,34,50` 的 `mirror: true`／`b.settings.mirror` 改用其他保留欄位（例如 `keepAwake: false` 或 `brightness: BrightnessMode.night`） |
| `lib/src/settings/shared_prefs_settings_storage.dart:9` | 以單一 `'settings'` JSON 字串保存設定 map | **舊設定遷移**：沿用 `autoMinimal` 的做法（見上文 `UX 留言板 5 題 §4`），`Settings.fromMap`（`lib/src/settings/settings.dart:56`）讀取舊 JSON 時直接忽略遺留的 `'mirror'` 與 `'autoMinimal'` 鍵，保留 `unit`、`brightness`、`keepAwake`、`accent` 等有效偏好；下次呼叫 `store.update()` 寫入時自然移除舊鍵，不清空 SharedPreferences。於 `test/settings_store_test.dart:37` 補一筆含舊鍵 `'mirror': true` 的讀取回歸測試 |

### 3. 橫式下的鍵盤（S14 VIN）、SafeArea 與表單頁實作注意事項

| 項目 | `01-flows.md` §7 規格要求 | Flutter 實作方式與注意事項 |
|---|---|---|
| **S14 VIN 橫式鍵盤收斂**（`01 §7.2` `:956`） | 鍵盤在橫式下佔去大半高度；鍵盤打開時版面收成**只剩**：步驟標示、VIN 欄（一行放得下 17 碼＋旁邊 `12/17` 字數）、欄位下即時錯誤、「下一步」，全部在鍵盤上方可見；插圖和「在哪裡找到 VIN？」收起成連結（收起鍵盤才展開） | 以 `final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;` 切換版面：鍵盤開啟時隱藏左側插圖並將 VIN 位置說明收合為文字連結，主體包在 `SingleChildScrollView`（配合 `padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom)`），確保在 `667×375 pt` 最小高度下輸入欄、錯誤與「下一步」皆在鍵盤上方且可捲動 |
| **S14 輸入欄與 Android 全螢幕鍵盤停用**（`01 §7.2` `:956`） | 全大寫、不自動校正、英數鍵盤；鍵盤確認鍵即「下一步」；**Android 不用橫式全螢幕輸入模式**，讓使用者看得到欄位標題和錯誤 | `TextFormField` 設 `textCapitalization: TextCapitalization.characters`、`autocorrect: false`、`enableSuggestions: false`、`keyboardType: TextInputType.visiblePassword`（或 ASCII 英數＋`FilteringTextInputFormatter` 轉大寫、擋 `I/O/Q`、限 17 碼）、`textInputAction: TextInputAction.done`（或 `next`）綁定提交；字型用等寬或 `tabularFigures` 確保 17 碼＋`12/17` 同行不折行。Android 保持 `android:windowSoftInputMode="adjustResize"`（`AndroidManifest.xml:16`），並確認 Flutter `TextInput` 啟用 `IME_FLAG_NO_FULLSCREEN`／`IME_FLAG_NO_EXTRACT_UI`，禁止系統輸入法在橫式進入全螢幕遮蓋標題與錯誤訊息 |
| **S14 移動證據立即收鍵盤**（`[L6][01 §3.6, §7.2]`） | 鍵盤同樣受 §3.6 操作閘門管：一出現移動證據就收起鍵盤、回 HUD | N2 操作閘門偵測到移動證據（任一有效來源 ≥5 km/h、非 P 檔或新鮮 P 但車速 >1 km/h）時，先執行 `FocusManager.instance.primaryFocus?.unfocus()` 與 `SystemChannels.textInput.invokeMethod('TextInput.hide')` 強制收起系統鍵盤，再導回 HUD（已填有效前綴可暫存於配對狀態機供停車後 S18-h 續接，完整 VIN 不寫入 log） |
| **對稱水平 SafeArea（回答 02 Q32）與底部手勢條**（`01 §7.1` `:940-943`） | 左右兩側都要避開瀏海／動態島／圓角；翻轉後瀏海換邊，左右兩側**都預留兩個方向中較大的安全距離**，翻轉時版面不跳；按鈕避開底部手勢條 | **不能直接用不對稱的預設 `SafeArea` 或寫死 `59`/`60` 邊距**。共用頁殼讀取實體安全區 `final vp = MediaQuery.viewPaddingOf(context); final side = math.max(vp.left, vp.right) + 16.0;`（無瀏海機型 `max(0, 0) + 16 = 16 pt`；iPhone 15 橫式 `max(59, 0) + 16 = 75 pt`，或至少 `math.max(math.max(vp.left, vp.right), 16.0)`），左右兩側套用完全相同的 `side`，並以 `MediaQuery.removePadding(context: context, removeLeft: true, removeRight: true, ...)` 包住子樹避免內層元件重複扣單邊安全區。如此在 `landscapeLeft` 與 `landscapeRight` 間 180° 翻轉時，左欄量表與右欄內容的畫面 X 座標完全不跳動；同時 S06 來源標示維持固定在左上（量表上方，與 drive 同位置，不隨右欄捲動），右欄頂端固定車況狀態行（01 §11 Q30）。底部固定按鈕列與可捲動區加上 `math.max(vp.bottom, 12.0)` 避開系統底部手勢條。翻轉時 `AppShell`／`HudController`／`TripStats` 保持同一實例，不重設行程、配對或試用狀態，且不播動畫 |
| **S08 雙欄（回答 02 Q31）與單欄表單 600 pt 上限**（`01 §7.2` `:952`、`§11 Q31`） | S08 預設**兩欄**（667 pt 寬也用兩欄：左群組清單約 190–240 pt、右內容上限約 600 pt），只有右欄可用寬度 <360 pt 或無障礙大字（iOS AX1 以上／Android ≥200%）時退回單欄換頁；其他表單／列表頁單欄、寬度上限約 `600 pt`、置中，標題列固定在上方、內容整頁捲動 | S08 在扣除對稱水平安全區後計算右欄可用寬度與 `MediaQuery.textScalerOf(context).scale(1.0)`：當 `rightWidth >= 360 && textScale < 2.0` 時渲染 `Row`（左清單 `SizedBox(width: 200)`＋右子頁 `ConstrainedBox(maxWidth: 600)`，共用同一個子頁 widget，不重複建 store／controller）；當 `rightWidth < 360` 或 `textScale >= 2.0` 時退回單欄 `ListView`＋`Navigator.push`。獨立單欄表單頁（S09、S10、S19、S25、S28、S12）外包 `Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), ...))`，上方固定 header 列，下方 `Expanded`＋`SingleChildScrollView` |
| **長文案、配對／購買兩欄與 460 pt 確認框**（`01 §7.2` `:953-959`、`§11 Q29`） | 長文案（S03、S12、S22 付費文案、S25、S28）單欄每行 ≤36 全形字／70 英文字元，不摺疊限制說明，主要按鈕固定右下；配對（S13、S15–S18）與購買（S20–S23）兩欄；確認框（S07、S19-b、S19 移除、S24）置中寬約 `460 pt`、高 ≤80%，S07 放右半邊露出左邊量表 | 長文案區以 `ConstrainedBox(maxWidth: 520)` 控制行寬並整段捲動，右下角按鈕固定於捲動區外。購買頁（S20–S23）右欄用 `Column`：上方價格、中段可捲動長文案、底部固定主要按鈕與「恢復購買」，確保價格與按鈕永不捲出畫面。所有確認框停用 `BottomSheet`，改用 `Dialog`＋`ConstrainedBox(maxWidth: 460, maxHeight: MediaQuery.sizeOf(context).height * 0.8)`，按鈕同列（左取消／關閉、右主要／重試；S24 依結果分「完成」、「關閉＋重試」、「關閉」三種，01 §11 Q29）；S07 以 `Align(alignment: Alignment.centerRight)` 置於右半邊，不遮擋左欄量表與來源標示 |

### 4. 工作量與實作順序更新

- **鏡像項目移除**：原 S11（M）與 `AppShell` 鏡像（M＋實機玻璃反射驗收）刪除，改為刪除既有 `mirror` 欄位、開關、Transform 與測試（清理 **S**，併入實作順序第 2 步）。
- **直式／橫式雙版面收斂為單一橫式**：刪除 `ParkedScreen` 直式分支（`lib/src/ui/parked_screen.dart:68-81`），省去直橫式雙套座標維護；共用橫式頁殼（對稱 SafeArea、S08 雙欄／窄螢幕單欄、600 pt 表單上限、460 pt 對話框、S14 鍵盤收斂）維持 **M**（併入實作順序第 2 步）。
- **實作順序調整**：見上方「建議的實作順序（最終版）」表——第 2 步改以 `frames/landscape/` 橫式稿驗收並先完成 L28 鎖定橫式與 L29 鏡像刪除；第 6 步裝置整合拿掉「鏡像反射」與「直橫式」，改驗橫式左右兩向翻轉與長時間 HUD。

## 第六輪(速度表置中、三個速度表方向與胎壓車子圖示)

依 `00-rulings.md` L31–L37（`00-rulings.md:145-164`）、`01-flows.md` 開頭「第六輪修訂」與 §7.4（`01-flows.md:13-30,1066-1122`）、以及 `02-visual.md` §7（`02-visual.md:579-709`）與 `docs/design/frames/gauge-variants/` 特寫 PNG（24 張）及 `gauge-variants.html:52-177`，本節逐項評估第六輪第一段之五項實作問題。

### 1. 速度表置中（L31、L35、L36，取代 L25 左邊固定）：要改的檔案、行號與工作量

- **整體工作量：M**（併入「建議的實作順序」第 2 步共用 UI M，取代第五輪原本把 `DriveScreen` 改成左置量表的重構，總排程不額外膨脹）。
- **核心版面公式（`01-flows.md:1070-1071`、L35 `00-rulings.md:160`）**：
  - 共用頁殼先取對稱水平安全區 `side = math.max(vp.left, vp.right) + 16.0`（`844×390` 時 `side = 75 pt`、內容寬 `694 pt`；`667×375` 無瀏海時 `side = 16 pt`、內容寬 `635 pt`），底部手勢安全區 `bottomSafe = vp.bottom`（`21 pt` 或 `0 pt`）。
  - **中央固定量表區（`L35`）**：在 `844×390` 為 `300×300 pt`（中心 `(422, 200)`、`x 272–572, y 50–350`）；在 `667×375` 為 `280×280 pt`（中心 `(333, 190)`、`x 193–473, y 50–330`）。行車（`S04`／`S05`）與停車（`S06`）共用同一個置中量表容器 Widget，座標與尺寸 100% 相同；檔位（`P / R / N / D` 或 `—`）統一放在量表區內數字下方附近（`L36` `00-rulings.md:162`）。
  - **左右兩側對稱側欄**：`sideColWidth = ((contentWidth - gaugeBoxWidth) / 2) - 12`（`844×390` 時左右欄各寬 `185 pt`：`x 75–260` 與 `x 584–769`；`667×375` 時各寬 `165.5 pt`：`x 16–181` 與 `x 485–651`）。

| 檔案與行號 | 現有程式碼（main） | L31／L35／L36 改法與注意事項 | 工作量 |
|---|---|---|---|
| `lib/src/ui/drive_screen.dart:43-100` | `:43-100` 為 `SafeArea`＋`Stack`：`:46` 左上 `_sourceChip`、`:47-57` 右上設定齒輪、`:58-70` `Center(child: SizedBox(width: 246, height: 246, ... GaugeArc))`、`:72-97` `Center(child: Column(車速 Text, 單位 Text))` | **好消息：現有 `DriveScreen`（`:58, :72`）原本就是置中 `Stack`**，不像 L25 需要改成左置雙欄。改法：① 抽出與 `ParkedScreen` 共用的中央量表區 `_CenteredGaugeBox`（`300×300`／`280×280`，中心位於可用高度 `(H - bottomSafe) / 2` 附近），整合 `:58-97` 的錶盤、車速大字（三位數 `≥140 px`，`L26`）、單位／`車速暫不可用`、以及量表區內數字下方的檔位框（`L36`）與預留給前方模式的數字上方 `▲`（`01-flows.md:1076`）；② 左欄（`left: side, width: sideColWidth`）頂端 `y 16` 放 `:46` 來源標示（含 `y 44` 第二行展開／閘門提示），底端 `y 336–369` 放左下角電量／續航（`L33`）；③ 右欄（`right: side, width: sideColWidth`）頂端 `y 16` 放 `:47-57` `48×48` 齒輪，上半部 `y 72–200` 固定放附近測速提醒卡或 `S05-b` 定位拒絕單行提示＋按鈕（`01-flows.md:1086-1088`）。提醒卡或左下電量出現／消失時，中央量表區完全不參與任何 `Row`/`Column` 彈性擠壓，位置零位移 | **S–M** |
| `lib/src/ui/parked_screen.dart:40-104,106-135,137-202` | `:42,58` 判斷 `landscape` 分支 `:68-81` `_portraitBody` 與 `:83-104` `_landscapeBody`；`:89` 左半 `Expanded(child: Center(child: _gaugeUnit()))`、`:90-100` 右欄 `SizedBox(width: 280, child: Column(_tripStrip(), _pill()))`；`:106-135` `_gaugeUnit()` 硬寫 `246×246` 與車速 `'0'`；`:137-150` `_tripStrip()` 為橫向 3 欄 `Row` | **主要重構集中在此檔**：① 刪 `:42,58` 與 `:67-81` `_portraitBody`（`L28`）；② 將 `:83-104` `_landscapeBody` 由「左錶＋右欄 2 欄 `Row`」改寫為**「左欄＋中錶＋右欄」三區置中骨架**：<br>• **中間區**：頂端 `y 16–42` 置中放 `:186-202` 的日期時間膠囊 `_pill(context)`（由原 `:97` 右欄移至量表正上方，`01-flows.md:1098`），下方 `y 50–350`（`667` 寬為 `y 50–330`）放與 `DriveScreen` 同一個置中量表元件（取代 `:106-135` 獨立的 `_gaugeUnit`，支援新鮮 `0`、`—`、`P 檔` 與底部缺口 `P 停車` 晶片，`L36`）。<br>• **左欄（寬 `185 pt`／`165 pt`）**：頂端 `y 16–44` 固定放 `:45` 來源標示（與行車同座標不捲動），`y 52–80` 固定放車況狀態行（`◌ 等待車輛…`／`◐ 藍牙中斷`／`◐ 藍牙資料過期`）；中段 `y 84–312` 為可捲動區（`L24` 大字可捲動），將 `:137-150` `_tripStrip()` **從橫向 3 格 `Row` 改為直向 3 列 `Column`**（`本趟 18.4 km`、`平均 46 km/h`、`最高 112 km/h`＋`由手機 GPS 計算`，因側欄僅 `165–185 pt` 寬，原橫向 3 格加分隔線 `:152` 會擠爆）及 `y 228–308` 未配對／未解鎖通知列；底端 `y 316–369` 固定放 `72% / 315 km` 與「電量最後更新 N 分鐘前」（`L33`）。<br>• **右欄（`x 585–769, y 72–360`，`184×288 pt`；`667` 寬為 `165×272 pt`）**：右上 `:47-56` 齒輪（`y 16–64`）下方固定放胎壓俯視車圖區（`L34`） | **M** |
| `test/drive_screen_test.dart:62-77` | `:62-77` 在 `Size(760, 360)` 測試橫式，`:76` 斷言 `expect(gaugeX, closeTo(380, 40), reason: 'gauge stays centered, no right column')` | **第五輪（L25）原本要刪改 `:76`，第六輪（L31）直接保留 `:76` 置中斷言！** 只需新增測試驗證：當加入右欄提醒卡（`y 72–200`）與左下角電量列（`y 336–369`）時，`gaugeX` 與 `gaugeY` 座標與純車速時完全一致（差值 `0.0`） | **S** |
| `test/parked_screen_test.dart:29-51` | `:29-51` 在 `Size(760, 360)` 斷言 `:49` `expect(gaugeX, lessThan(380))` 與 `:50` `expect(tripX, greaterThan(380))` | **必須反轉斷言**：依 L31 與 `01-flows.md` §7.4，`:49` 改為斷言 `expect(gaugeX, closeTo(380, 20))`（與 `DriveScreen` 量表中心同座標）；`:50` 的行程 `tripX`（`find.text('本趟')`）移到**左欄**，改為斷言 `expect(tripX, lessThan(gaugeX - 100))`；並補右欄胎壓區 `tireX > gaugeX + 100` 與上方日期膠囊 `pillX ≈ 380, pillY < gaugeY` 斷言 | **S** |
| `S07` 手動停車確認面板（`01-flows.md:976,1090,1115` `A27`） | 尚無正式元件（第五輪原規畫為右半邊 `352 pt` 寬 Dialog） | 依 L31 量表改置中（`x 272–572`），若 S07 仍用 `352 pt` 會蓋住中間量表右半部；實作改為**右欄面板**（`844×390` 時 `x 584–769, y 72–369`，寬 `185 pt`；`667×375` 時 `x 485–651, y 72–359`，寬 `166 pt`），內部文字自然換行、兩顆按鈕（「繼續行車畫面」／「進停車畫面」）改上下垂直排列（各高 `48 pt`），完全不遮擋中央量表與左上來源標示 | **S** |

---

### 2. 左下角電量／續航改「`/`」分隔（L33），只有 GPS 時留空、版面不跳

- **工作量：S**（單一共用元件 `BatteryRangeSlot`＋字串格式更新）。
- **字串與數字穩定度（`L33` `00-rulings.md:155`、`01-flows.md:21,182,538`）**：
  - 全 app（`S04` 左下角、`S06` 左下角、`S01`／`S09` 預覽卡、`S17` 配對完成讀值）統一由 `72% · 315 km` 改為 **`72% / 315 km`**（切 `mph` 時為 `72% / 196 mi`；若單一子欄缺值則顯示 `72% / —` 或 `— / 315 km`，斜線前後各留半形空白）。
  - `TextStyle` 強制加上 `fontFeatures: const [FontFeature.tabularFigures()]`，讓電量或續航數字變動時字元寬度固定。
- **只有 GPS（或純車速／過期）時留空、版面不跳動的實作方式**：
  - **行車畫面（`S04`／`S05`，`01-flows.md:1085`）**：
    - 在 HUD `Stack` 中，左下角電量區以獨立的 `Positioned(left: side, bottom: math.max(vp.bottom, 16.0), width: sideColWidth, height: 33, child: ...)` 定錨（在 `844×390` 對應 `x 75–260, y 336–369`；在 `667×375` 對應 `x 16–181, y 322–359`）。
    - 當來源只有 GPS（`S04-a`）、使用者選「純車速」（`S04-c`）、無車速（`S05`）、或藍牙電量超過 60 秒有效期時，該 `Positioned` 內渲染 `const SizedBox.shrink()`，**不畫空框或佔位虛線**（`01-flows.md:1085`）。
    - 由於左上來源標示（`top: 16, left: side`）、中央量表區（`Center`／固定 `top: 50`）與右欄提醒卡（`top: 72, right: side`）各自獨立定位，左下角槽位在「有顯示 `72% / 315 km`」與「留空」之間切換時，**畫面上任何其他元素的座標都是常數，絕對不會跳動 1 px**。
  - **停車畫面（`S06`，`01-flows.md:1100-1105`）**：
    - 左欄（`x 75–260`）採固定高度分段：頂端固定車況狀態行（`y 52–80`）、中段固定高度可捲動區（`y 84–312`，內含直向行程與 `y 228–308` 的「連接車輛後可顯示檔位與電量」虛線佔位或試用通知）、**底端固定保留 `y 316–369`（高 `53 pt`）給電量／續航＋「電量最後更新 N 分鐘前」兩行**。
    - 當處於 `S06-a`（只有 GPS 的手動停車且無歷史藍牙電量）或 `S06-e`（未解鎖）時，底端 `y 316–369` 保留同尺寸空白 `SizedBox(height: 53)`，不改變上方 `y 84–312` 行程與佔位區的高度與捲動邊界，因此左欄、中錶與右欄版面皆不跳動；當藍牙斷線但留有舊電量（`S06-d`）時，第一行 `72% / 315 km` 與電池膠囊套用歷史色 `#8A97AE`（`L21`，對比 `5.84:1`），第二行顯示完整對比度的「電量最後更新 12 分鐘前」。

---

### 3. 三個速度表方向（A 直讀數字、B 點陣環、C 扇形）的實作方式、效能與工作量比較

依 `02-visual.md` §7.3–§7.6（`02-visual.md:610-705`）與 `docs/design/frames/gauge-variants.html:62-146`，三個新方向與「現在的版本」共同遵守 `L32`／`L35`／`L36` 硬規則：車速數字與填色／亮段**直接跳變、不做補間動畫**（`02-visual.md:661,703`，可移除現有 `lib/src/ui/drive_screen.dart:62-69` 的 `TweenAnimationBuilder`，使每次速度更新只觸發 1 次繪製而非 250ms 內連續重繪 15 幀）；無有效車速（`na`）時顯示 `#8A97AE` 的 `—`＋`車速暫不可用`，底軌改為 `#33476A` 虛線或暗段、**完全不畫填色與紅色標記**；三位數車速皆 `≥140 px`，並縮放進 `L35` 的 `300×300`（`844×390`）／`280×280`（`667×375`）量表區。

#### 四種方案逐項比較表

| 維度 | 對照：現在的版本（`cur`，250° 細環） | 方向 A：「直讀數字」（巨字＋底部橫條） | 方向 B：「點陣環」（300° 41 段 LED 環） | 方向 C：「扇形」（上半圓 180° 實心扇面） |
|---|---|---|---|---|
| **視覺結構（`gauge-variants.html`）** | `215°` 起順時針掃 `250°` 細圓弧（`strokeWidth: 7.5`）、active 弧＋端點亮圓點（`r=7`）、內圈紅色短線標記（`r 118→136`）；中央數字 `158 / 140 px`（`:63-75`） | **無圓形錶盤**：上方巨型數字 `200 / 168 px`（縮進 `300`／`280` 框為 `164`／`152 px`）＋單位；底部一條水平速度條（寬 `280`/`260 px`、`strokeWidth: 8`）＋`0/60/120/180/240` 刻度與紅色圓角矩形游標 `5×26 px`（`:78-94`） | `240°` 起順時針掃 `300°`、共 **41 根放射短線**（`i = 0..40`，每格 `6 km/h`；`i % 10 == 0` 每 `60 km/h` 向內長 `6 px`）；亮到 `lit` 段，最前段 `i == lit` 最亮且加粗（`7 px` vs `5 px`）＋內側紅色短標記；中央數字 `150 / 140 px`（`:97-116`） | 上半圓 `180°→0°` 封閉扇形環帶（外徑 `R`、內徑 `r`）、扇面半透明填色＋外弧 `5 px` 亮邊＋跨越內外弧的紅色標記線（長 `R - r`）＋外圈 `0..240` 刻度與文字；數字 `170 / 150 px` **疊在扇面前方下緣**（`:119-139`） |
| **`CustomPainter` 怎麼畫** | 沿用 `lib/src/ui/gauge_arc.dart:50-105`：① 修正 `:56` 起始角度為 `215°` 順時針、刪 `:85-95` 舊邊緣刻度與 `:104` 圓心紅點；② 補 active 終點 `canvas.drawCircle(tip, 7, brightPaint)`；③ `!active`（沒資料）時底軌改畫 `#33476A` 虛線弧（預切 `PathMetrics` 或每隔固定角度畫短 `drawArc`） | **最單純的一維繪圖**：上半部純 `Column`/`Stack` 原生 `Text`；底部只對 `height: 48` 的橫條區域用 `CustomPainter`：① 底軌 `canvas.drawLine(Offset(x0, y), Offset(x1, y), trackPaint)`（`!active` 時用簡單 X 迴圈每 `12 px` 畫 `3 px` 點線，完全不用 `PathMetrics`）；② `v > 0` 時畫水平 active 線 `drawLine(x0→xv)`；③ 紅標 `canvas.drawRRect(RRect.fromRectAndRadius(..., 2.5))`；④ 5 個刻度線 `drawLine`＋下方 `0..240` 文字（可用靜態 `Row` Widget 或預先 `layout()` 的 `TextPainter`） | **極座標 41 段迴圈**：① 預先在 `static final` 算好 41 個固定角度 `a = 240° - 300° * i / 40` 的單位向量 `(cos, sin)`；② `paint()` 算 `lit = !active ? -1 : (40 * fraction).round()`，跑 `0..40` 迴圈乘上半徑 `(Ro, major ? Ri - 6 : Ri)` 呼叫 `canvas.drawLine(p0, p1, paint)`（分 `segOff`、`segOn`、`segHead` 三支預建 `Paint`）；③ `!active` 時全段直接用 `#33476A` 55% 不透明度畫出（天然是分段點陣，**不用切虛線**）；④ 有效時在 `lit` 角度內側 `Ri-14 → Ri-4` 畫紅色 `drawLine` | **複合封閉 `Path`＋外弧獨立描邊＋外圈文字**：① 底環用 `Path()..arcTo(outerRect, pi, pi, false)..lineTo(cx+r, cy)..arcTo(innerRect, 0, -pi, false)..close()` 填色 `rgba(30,42,64,0.55)`；`!active` 時不填色，改對整條封閉扇形外框用 `PathMetrics` 切 `5 px` 實／`8 px` 空的虛線 `Path` 描邊；② `v > 0` 時動態組出 `pi` 掃過 `sweepRad` 的內外弧封閉扇形 `Path` 填入 `fanFill`（或漸層 Shader），再**單獨呼叫 `canvas.drawArc(outerRect, pi, sweepRad, false, edgePaint)`** 畫外弧 `5 px` 亮邊（不能直接 `stroke` 扇形 `Path`，否則內弧與兩側半徑也會被描粗邊）；③ 畫 `r → R` 紅色標記線；④ 以 5 個快取 `TextPainter` 畫外圈 `0/60/120/180/240` 與放射短線 |
| **效能與重繪（`shouldRepaint`）注意事項** | • 連續比例 `fraction`：每當整數 `km/h` 改變就重繪一次。<br>• `!active` 的虛線圓弧 `Path` 應按 `Size` 快取，不在 `paint()` 內每次跑 `computeMetrics()` | • **GPU 繪製面積最小**（僅底部 `280×48 pt` 橫條，不到圓環的 1/5）。<br>• `shouldRepaint` 比較整數 `km/h`（或量化後的像素 `xv.round()`）與 `active`。<br>• `0/60/120/180/240` 若用 `TextPainter`，必須在建構或尺寸變更時快取 `layout()`，禁止每幀重排文字 | • **執行期重繪次數最少（最大優勢）**：因為 41 段是離散刻度（每段代表 `6 km/h`），`shouldRepaint` 只需判斷 `old.lit != lit || old.active != active`——**車速在同一段（6 km/h 區間）內微幅跳動時完全不觸發 Canvas 重繪（0 repaint）**！<br>• 若 L37 為亮段加光暈（`MaskFilter.blur`），切勿對 41 根線段逐一開 blur，應只對 `i == lit` 首段開 blur 或將亮段合為單一 `Path` 畫一次，並外包 `RepaintBoundary` | • **每幀重繪與配置成本最高**：每次 `km/h` 變動都要重建正反向內外弧封閉 `Path`（建議重用單一 `Path..reset()`）；`!active` 的封閉扇形虛線外框必須在 `Size` 改變時預先用 `PathMetrics` 算好快取。<br>• 若 L37 為扇面加 `SweepGradient`／`RadialGradient` 材質，必須依 `Size` 快取 `Shader` 物件，避免在 `paint()` 每幀呼叫 `createShader`。<br>• 數字 `Text` 疊在 `CustomPaint` 上方，需用 `RepaintBoundary` 隔離扇面 Canvas 與前景 `Text` |
| **放入 `L35`（`300×300`／`280×280`）與 `L36` 檔位注意事項** | • 原生即為 `300×281`，放 `300×300` 剛好、`280×280` 縮約 7%（`02-visual.md:636`）。<br>• 底部有 `110°` 缺口，檔位放 `(cx, cy + 120)` 最自然 | • 放 `300×300` 時三位數微調為 `164 px`；放 `280×280` 時三位數 `152 px`、橫條寬 `260 px`（`02-visual.md:637`）。<br>• 無錶盤缺口，依 `L36` 檔位改放數字／單位下方（與底部橫條拉開間距，避免和數字上方的前方模式 `▲` 搶位） | • 特寫稿寬 `321 px`，放 `300×300` 時縮為 `Ro = 148, Ri = 127`；放 `280×280` 時縮為 `Ro = 138, Ri = 124`，內圈直徑 `248 px` 仍容納三位數 `140 px`（`02-visual.md:638`）。<br>• 底部有 `60°` 缺口（寬約 `136 px`），檔位晶片（寬 `≤80 px`）可直接放缺口中央 | • 特寫稿含外側 `60/180` 刻度文字寬達 `343 px`，依 `L35` 縮進 `300×300` 時扇形需縮至 `R ≈ 132–145, r ≈ 96–104`（`280×280` 時 `R ≈ 115`），幾何空間最緊。<br>• **大字直接疊壓在扇面填色與紅色標記線上**：若 L37 提高扇面亮度或紅標在 `80–160 km/h` 穿過數字筆畫後方，需特別驗證強光／夜間可讀性；檔位需塞在平底扇腳間、單位正下方 |
| **工作量估計** | **S**（基於 `gauge_arc.dart` 修改） | **S（三個新方向中最容易）** | **S–M（次容易，重繪最省）** | **M（三個新方向中最難）** |

- **結論：哪一個最容易、哪一個最難？**
  1. **最容易：方向 A「直讀數字」（工作量 S）**——完全不需圓弧幾何、極座標或複雜 `Path`，只有大字 `Text` 加一條一維水平線性速度條（`drawLine` + `drawRRect`），沒資料的水平點線也不用 `PathMetrics`。
  2. **次容易：方向 B「點陣環」（工作量 S–M）**——41 段放射刻度全部是單純的 `drawLine`，沒資料只需直接調暗段色（免切虛線 `Path`），底部天然有 `60°` 缺口放 `L36` 檔位，且**離散 41 段（每 `6 km/h` 一格）在行駛中重繪次數最少**。
  3. **最難：方向 C「扇形」（工作量 M）**——需處理內外弧正反向封閉 `Path`、外弧獨立描邊、沒資料時整圈扇形外框的 `PathMetrics` 虛線切割、5 組外圈角度 `TextPainter` 定位；加上外圈刻度最佔寬度（縮進 `280×280` 最緊），且車速大字疊壓在扇面與紅標上，對 `L37` 配色／材質與 `L36` 檔位排版的容錯度最低。

---

### 4. 如果某個方向換字型（L37，要隨 app 打包）：要改什麼、會不會影響 L15 的 Inter + Noto Sans TC？

- **工作量：S**。
- **要改什麼（具體檔案與行號）**：
  1. **新增字型檔資產（`assets/fonts/`）**：將被選中方向的車速專用字型檔（`.ttf` 或 `.otf`；只需打包車速用到的字重如 `Bold 700` 與刻度 `SemiBold 600`，且可做 ASCII 數字與符號子集化，單檔僅約 `15–80 KB`）放入 `assets/fonts/`。
  2. **註冊獨立 `fontFamily`（`pubspec.yaml:56-93`）**：在 `pubspec.yaml:56` 的 `flutter:` 區段下 `fonts:` 註冊專屬家族名稱（例如 `family: HudGaugeNumeral`），與全域的 `Inter`、`NotoSansTC` 分開並列宣告：
     ```yaml
     flutter:
       uses-material-design: true
       fonts:
         - family: Inter
           fonts:
             - asset: assets/fonts/Inter-Regular.ttf
               weight: 400
             - asset: assets/fonts/Inter-Medium.ttf
               weight: 500
             - asset: assets/fonts/Inter-SemiBold.ttf
               weight: 600
             - asset: assets/fonts/Inter-Bold.ttf
               weight: 700
         - family: NotoSansTC
           fonts:
             - asset: assets/fonts/NotoSansTC-Regular.ttf
               weight: 400
             - asset: assets/fonts/NotoSansTC-Medium.ttf
               weight: 500
             - asset: assets/fonts/NotoSansTC-SemiBold.ttf
               weight: 600
             - asset: assets/fonts/NotoSansTC-Bold.ttf
               weight: 700
         - family: HudGaugeNumeral
           fonts:
             - asset: assets/fonts/<SelectedDirectionFont>-Bold.ttf
               weight: 700
     ```
  3. **局部套用在量表車速 `TextStyle`（`lib/src/ui/drive_screen.dart:78-84`、`lib/src/ui/parked_screen.dart:118-123`）**：
     - 只在共用中央量表元件的車速數字（及必要時的錶盤 `0/60/120/180/240` 刻度數字）指定 `fontFamily: 'HudGaugeNumeral'`，並設定 `fontFamilyFallback: const ['Inter', 'NotoSansTC']` 與 `fontFeatures: const [FontFeature.tabularFigures()]`。
     - **垂直對齊與三位數字寬校正**：不同展示／幾何／機械字體的 cap-height、ascender/descender 與字面寬度（advance width）和 `Inter` 不同。套用新字型時，需在車速 `Text` 加上 `textHeightBehavior: const TextHeightBehavior(applyHeightToFirstAscent: false, applyHeightToLastDescent: false)`，微調數字在 `300×300`／`280×280` 框內的 `top` 偏移與 `letterSpacing`，並在 widget test 驗證三位數（如 `128`、`188`、`240`）在最小字級 `≥140 px`（`L26`、`L32`）下不會超框或折行。
  4. **開源字型授權（`S25 關於與聲明`）**：確認該字型具備允許隨商用 App 內嵌散佈的授權（如 SIL Open Font License 1.1 或 Apache 2.0），將授權全文放入 `assets/fonts/` 並透過 `LicenseRegistry.addLicense` 顯示於 `S25`。
- **會不會影響 L15 的 Inter + Noto Sans TC？**
  - **完全不會影響，零衝突**：
    - `lib/main.dart:23-28` 的 `MaterialApp` 全域 `ThemeData` 仍然維持 `fontFamily: 'Inter'` 與 `fontFamilyFallback: const ['NotoSansTC']`（`L15` `00-rulings.md:62`）。
    - 全 app 的所有中文與一般 UI 文字——包含左上來源標示、單位 `km/h`、`車速暫不可用`、`P 停車` 晶片、左下角 `72% / 315 km`、附近測速提醒卡、停車行程／胎壓與所有設定／配對／購買頁——**100% 繼續使用 `Inter + Noto Sans TC`**，不會被車速字型污染。
    - 當無有效車速顯示 `—`（`U+2014`）或 `S06-f` 顯示「`P 檔`」時，即使新數字字型不含全形破折號或中文字，也會透過 `fontFamilyFallback: const ['Inter', 'NotoSansTC']` 自動退回 `Inter`／`Noto Sans TC`。

---

### 5. 停車畫面右欄的胎壓車子圖示（L34）：SVG 或 `CustomPainter` 兩種做法的取捨

依 `L34`（`00-rulings.md:157`）與 `01-flows.md` §7.4（`01-flows.md:1106-1107`、`team-board.md:70`），停車畫面（`S06`）右欄胎壓區固定在 `844×390` 的 `x 585–769, y 72–360`（**寬 `184 pt × 高 288 pt`**）與 `667×375` 的 `x 486–651, y 72–344`（**寬 `165 pt × 高 272 pt`**），中央畫車頭朝上的未來感雙門轎跑俯視圖，四個輪位旁顯示各自的胎壓值與「最後量測 N 分鐘前」，底部放「僅供參考，請以車上的胎壓警示為準」。在 `tire` 交付細節前，先確立架構原則與兩種畫法的取捨：

- **共同前提（兩種做法都必須遵守）：「車身圖形」與「四輪文字標籤」必須分離**
  - **四輪數值（`2.9 bar`／`42 psi`／`—`）、每輪各自的「最後量測 N 分鐘前／量測時間未知／尚無讀值」及底部免責聲明，絕對不能燒進 SVG `<text>` 或寫死在固定 Canvas 像素內**，必須由外層 Flutter `Stack`／`Row`／`Column` 的原生 `Text` widget 負責。
  - **理由**：① 需支援 `bar`／`psi` 單位切換、繁中／英文雙語（窄欄 `60–70 pt` 內時間文字需自動換行）、以及新鮮值（`#F2F5FA`）與過期歷史色（`#8A97AE`，`L21`）切換；② 需支援 `L19`「大字與高對比」模式——依 `01-flows.md:1106`，大字模式下**車身俯視圖縮小，四輪數值改排在車身下方的直向清單並在 `y 72–360` 內捲動**，若文字與車身綁死將無法重排；③ 需支援 VoiceOver／TalkBack 依「左前、右前、左後、右後」順序朗讀。

| 比較維度 | 做法一：車身用 SVG 資產（`flutter_svg`）＋外層 Flutter `Text` | 做法二：車身與引出線全用 `CustomPainter`＋外層 Flutter `Text` |
|---|---|---|
| **套件與 `pubspec.yaml` 變更** | **需新增第三方套件 `flutter_svg`**（現有 `pubspec.yaml:30-40` 未安裝），並在 `pubspec.yaml:64` `assets:` 宣告 `assets/images/tire_car_topdown.svg` | **零新增套件**，直接使用 Flutter SDK 內建 `CustomPainter`、`Canvas`、`Path` 與 `Shader` |
| **複雜曲線還原度與改稿成本** | **高（設計師友善）**：`tire` 在 `frames/tire/` 畫好的雙門轎跑流線車頂、車窗折線、輪拱倒角等貝茲曲線 `<path d="...">` 可直接匯出使用；後續微調車身造型只需替換 `.svg` 檔 | **中**：若手工將多條複雜三次貝茲曲線（`cubicTo`）轉成 Dart 程式碼較繁瑣；但可利用車身**左右對稱**特性（只定義左半邊正規化座標 `0..1`，右半邊用 `canvas.scale(-1, 1)` 鏡像繪出），或直接把 `tire` 的 SVG `d` 字串轉為常數 `Path` |
| **逐輪狀態（有值／缺值／過期）與 L19 高對比控制** | **較受限**：單一靜態 `.svg` 不易針對「左前有值、右後缺值」個別改變單一輪胎框或引出線（callout line）的粗細／虛線／顏色，也較難隨 `L19` 高對比模式動態加粗車身外框線條（需準備多份 SVG 或用 `ColorFilter` 整張變色） | **極靈活（最大優勢）**：`paint()` 可直接接收四輪狀態陣列與 `highContrast` 旗標，動態為每一輪畫出實線／虛線引出線、切換輪胎框顏色（`#2C5A66` vs 歷史色 `#4C586D` vs 高對比 `#4F8796`）與動態加粗線寬 |
| **科技光暈／漸層質感與渲染效能** | `flutter_svg`（底層 `vector_graphics`）**不完整支援 SVG `<filter>`（如 `feGaussianBlur` 發光、`feDropShadow`）**；若 `tire` 用了 SVG 濾鏡，匯入 Flutter 時可能消失或破圖，必須改用純漸層與半透明色塊 | 原生支援 `LinearGradient`、`RadialGradient` 與 `MaskFilter.blur`；且車身在停車畫面是**完全靜態圖形**（`shouldRepaint` 只在四輪狀態或高對比設定改變時回傳 `true`），搭配 `RepaintBoundary` 幾乎是 0 CPU/GPU 負擔 |
| **工作量估計** | **S–M** | **S–M** |

- **建議結論（供 `tire` 與第二段整合採用）**：
  - **推薦採「混合／正規化 `CustomPainter`」做法（工作量 S–M）**：
    1. 請 `tire` 繪製車身時**保持左右對稱、使用乾淨的 `<path>`／`<rect>`／`<line>` 與線性／放射漸層，避免依賴 SVG `<filter>`（`feGaussianBlur`）**，且不要把四輪文字塞進車身圖層內。
    2. 若 `tire` 定稿的車身線條精簡（≤10 條對稱路徑），直接轉成 Flutter `CustomPainter`（左半邊 `Path`＋右半邊鏡像，搭配動態四輪輪胎框與引出線），**免裝 `flutter_svg` 套件**，且能完美支援逐輪缺值虛線與 `L19` 高對比加粗。
    3. 若 `tire` 定稿的車身含多層複雜光影曲面，則將**純車身底圖**存為無濾鏡 SVG（以 `flutter_svg` 載入），而**四個輪胎狀態框、引出線與四輪數值／時間 `Text`** 仍由 Flutter `CustomPainter`＋Widget `Stack` 繪製。等下次 `tire` 完成 `05-tire-icon.md` 與 `frames/tire/` 後再做最終細節盤點。

---

### 6. 第六輪第二次評估：三款字型（Jost／Exo 2／Barlow Semi Condensed）與新質感（L37、L38）

依 `02-visual.md` §7.5–§7.7（`02-visual.md:688-843`）、`docs/design/frames/gauge-variants.html:13,88-250` 與 `frames/gauge-variants/compare.png`，`visual` 已完成四個速度表版本的完整畫面（行車、提醒、沒資料、停車、`667×375`）與 `L37`／`L38` 各方向的專屬字型、配色與質感。以下逐項評估實作可行性：

#### 6.1 三款字型的授權、檔案大小、等寬數字（`tnum`）與繁中 Fallback 接法

| 項目 | 方向 A：`Jost` | 方向 B：`Exo 2` | 方向 C：`Barlow Semi Condensed` |
|---|---|---|---|
| **設計稿用到的字重（`02-visual.md:722-728`、`gauge-variants.html:98-117,266`）** | 車速 `600 SemiBold`、單位 `500 Medium`（檔位方塊 `D`/`P` 用 `700 Bold`） | 車速 `700 Bold`、單位 `600 SemiBold`（檔位方塊 `D`/`P` 同用 `700 Bold`） | 車速 `600 SemiBold`、單位 `500 Medium`（檔位方塊 `D`/`P` 用 `700 Bold`） |
| **開源授權（能否隨 App 打包）** | **SIL Open Font License 1.1（OFL-1.1）**（作者 Owen Earl / indestructible type*，Google Fonts 收錄）。**允許免費隨商用 iOS／Android App 內嵌打包散佈**，無需額外授權費 | **SIL Open Font License 1.1（OFL-1.1）**（作者 Natanael Gama，Google Fonts 收錄）。**允許免費隨商用 iOS／Android App 內嵌打包散佈** | **SIL Open Font License 1.1（OFL-1.1）**（作者 Jeremy Tribby，Google Fonts 收錄）。**允許免費隨商用 iOS／Android App 內嵌打包散佈** |
| **隨 App 打包合規要求（`S25`）** | 只打包老闆最終選定的那 1 套字型；將該字型的 `OFL.txt` 放入 `assets/fonts/`，並於啟動時透過 `LicenseRegistry.addLicense` 註冊，使 `S25 關於與聲明` 的開源授權頁面可檢視版權與 OFL 1.1 條款（不可將 App 本身當成單獨字型檔轉售） | 同左（附 `Exo 2` 之 `OFL.txt` 至 `LicenseRegistry`） | 同左（附 `Barlow` 之 `OFL.txt` 至 `LicenseRegistry`） |
| **檔案大小（未壓縮 `.ttf`）** | • 靜態單一字重約 **`55–68 KB`／檔**（打包 `500`＋`600` 兩檔約 **`120 KB`**，加 `700` 三檔約 **`180 KB`**）。<br>• 或直接打包單一可變字型 `Jost-VariableFont_wght.ttf` 約 **`105 KB`**。<br>• 若做 ASCII 子集化（僅留 `0-9`、`km/h`、`mph`、`D/P/R/N`、`—`）每檔僅 **`12–18 KB`** | • 靜態單一字重約 **`60–75 KB`／檔**（打包 `600`＋`700` 兩檔合計約 **`135 KB`**）。<br>• 單一可變字型 `Exo2-VariableFont_wght.ttf` 約 **`120 KB`**。<br>• ASCII 子集化後每檔約 **`14–20 KB`** | • 純靜態字體家族（無 Variable Font），單一字重約 **`65–80 KB`／檔**（打包 `500`＋`600` 兩檔約 **`145 KB`**，加 `700` 三檔約 **`210 KB`**）。<br>• ASCII 子集化後每檔約 **`14–20 KB`** |
| **等寬數字（`tabular-nums` / `tnum`）支不支援** | **原生支援 OpenType `tnum`**（`02-visual.md:725,801` 已在 Chrome 驗證）。Flutter `TextStyle` 設定 `fontFeatures: const [FontFeature.tabularFigures()]` 後，`0–9` 字元寬度完全相等，車速跳動時零水平位移 | **原生支援 OpenType `tnum`**（`02-visual.md:726,801`）。Flutter 設 `FontFeature.tabularFigures()` 後 `0–9` 等寬 | **原生支援 OpenType `tnum`**（`02-visual.md:727,801`）。Flutter 設 `FontFeature.tabularFigures()` 後 `0–9` 等寬 |

- **繁中 Fallback 怎麼接（數字用新字型，中文仍用 `Noto Sans TC`）**：
  1. **全 App 預設字型維持 `L15` 不變**：
     - `lib/main.dart:23-28` 的 `MaterialApp` 全域 `ThemeData` 保持 `fontFamily: 'Inter'`、`fontFamilyFallback: const ['NotoSansTC']`。
     - 因此畫面上所有中文元件——左上來源標示（「`車輛藍牙`」、「`搜尋 GPS 訊號…`」）、量表內的中文原因文字（「`車速暫不可用`」，對應 `gauge-variants.html:130,141,169,198` 的 `fam: NOTO`）、右欄「`附近有測速點`／`點位資料速限`」、停車左欄行程與所有設定／配對／購買頁——**直接繼承全域 `Inter + NotoSansTC`，完全不碰新字型**。
  2. **量表元件局部指定 `fontFamily` 並掛載 `NotoSansTC` Fallback**：
     - 在中央量表元件內，僅對**車速大字**（`88`、`128`、`—`）、**單位**（`km/h`、`mph`）與**檔位方塊字母**（`D`、`P`）的 `TextStyle` 指定新字型，並將 `'NotoSansTC'` 列為第一 fallback：
       ```dart
       TextStyle(
         fontFamily: 'Jost', // 或 'Exo2' / 'BarlowSemiCondensed'（只註冊最終選定的那 1 套）
         fontFamilyFallback: const ['NotoSansTC', 'Inter'],
         fontWeight: FontWeight.w600, // B 為 FontWeight.w700
         fontFeatures: const [FontFeature.tabularFigures()],
         height: 1.0,
       )
       ```
     - **混排與缺字自動退回機制**：`Jost`、`Exo 2`、`Barlow Semi Condensed` 都是純西文字型（含 ASCII 數字、拉丁字母與 `U+2014` 全形破折號 `—`，但**不含 CJK 漢字**）。當出現像 `S06-f`（新鮮 P 但車速缺值，中央顯示 `"P 檔"`）的英中混排字串時，Flutter 的 SkParagraph／HarfBuzz 引擎會按字元（per-grapheme cluster）匹配 glyph：`'P'` 使用新字型，漢字 `'檔'` 在主字型找不到 glyph 時立即自動退回 `fontFamilyFallback` 的 `'NotoSansTC'`；也可直接拆成 `Row` 或 `Text.rich` 分別指定英數與中文 `TextSpan`，視覺與 `gauge-variants.html:92` 的 `font-family: '<fam>', 'Noto Sans TC'` 100% 一致。
  3. **墨跡中心定位與回應 `02-visual.md` Q40（三位數字高）**：
     - `gauge-variants.html:89-92` 利用 Canvas `actualBoundingBoxAscent/Descent` 將三款字型的「實際墨跡中心」強制定在 `yc`（現在／B／C 為 `c - 10`，A 為 `104 * k`）。在 Flutter 中，因為 `Jost`、`Exo 2`、`Barlow Semi Condensed` 的內建上下行高留白（ascent/descent leading）不同，車速 `Text` 應加上 `textHeightBehavior: const TextHeightBehavior(applyHeightToFirstAscent: false, applyHeightToLastDescent: false)`，並對最終選定方向設定固定的垂直微調常數（只需在 `300×300` 與 `280×280` 兩個尺寸各定一個 `top` 常數）。
     - **關於 Q40（`280×280` 下 B、C 三位數字高 `100`／`101 px` vs 現在版本 `105 px`）**：因為 `Exo 2` 與 `Barlow Semi Condensed` 的 cap-height 比例（約 `0.71–0.72`）略低於 `Inter`（`0.75`），同樣 `fontSize: 140` 時實際墨跡高度少約 `4–5 px`。從 Flutter 實作角度，若 `safety` 裁定要以「墨跡字高 `≥105 px`」為準，只需將 `280×280` 時 B 與 C 的三位數 `fontSize` 由 `140` 調為 `146–147 px`（因 B 內淨寬已擴大至 `256 px`、C 為 Semi Condensed 窄體且內圈直徑 `220 px`，調到 `146 px` 寬度依然完全放得進內圈，零額外成本）。

---

#### 6.2 各版本新質感（A 純黑底、B 點陣底紋與電光藍、C 槍灰金屬漸層錶盤）的 Flutter 畫法、效能與工作量更新

第二段各方向除了量表本身，還帶有專屬的全畫面配色 Token（`gauge-variants.html:97-112` 的 `TH.cur / TH.A / TH.B / TH.C`：背景 `bg`、主字 `num`、無資料 `na`、單位 `unit`、次要字 `sec`、齒輪 `icon`、卡片 `card`/`cardBd`/`cardIc`、分隔線 `div`；語意色 `#3DE0A8` 綠、`#F5B53C` 琥珀、`#E8344F` 紅針保持全域固定）。在 Flutter 只需定義一個常數 `HudThemeTokens` 類別，選定方向後直接注入，不影響業務邏輯。

| 方向與新質感（`02-visual.md` §7.7.2） | Flutter 具體繪製方式（`Container`／`CustomPainter`／`Shader`） | 效能有無疑慮与注意事項 | 更新後工作量（與第一段比較） |
|---|---|---|---|
| **方向 A：「直讀數字」**<br>• 純黑中性漸層底 `#171717 → #060606`<br>• `Jost 600` 巨字 `196 / 150 px`<br>• `224 px` 細速度條（底軌 `#2C2C2C`、填色 `#E6E6E3`、只留 `60/120/180` 三根短刻度、**無刻度數字**）<br>• 比速度條高的白色圓角直條游標（`4×24 px`，`#FFFFFF`）<br>• 檔位方塊在速度條下方（`R6-01`） | 1. **純黑背景**：外層 `DecoratedBox` 使用 `RadialGradient(center: const Alignment(0.0, -0.1), radius: 1.25, colors: [Color(0xFF171717), Color(0xFF060606)])`。<br>2. **速度條 `CustomPainter`（`gauge-variants.html:143-150`）**：第二段依 `R6-01`／`R6-05` **刪除了原本的 `0/60/120/180/240` 五個刻度數字**，因此連 `TextPainter` 都不需要！在 `paint()` 中：<br>• 有效時：1 條底軌 `drawLine`（`strokeWidth: 5*k, StrokeCap.round`）＋ 3 條 `4*k px` 垂直短刻度 `drawLine`（`60/120/180`）＋ 1 條近白填色 `drawLine` ＋ 1 個白色直條游標 `drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(xv, y), width: 4, height: 24*k), Radius.circular(2)))`。<br>• 沒資料時：不畫刻度線與游標，只用簡單 X 迴圈（每 `11 px` 畫 `2 px` 實、`9 px` 空）畫一條 `#4A4A48` 點線。<br>3. **檔位方塊（`40×32`）**：放在速度條下方 `y = 268`（`300` 框）／`252`（`280` 框），與其餘三版同座標 | **零效能疑慮（四版最輕）**：<br>• 整個量表只有 6 次極基礎的一維 `drawLine`／`drawRRect` 呼叫，無三角函數、無 `Path`、無 `Shader`、無 `MaskFilter`。<br>• 註：如 `02-visual.md` Q38 所述，A 的數字頂端在 `y = 33`，若未來 v1.x 開啟前方模式，數字上方的琥珀 `▲` 需照 ux 裁定放位置（v1 只開附近模式，不受影響） | **S（比第一段更簡單，穩居最容易）** |
| **方向 B：「點陣環」**<br>• 深靛藍三階放射漸層 `#10143A → #060820 → #03040E` ＋ **疊加 `6×6 px` 細點陣底紋** `rgba(130,150,255,0.07)`<br>• `Exo 2 700` 數字 `172 / 150(140) px`<br>• 41 段短 LED 環（內徑擴大至 `137`／`128 px`，亮段 `#6F88FF`、暗段 `#232A5C`、最前段加粗 `8 px` 冰白 `#E4E9FF`；**已拿掉發光模糊與內圈紅針，`R6-02`**） | 1. **深靛藍＋`6×6 px` 點陣底紋（`gauge-variants.html:105`）**：<br>• 底層：`DecoratedBox` 畫三色 `RadialGradient([Color(0xFF10143A), Color(0xFF060820), Color(0xFF03040E)], stops: [0.0, 0.55, 1.0])`。<br>• **上層 `6×6 px` 點陣底紋（關鍵做法）**：**不要**在每幀用迴圈跑 `141 × 65 ≈ 9,165` 次 `canvas.drawCircle`！應採用**硬體紋理平鋪（Tiling）**：在啟動時用 `ui.PictureRecorder` 離屏生成一張 `6×6`（或 `24×24` 含 4×4 點）的微小 `ui.Image`（中心畫 `r = 1.0, Color.fromRGBO(130, 150, 255, 0.07)`），建立單一常駐 `ImageShader(tileImg, TileMode.repeated, TileMode.repeated, Matrix4.identity().storage)` 填入全畫面 `Rect`（或直接放一張 `12×12 px` 2x 透明點陣 PNG 資產，用 `DecorationImage(image: AssetImage(...), repeat: ImageRepeat.repeat, scale: 2.0)`）。<br>2. **41 段短 LED 環（`gauge-variants.html:156-165`）**：預先算好 41 個角度單位向量；`paint()` 中依 `i < lit`（`#6F88FF`）、`i == lit`（`#E4E9FF`, `strokeWidth: 8`）、`i > lit`（`#232A5C`）及 `major`（`strokeWidth: 5.5` vs `4`）計算 `ri = clear + sw / 2` 到 `ro = c - sw / 2 - 0.5`，呼叫 41 次 `canvas.drawLine` | **零效能疑慮（且行駛重繪最省）**：<br>• `ImageShader`（`TileMode.repeated`）由 GPU 紋理取樣器直接平鋪整個 `844×390` 背景，只需畫 **1 個矩形（耗時 `<0.05 ms`）**，且背景與前景量表分離，車速變化時背景 **0 次重繪**。<br>• 第二段依 `R6-02` **移除了發光模糊（`MaskFilter.blur`）與內圈紅針**，消除了第一段唯一提醒過的模糊濾鏡風險；且 41 段為離散 `lit` 索引（每 `6 km/h` 一格），車速在同格內微幅波動時 `shouldRepaint` 回傳 `false`（**0 repaint**） | **S–M（因拿掉發光模糊與內圈紅針，比第一段更單純；含點陣平鋪底紋仍為 S–M，次容易）** |
| **方向 C：「扇形」**<br>• 槍灰放射漸層底 `#1D1F23 → #0A0B0D`<br>• `Barlow Semi Condensed 600` 數字 `176 / 146(140) px`（**完全收進內圈 `r=118*k` 內**）<br>• **雙層金屬漸層錶盤**：內圈半圓放射漸層 `#22252A → #1A1C20`＋`1 px` 內環細線 `#30343A`；外圈半圓刻度帶垂直線性漸層 `#3A3E45 → #26292E`<br>• 刻度帶內 25 條金屬刻度（每 10 一小格、每 40 一大格，**已刪除外圈刻度數字，`R6-02`**）<br>• 銀白 30% 扇面填色＋外緣 `#E1E6EC` 亮弧＋**外弧帶內雙層描邊紅針**（底墊 `#0D0E10` `9px` 黑邊＋上疊 `#E8344F` `5px` 紅針） | 1. **靜態金屬錶盤底層（`gauge-variants.html:177-183`）**：<br>• 內圈錶面（`#faceC`）：組上半圓 `Path`（半徑 `r = 118*k`），以 `RadialGradient(center: Alignment.bottomCenter, radius: 1.0, colors: [Color(0xFF22252A), Color(0xFF1A1C20)]).createShader(faceRect)` 填色；再畫 `r - 6*k` 的 `1 px` `#30343A` 圓弧。<br>• 外圈金屬刻度帶（`#bandC`）：組內外弧封閉半圓環帶 `Path`（`r = 118*k` 到 `R = 148*k`），以 `LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A3E45), Color(0xFF26292E)]).createShader(bandRect)` 填色。<br>• 沒資料時：不畫上述雙漸層錶面與刻度，改用預先以 `PathMetrics` 切好的虛線半圓環帶 `Path`（`5 px` 實／`8 px` 空，`#5A5F67`）描邊。<br>2. **動態扇面與外緣亮線（`:184-186`）**：`v > 0` 時組 `180°` 到 `a` 的封閉扇形 `Path` 填入 `Color(0x4DE1E6EC)`（30% 銀白），並對 `R - 2*k` 呼叫 `canvas.drawArc` 畫 `4*k px` 的 `#E1E6EC` 外緣亮線。<br>3. **25 條內置金屬刻度與雙層紅針（`:188-194`）**：畫預先算好端點的 25 條刻度線（大格 `#C3C8CF` `2.5px`、小格 `#60656D` `1.5px`）；最後在角度 `a` 的 `r + 2*k` 到 `R - 4*k` **同座標連畫兩次 `drawLine`**：先畫 `strokeWidth: 5*k + 4` 的深色描邊 `#0D0E10`，再疊畫 `strokeWidth: 5*k` 的紅針 `#E8344F` | **無效能疑慮（需快取兩組 `Shader` 與靜態座標）**：<br>• `faceShader`（放射漸層）、`bandShader`（線性漸層）、底環 `Path`、沒資料的虛線 `Path` 以及 25 條刻度的 `50` 個端點座標，都**只依賴量表尺寸 `S`（`300` 或 `280`）而不隨車速改變**！在 `CustomPainter` 中以 `Size` 為 key 快取這些物件，每次車速改變時 `paint()` 完全不需重建 `Shader` 或重算三角函數。<br>• 第二段依 `R6-02` **刪除了外圈刻度數字並將數字完全收進內圈、紅針留在外弧帶**，徹底解決了第一段「外框 `343 > 300` 超框」與「紅針穿過車速大字」兩大難題！ | **S–M（由第一段的 M 下修為 S–M！刪除外圈 `TextPainter` 與超框問題後大幅簡化；因含雙漸層 `Shader`、封閉扇形 `Path`、25 刻度與雙層紅針，在三方向中仍為步驟最多者）** |

- **同步 반영 `ux 16:15` 與 `02-visual.md` Q39 版面細節（皆為 S，已納入第 2 步共用 UI）**：
  - **S07 右欄面板（`ux 16:15 (1)`）**：高度擴展為右欄頂端到底部安全線（`844`：`x 584–769, y 16–369`；`667`：`x 485–651, y 16–359`），直接覆蓋右上齒輪、不往左侵入中央量表區；底部固定上下兩顆滿寬 `≥48 pt` 按鈕（「我已安全停車」在上、「取消」在下），上方標題與 L20 說明區在大字／英文放不下時可捲動。
  - **附近測速提醒卡與 S02／S05 說明（`ux 16:15 (2)`）**：改為單欄上下排（第一行圖示＋「附近有測速點」，第二行「點位資料速限 **60** km/h」；`667` 寬用 `Wrap` 在「點位資料速限」與「60 km/h」間自然換為第三行）。
  - **左下電量／續航多行保留槽位（`ux 16:15 (4)`）**：行車固定保留兩行高（`844`：`y 321–369`；`667`：`y 306–359`）、停車固定保留三行高（`844`：`y 300–369`；`667`：`y 286–359`，左欄中段捲動區對應收至 `y 84–296`／`y 84–282`），以 `Align(alignment: Alignment.bottomLeft)` 貼齊保留區底部；一般字級單行時行車與停車在同一水平線（`y 343–369`）切換不跳，大字或 `100% / 520 km` 折成兩行時在保留槽位內往上長，不推動上方行程或中央量表。
  - **沒資料時的虛線軌道（`02-visual.md` Q39）**：Flutter 的 `CustomPainter` 透過布林參數 `showNoDataDashedTrack` 控制沒資料時「畫虛線軌道」或「完全隱藏軌道」，無論 `ux`／`safety` 最終裁定保留虛線或完全隱藏，皆只需改一行條件分支（**0 成本切換**）。

#### 6.3 停車胎壓車子圖示（L34）第二版狀態

- `tire` 目前正依主持人指示（`team-board.md:80`）修改第二版（車身放大至約 `80×170` 以上、加強漸層玻璃感、前後光條、發光輪子膠囊＋引線端點，並維持 `L38` 四象限配置）。本次依指示先跳過，待 `tire` 完成第二版後再針對其具體 SVG／漸層／發光結構做實作與效能評估。

## 假設

- 第六輪以 L31–L38（速度表置中、三個速度表方向與各自配色／字型／質感、左下角 `/` 電量列、停車右欄胎壓俯視圖四象限）及 `01-flows.md` §7.4、`02-visual.md` §7.5–§7.7 為準，保留第一至五輪證據；只更新 `04-feasibility.md` 並在 `team-board.md` 檔尾追加，不改其他人的稿、程式碼或分支。
- 第五輪以 L28（只做橫式）、L29（拿掉鏡像）及 `01-flows.md` §7 為準，保留第一至四階段證據並更新橫式鎖定、鏡像刪除、橫式鍵盤／SafeArea／表單規則與實作順序；只更新 04 並在 team-board 檔尾追加，不改其他人的稿、程式碼或分支。
- source／session／key role 以本文件基準 commit 查核，協定語意另附固定官方來源。monitor 結論是協定允許，未完成 app 實車驗證；不以新的協定文件假裝分支已更新。
- BLE 有效優先、冷啟動一筆／GPS 備援後兩筆依 L7；只有接收時間不能充當來源時間證據。S06 自動摘要與 N2 操作資格分開；不用確認按鈕繞未知。
- L12 暫以單車、手機定位台灣、S26／S27 僅草稿排程；L8 v1 預設附近。裁定列待使用者決定的範圍仍由 lead 追蹤，本次不等待、不自行擴成多車／前方模式。
- L14 已定 iOS 商店試用、Android 本機 7 天試用且無後端；不宣稱商品、驗章、secure storage 或防重裝已完成。L1 不設安裝後領取期限，與開始後 168 小時分開。
- L15 字型打包已定；點庫隨 app 更新是本文件建議。01 已定新車成功才取代與每次點庫發布前比對／抽查；有效期長度仍待 Q24 實測。若改遠端更新，另估成本並更新 S10／Q18；不把本輪驗證要求當成已完成資料維護。
- 所有 S／M／L 都是工作類型的相對估計，不承諾實車通訊性能、套件升級成本、上架時間或道路使用安全認證。

## 待確認問題

| 項目 | 裁定／驗證對象 | 本次可繼續採用的處理 |
|---|---|---|
| 最小定位／系統設定返回、地下室限制及操作中止 | 裝置驗證；L6／L13／L17 | 政策已定：S05 只一行＋OS 設定按鈕；返回重查。無 GPS 又未配對不開設定／配對，提示到收得到 GPS 的地方停好車，限制由 lead 追蹤 |
| Monitor 的各車型／韌體可讀性、卡片等待與車上權限名稱 | 實車；01 Q1–Q3、Q6、Q7 | 保留 role 對應文案，未驗不宣稱 app 已採只讀權限 |
| 2／60 秒、來源時鐘語意、睡眠識別 | 實車；01 Q4、Q5 | 每欄來源／接收時間分開，失效 timer 獨立；timeout 不猜車休眠 |
| 點庫有效期／驗證責任人與證據、台灣位置參數 | lead 指定維護者；資料／道路實測，01 Q24、L8／L12／L16 | Q20 已列每次發布前比對／抽查與 manifest；無證據／期限不啟用，過期整卡撤。01 的 20 km 邊界緩衝、精度／位置期限仍須驗，不按 locale 猜位置；尚無有效新版維持停用 |
| iOS 商品核准／原始交易恢復／13–14 本機收據驗證，Android 保存與備份行為 | Flutter 後續實作與 sandbox；L14 | 平台機制已定，Q19 狀態稿已可畫；驗恢復不續期、未知不當已用完，Android 不承諾帳號限次／重裝限制 |
| 字型檔／授權／字寬、橫式動態排版、對稱 SafeArea 與 S14 橫式鍵盤 | visual／UX／safety／裝置驗證；L15／L19／L28／L29／L37／L38 | L29 已刪除鏡像與反射驗收；三款候選車速字型（Jost／Exo 2／Barlow Semi Condensed）皆確認為 OFL 1.1 且支援 `tabularFigures`，待老闆選定方向後打包對應字型並於實機驗收系統大字、最小 `667×375` 橫式、左右兩向翻轉不跳動與 S14 橫式鍵盤 |
| 速度表最終方向（現有／A／B／C）與停車胎壓俯視圖第二版 | 老闆（經 lead）／visual／tire；L32／L34／L35／L36／L37／L38 | 第二段已完成三方向新字型與新質感評估（A 為 S 最易、B 為 S–M、C 刪外圈數字並收進內圈後降為 S–M）；待 `tire` 完成第二版胎壓車子圖示後進行下一輪評估 |
| 自動亮度定義、舊 amber 偏好遷移 | UX／實作驗證 | auto 現未完成；若拿掉琥珀強調色，明確指定舊設定映射，不清掉其他使用者偏好 |
| L1 領取上限、L12 單車、L8 附近首發、L17 地下室限制、L5 .pen 同步 | lead 追蹤使用者決策 | 先依現行裁定估工；網頁僅草稿、不收資料；本次不改 .pen，也不擴充無資料操作例外 |


## 第六輪(胎壓圖示)— 主持人代寫

> 本節由主持人以 Claude 代 `flutter` 撰寫,因為 agy 額度用完(2026-10-19)。依據:`00-rulings.md` L34、L38、L39;`05-tire-icon.md` 第二版與 T1–T3 修訂(§5.1、§5.4、§6–§6.2);`frames/tire/car-glass.svg`、`car-ceramic.svg`;`02-visual.md` §7.8.1;`01-flows.md` §2.3、§7.4。程式基準 main `8b4acb5`、BLE `914b7c1`(用 `git show` 讀,未切分支)。只讀程式,沒有改碼,也沒有實機量測。

**結論**
- 車身用 `CustomPainter`,不加 `flutter_svg`,也不用預先匯出的點陣圖。SVG 很小,`flutter_svg` 又會把 4 處光暈畫成硬邊。四個速度表版本只換調色盤常數。
- 車圖包 `RepaintBoundary`,停車時 UI 端不重錄。不過停車畫面約每秒因 GPS 重建一次,Impeller 每幀仍會重算模糊;成本小,實機真的卡才改成快取 `ui.Image`。
- 四象限文字用一般 `Text`。在 build 裡用 `TextPainter` 量每一行的實際寬度,同一幀算出「要不要切清單」和引線端點,不必等第二幀。
- 05 的固定行框上下只剩約 2 pt,所以實際上只有系統預設字級能用四象限,iOS／Android 第一級放大字就會切到清單。這和 01 §7.4「讀值最多兩行」有落差,列待確認。
- UI 整體 **M**(比 §5 的 S–M 高一級)。資料接線算在 N4,上線要等 C03 實車通過。

### 1. 車身:`flutter_svg`、`CustomPainter`、預先點陣

兩個 SVG 各約 4.5 KB:14–15 條 path、9 個 rect、1 個 ellipse、5 個漸層(4 線性、1 放射),2 種 `feGaussianBlur`(2.2、4)用在 4 處。path 只有 M／L／Q／H／V／Z 指令。

| 項目 | `flutter_svg` 2.x 載入原檔 | **`CustomPainter`(推薦)** | 預先點陣 PNG |
|---|---|---|---|
| 光暈 | 底層 `vector_graphics_compiler` 的解析器完全不處理 `<filter>`。filter 子樹被丟掉,`filter=` 屬性被忽略,形狀照畫但**沒有模糊**。結果:地面光變成硬邊橢圓、輪胎柔光被膠囊蓋住、光條柔光變成 4 寬硬線、外輪廓淡光變成硬線(2026-10-19 查 `flutter/packages` main 的 `svg/parser.dart`) | `MaskFilter.blur` 原生支援,照 05 §6.1 | 和 Chrome 渲染一致 |
| 四版調色(02 §7.8.1) | 只能整張套 `colorFilter`(`ColorFilter.matrix` 多一個 `saveLayer`),或用 `colorMapper` 逐色換 | 調色盤當參數。A、C 的 `saturate()`／`brightness()` 事先套到色碼,執行時沒有濾鏡 | 4 種配色 × 4 種尺寸(80×160、90×180、94×188、清單 24×48)× 2x／3x,約 32 張 |
| 套件／資產 | 要新增 `flutter_svg`(`pubspec.yaml:30-39` 沒有) | 不加套件 | 要新增資產和匯出流程,可沿用 `export-pngs.sh` |
| 引線對位 | 要另算一套座標 | 車身、輪胎接點、引線用同一個縮放 | 錨點要另存常數;非整數縮放會糊 |
| 改稿 | 換檔就好,但光暈仍然失真 | path 手抄成 Dart,約 30 段 | 每次都要重匯出 |
| 結論 | 不採用 | **採用** | 只當後備:profile 證明模糊太貴時才用 |

照抄 SVG 最容易出錯的地方:

| SVG 寫法 | 照抄會錯在哪 | Flutter 做法 |
|---|---|---|
| 5 個漸層都沒寫 `gradientUnits`,預設是 `objectBoundingBox` | `glass-glass` 同時套在前擋和後窗兩條 path 上,兩者範圍不同 | 每個形狀用自己的 `path.getBounds()` 建 shader,不能用整台車的範圍 |
| `radialGradient` 套在 `ellipse rx=45 ry=74` | `RadialGradient.createShader(rect)` 會畫成正圓 | 先 `canvas.scale(1, 74/45)` 再畫圓,或給 `GradientTransform` |
| `<g opacity=".55" filter>` 包 4 個不重疊的 rect | 照抄會多一層 `saveLayer` | 把 0.55 乘進每個 rect 的顏色 alpha |
| `fill-opacity=".94"`、`stop-opacity` | 漏掉的話整台車偏亮 | 乘進漸層每一色的 alpha |
| `stdDeviation` 2.2／4 | 先 `canvas.scale` 再畫時,sigma 會不會跟著縮放,Skia 和 Impeller 要實機核對 | 每種尺寸先用 `Path.transform` 把 path 轉成 logical 座標,sigma 直接傳換算後的值(主版約 1.98／3.6,05 §6.1)。先 `clipRect` 到車圖視窗,讓模糊範圍小 |
| 兩款車的結構相同 | — | 只寫一個 painter,吃 `shape`(玻璃／陶瓷)、`palette`(4 版)、`size` 三個參數;Path 和 shader 依這三個值快取 |

**和 §5 不同的地方**
- §5 建議引線依狀態改成虛線、輪胎框依狀態變色、高對比時加粗。05 不允許這些:四輪膠囊一律相同亮度,缺值也不變色(`05-tire-icon.md:61`);引線「無動畫、無狀態變色」(`05-tire-icon.md:110`)。所以 painter 完全不需要逐輪狀態,只吃上面三個參數。這是簡化,不是衝突。
- §5 說 `flutter_svg`「不完整支援 filter,可能消失或破圖」。實際上是完全不處理:形狀照畫,只是沒有模糊。
- §5 原本請 tire 不要用 filter,否則改用「SVG 底圖 + painter」混合做法。tire 第二版保留了 filter,但圖很小,直接手寫 painter 比混合做法簡單。

### 2. 光暈與漸層的成本:什麼時候會重畫

| 什麼時候 | 會發生什麼 | 建議 |
|---|---|---|
| 停車時每筆 GPS:`bestForNavigation`、沒設 `distanceFilter`(`gps_source.dart:27-32`),約每秒一筆 | `_onReading` 每筆都 `notifyListeners`(`hud_controller.dart:60-66`),`AppShell` 的 `ListenableBuilder` 重建整個 `ParkedScreen`(`app_shell.dart:69-86`)。行程數字和時間膠囊改變,同一層的東西都會重畫 | 車圖包 `RepaintBoundary`,`shouldRepaint` 只比 `shape／palette／size`。這樣 UI 執行緒不會重錄車圖 |
| 每次合成畫面(Impeller) | Impeller 沒有 Skia 那種自動點陣快取。`RepaintBoundary` 省的是 UI 執行緒的重錄,GPU 每幀仍會重算模糊。範圍只有車圖視窗(最大 94×188 pt),大約每秒一幀,預估成本很小 | 用 profile 模式在最低階目標機看 raster 執行緒。真的卡,才把同一個 painter 用 `PictureRecorder` + `toImageSync` 轉成 `ui.Image`,依 `(shape, palette, size, dpr)` 快取,之後每幀只貼圖 |
| drive ↔ parked 切換 | `AppShell` 依模式換 `DriveScreen`／`ParkedScreen`(`app_shell.dart:73-86`),車圖的 layer 每次都重建 | 一次性成本,可以接受。如果改用 `ui.Image`,快取要放在 static map,才不會每次重算 |
| 胎壓資料或相對時間更新(每分鐘) | 只改文字和引線位置 | 引線和字底板用另一個 painter,只在端點座標改變時重畫,不碰車圖 |
| 換速度表版本、換寬度模式、換字級(切清單) | 車圖要重畫 | 很少發生,不需優化 |
| 夜間變暗(`app_shell.dart:90-97`,全畫面 28% 黑) | 只是上面多疊一層 | 不影響車圖 |

- 05 §6.1 的低效能退路照用:先拿掉地面光,保留漸層、清晰輪胎和光條;不縮字,不降對比。
- 不要對整個胎壓區用 `saveLayer` 或 `Opacity`。
- 開頭第 8 點的「停車 0 重繪」只對 UI 執行緒成立,GPU 端照上表。

### 3. 四象限文字與引線端點

做法:
- 用 `LayoutBuilder` 取側欄實際寬度來選模式:165–183 用緊湊、184–279 用主要、280 用擴寬。座標照 05 §5.1 的表。
- 每輪的文字照 05 已經拆好的行來放:輪位 1 行、數值加單位 1 行、時間 1–2 行(例如「最後量測」／「18 分鐘前」)。每行各用一個 `Text`,不靠自動換行。
- build 裡呼叫一個純函式 `layoutTirePanel(...)`,用 `TextPainter` 量每一行,回傳:(a) 要不要切清單;(b) 每行的位置和實際寬度;(c) 字底板矩形;(d) 四條引線的兩端座標。同一幀就畫對,不需要像 HTML 那樣等 `fonts.ready` 後再定位。
- 端點照 05 §6.2:
  - 前輪圓點放在最後一個可見時間行的字底板下緣再往下 4.4 pt;後輪圓點放在輪位行的字底板上緣再往上 4.4 pt。圓點半徑 1.4,外緣到字底板剛好 3 pt。
  - 圓點 x:把輪胎接點的 x 夾在那一行的實際文字範圍內(T3)。
  - 車輪端:SVG 接點 `(11|89, 53)`、`(11|89, 128)`,用和車身同一個縮放與位移換算。
  - 線長不到 8 pt 時,只沿同一條文字邊橫移起點。
  - 字底板是每行 `(left−2, top, width+4, 行高)`,上下不外擴;畫在引線上面、文字下面,不必用 `TextStyle.backgroundColor`。
- 疊層由下往上:車圖(`RepaintBoundary`)→ 引線、端點、字底板(同一個 painter)→ `Text`。
- T1–T3 已經由 tire 修好(team-board 16:58、05 §6.2)。Flutter 是把同一套做法搬過來,不是另外「根治」。

為什麼不用其他做法:

| 做法 | 問題 |
|---|---|
| 畫完後用 `GlobalKey` 讀 `RenderBox` | 要第二幀:第一幀的引線位置會錯,不然就得先藏起來 |
| `CustomMultiChildLayout` | 拿得到子元件的大小,但在 layout 階段沒辦法把整區換成清單 |
| 直接在 Canvas 上畫字 | 05 §6 規定文字要用一般 `Text` |

要注意的地方:
- **量的和畫的要一致**:`TextPainter` 要用和 `Text` 相同的有效設定,包括合併 `DefaultTextStyle` 後的樣式、`MediaQuery.textScalerOf`、`MediaQuery.boldTextOf`(iOS 粗體文字設定,`Text` 會自動加粗)、locale(`zh-Hant` 會影響中文字形)、`textHeightBehavior` 和 `FontFeature.tabularFigures()`。建議由同一個函式同時產生兩邊用的樣式。
- **測試**:widget test 用 `tester.getRect(find.text(...))` 對照算出來的矩形,跑 9 種狀態 × 3 種寬度 × 中英文 × 幾種字級,等於 Flutter 版的 `tireAudit()`。測試要先用 `FontLoader` 載入打包的 Inter 和 Noto Sans TC;`flutter_test` 預設字型的每個字都是方塊,不載入的話量到的寬度沒有意義。
- **字型**:L15 的字型寫在 `pubspec.yaml` 裡打包,引擎啟動時就註冊好,不會像 HTML 那樣字型晚到、端點錯位。不要在執行期下載字型(例如 `google_fonts` 線上抓),否則 build 時量到的是備用字型。
- **方向**:`Stack` 明確設 `textDirection: TextDirection.ltr`,用 `Positioned(left:)`,不用 `PositionedDirectional`。輪位是車輛座標,任何語系都不能左右對調(05 §6)。現在只有繁中和英文,不會遇到 RTL,這只是保險。
- **字級**:Android 14 起系統字級是非線性放大,12 pt 放大的比例比 19 pt 多。要用 `TextScaler` 物件量,不要乘一個固定倍率。現在 `lib/` 完全沒有讀 textScaler(搜尋無結果)。
- **讀屏**:車圖和引線包 `ExcludeSemantics`。每輪用 `Semantics(label: 完整句子, excludeSemantics: true)`,讀完整的 `Measurement time unknown`,不讀 165 寬的短文案。用 `OrdinalSortKey` 固定朗讀順序:胎壓 → 左前 → 右前 → 左後 → 右後 → 免責。

### 4. 什麼時候切到大字清單

05 §5.1 的上下空間幾乎用滿:

| 寬度 | 前輪標籤 y | 後輪標籤 y | 免責 y | 剩餘空間 |
|---|---|---|---|---|
| 184 | 22–90 | 176–244 | 246–288 | 約 2 pt |
| 165 | 20–88 | 160–228 | 230–272 | 約 2 pt |

- 每輪標籤高 68 pt(16+24+28),行高會跟著字級放大。放大 1.12 倍時約 76 pt,後輪標籤會壓到免責,前輪標籤會蓋到前輪膠囊。所以**照 05 的固定座標,只有預設字級(約 1.03 倍以內)能用四象限**;iOS 第一級放大(約 1.12)和 Android 1.15 都會切到清單。
- 這和 01 §7.4 的大字列(`01-flows.md:1048`)不一致。01 寫「胎壓區先維持四象限、讀值跟著放大(讀值最多兩行)」,但照 05 的座標,「放大後仍維持四象限」這一段幾乎不存在。列入待確認;本節先照 05 的固定座標。
- 判斷規則:下面三項全部成立才用四象限,否則整區換成清單。
  1. 每一行的實際寬度 ≤ 欄寬(86／76.5／134)。
  2. 每輪標籤總高沒有超過自己的固定行框(68 pt,含 2 pt 餘裕),免責 ≤ 42 pt。
  3. 引線能從字底板外 4.4 pt 連到輪胎接點,而且長度 ≥ 8 pt。
- 用每個語系「最寬的範本字串」來量,不用畫面上的即時字串。範本例如 `59 分鐘前`、`23 小時前`、`Measurement`／`time unknown`、`No reading`／`yet`;165 英文用 05 §5.4 的短文案。這樣「9 分鐘前」變「10 分鐘前」或狀態改變時,畫面不會來回切換。判斷結果只會在字級、粗體設定、語系或寬度模式改變時變動,所以不用防抖。
- 參考值:184 寬英文的 `Measurement` 是 80.19 pt(`05-tire-icon.md:151`),欄寬 86,光看寬度約 1.07 倍就會超出;165 寬英文在預設字級就已經要用短文案。
- 清單版:車身縮成 24×48(同一個 painter;這個尺寸的模糊 sigma 約 0.5 px,看不出效果,可以省略,請 visual 確認),下面依左前、右前、左後、右後排四行,在原本的 y 範圍內用 `SingleChildScrollView` 加常顯捲軸(05 §5.4「可見捲軸」),免責放最後。

### 5. 胎壓各狀態與資料模型缺口

| 狀態(01 §2.3、05 §4) | 需要的資料 | 現在的程式 | 缺口與建議 |
|---|---|---|---|
| C03 未通過 → 整區隱藏 | 功能旗標 | 沒有 | 新增旗標,預設關閉。關閉時回傳空元件,保留右欄空間,不建讀屏節點 |
| 單位不明 → 整區隱藏 | 已驗證的來源單位 | 沒有。proto 註解寫「in bar」(BLE · `vehicle.proto:650`),但還沒實車驗證 | `verifiedSourceUnit` 是 null 就隱藏;不依地區猜 |
| 不支援／四輪都缺 | 請求被拒、沒有 `TirePressureState`,或四個 `oneof` 都沒設 | 沒有 | 畫面上合併成同一個 `noData`,原因另記 log |
| 單輪缺值 `—` | 每輪用 `has*()` 判斷有沒有值 | main `Reading`(`reading.dart:3-16`)和 BLE `Reading`(BLE · `reading.dart:8-20`)都沒有胎壓欄位;mapper 也不收 `TirePressureState`(BLE · `tesla_reading_mapper.dart:10-25`) | 一定用 `hasTpmsPressureFl()` 這類方法判斷,值是 nullable,不能變成 0 |
| 量測時間未知(數值變暗) | 每輪的 `tpms_last_seen_pressure_time_*`(BLE · `vehicle.proto:656-659`) | 沒有 | 沒有這個欄位或 `seconds == 0` 都算未知。不能用接收時間或整包的 `timestamp` 代替 |
| 歷史值(超過 60 分鐘,A20) | `measuredAt` 和現在時間 | 停車畫面只在 build 時讀一次 `TimeOfDay.now()`(`parked_screen.dart:186-187`),靠每筆 GPS 重建才會更新 | 要加可注入的時鐘和每分鐘一次的 ticker,否則地下室沒有 GPS 時,「N 分鐘前」和 60 分鐘變暗都會停住。是否算歷史值在畫面上即時算,不存進資料 |
| 不判斷好壞 | — | proto 有 hard／soft warning(BLE · `vehicle.proto:660-667`) | v1 的 mapper 不要把這些欄位帶進 UI 模型(`01-flows.md:624`:v1.x 才做) |

其他缺口:
- 胎壓是慢輪詢、只在停車畫面用。建議獨立成 `TireSnapshot`(四輪各自的 `pressure`、`measuredAt`,另加 `receivedAt`),有自己的 stream／cache,不要塞進約每秒一筆的 `Reading`。C03 也要求慢輪詢不能拖慢 DriveState(05 §6)。
- 顯示單位從哪裡來還沒定。`Settings` 只有車速單位(`settings.dart:12,20`);01 A14 寫「台灣 bar、美國 psi」,05 §6 寫「語言與單位分開」。要新增胎壓單位設定,還是跟著車速單位走,待 ux 決定。換算照 05:資料層用沒取整的來源值,`psi = bar × 14.5037738`,bar 顯示一位小數、psi 顯示整數。
- 車端量測時間如果在未來(車上時鐘比手機快),01 和 05 都沒有寫怎麼顯示(L7 只管 GPS)。列待確認,本節不自行決定。
- `ParkedScreen` 目前沒有胎壓參數(`parked_screen.dart:11-24`),右欄是 280 寬的行程加時間膠囊(`parked_screen.dart:90-100`)。要先完成本輪 §1 的置中版面,胎壓區才有位置。

### 6. 工作量與實作順序

| 項目 | 量 |
|---|---|
| `TireCarPainter`:2 種車形 × 4 版配色 × 4 種尺寸,含手抄 path 和快取 | S–M |
| 量字、四象限排版、引線和字底板 painter | M |
| 大字清單、9 種狀態、讀屏 | S |
| UI 模型、時鐘 ticker、單位換算(不含 BLE 輪詢) | S |
| 測試:真字型 golden、`Text` 和 `TextPainter` 位置一致、狀態 × 寬度 × 語系 × 字級 | S–M |
| **UI 合計** | **M** |

- 比 §5 和開頭第 8 點的 S–M 高一級。多出來的工作是:依實際字框算引線、切清單的判斷規則,以及要載入真字型的 golden 與一致性測試。
- 順序:
  1. 第 2 步(L15 打包字型、§1 置中版面)完成後,用示範資料做 UI,和第 3 步並行。速度表版本還沒選也不會卡住,配色只是參數。
  2. 第 3 步 N4:接上 `TirePressureState` 的 mapper 和慢輪詢。
  3. 第 6 步:C03 實車通過才打開旗標,付費清單才列胎壓(`01-flows.md:463`)。

### 待確認(本節新增)

| 問題 | 誰決定 |
|---|---|
| 四象限只在預設字級成立,能不能接受;或修改 05 §5.1,讓標籤區可以長高 | ux、tire |
| 胎壓顯示單位從哪裡來(新設定、跟車速單位,或 A14 的地區預設) | ux |
| 量測時間在未來時怎麼顯示 | ux、safety |
| `MaskFilter.blur` 在 iOS／Android 實機的光暈是否和 05 的 PNG 一致,低階機 raster 成本多少 | 實作後實機驗證 |

## 第七輪

從這一節起 flutter 改用 Codex

2026-10-20。依據 `00-rulings.md` L41–L46、01 檔頭第七輪修訂、03「第七輪(規格)」R7-01–R7-18、05 檔頭 L46 修訂。本輪只評估規格，不等 visual、不宣稱新圖或 Flutter golden 已通過。下列程式行號皆指 `origin/feature/goal-2-ble`，本次以 `git show`／`git grep` 讀取，基準 `914b7c1`。

### 重點結論

- P／R／N／D 的解碼和 Gear 已有；缺來源新鮮度、矛盾排除、隱藏後恢復狀態與 HUD 接線。
- 胎壓原值是 bar，先乘 `14.5037738` 再取整數；四輪最後量測時間欄位已有，Reading／mapper 尚未承接。
- 細字可離線打包；Jost 340、Exo 2 320 要可變字型或預先產出的固定字重，筆畫合格與否仍須 Flutter 實量。
- 固定尺寸 Stack 可讓檔位、提醒出現消失時數字位移 0 px；資料接線 M，含 BLE 解密與實車證據整體 L。

### 1. 檔位與倒車車速

| 現在已有 | 還缺什麼 |
|---|---|
| `vehicle.pb.dart:10316` 的 `ShiftState_Type` 有 invalid／p／r／n／d／sNA／notSet；mapper `tesla_reading_mapper.dart:33` 已映射 P／R／N／D 到 `Gear.park/reverse/neutral/drive`，其餘 unknown；`reading.dart:2`、`:15` 有 Gear 和欄位 | 不必新增檔位 enum。HUD 要使用獨立的「可顯示檔位」狀態，不能只判斷 `gear != null` |
| `DriveState` 有來源 timestamp（`protocol/protobuf/vehicle.proto:178`、`vehicle.pb.dart:3287`） | `Reading.timestamp` 只有一個（`reading.dart:20`）；目前 client 傳 `DateTime.now()`（`tesla_ble_client.dart:201`），mapper 未讀 drive timestamp。須保留來源時間、收到時間、來源／連線資格，驗證來源時間語意；不能把收到時間充當新鮮證據 |
| `_speedMs` 優先取 speedFloat，否則整數 speed，再乘 0.44704（`tesla_reading_mapper.dart:27`） | 沒有 finite／負值檢查。Q29 spike 前先擋 NaN／Infinity／負值為無效，不 `abs()`、不夾成 0；合格 GPS 可備援，兩源無效顯示「—」 |

- R7-03：版面 = 車速 + 車況、BLE 可用、檔位已知且合格來源時間 ≤2 秒才顯示；GPS-only／過期／斷線／休眠／unknown／S06-f 整排隱藏。**P 且任一有效來源 ≥5 km/h** 時也隱藏，不能只檢查目前選中的車速來源。R／N／D 仍是操作閘門的移動證據，負車速無效不會把 R 變成「已停車」。
- R7-07：冷啟動第一筆合格檔位可顯示；隱藏後重置計數，收到 **2 筆不同、依序、各自新鮮** 的檔位樣本才恢復。「不同」指樣本，不要求換檔；兩筆 D 可以。重複／亂序／缺檔位／只有 ChargeState 不累計，資格中斷歸零；P 矛盾未解除也不恢復。前景恢復先重驗，不能沿用背景前的顯示資格。
- 必須有到期排程，在最後合格樣本滿 2 秒後主動隱藏，不能等下一筆 BLE 才發現過期。解密仍未完成（`tesla_ble_client.dart:181`），解析結果目前只記 log（`:206`），還要送入正式 DataSource／狀態層；現況不能稱為已能上實車顯示。

### 2. 胎壓 psi 與共用時間

- **單位有直接證據**：分支 `protocol/protobuf/vehicle.proto:650` 註解為 bar；`:652`–`:655` 的四個 float 是 `tpms_pressure_fl/fr/rl/rr`。產生碼 `vehicle.pb.dart:9639` 保留同一註解，`:9652` 起為 Dart double，並有 `hasTpmsPressureFl()` 等 presence 檢查。[Tesla vehicle-command 原始 proto](https://github.com/teslamotors/vehicle-command/blob/main/pkg/protocol/protobuf/vehicle.proto) 與 [Tesla 官方 available data](https://developer.tesla.com/docs/fleet-api/fleet-telemetry/available-data) 也標示胎壓為 bar（查閱 2026-10-20）。
- 顯示公式 `psi = bar × 100000 / 6894.757293168 ≈ bar × 14.5037738`，最後才 `round()`。例如 2.9 bar → 42.061 psi → `42 psi`；不能先把 bar 取整數。資料層保留原始精度，缺欄位或非有限／無效讀值才顯示無單位「—」，不拿 protobuf 預設 0 當收到值；不依數值判斷胎壓正常與否。固定 psi，不跟 km/h／mph 切換。
- **四輪時間已有**：proto `:656`–`:659` 的 `tpms_last_seen_pressure_time_fl/fr/rl/rr`；Dart 為 `tpmsLastSeenPressureTimeFl/Fr/Rl/Rr`（`vehicle.pb.dart:9688`、`:9699`、`:9710`、`:9721`），各有 `has...()`。還缺胎壓 request／慢輪詢、mapper 和逐輪模型 `{pressureBar, measuredAt?, receivedAt}`。TirePressureState 整包 timestamp 和收到時間都不能替代每輪量測時間。
- 共用時間照 **01 §2.3 六種情況／05 L46**：只聚合有值輪；≤15 分鐘新鮮，>15 分鐘才舊；有值卻無可信量測時間的輪優先顯示「時間未知 / Time unknown」或「部分讀值時間未知 / Some readings: time unknown」，否則取最舊有值輪；全缺顯示「尚無讀值 / No readings yet」。只暗舊／未知輪，時間行不暗；讀屏每輪唸自己的時間，共用行不重複唸。
- 用可注入 clock＋可取消的分鐘 timer 重算分鐘／小時／天，收到資料及回前景立即重算；在 >15 分鐘轉舊邊界安排更新，不等新 BLE。固定保留最多兩行時間區，置於輪位清單捲動區外；timer 隨離頁／背景暫停、dispose 取消，無須逐幀 ticker。
- 時間風險：上述 Tesla 官方頁明列 TPMS timestamp 有時區回報問題。這是 Fleet Telemetry 的已知限制，**不能直接斷言 BLE 同樣錯誤或套用 Pacific Time 修正**；C03 fixture 要核對 epoch／車輛時區／未來時間，未能確認一律時間未知。胎壓上線仍依 C03，不因欄位存在而開旗標。

### 3. 細數字打包與 golden

下表是 Google Fonts 未子集化、非斜體檔案；大小採 GitHub 顯示的約 KB，非 WOFF2 或安裝包壓縮增量（查閱 2026-10-20）。取代前文把所有字型概括為 115–210 KB 的估法。實作時只帶選定方案、必要字重和 OFL 授權。

| 字型 | 較細字重與打包方式 | 上游檔案大小 |
|---|---|---|
| Jost | `Jost[wght].ttf`，wght 100–900；R7 參考 340–400，340 用 `FontVariation('wght', 340)`；也可離線實例化成單一固定字重 | [約 132 KB](https://github.com/google/fonts/blob/main/ofl/jost/Jost%5Bwght%5D.ttf) |
| Exo 2 | `Exo2[wght].ttf`，wght 100–900；參考 300–400，320 用 `FontVariation('wght', 320)`；整百也可用固定 Light／Regular 檔 | [約 297 KB](https://github.com/google/fonts/blob/main/ofl/exo2/Exo2%5Bwght%5D.ttf) |
| Barlow Semi Condensed | 這批 Google Fonts 採固定 Regular 400／Medium 500，在 pubspec 分別登記 `weight: 400/500`，用 `FontWeight.w400/w500`；固定檔加 wght 不會產生 340 | [Regular 約 103 KB](https://github.com/google/fonts/blob/main/ofl/barlowsemicondensed/BarlowSemiCondensed-Regular.ttf)、[Medium 約 103 KB](https://github.com/google/fonts/blob/main/ofl/barlowsemicondensed/BarlowSemiCondensed-Medium.ttf) |
| Inter | `Inter[opsz,wght].ttf`，wght 100–900／opsz 14–32；參考 300–400，選定字重並固定 opsz，避免 optical size 改變墨跡；或帶相應固定 Light／Regular 檔 | [約 856 KB](https://github.com/google/fonts/blob/main/ofl/inter/Inter%5Bopsz,wght%5D.ttf) |

- `pubspec.yaml:79` 目前只有示例註解，正式資產尚未打包。可變檔登記一次，用共用數字 TextStyle 的 `fontVariations` 指定已選值；固定檔按實際字重登記，避免合成細／粗體。中英介面仍沿用 Inter／Noto Sans TC。Flutter API：[fontVariations](https://api.flutter.dev/flutter/painting/TextStyle/fontVariations.html)、[FontVariation](https://api.flutter.dev/flutter/dart-ui/FontVariation-class.html)（查閱 2026-10-20）。
- **等寬數字不因變細而取消**，仍設定 `fontFeatures: [FontFeature.tabularFigures()]`；它啟用 tnum，前提是字檔包含此功能或預設數字本來等寬，不能由這個屬性創造等寬字形。[Jost 上游](https://github.com/indestructible-type/Jost) 與 [Inter 上游](https://rsms.me/inter/) 明載 tabular 支援；Exo 2 有過 [Google Fonts 版本缺 tnum 的紀錄](https://github.com/google/fonts/issues/1500)。本輪未下載並解析四套最終打包檔，**Exo 2／Barlow 的實際細字檔與子集檔仍須驗證，不能沿用前文「全部支援」當驗收**。用選定字重逐字 TextPainter 比較 `0`–`9` advance，並驗 `111`／`888`／`147` 等寬；子集化保留 GSUB／tnum 替代字形與 layout closure。[Flutter tabularFigures API](https://api.flutter.dev/flutter/dart-ui/FontFeature/FontFeature.tabularFigures.html)（以上查閱 2026-10-20）。
- **golden 量墨跡，不用 TextPainter.width 當筆畫寬**：`FontLoader` 載入同一批本機字檔，固定引擎／平台、字重、opsz、文字縮放及畫布尺寸。844／667、日／最暗夜間、`147`／`80` 各輸出 2× PNG，以 `RepaintBoundary.toImage(pixelRatio: 2)` 取像素，量完除以 2 得邏輯 px；另用無文字背景圖定位取樣，避免把量表線算進筆畫。
- 按 03 §2.2 對 1 半高、4 下段直筆、0 左右及上下、7 斜筆取亮度剖面，以前景與當地背景亮度中點量半高寬，7 修正為垂直筆畫方向。每張驗 `max(9, 字高/12)`／`max(8.5, 字高/12)`，最細處 ≥該下限 ×0.8；筆畫中心對外側 9 px 內最亮背景 ≥7:1，字高仍 ≥105／100。這些斷言搭配 golden 比對，避免把不合格畫面更新成新 baseline；不加描邊、光暈或數字補間，日夜同字重。Chrome 推薦字重只作起點，尚未跑 Flutter golden。

### 4. 固定槽位與動態

- 共用 HUD 用固定尺寸 `Stack`：量表、車速數字、單位、上方檔位槽、下方 ▲ 槽、右欄提醒槽各自 `Positioned`。P／R／N／D 每字固定格寬高，底線／外框也預留空間；不要用條件式 Column 子項擠動車速，或讓字母變粗撐開相鄰格。A 需要下移數字時，選定版型就固定下移，不能隨檔位顯隱才移。
- 檔位只直接換或透明度過渡 **≤150 ms**；提醒 **≤200 ms**，`disableAnimations` 時皆 0 ms。保留槽位，用 `AnimatedOpacity` 或明確 `FadeTransition`，不做尺寸／位置／縮放動畫；隱藏時移除 semantics、阻止點擊。無效／矛盾檔位即刻清除語意及舊檔位，建議直接隱藏，不讓過期 P 留在淡出途中；減少動態也立即清除。
- 車速每筆直接換值，失效立即「—」，不 Tween 數字。提醒出現後靜止，無聲音、按鈕或輪換文案；保留 L46 的「附近測速點／點位資料速限」與英文 camera。R7-05 的 12／6／12 px 間距及 R7-12 的其他元素位移 0 px，用同一讀值在顯示前／中／後檢查數字墨跡外框完全一致，並驗 150／200 ms 上限及減少動態。

### 5. 工作量與先後

| 項目 | 工作量 | 先做什麼／驗證 |
|---|---|---|
| 檔位資格、逐欄時間、恢復計數、負速度過濾 | M | 先用 fixture 驗 2 秒到期、重複／亂序、只有 ChargeState、P + 任一有效源 ≥5、冷啟動與隱藏後 2 筆；再接 DataSource |
| 胎壓 mapper、換算、時間聚合／分鐘更新 | M（換算本身 S） | 先保留每輪 presence／量測時間，驗 2.9→42、≤15／>15、全缺／部分未知／混合時間與前景恢復；C03 核對單位與時區 |
| 字型資產與固定槽位／透明度 | S | 可直接用示範資料做，不等 visual；最終字重和 A 偏移待 visual 交付後寫死 |
| 真字型筆畫／對比 golden 和位移檢查 | M | 先做 667 三位數最暗夜間，確認通過再擴 844／兩位數／英文大字；新增 golden 不是本輪已完成事項 |
| BLE 解密、來源時間可信度、倒車與 TPMS 實車驗證 | L | 沿用既有解密／C03／Q29 前置工作；缺證據先維持無效或時間未知，胎壓不開旗標 |

本輪假設：字型仍由 visual 選、速度表尚未定案；沒有新增依賴的必要。上述是後續實作順序與驗收條件，本輪未改程式、未跑車機或 Flutter 渲染測試。
