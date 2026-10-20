# 方向燈能不能用 BLE 拿到?——獨立查證

研究者:signal(技術查證員);查核日:2026-10-17。不分美國/台灣。未修改程式碼。本文獨立查核,不以 09 為前提;結論與 09 一致的地方會標出,補充的地方也會標出。

## 重點結論

1. **【事實】原生 BLE 拿不到方向燈。** Tesla 最新版 `vehicle-command`(main `a4b43c1`,2026-09-25)的 `vehicle.proto`、`car_server.proto`、`vcsec.proto` 都沒有方向燈、危險警示燈或車燈狀態欄位。唯一和燈有關的是「閃燈」指令 `VehicleControlFlashLightsAction`,而且不會回傳狀態。我們分支的 `vehicle.proto`、`vcsec.proto` 和 upstream 完全一樣;`car_server.proto` 只少了 2026-06-25 新增的家長監護指令。[G1][G2][G3][G4]
2. **【事實】有四條彼此獨立的證據都指向同一個結論。** ①2024-03 有人在 issue #202 問「BLE 讀車速和方向燈」,Tesla 維護者把它併入 #52;#52 由 PR #330(2024-11-18)解決,但新增的 VehicleData 沒有方向燈。②2026-09 的 #481 有 contributor 逐檔查核後確認:兩個 domain 都沒有燈光狀態。③從 Tesla 官方 Android app 解編譯出來的 VCSEC proto(v4.20.69)裡,`VehicleStatus` 也沒有燈光欄位。④Tesla 官方 Fleet Telemetry 欄位表中,`LightsTurnSignal` 的「Vehicle Data Equivalent」是空的。[G7][G8][G9][G10][G11][F1]
3. **【推論】未公開欄位理論上存在,但不太可能藏著方向燈。** 公開 proto 確實是內部 schema 的子集(有保留欄位編號,`VehicleState` 只公開了第 74 號欄位)。但 Tesla 自己的對照表說方向燈沒有 vehicle_data 對應欄位,而且 Tesla 2025-02 把它加進 Fleet Telemetry 之後,BLE proto 改了 6 次,一次都沒加。實車 spike 可以低成本確認。[G1][G2][F1][F3]
4. **【事實+估計】零硬體只有「雲端」這條路:Fleet Telemetry 的 `LightsTurnSignal`。** 它是狀態值(Off/Left/Right/Both),變化時才推送;車端以 500 ms 分桶,欄位最小間隔 1 秒(第三方文件)。端到端延遲**找不到可靠量測**,估計是秒級。而且需要 Tesla 帳號、自架 mTLS 伺服器、虛擬鑰匙、車端連網和按量計費,和「不經雲端、免帳號」的定位衝突。麥克風聽滴答聲在技術上可行,但分不出左右,隱私成本也高,不建議。[F1][F2][F5]
5. **【結論】BLE:拿不到(信心高)。零硬體整體:有條件拿得到(只靠雲端,延遲是秒級,不能當即時提示;信心中)。** 競品方面,DriveCluster、Dashla 都明寫方向燈要 TITA 硬體;TPlayer 沒寫方向燈的資料來源。[A1][A2][A4]

## 1. 官方 BLE 協定逐檔查核

查法:clone `teslamotors/vehicle-command`(main HEAD `a4b43c1`,2026-09-25),對 `pkg/protocol/protobuf/*.proto` grep `light|turn|signal|hazard|blink|lamp|indicator|flash|headl|beam|fog`,再和分支 `origin/feature/goal-2-ble`(`914b7c1`,2026-06-24;proto 在 `1bab91b`,2026-06-10 加入)的 `protocol/protobuf/*.proto` 做 diff。Dart 產生碼 `lib/src/ble/gen/vehicle.pb.dart` 也用相同關鍵字 grep。

| 檔案 | 分支 vs upstream | upstream 最後修改 | 和燈有關的命中 | 結論 |
|---|---|---|---|---|
| `vehicle.proto` | **完全相同** | `8e16f0d`,2024-12-17 | 只有 `ChargePortColorFlashing*`(充電口燈色) | 沒有方向燈/危險警示燈/大燈。`VehicleData` 有 12 類:charge、climate、drive、location、closures、charge schedule、preconditioning schedule、tire pressure、media、media detail、software update、parental controls【事實】[G1][G4] |
| `car_server.proto` | upstream 多 5 個家長監護指令(`ed0cacc`,2026-06-25,欄位 109–113) | `ed0cacc`,2026-06-25 | `VehicleControlFlashLightsAction`(欄位 26,空訊息) | 這是「讓車閃燈」的**指令**,不回報燈號狀態。新增的家長監護指令也和燈無關【事實】[G2] |
| `vcsec.proto` | **完全相同** | `33d9cbd`,2025-05-16 | 無 | 見第 2 節【事實】[G3] |
| `vehicle.pb.dart`(分支) | 由上述 proto 產生 | — | 只有充電口燈色 enum | 和 proto 一致【事實】[G4] |

- 【事實】`DriveState` 只有:`shift_state`、`speed`、`power`、`odometer_in_hundredths_of_a_mile`、`speed_float`、導航路線摘要(目的地、到達時間/距離、塞車延誤、抵達電量、座標、更新時間)。沒有方向燈。[G1] `vehicle.proto:173`
- 【事實】`ClosuresState` 只有門、窗、天窗、上鎖、使用者在車內、中控螢幕狀態、遙控啟動、代客模式、哨兵模式、限速模式、Cybertruck 後斗蓋。沒有燈。[G1] `vehicle.proto:29`
- 【事實】在 `vehicle.proto` 最後修改(2024-12-17)之後,`car_server.proto` 又改了 4 次:PIN 管理(2025-07-30)、低功耗(2025-11-05)、保持配件供電(2026-01-15)、家長監護(2026-06-25),都沒有新增狀態欄位。[G2]
- 【事實】Tesla 在 2025-02-12 把 `LightsTurnSignal` 加進 fleet-telemetry proto(`3b4e7c0`)。之後 vehicle-command 的 proto 共改了 6 次:VCSEC 白名單(2025-05-16)、PIN(2025-07-30)、Guest key(2025-10-15,`keys.proto`)、低功耗(2025-11-05)、保持配件供電(2026-01-15)、家長監護(2026-06-25),都沒有加燈號。【推論】Tesla 有能力也有意願對外提供方向燈資料,但到目前為止(約 20 個月)只放在雲端。[F3][G1]
- 【事實】其餘 proto(`keys`、`signatures`、`errors`、`managed_charging`、`common`、`universal_message`)分支和 upstream 完全一樣,grep 也沒有燈光相關字。`4c2143a`(2026-07-16)重新產生 `.pb.go`,只多了註解,沒有新欄位。[G1]
- 【事實】upstream 其他分支(`low-power-mode`、`explain-why-no-tls`、`normalize-proto-versions`、`proxy-tests`)的 proto 差異也沒有燈光欄位。[G1]

## 2. VCSEC 通道

| 訊息 | 欄位 | 有沒有燈光 |
|---|---|---|
| `VehicleStatus`(`vcsec.proto:279`) | `closureStatuses`、`vehicleLockState`、`vehicleSleepStatus`、`userPresence`、`detailedClosureStatus` | 無【事實】[G3] |
| `ClosureStatuses`(`vcsec.proto:251`) | 四門、前後車廂、充電口、後斗蓋 | 無【事實】[G3] |
| `InformationRequestType` | GET_STATUS、GET_WHITELIST_INFO、GET_WHITELIST_ENTRY_INFO | 沒有可查燈號的請求類型【事實】[G3] |
| `RKEAction_E` | 解鎖、上鎖、遠端駕駛、自動上鎖、喚醒 | 無【事實】[G3] |
| 解編譯 VCSEC v4.20.69(Tesla Android app,2023-04-29 擷取,**超過 2 年**) | `VehicleStatus` 只有 closure、lock、sleep 三個欄位,全檔 80 個 message | 無【事實】[G11] |

- 【事實】VCSEC 是車身控制器(門鎖/鑰匙)這個 domain。`tesla-control body-controller-state` 回傳的就是這份 `VehicleStatus`,在 infotainment 休眠時也能用。[G6]
- 【推論】VCSEC 的職責是門禁和鑰匙,燈光狀態不在它的公開範圍內。官方 app 解編譯的版本也沒有,所以「VCSEC 偷偷有燈號」的可能性很低。

## 3. 未公開欄位(unknown fields)

**公開 proto 是內部 schema 的子集**。下列欄位編號是【事實】;由此推出「內部還有更多欄位」是【推論】(`reserved` 是 Tesla 刻意標出的,所以這個推論很強):

- `VehicleData` 的欄位編號是 3、4、5、8、9、15、16、19、20、21、23、24;1、2、6、7、10–14、17、18、22 都沒有公開。[G1] `vehicle.proto:14`
- `GetVehicleData` 的請求有 `reserved 5, 6` 和 `reserved 12, 13`,而且 1、9、18 號也空著。[G2] `car_server.proto:88-103`
- `VehicleState` 只公開 `guestMode = 74`【事實】;因此內部很可能還有其他欄位【推論】。[G1] `vehicle.proto:524-529`
- VCSEC 的 `FromVCSECMessage` 有 `reserved 6 to 10`,`UnsignedMessage` 有 `reserved 6,7,10,12,13`。[G3]

**但能觀察到的範圍很窄**【推論】:

- `VehicleState` 不在 `GetVehicleData` 可請求的 12 類裡(`pkg/vehicle/state.go` 也只列這 12 類),車子不會主動回傳它。我們實際能看到的,只有「已請求的子訊息裡,有沒有多出 proto 沒定義的欄位」。[G5]
- Tesla 官方 Fleet Telemetry 欄位表中,`LightsTurnSignal`、`LightsHazardsActive`、`LightsHighBeams` 的「Vehicle Data Equivalent」都是空的;`VehicleSpeed` 則對應 `drive_state.speed`。也就是說,連 Tesla 自己的 vehicle_data(REST,BLE 也是同一套分類)都沒有方向燈。[F1]
- 綜合判斷:方向燈藏在 unknown fields 裡的機率**低**【估計】。

**社群有沒有人觀察過?** 找不到可靠資料。vehicle-command 的 issues 搜尋 "unknown fields" 沒有結果。【事實】主流工具會把 unknown fields 丟掉:`tesla-control state` 用 `protojson.Format` 輸出,而 Go `protojson` 編碼器只走訪 schema 定義的欄位(`encoding/protojson/encode.go:235-259`,v1.36.6;vehicle-command 鎖 v1.34.2)。【推論】所以「沒人回報」不代表「沒有」,只是多數人根本看不到。[G6][G13]

**我們的 Dart client 看得到**【事實】:分支用 `protobuf` 6.0.0。`fromBuffer` 會把未知 tag 存進 `GeneratedMessage.unknownFields`(`UnknownFieldSet`,有 `isNotEmpty`/`asMap()`/`hasField()`),不認得的 enum 值也會放進去(`coded_buffer.dart:49, 73`)。現有 client 已經會記錄加密回應的原始 hex,但只請求 drive+charge 兩類(`tesla_ble_client.dart:104-147`)。記錄方法見第 7 節。[G12][G14]

## 4. 社群與競品證據

| 來源 | 內容 | 標記 |
|---|---|---|
| vehicle-command #202(2024-03-04,**超過 2 年**) | 開發者問:「想做 BLE app 顯示車速和燈號狀態(例如方向燈),可能嗎?」Tesla collaborator `sethterashima` 在 2024-03-08 以「duplicate of #52」關閉 | 事實 [G7] |
| #52 → PR #330 | #52 要求「BLE 讀 vehicle_data」;PR #330 "Support vehicle data over BLE" 在 2024-11-18 合併(`7457011`),#52 在 2025-01-22 關閉。這次合併正是現行 VehicleData,裡面沒有方向燈 | 事實 [G8][G9] |
| #481(2026-09-24,open) | 問車內燈和氛圍燈的狀態。2026-09-27 `ZayanKhan-12`(GitHub association 是 contributor,**不是 repo 維護者**;雇主不明)回覆:兩個 domain 都沒有燈光欄位;第三方「不能自己發明欄位編號讓車照做」;要等 Tesla 公開 protobuf | 事實(社群) [G10] |
| GitHub/Reddit/TMC 搜尋 | 沒找到任何人用 BLE 讀到方向燈。Reddit 頁面和 JSON 都被擋,DriveCluster 討論串(r/TeslaLounge `1sth0r7`)的留言無法查核 | 找不到可靠資料 |
| **DriveCluster**(美區 v3.4.0,9/30) | 原文:"turn-signal, blind-spot, and traffic-light indicators" with "optional TITA integration"。TITA 可補充 "...turn-signal, blind-spot, and traffic-light data";基本連線 "no dongle or extra hardware required" | 事實:方向燈需 TITA [A1] |
| **Dashla**(台區 v2.1.0) | 1.13.0(9/12):「胎壓面板車燈效果,煞車燈、方向燈、大燈、遠光燈即時同步顯示(**需搭配 TITA 發射器**)」;1.12.4(9/11)美區也有同樣標註。2026-03 有三則評論要方向燈,開發者 10/06 回覆「都有記下,會轉給團隊評估」,沒說藍牙能做 | 事實:方向燈需 TITA [A2][A3] |
| **TPlayer**(cn/us App Store) | 資訊卡片有「转向灯」,但**沒寫資料來源**。資料源有三種(發射器 > 藍牙 > 雲端 Fleet API),會自動融合 | 事實:來源未標示。【推論】BLE 沒有欄位,所以只可能來自 TITA 或雲端 [A4] |
| TITA 發射器 | 接原車 CAN/PING 線束,廠商宣稱約 50 ms。本次官網回 403,沿用 09 的查核 | 事實(廠商宣稱) [R1] |

## 5. 其他零硬體路徑

| 路徑 | 可行性 | 延遲/準確度 | 成本與限制 | 評估 |
|---|---|---|---|---|
| **Fleet Telemetry `LightsTurnSignal`/`LightsHazardsActive`** | 【事實】官方欄位;enum 是 Unknown/Off/Left/Right/Both(`vehicle_data.proto:264, 682`)。【事實(第三方)】Teslemetry 列最小間隔 1 秒,韌體 2025.2.6 起才有 [F1][F3][F5] | 【事實】車端 500 ms 分桶;只有「間隔已到**且**值有變」才送;斷線時最多緩存 5000 則,之後補送 [F2]。【事實】傳的是狀態,不是每次閃爍。端到端實測:**找不到可靠資料**。【估計】一般在秒級,經過「車端 LTE → 自家伺服器 → 手機網路」,沒有上限保證。【推論】小於最小間隔的短開關可能被延後或合併 | 【事實】需開發者帳號、網域和公鑰、自架 mTLS 伺服器、配對虛擬鑰匙、車主 OAuth,韌體 ≥2024.26;按訊號計費,每月有 US$10 折抵 [F2][F4][F6]。【推論】違背 brief「不經雲端、免帳號、零費用」;隧道或沒有訊號時失效;資料會經過 Tesla 和自家伺服器 | **拿得到,但不能當即時提示**。最多只能當「非安全用途的狀態回顯」,v1 不建議 |
| Fleet API REST `vehicle_data` | 【事實】官方對照表的 vehicle_data 欄位是空的 [F1] | — | — | **拿不到** |
| 麥克風偵測滴答聲 | 【推論】車內有方向燈提示音,手機麥克風收得到。但要自訓分類器,Apple 內建 SoundAnalysis 類別是否涵蓋這種聲音尚未查證 | 【估計】至少要聽到 2 聲才能判斷週期,約 1 秒以上。音樂、胎噪、雨聲會造成誤判。手機收音近似單聲道,**分不出左右**;Tesla 從哪顆喇叭播放未查到資料 | 【事實】iOS 用麥克風時狀態列會亮橘點 [P2];Android 的 `RECORD_AUDIO` 受 while-in-use 限制,不能從背景啟動麥克風前景服務 [P1]。【推論】整趟行程常開麥克風,隱私和審核說明成本高;通話時會和麥克風搶用 | **不建議**。頂多做實驗室 spike |
| 手機 IMU/GPS 推測變換車道 | 【推論】只能事後偵測橫向運動,不是駕駛的方向燈意圖 | 晚於事件,會誤判 | — | **不是方向燈**,不做 |
| 手機相機拍中控方向燈圖示 | 【推論】支架角度和 mirror mode(手機平放朝上)都拍不到,隱私成本也高 | — | — | 不可行 |
| BLE 廣播封包 | 【事實】vehicle-command 只用廣播的 local name(由 VIN 推導)比對車輛 [G15]。廣播內容帶不帶狀態:找不到可靠資料 | — | spike 時順手錄一段即可 | 機率極低,但驗證成本也低 |
| 外接 CAN 硬體(TITA 等,**非零硬體**) | 【事實(廠商)】競品實際走的路線 [R1] | 宣稱約 50 ms,未經獨立驗證 | 約 US$79.98,要拆飾板 | 參考用;沿用 09/10 的「v1.x 之後再評估」 |

## 6. 結論與信心

| 問題 | 答案 | 信心 | 最關鍵證據 |
|---|---|---|---|
| 原生 BLE(公開 proto)有沒有方向燈 | **拿不到** | **高** | 三個 proto 檔逐一 grep 皆無;分支與 upstream 一致 [G1–G4] |
| BLE 有沒有可能藏在 unknown fields | **不太可能** | 中 | Tesla 對照表 vehicle_data 無對應欄位 [F1];BLE proto 在方向燈加進 Telemetry 之後改了 6 次都沒加 [G1][G2][G3][F3];實車還沒驗 |
| 零硬體整體 | **有條件拿得到**:只靠 Fleet Telemetry 雲端,延遲秒級、沒有保證,不能當即時提示 | 中 | 官方欄位和推送規則 [F1][F2];端到端延遲沒有可靠量測 |
| 競品有沒有零硬體方向燈 | DriveCluster、Dashla **沒有**(明寫要 TITA);TPlayer 來源不明 | 高(前兩者)/低(TPlayer) | App Store 版本說明原文 [A1][A2][A4] |

和 09 的差異:09 的大方向成立。本文補上:①分支和 upstream 的逐檔版本比對;②VCSEC 和解編譯 proto 的佐證;③Tesla 官方對照表「vehicle_data 無對應欄位」;④unknown fields 的觀察方法;⑤TPlayer 不能寫成「已確認需要 TITA」,08 第 19、187 行的「三家皆透過 TITA」應改成「DriveCluster、Dashla 明寫需 TITA;TPlayer 來源未標示」。

## 7. 實車 spike 要加驗的事

不改既有驗證順序(10 §待驗證問題),只在「E2E 解密」通過後追加。每次都記錄車型年份、HW3/HW4、韌體版本、app commit。

1. **全類別請求**:12 類 `GetVehicleData` 至少各請求一次(可以分批),不要只請求 drive+charge。
2. **unknown fields 傾印**:解密後:①保留明文 hex;②遞迴走訪 `Response` → `VehicleData` → 每個子訊息,只要 `unknownFields.isNotEmpty`,就記下 `asMap()` 的 tag、wire type 和值;③用 `protoc --decode_raw` 解析同一份明文,和 `.proto` 對照,列出沒定義的 tag。
3. **燈號 A/B 對照**:停車、P 檔、安全環境下,以 1–2 Hz 輪詢 DriveState + ClosuresState(加上其他有 unknown fields 的類別),依序切換:無燈 → 左轉 → 右轉 → 危險警示燈 → 遠光燈,每種 ≥10 秒、重複 3 次。比對每個狀態的 payload 長度和欄位集合。**判定規則**:有未定義的 tag 值穩定跟著燈號變化(3 次都一致)→ 列為候選,另案評估;否則結案,寫「BLE 無方向燈,已實車確認」。
4. **VCSEC 同步觀察**:同一組切換中,發 `GET_STATUS`(對應 `body-controller-state`),並記錄車子主動推送的 `VehicleStatus`,一樣傾印 unknown fields。
5. **選做,低期待**:用 `GetVehicleData` 的保留或未使用編號(5、6、12、13,以及 1、9、18)送空的唯讀請求,記錄回應或錯誤碼。這只是觀察,不做成產品功能;#481 明確不鼓勵猜欄位,所以只做唯讀,出錯就停。
6. **選做**:燈號切換時,用 nRF Connect 之類的工具錄 BLE 廣播,確認廣播內容不隨燈號改變。
7. **如果要評估雲端**(不在 v1 範圍):另設測試伺服器,`LightsTurnSignal` 設 interval 1,記錄「車上切換時刻(影片)→ 封包 `createdAt` → 伺服器收到 → 手機顯示」四個時間點,各做 ≥20 次,報 P50/P95 和漏報數。也可以拿 TPlayer 的雲端模式對照,看它的方向燈卡片有沒有反應、延遲多少。
8. **如果要評估麥克風**(低優先):手機放在實際支架位置錄車內音訊,分有無音樂、高速和市區,順便確認提示音是否分左右喇叭。

## 假設

- 「BLE」只指 Tesla 原生 vehicle-command(VCSEC + Infotainment),不包括外接 CAN 發射器到手機的 Bluetooth。
- 以 GitHub main 為「最新版」。Tesla 內部或尚未公開的 proto 無法查核。
- 車端韌體可能有公開 proto 以外的行為,所以第 3 節只算「機率低」,不寫成「已證明沒有」,要靠第 7 節確認。

## 來源

除非另外註明,都在 **2026-10-17** 查閱。沒有標發布日的頁面寫「未標日期」。commit 日期來自 git 記錄。

- **G1** `teslamotors/vehicle-command` `pkg/protocol/protobuf/vehicle.proto` @ main `a4b43c1`(2026-09-25),最後修改 `8e16f0d`(2024-12-17):<https://github.com/teslamotors/vehicle-command/blob/a4b43c1eff0e09d77deb9f2dce97031141fe8c8a/pkg/protocol/protobuf/vehicle.proto>
- **G2** 同 repo `car_server.proto` @ `a4b43c1`,最後修改 `ed0cacc`(2026-06-25):<https://github.com/teslamotors/vehicle-command/blob/a4b43c1eff0e09d77deb9f2dce97031141fe8c8a/pkg/protocol/protobuf/car_server.proto>
- **G3** 同 repo `vcsec.proto` @ `a4b43c1`,最後修改 `33d9cbd`(2025-05-16):<https://github.com/teslamotors/vehicle-command/blob/a4b43c1eff0e09d77deb9f2dce97031141fe8c8a/pkg/protocol/protobuf/vcsec.proto>
- **G4** 本 repo 分支 `origin/feature/goal-2-ble` @ `914b7c1`(2026-06-24);proto 和 Dart 產生碼在 `1bab91b`(2026-06-10)加入:`protocol/protobuf/*.proto`、`lib/src/ble/gen/vehicle.pb.dart`。用本地 `git show` 查核。<https://github.com/huangc28/tsla-speed-meter/blob/914b7c1b0f7150b2fc88988e37d1d4c245a834ea/protocol/protobuf/vehicle.proto>
- **G5** 同 repo `pkg/vehicle/state.go` @ `a4b43c1`(12 個 StateCategory):<https://github.com/teslamotors/vehicle-command/blob/a4b43c1eff0e09d77deb9f2dce97031141fe8c8a/pkg/vehicle/state.go>
- **G6** 同 repo `cmd/tesla-control/commands.go` @ `a4b43c1`(`body-controller-state`、`state` 用 `protojson` 輸出):<https://github.com/teslamotors/vehicle-command/blob/a4b43c1eff0e09d77deb9f2dce97031141fe8c8a/cmd/tesla-control/commands.go>
- **G7** Issue #202,2024-03-04 開,2024-03-08 關(**超過 2 年**):<https://github.com/teslamotors/vehicle-command/issues/202>
- **G8** Issue #52,2023-11-20 開(**開啟日超過 2 年**),2025-01-22 關(未滿 2 年):<https://github.com/teslamotors/vehicle-command/issues/52>
- **G9** PR #330 "Support vehicle data over BLE",2024-11-18 合併,`7457011`:<https://github.com/teslamotors/vehicle-command/pull/330>
- **G10** Issue #481,2026-09-24 開;contributor 回覆 2026-09-27:<https://github.com/teslamotors/vehicle-command/issues/481>
- **G11** `trifinite/vcsec-archive` `protos/VCSECv4.20.69.proto` @ `520b073`(2023-04-29,**超過 2 年**;從 Tesla Android app 解編譯,Project TEMPA):<https://github.com/trifinite/vcsec-archive/blob/520b0739a700c384bf8e07089e99bb0003a8dfaa/protos/VCSECv4.20.69.proto>
- **G12** Dart `protobuf` 6.0.0(分支 `pubspec.lock`):`lib/src/protobuf/generated_message.dart:76`(`unknownFields`)、`coded_buffer.dart:49, 73`。查本地 pub cache:<https://pub.dev/packages/protobuf/versions/6.0.0>
- **G13** Go `google.golang.org/protobuf` v1.36.6 `encoding/protojson/encode.go:235-259`(只走訪已知欄位,沒有呼叫 `GetUnknown`)。查本地 module cache;vehicle-command `go.mod` 鎖 v1.34.2。<https://github.com/protocolbuffers/protobuf-go/blob/v1.36.6/encoding/protojson/encode.go>
- **G14** 本 repo `lib/src/ble/tesla_ble_client.dart` @ `914b7c1`:<https://github.com/huangc28/tsla-speed-meter/blob/914b7c1b0f7150b2fc88988e37d1d4c245a834ea/lib/src/ble/tesla_ble_client.dart>
- **G15** vehicle-command `pkg/connector/ble/ble.go` @ `a4b43c1`(beacon 用 local name 比對):<https://github.com/teslamotors/vehicle-command/blob/a4b43c1eff0e09d77deb9f2dce97031141fe8c8a/pkg/connector/ble/ble.go>
- **F1** Tesla Fleet Telemetry Available Data,未標日期。`LightsTurnSignal`/`LightsHazardsActive`/`LightsHighBeams` 的 Vehicle Data Equivalent 欄空白;頁面是前端渲染,以 WebFetch 擷取的渲染文字為準:<https://developer.tesla.com/docs/fleet-api/fleet-telemetry/available-data>
- **F2** Tesla Fleet Telemetry Overview,未標日期(500 ms 分桶、interval 加變化才送、緩存 5000 則、韌體 ≥2024.26):<https://developer.tesla.com/docs/fleet-api/fleet-telemetry>
- **F3** `teslamotors/fleet-telemetry` `protos/vehicle_data.proto` @ `3d366a3`(2026-09-24),`:263-265`、`:682`;`LightsTurnSignal` 在 `3b4e7c0`(2025-02-12)加入:<https://github.com/teslamotors/fleet-telemetry/blob/3d366a3da23c41b6fe4eb538409d071402c4884b/protos/vehicle_data.proto>
- **F4** `teslamotors/fleet-telemetry` README,未標日期(虛擬鑰匙配對、"transmitted on change, but not more frequently than the configured interval"):<https://github.com/teslamotors/fleet-telemetry>
- **F5** Teslemetry Telemetry Fields(**第三方**),未標日期(最小間隔 1 秒、韌體 2025.2.6):<https://teslemetry.com/docs/topics/telemetry-fields>
- **F6** Tesla Fleet API Billing and Limits,未標日期(每月 US$10 折抵):<https://developer.tesla.com/docs/fleet-api/billing-and-limits>
- **A1** DriveCluster for Tesla,美區 App Store,v3.4.0(9/30):<https://apps.apple.com/us/app/id6762794279>
- **A2** Dashla,台區 App Store,v2.1.0;1.13.0 版本說明 9/12;評論 2026-03-16/18/23,開發者回覆 10/06:<https://apps.apple.com/tw/app/id6760206753>
- **A3** Dashla,美區 App Store(1.12.4,9/11):<https://apps.apple.com/us/app/id6760206753>
- **A4** TPlayer for Tesla,中國區 App Store(美區 v1.11.0):<https://apps.apple.com/cn/app/id6759967612>、<https://apps.apple.com/us/app/id6759967612>
- **P1** Android Foreground service types — microphone,頁面更新 2026-10-16:<https://developer.android.com/develop/background-work/services/fgs/service-types>
- **P2** Apple Support「About the orange and green indicators in your iPhone status bar」,未標日期:<https://support.apple.com/en-us/108331>
- **R1** 沿用 09 的 S10/S11(TITA 產品頁,未標日期;本次直接抓取回 403):<https://www.hellotita.com/products/tita-tesla-data-transmitter>
