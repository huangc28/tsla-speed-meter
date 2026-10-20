# 車輛資料技術可行性審查

> **修訂(2026-10-17)**：依 07 新增的共用 ID 與 10 的優先順序，補 X05「目前道路／國道里程數」及 X06「後方影像常駐／電子後視鏡」。X05 需 GPS＋道路／里程圖資匹配；X06 沒有本次驗證的公開原車影像介面，另裝相機屬不同硬體方案。原 D01–D28 與 BLE 查核結論保留。

研究者：risk（本次角色：技術可行性）；查核日：2026-10-17。依 `00-brief-data-needs.md`，不分市場；未修改程式碼。

## 重點結論

1. 【事實】原生 BLE schema 有速度、檔位、功率、電量、續航，以及導航摘要、胎壓、內外溫等；沒有方向燈、盲點、TACC、AP/FSD 狀態欄位。[C1][C2]
2. 【事實】指定分支只映射五項，client 尚未完成加密回應解密與資料輸出；「schema 可讀」不等於 repo 已能持續顯示。[C3][C4]
3. 【估計】先以 DriveState **1–2 Hz** 驗證；社群單次往返約 **270–500 ms**，沒有官方 10 Hz 或端到端延遲保證。[S2]
4. 【事實】「方向燈／定速／遠光燈／溫度都只有 CAN」不成立：Fleet **Telemetry 雲端**已有部分欄位；但其延遲與斷線補送不適合當即時安全警示。[S6][S7]
5. 【推論】零硬體可增加簡短車況與導航摘要；原車轉彎影像、完整周遭視覺化拿不到已驗證公開來源，盲點／AP 接手提示若做，需另案驗證 CAN 硬體。[S10]

## 可行性總表

**讀表方式。**「BLE」專指車輛原生 vehicle-command／CarServer，絕非 CAN 發射器到手機的 Bluetooth。「雲端」包含 Fleet REST 與 Fleet Telemetry，後者不是 REST 輪詢。來源與欄位屬【事實】，未取得實車值者只確認介面存在；所有標「估」的頻率均為**建議實驗排程，不是已測性能或感測器更新保證**。車已醒、連線／session 已建立時，BLE 單次往返參考 0.27–0.5 秒；冷連線先預留數秒，含喚醒可能更久，沒有可靠的時間上限。頻率不能全表同時相加執行，見下一節。[C1][C2][C3][C4][C5][S1][S2][S5]

行駛中可用性是【推論】：以**零硬體、本地 GPS／BLE 路線完成實作並通過新鮮度驗證後**判定；「適合」不代表目前已交付，也不要求把全部資料一起放入 drive。慢變數的「即時顯示」意指顯示最近有效讀值，不能宣稱即時感測。雲端／CAN 替代方案另外說明。D02／D12 需要地圖或導航服務，不能硬歸為「手機 GPS」；另列「開放圖資／授權導航 SDK」。

| ID／資料點 | 來源／拿不拿得到 | message.欄位（BLE 為實際 Dart 名稱） | 更新頻率／多快拿到 | 行駛中可用性 | 備註／證據 |
|---|---|---|---|---|---|
| D01 車速 | 手機 GPS；BLE 可取 | `DriveState.speedFloat`，備用 `DriveState.speed` | 估：GPS 約 1 Hz；BLE 1–2 Hz；有效定位前無到值時間保證 | 適合行駛中即時顯示 | BLE 單位 mph，mapper ×0.44704 得 m/s；GPS 已實作，但 OS 不保證固定頻率。BLE 五項之一。[C1][C3][C5][S2][S15] |
| D02 道路速限 | 開放圖資／授權地圖＋GPS；BLE 拿不到 | BLE 無。OSM `maxspeed` 等道路屬性 | 估：定位約 1 秒比對一次；圖資新鮮度另計 | 適合行駛中即時顯示（完成道路匹配後；v1 已延後） | `ClosuresState.speedLimitMode`／`SpeedLimitMode.currentLimitMph` 是車輛限速設定，不是道路速限；測速點 `limit` 也不是全道路資料。施工／時段速限與路段匹配須另驗。[C1][S13][S17] |
| D03 固定測速提醒 | 開放資料＋手機 GPS 可做 | 警政署 CSV `Longitude`、`Latitude`、`direct`、`limit`；BLE 不需要 | 估：離線點庫每次 GPS 更新計算，約 1 Hz；點庫不定期更新 | 適合行駛中即時顯示（簡短距離／點位速限） | 已有定位後可當次計算；幾何直線距離不是沿道路距離，無地圖匹配難分平行道路／高架。定位無效即停止可信距離提示。[C5][S13] |
| D04 檔位 | BLE 可取 | `DriveState.shiftState` → `ShiftState` oneof `p/r/n/d` | 估：與速度同批 1–2 Hz；換檔可能下一輪才看見 | 適合行駛中即時顯示 | 已映射；缺欄位／invalid 是 unknown，不能猜 P，R 顯示也不能取代倒車即時資訊。[C1][C3] |
| D05 方向燈 | 原生 BLE 無；雲端有；CAN 硬體有供應商宣稱 | BLE 無；Fleet Telemetry `LightsTurnSignal`、`LightsHazardsActive` | 雲端：500 ms 分桶＋欄位間隔＋網路；CAN：TITA 宣稱約 50 ms，未獨立驗證 | 不適合（目前零硬體即時提示）；CAN 驗證後再評估 | 不是「只有 CAN 才有欄位」，但雲端不能保證捕捉短事件；燈號狀態也不等於每次閃爍相位。[C1][C2][S6][S7][S10] |
| D06 盲點／側後方來車 | BLE 無；CAN 硬體可取得部分盲點狀態（廠商宣稱）；完整來車物件未證實 | BLE 無；`BlindSpotCollisionWarningChime` 只是雲端偏好設定 | CAN：TITA 約 50 ms 為整體宣稱，逐訊號頻率未知 | 不適合（目前方案）；不能把未知畫成「無車」 | 沒有公開 BLE 盲點偵測欄位；雲端開啟盲點鏡頭／警告音設定不是當下來車。[S6][S10] |
| D07 定速／TACC 設定速度 | BLE 無；雲端有；CAN 路徑待 SDK／實車確認 | BLE 無；Fleet Telemetry `CruiseSetSpeed` | 雲端：分桶＋欄位間隔＋網路，無端到端 SLA；CAN 單項未知 | 不適合（目前 BLE 路線）；即時替代來源驗證後再評估 | 設定速度不是「TACC 正在控制」；不能由數值存在推斷啟用。[S6][S7] |
| D08 AP／FSD 啟用、可用、接手 | BLE 無；本次未找到公開 Fleet 對應完整即時狀態；CAN 廠商有部分宣稱 | BLE 無；TITA 宣稱 AP status／hands-on reminders，未公開欄位契約 | CAN：逐項更新／最壞延遲未知，不接受整體 50 ms 當接手提示證明 | 不適合 | AP 狀態、FSD 可用、接手警告須分開驗證；累計自駕里程不是目前狀態。不能承諾完整複製原車警示。[C1][C2][S6][S10] |
| D09 電量 % | BLE 可取 | `ChargeState.batteryLevel`、`ChargeState.usableBatteryLevel` | 估：5–15 秒輪詢；同批取兩值不增加一次往返 | 適合行駛中即時顯示（低頻摘要） | mapper 已用 batteryLevel；usable 與總 SOC 意義不同，不能任意切換標籤。[C1][C3] |
| D10 續航 | BLE 可取 | `ChargeState.batteryRange`、`ChargeState.estBatteryRange`、`ChargeState.idealBatteryRange` | 估：5–15 秒；車端估算變化率未證實 | 適合行駛中即時顯示（低頻摘要） | mapper 只用 batteryRange，單位 miles；不同續航模型要標明，不能當必定可達距離。[C1][C3] |
| D11 功率／回收 | BLE 可取粗略功率；CAN 可另取更細訊號 | `DriveState.power`（int32，kW） | 估：隨 DriveState 1–2 Hz；非高頻連續功率曲線 | 適合行駛中即時顯示（粗略功率條） | 已映射，故「100% 必須 CAN」錯誤。正負號與回收意義須對原車驗證；不能推得精準電池端功率或回收可用上限。[C1][C3] |
| D12 下一轉彎／距離／車道 | 原車 BLE 拿不到；可自建手機導航，需圖資／導航 SDK | BLE 無 maneuver／lane；外部 Routes API `routes.legs.steps.navigationInstruction`、`distanceMeters` | 估：有路線後以定位約 1 Hz 推進；規劃／重算延遲、車道覆蓋依服務 | 不適合（目前原車資料路線）；自建導航完成後可另評 drive | `DriveState.activeRouteCoordinates` 是目的地座標，不是下一轉彎；Fleet `RouteLine` 折線也不是車道指示。不能讀取另一個手機 app 畫面當正式資料介面。[C1][S6][S18] |
| D13 ETA／剩餘距離／抵達電量 | BLE 可取原車路線摘要 | `DriveState.activeRouteMinutesToArrival`、`activeRouteMilesToArrival`、`activeRouteEnergyAtArrival`；另有 `activeRouteDestination`、`lastRouteUpdate` | 估：DriveState 已輪詢時隨同取得；只為導航查詢可降至 5–10 秒；原車計算更新可能更慢 | 適合行駛中即時顯示（簡短摘要） | ETA 可由現在時間＋剩餘分鐘推算；energyAtArrival 對應預估抵達百分比。無有效導航就隱藏，不能以缺值 0% 製造警報；尚未映射。[C1][S6] |
| D14 時間 | 手機本身即可 | 系統時鐘；無需 BLE | 估：秒顯示 1 Hz／分鐘到分鐘邊界更新；本地立即可得 | 適合行駛中即時顯示 | 顯示時間與行程耗時分開；後者用單調時鐘，避免校時跳變。【推論】 |
| D15 四輪胎壓 | BLE 可取，車型／感測器相容待驗 | `TirePressureState.tpmsPressureFl`、`tpmsPressureFr`、`tpmsPressureRl`、`tpmsPressureRr`；各有 `tpmsLastSeenPressureTimeFl/Fr/Rl/Rr` | 估：查詢 10–30 秒；實際感測更新可能更慢／停車不更新 | 適合行駛中即時顯示（摘要＋讀值年齡） | 單位 bar；「更快問」不會讓 TPMS 更快量。另有每輪 `tpmsHardWarning*`／`tpmsSoftWarning*`；不能宣稱取代原車即時胎壓告警。[C1][S14] |
| D16 車輛警示 | BLE 可取門／胎壓部分；雲端可取部分安全帶；完整故障警示未證實 | `ClosuresState.doorOpenDriverFront` 等六門／廂欄位，詳 D22；`TirePressureState.tpmsHardWarningFl` 等；雲端 `DriverSeatBelt`、`PassengerSeatBelt` | 估：門狀態 1–2 秒查詢（占用輪詢額度）；胎壓依 D15；雲端無固定延遲 | 適合行駛中即時顯示（只限已驗證的門／胎壓摘要）；完整警示不適合 | Fleet 官方明列 PassengerSeatBelt 誤報第二排中央座位，不能當前乘客可靠狀態；REST `recent_alerts` 是近期歷史。沒有完整故障燈 BLE message，未收到≠沒有故障。[C1][S6][S8] |
| D17 大燈／遠光燈 | BLE 無；雲端可取遠光；CAN 可另驗低／遠光 | BLE 無；Fleet Telemetry `LightsHighBeams` | 雲端：分桶＋欄位間隔＋網路；CAN 逐項未知 | 不適合（目前 BLE 路線） | 已確認遠光雲端欄位；不能從它推斷近光／所有燈具。其存在也不證明高頻顯示可靠。[S6][S7] |
| D18 車外溫 | BLE 可取 | `ClimateState.outsideTempCelsius` | 估：10–30 秒；車端感測更新率未知 | 適合行駛中即時顯示（低頻摘要） | 是車外溫度，不是路面溫度／結冰偵測；尚未映射。[C1] |
| D19 本趟行程 | 手機可算里程／時間；原車平均能耗未找到完整 BLE 欄位 | GPS 速度／位置積分；BLE 可用 `DriveState.odometerInHundredthsOfAMile` 差值、`power` 積分估計 | 估：里程／時間 1 Hz 計算；平均能耗隨有效樣本重算 | 只適合停車時（完整統計）；簡短里程可另評 drive | app 行程≠Tesla Trip A/B。斷線／停等／功率定義會影響能耗；`ChargeState.chargeEnergyAdded` 是充電量，不能冒充行車耗電。[C1][C5] |
| D20 總里程 | BLE 可取 | `DriveState.odometerInHundredthsOfAMile` | 估：5–10 秒即可；同 DriveState 可順帶讀 | 只適合停車時 | ×0.01 為 miles，換 km 再 ×1.609344；欄位存在仍須實車驗單位／支援，尚未映射。[C1] |
| D21 充電 | BLE 可取 | `ChargeState.chargingState`、`chargerPower`、`chargerVoltage`、`chargerActualCurrent`、`chargeRateMphFloat`／`chargeRateMph`、`minutesToFullCharge`／`minutesToChargeLimit` | 估：充電且 app 使用中每 5–15 秒；不為看充電而持續喚醒停放車 | 只適合停車時 | kW、V、A、miles/hour 是不同量；「加回續航速度」不是電功率。停放背景策略見下節。[C1] |
| D22 門／廂／窗 | BLE 可取 | `ClosuresState` 的 `doorOpenDriverFront`、`doorOpenDriverRear`、`doorOpenPassengerFront`、`doorOpenPassengerRear`、`doorOpenTrunkFront`、`doorOpenTrunkRear`；`windowOpenDriverFront`、`windowOpenPassengerFront`、`windowOpenDriverRear`、`windowOpenPassengerRear` | 估：有需要時 1–2 秒；一般停車頁可降至 5–10 秒 | 只適合停車時（完整車況圖）；行駛門未關摘要見 D16 | 窗是開／關狀態，不保證開啟百分比。[C1] |
| D23 周遭車輛／車道視覺化 | 拿不到已驗證的完整公開來源；CAN 部分警示≠完整視覺化 | BLE 無車道／物件清單；Fleet 未找到相應完整場景 | 無可估計更新率 | 不適合 | TITA 的盲點／AP 圖示不能證明能取到完整原車 3D 物件座標。不能以裝飾動畫偽裝真實偵測。[C1][C2][S6][S10] |
| D24 跟車距離／FCW | 雲端可取「設定」；實際車距／當前 FCW 事件無本次驗證的公開介面，CAN 候選 | BLE 無；Fleet `CruiseFollowDistance`、`ForwardCollisionWarning` | 設定可低頻讀；實際距離／警示事件頻率未知 | 不適合（即時車距／碰撞警示） | 前者是選定跟車級距，後者在官方資料表指碰撞警示敏感度；均不能當公尺車距／警報正在發生。[S6][S9] |
| D25 轉彎／倒車影像 | 拿不到公開 BLE／Fleet 原車即時影像介面 | 無 video stream／frame 欄位 | 無可估計更新率 | 不適合 | CAN 狀態資料也不等於相機影像。副廠新增相機＋有線／Wi-Fi 影像鏈路是另一套硬體來源，不能稱解鎖原車影像。[C1][C2][S8] |
| D26 媒體／音樂 | BLE 可取文字／播放狀態；封面與歌詞沒有對應欄位 | `MediaState.nowPlayingArtist`、`nowPlayingTitle`、`mediaPlaybackStatus`；`MediaDetailState.nowPlayingAlbum`、`nowPlayingElapsed`、`nowPlayingDuration` | 估：2–5 秒查詢；播放進度可本地外推，但需校正 | 只適合停車時（列表／歌詞等）；簡短歌名可另評 drive | 封面／歌詞須外部服務與識別，不能把競品封面歸功於 VehicleData。讀取不代表已實作播放控制。[C1][C2] |
| D27 空調／車內溫 | BLE 可取 | `ClimateState.insideTempCelsius`、`driverTempSetting`、`passengerTempSetting`、`fanStatus`、`isClimateOn`、`isAutoConditioningOn` | 估：10–30 秒；調整後另取有效回應 | 只適合停車時（完整面板）；溫度摘要可另評 drive | 本報告只確認讀取；不因此承諾空調控制。尚未映射。[C1] |
| D28 性能數據 | 手機 IMU 可算手機 G；BLE 無馬達／電池溫度；雲端有部分溫度／加速度，CAN 候選 | BLE 無；Fleet `DiStatorTempF/R/REL/RER`、`ModuleTempMax/Min`、`LateralAcceleration`／`LongitudinalAcceleration` | 估：手機 IMU 20–50 Hz 起測；雲端依設定與網路；CAN 單項未知 | 只適合停車時（檢視紀錄） | IMU 須去重力、校準安裝座標，不能當精準車身 G；`ClimateState.batteryHeater` 是開關，非電池溫度。溫度有雲端來源，不是只有 CAN。[C1][S6][S16] |

**沿用 08 已公告的 X01–X04 與 07 新增的 X05–X06，沒有另占新編號。**複合資料點拆解如下，不能因其中一項可取就判整列全可取。

| ID／資料點 | 來源／拿不拿得到 | message.欄位 | 更新頻率／多快拿到 | 行駛中可用性 | 備註／證據 |
|---|---|---|---|---|---|
| X01 紅綠燈號誌提示 | 原生 BLE 無；TITA 產品有號誌宣稱，CAN 解碼來源／SDK 未證實；道路號誌開放資料須另查覆蓋 | 無已驗證 BLE 欄位 | 實際號誌延遲／識別範圍找不到可靠資料 | 不適合 | 販售標題有「紅綠燈」不代表取得路口控制器真實燈態，更不代表可以起步；本次不把廠商說法升格為可交付能力。[C1][C2][S11] |
| X02 煞車燈／Hold | BLE 無；CAN 候選；雲端只有部分相近訊號 | Fleet `BrakePedal`、`BrakePedalPos`；無已驗證 BLE brake-light／Hold 欄位 | 雲端延遲依 S7；CAN 單項未知 | 不適合（目前路線） | 踩煞車、煞車燈點亮、回收煞車、Hold 是不同狀態；不能互相推定，更不能由零速猜 Hold。[S6] |
| X03 天氣／海拔／指南針 | 手機 GPS／感測器；BLE 有海拔／航向；天氣另用開放資料或服務 | `LocationState.geoElevation`、`geoHeading`／`heading`；手機位置與磁力計；氣象署資料 | 估：航向／高度約 1 Hz 起測，磁力計可更快；天氣快取 10–30 分鐘（非供應商更新保證） | 只適合停車時（完整天氣）；簡短航向可另評 drive | 航向是移動方向，不等於靜止手機指向；車內磁干擾／GPS 高度誤差須驗。BLE 氣溫不等於天氣預報。[C1][S15][S16][S19] |
| X04 CarPlay／Android Auto | 不是車輛資料點；原生 BLE VehicleData 拿不到投屏，需手機平台 SDK＋相容接收端 | 無 VehicleData 欄位；CarPlay／Android for Cars 模板介面另案 | 無通用更新率；取決於接收端、平台與資料來源 | 不適合（目前 v1 路線）；合規車用模板另案評估 | 不是讓任意 Flutter 儀表畫面直接鏡像。需符合平台類別／權限與模板，也不能假設副廠接收器一定開放第三方整合。[S20][S21] |
| X05 目前道路／國道里程數 | 手機 GPS＋開放道路／里程圖資可做部分範圍；不是 BLE 直接回傳道路／樁號 | BLE 可提供定位 `LocationState.latitude`、`LocationState.longitude`、`LocationState.heading`；無已確認當前道路／樁號欄位。外部 OSM `name`／`ref`、國道標誌座標／方向／里程 | 估：有效定位後約 1 Hz 做本地匹配；首次定位、網路反查延遲無保證，圖資更新另計 | 適合行駛中即時顯示（短道路名／約略樁號，限匹配通過的路段）；10 列為之後 | 【事實】官方有「國道交通標誌位置」候選資料；本次未驗完整 CSV／覆蓋率。【推論】須道路幾何、方向與線性里程參照，不能把最近標誌當目前里程。`LocationState.locationName` 未確認有當前道路語意，`DriveState.odometerInHundredthsOfAMile` 是車輛總里程。隧道／平行路匹配不確定時隱藏；不能當救援精確定位。[C1][C5][S25][S26] |
| X06 後方影像常駐／電子後視鏡 | 拿不到本次驗證的公開 BLE／Fleet **原車即時影像**來源；另裝相機＋影像接收器技術上是另一硬體路徑 | VehicleData／GetVehicleData 無 video stream／frame 欄位；CAN 狀態也不提供此影像介面 | 原車公開路徑無可估計 Hz／延遲；外加相機須逐幀實測端到端年齡、掉幀／凍結，無通用保證 | 不適合（目前零硬體路線；不提供電子後視鏡替代） | 【事實】原車中控可開後鏡頭，不表示手機可讀取同一串流。【推論】另裝相機不能稱「解鎖原車後鏡頭」，不得用舊影像維持正常顯示；也不能由「CAN 無影像」推成所有硬體永遠做不到。沿用 D25 的公開介面限制，10 列不做。[C1][C2][S8][S27] |

## BLE 輪詢頻率與限制

### 介面存在、程式接通、資料夠新，是三個不同驗收點

- 【事實】本次固定查核 `origin/feature/goal-2-ble` 的 commit **`914b7c1b0f7150b2fc88988e37d1d4c245a834ea`（2026-06-24）**。下列命令已實際讀取：[C1][C2][C3][C4]

  ```sh
  git show origin/feature/goal-2-ble:lib/src/ble/gen/vehicle.pb.dart
  git show origin/feature/goal-2-ble:lib/src/ble/gen/car_server.pb.dart
  git show origin/feature/goal-2-ble:lib/src/ble/tesla_reading_mapper.dart
  git show origin/feature/goal-2-ble:lib/src/ble/tesla_ble_client.dart
  git show origin/feature/goal-2-ble:lib/src/ui/spike_screen.dart
  git show origin/feature/goal-2-ble:lib/src/ble/ble_transport.dart
  ```

- 【事實】`GetVehicleData` 可選 **12** 個子請求：`getDriveState`、`getChargeState`、`getClimateState`、`getLocationState`、`getClosuresState`、`getChargeScheduleState`、`getPreconditioningScheduleState`、`getTirePressureState`、`getMediaState`、`getMediaDetailState`、`getSoftwareUpdateState`、`getParentalControlsState`。`VehicleData` 有相應子狀態；**沒有 `getVehicleState`**。該版 `VehicleState` 只有 `guestMode`，不能套用 Fleet REST 同名 `vehicle_state` 的廣泛內容。[C1][C2]
- 【事實】mapper 只映射 D01、D04、D09、D10、D11。client 每次要求 drive＋charge，`readVehicleData()` 發送後直接 `return null`；加密回應分支只記錄密文，明文分支只解析並記 log，尚未把有效讀值串回 HUD。明文 mapper 的 timestamp 用 `DateTime.now()`，只表示接收時刻，未保留各 state 的來源時間。spike 的 **100 ms** 間隔量的是「送出請求」，不能當「10 Hz 成功讀值」。[C3][C4]
- 【事實／推論】官方協定的 BLE notification 是**回應封包的傳輸機制**，不是 VehicleData 自動推播訂閱。官方文件要求 write with response；spike 使用 `withoutResponse: true`，也須先驗正確性。協商 MTU／分段與大回應可能影響耗時；2024-07-22 issue #279 有 MTU／回應過大案例，已超過兩年，僅當歷史測試線索，不能推定所有新車仍有同一限制。[C4][S1][S3]

### 可用的實測線索與合理起點

| 證據／日期 | 實際支持什麼 | 不能推出什麼 |
|---|---|---|
| vehicle-command issue #414，2025-07-30 開啟；2025-12-24 另有回覆 [S2] | 【事實：使用者回報】GetDriveState 平均約 270–300+ ms；一份分解為 1＋2＋265＋41＝309 ms；另一使用者回報約 500 ms。暖連線往返可先以 0.27–0.5 秒作估算。 | 不是 Tesla SLA，樣本不足以代表所有手機／車型；50–100 ms 是討論中的期望，非驗證結果。 |
| ESPHome Tesla BLE 專案，發布日期未標；2026-10-17 查閱 [S4] | 【事實：專案預設】VCSEC 10 秒；infotainment 醒車 30 秒、活動中 10 秒，醒車觀察窗 660 秒。 | 家用狀態整合的預設不等於 HUD 的最高 Hz，也不證明 2 Hz 一定耗掉多少電。 |
| TeslaBleHttpProxy，發布日期未標；2026-10-17 查閱 [S5] | 【事實：專案設計】冷連線需數秒；預設端點快取 30 秒，GetData 可不主動 wake。 | HTTP 回應很快可能只是快取；不能當車輛資料低延遲實測。 |

【估計】若完全串行、每次回應耗時 0.27–0.5 秒，理想上限約 **2–3.7 次完整回應／秒**，尚未扣除間隔、重試、解密與多子狀態成本。建議先量 **1 Hz、2 Hz**，有餘裕再試 3 Hz；**現有證據不足以承諾穩定 5–10 Hz**。例如五個分開請求各耗 0.3 秒，一輪至少 1.5 秒；不能說五種狀態都能各跑 2 Hz。合併 GetVehicleData 可減少往返，但封包大小／車端準備耗時也要實測。[S2][C2]

【推論／建議】排程以 DriveState 優先，其他狀態分批降頻；在速度更新壓力下允許慢欄位延後。表中 5–30 秒是各項建議量級，實際排程必須量測合併請求與隊列占用，不能同時保證每列目標。HUD 即使 60 fps 重繪，也只是在重畫最近樣本，不能宣稱 60 Hz 車況。

**不到一秒的事件能不能輪詢？**【推論】先決條件是來源本來就有該欄位；目前 D05／D06／D08 沒有。即使未來新增，輪詢也沒有事件保存保證。簡化為事件持續 `d`、取樣週期 `T`、相位均勻且無丟包，當 `d<T`，捕捉機率約 `d/T`；200 ms 事件用 1 秒輪詢，只有約 20% 機會碰到。捕捉後還有往返與來源資料年齡，不能當接手／碰撞警告。方向燈的持續啟用狀態或許能讀到，短閃／短脈衝與起始時刻仍可能漏掉；不能用本地動畫補出未曾觀測的安全事件。

### 喚醒、耗電與雲端替代

- 【事實】原生 BLE 的 VCSEC 與 infotainment 是不同 domain；後者處理車況查詢。官方記載車輛支援最多三個可靠 BLE 連線，會與手機鑰匙／遙控器等共用資源，不能假設我們永遠有獨占頻寬。[S1]
- 【推論】行駛時車已醒，重點是附加通訊／車機／手機耗電；停車時反覆 infotainment 查詢或 wake 有延長醒車的可能。社群刻意設醒車觀察窗、到期停問，是可參考策略；**找不到可可靠換算成本產品「2 Hz 每小時多耗幾 Wh／SOC」的資料**。[S4][S5]
- 【建議】只在 app 使用中且有有效連車需求時高速讀；離車／結束行程停止高速輪詢，停車頁短時低頻讀，不為背景儀表自動反覆 `wake_up`。喚醒失敗、車休眠時顯示不可用，不能用舊車速充當現在車速。
- 【事實】Fleet Telemetry 以 **500 ms 分桶**，欄位還受 `interval_seconds` 與值變化條件控制；斷線資料可緩存後補送，所以「收到訊息」不等於「現在狀態」。它需要授權、車端配置與可連線的 TLS 伺服器；不是原生 BLE 的免費、離線替代。REST `vehicle_data` 每次 live query 的頻繁輪詢亦不受官方推薦。[S7][S8]
- 【推論】雲端表列項目可供停車查詢／紀錄，不能只憑 500 ms 分桶就宣稱適合盲點、接手或燈號即時顯示。必須另測 source timestamp → server → phone 的端到端年齡，拒收過期補送事件。

## 只有 CAN 才拿得到的項目

**精確說法是「指定原生 BLE 缺少、低延遲替代目前主要依賴 CAN 硬體」，不是所有都絕對只能 CAN。**【事實】D05 方向燈、D07 定速設定、D17 遠光、D16 部分安全帶、D28 部分溫度已有雲端欄位；D11 更已有原生 BLE 功率。D06 當前盲點、D08 部分 AP／hands-on 提醒是 TITA 公開宣稱的硬體能力，仍不代表全部 FSD 接手狀態。D24、X01、X02 的完整事件語意／頻率未獲公開 SDK 證實，不能直接列「全解鎖」。[C1][S6][S9][S10]

【事實：供應商說法】TITA 安裝說明要求拆局部飾板，找到原車 CAN Bus／PING 模組，接入專用線束與並聯模組，再把訊號傳給手機 app／顯示器。資料先由外加硬體解析，再透過 Bluetooth 傳到 app。其約 **50 ms** 是延遲宣稱，不能反推每個訊號都以 20 Hz 更新；頁面也註明會隨車型、韌體、連接裝置與環境變化。沒有我們 app 的量測或公開完整欄位／SDK 契約。[S10][S11]

| 我們可走的路 | 能取得什麼／前置工作 | 與零硬體定位的關係 |
|---|---|---|
| 與 TITA／同類供應商合作 | 取得正式 SDK／協定、授權、欄位定義、支援車型與更新策略；實測盲點／AP／方向燈。能連上商品不代表已可供第三方 app 使用。 | 可做**選配進階來源**，但使用這些功能時不能繼續宣稱免硬體／免安裝。 |
| Tesla 專用線束＋相容 OBD/CAN adapter | Scan My Tesla 列出不同車款／年份線束，另需支援的 adapter；iOS／Android 選型不同。還需取得正確 bus、訊號定義與解碼；不是買任一 ELM327 就有盲點。 | 明確新增硬體、安裝與適配成本；只能作另一產品層級。[S12] |
| 自製 CAN gateway／發射器 | 自行處理取樣、時間戳、封包、手機連線與韌體相容；應先以被動讀取原型量測。 | 已是硬體產品路線，超出現階段零硬體 app。 |
| 保持原生 BLE＋GPS | 車速／檔位／車況／導航摘要；接受缺少盲點、AP 接手等事件。 | 與既有定位一致，資料範圍較小，但不需外接盒。 |

【推論】CAN access 也不保證原車影像、完整 3D 物件或下一轉彎。TITA 現行說明把地圖／導航／音樂介面歸給 Dashla；畫面有導航不能證明導航指令來自 CAN。須逐項列供應商可提供的實際 payload，不能用一個硬體名稱概括所有訊號。[S10]

## 行駛中顯示的安全限制

【事實】NHTSA 對原車 visual-manual 工作的自願性指南採單次離路瞄視約 **2 秒以內**、累計約 **12 秒以內**等評估原則；不是每看 2 秒就安全或取得法規認證。2016 對攜帶式／售後裝置的 Phase 2 是提案，不能寫成手機 app 已有同等強制標準；兩份資料均超過兩年。[S22][S23]

【事實】台灣《道路交通管理處罰條例》§31-1 規範行駛中以手持方式操作手機等；固定支架不等於任何顯示／操作都安全合法，也沒有逐項准許資料或台灣版「2 秒」豁免。[S24]【推論】drive 可放短、被動、穩定位置的速度／檔位／簡短車況及已驗證導航提示；歌詞、長文字、密集圖表、設定操作留 parked。盲點／碰撞／接手資料未證明低延遲與完整性前不放成安全告警；即使 CAN 可取也須獨立驗證。紅燈零速不是安全停車，不能因此解鎖完整面板操作。

## 假設

1. 【假設】目標仍是 Model 3/Y，iOS／Android 前景手機儀表；BLE 已配對合法金鑰、車可正常回應。沒有假設全部年份／韌體都回傳全部 optional 欄位；缺值、零值、過期值分開處理。
2. 【假設】以固定 commit 的 schema／實作為 repo 判斷基準；官方雲端文件是 2026-10-17 可見版本。不能因雲端新增欄位就說本地 BLE 也有，也不能把此 commit 的缺欄位說成 Tesla 永遠不提供。
3. 【估計】表列 BLE／GPS／IMU 頻率是實車 spike 起點；未自行完成任何道路性能、能耗或硬體延遲測試。無可靠資料者明示未知，沒有把廠商零延遲／零誤差宣傳當性能事實。
4. 【假設】drive 適用性只評估資料與顯示方式，不決定 PMF 排序；因此沒有預設 drive 永遠只能放車速，也沒有建議把所有可取資料塞進 drive。
5. 【推論】來源分類容許複合項拆開、容許外部地圖／導航 SDK；GPS 只給位置／速度等，不能單靠 GPS 生成道路法定速限、車道指示或天氣。

## 待驗證問題

| 驗證 | 最小實車 spike／查核內容 | 如何決定可交付 |
|---|---|---|
| E2E BLE 先接通 | 完成回應解密、請求／回應關聯、資料流輸出；確認 write 模式、session、實際 optional 欄位；先 drive 單獨，再 drive＋charge。 | 有可重現有效回應；不能以 requests issued／成功連線代替有效讀值。 |
| 速度／檔位延遲 | 分別跑 1／2／3 Hz，記 source timestamp、送出／收到／顯示時間、有效回應率、P50／P95／最大 age；用同步拍攝對照原車換檔／速度。 | 【建議驗收目標，非標準】核心資料 P95 age ≤1 秒起測；超過可接受年齡顯示未知／來源失效，不畫成 0。協定時間戳與手機時鐘不同時先校時。 |
| 排程／封包大小 | drive＋charge＋其他狀態分組，加入長目的地／媒體文字，測 MTU、分段、timeout、重試與隊列積壓。 | 慢狀態不能拖垮核心資料；無需每個 state 同頻。若單輪不滿足目標，就減少欄位或降低宣稱。 |
| 真正感測更新 | 查 TPMS last-seen、路線 last-update／timestamp；測換歌、門、溫度、功率正負、里程單位與空欄位。 | 分清回應刷新／感測刷新；導航不存在、TPMS 舊值等都有明確不可用狀態。 |
| 連線共存／跨平台 | 有車主手機鑰匙、乘客鑰匙、音樂／通話時測 iOS／Android、不同 3/Y 年份與韌體；測 app 背景、螢幕鎖定、斷線重連。 | 記錄各組成功率與降級行為；不能因一台車成功就稱全車系支援。 |
| 耗電／休眠 | 對照不連 app、前景 1 Hz／2 Hz、離車停止三組；記車輛醒睡與能耗、手機耗電／溫度，控制哨兵／充電等干擾。 | 得到本產品實測差異與置信範圍前，不寫「零耗電」或預估每日 SOC 損耗。 |
| 外部來源 | 固定點庫方向／平行道路；導航服務轉彎／車道／授權；Fleet 硬體／韌體支援、丟包與補送時間戳。 | D02／D03／D12 分別驗收，不能用一項可用代替另一項；雲端只在年齡可靠時顯示相應摘要。 |
| CAN 商務與實測 | 向供應商取得 D05／D06／D08／D24／X01／X02 逐項定義、SDK 使用權、支援表；量測事件到手機顯示的最大延遲與漏報。 | 沒有 payload／權利／可靠延遲證據，不排入零硬體版承諾；TITA 約 50 ms 不直接當我們的指標。 |
| drive 的可讀性 | 用候選少量資料，測單次瞄視、完成任務總離路時間、日夜可讀性；控制在安全環境測試。 | 安全段落只給篩選原則；通過資料可行性不等於通過人因驗證。 |

## 來源

下列 URL 均於 **2026-10-17** 查閱；未標發布／更新日期者明列「未標日期」，查閱日不冒充發布日。社群 issue 是實測線索，供應商頁面是能力宣稱，兩者皆非我們實車驗證。

- **C1–C4｜repo 原始證據，commit 2026-06-24**：固定 SHA `914b7c1b0f7150b2fc88988e37d1d4c245a834ea`。C1 [vehicle.pb.dart][C1]（並查同分支 `protocol/protobuf/vehicle.proto` 註解／單位）；C2 [car_server.pb.dart][C2]；C3 [tesla_reading_mapper.dart][C3]；C4 [tesla_ble_client.dart][C4]、[spike_screen.dart](https://github.com/huangc28/tsla-speed-meter/blob/914b7c1b0f7150b2fc88988e37d1d4c245a834ea/lib/src/ui/spike_screen.dart)、[ble_transport.dart](https://github.com/huangc28/tsla-speed-meter/blob/914b7c1b0f7150b2fc88988e37d1d4c245a834ea/lib/src/ble/ble_transport.dart)。以本地 `git show` 物件實查，GitHub 存取受 repo 權限影響。
- **C5｜工作目錄現況，查核 2026-10-17，未據此推定發布日**：[gps_source.dart][C5]、[trip_stats.dart](../../lib/src/trip/trip_stats.dart)（app 行程里程／均速／最高速，沒有平均能耗）。
- **S1｜Tesla vehicle-command BLE protocol，未標日期**：[protocol.md][S1]。官方公開協定，無 polling Hz／延遲 SLA。
- **S2｜vehicle-command issue #414，2025-07-30；另參 2025-12-24 回覆**：[Can the delay in retrieving the vehicle status via BLE be reduced][S2]。使用者環境回報。
- **S3｜vehicle-command issue #279，2024-07-22，超過兩年**：[BLE MTU / large-response discussion][S3]。歷史限制線索。
- **S4｜ESPHome Tesla BLE，未標日期**：[專案 README 與輪詢設定][S4]。社群第一手實作。
- **S5｜TeslaBleHttpProxy，未標日期**：[快取、冷連線與 wake 行為][S5]。社群第一手實作。
- **S6｜Tesla Fleet Telemetry Available Data，未標頁面日期**：[官方欄位表][S6]。欄位存在不保證每車支援。
- **S7｜Tesla Fleet Telemetry Overview，未標頁面日期**：[分桶、emit 條件、斷線緩存][S7]。
- **S8｜Tesla Fleet API Vehicle Endpoints，未標頁面日期**：[vehicle_data、recent_alerts、wake_up][S8]。
- **S9｜Tesla fleet-telemetry proto，未標頁面日期**：[vehicle_data.proto][S9]，含 `ForwardCollisionSensitivity` 等 enum；未把 main 分支當本地 BLE schema。
- **S10｜TITA Data Transmitter，未標日期**：[產品規格與約 50 ms 宣稱][S10]；現行頁明示依車型／韌體／顯示端而異。
- **S11｜TITA Dashla transmitter，未標日期**：[CAN／PING 線束安裝說明][S11]；本次網頁文字擷取不完整，並以同一官方頁搜尋索引確認安裝段落，號誌能力仍待 SDK 證實。
- **S12｜Scan My Tesla，未標日期**：[Adapters][S12]，各車型線束與 iOS／Android adapter 選型。
- **S13｜警政署固定測速執法設備，頁面資料更新 2026-10-16 15:08**：[政府開放資料 dataset 7320][S13]；不定期更新，非每點部署狀態的即時保證。
- **S14｜Tesla Model 3 Owner's Manual，未標日期**：[Tire Care and Maintenance][S14]；直接 TPMS 可能需行駛啟動，未給通用刷新週期。
- **S15｜Android Location，未標頁面日期**：[Location reference][S15]；speed、有效性與位置時間戳。
- **S16｜Android Motion sensors，未標頁面日期**：[linear acceleration／gravity][S16]；不含重力的手機軸加速度。
- **S17｜OpenStreetMap Wiki，持續編修，未核得本頁更新日**：[Key:maxspeed][S17]；屬道路圖資標記規範，沒有完整率保證。
- **S18｜Google Routes API，頁面更新 2026-10-15**：[Review the route response][S18]；steps／maneuver，不代表提供 Tesla 原車導航同步或所有車道。
- **S19｜中央氣象署，未標平台頁日期**：[氣象資料開放平台][S19]；各資料集更新與授權需另驗。
- **S20｜Apple CarPlay，未標頁面日期**：[官方 framework 文件][S20]；相容車端、類別／entitlement 與模板。
- **S21｜Android for Cars，未標頁面日期**：[Use the Android for Cars App Library][S21]；車用介面是獨立整合工作。
- **S22｜U.S. DOT，頁面標示 2019-08-01，超過兩年**：[Driver distraction guidelines 說明][S22]；描述自願性原車指南及 2 秒／12 秒原則。
- **S23｜NHTSA／Federal Register，2016-12-05，超過兩年**：[Portable and aftermarket devices Phase 2 proposal][S23]；不可寫成最終強制規則。
- **S24｜全國法規資料庫，條例修正日期 2026-08-17**：[道路交通管理處罰條例 §31-1][S24]；部分其他修正條文另有施行日，本段引用現行手持操作規定。
- **S25｜交通部／高速公路局，資料集發布／修訂欄未填，2026-10-17 查閱**：[國道交通標誌位置][S25]；描述含 WGS84／TWD97 座標、方向、里程，更新頻率「無」。網站頁尾 2026-10-07 不當資料清查日期；本次未驗原 CSV 的全路網完整性與再利用條件。
- **S26｜OpenStreetMap Wiki，持續編修，未核得單頁更新日，2026-10-17 查閱**：[Key:name][S26]、[Key:ref](https://wiki.openstreetmap.org/wiki/Key:ref)；道路名稱／路線編號仍須和道路幾何匹配，不能只反查最近地名。
- **S27｜Tesla Model 3 Owner's Manual，未標單頁日期，2026-10-17 查閱**：[Rear Facing Camera(s)][S27]；中控相機功能與限制，不是第三方手機影像 API 的證據。

[C1]: https://github.com/huangc28/tsla-speed-meter/blob/914b7c1b0f7150b2fc88988e37d1d4c245a834ea/lib/src/ble/gen/vehicle.pb.dart
[C2]: https://github.com/huangc28/tsla-speed-meter/blob/914b7c1b0f7150b2fc88988e37d1d4c245a834ea/lib/src/ble/gen/car_server.pb.dart
[C3]: https://github.com/huangc28/tsla-speed-meter/blob/914b7c1b0f7150b2fc88988e37d1d4c245a834ea/lib/src/ble/tesla_reading_mapper.dart
[C4]: https://github.com/huangc28/tsla-speed-meter/blob/914b7c1b0f7150b2fc88988e37d1d4c245a834ea/lib/src/ble/tesla_ble_client.dart
[C5]: ../../lib/src/data/gps_source.dart
[S1]: https://github.com/teslamotors/vehicle-command/blob/main/pkg/protocol/protocol.md
[S2]: https://github.com/teslamotors/vehicle-command/issues/414
[S3]: https://github.com/teslamotors/vehicle-command/issues/279
[S4]: https://github.com/yoziru/esphome-tesla-ble
[S5]: https://github.com/wimaha/TeslaBleHttpProxy
[S6]: https://developer.tesla.com/docs/fleet-api/fleet-telemetry/available-data
[S7]: https://developer.tesla.com/docs/fleet-api/fleet-telemetry
[S8]: https://developer.tesla.com/docs/fleet-api/endpoints/vehicle-endpoints
[S9]: https://github.com/teslamotors/fleet-telemetry/blob/main/protos/vehicle_data.proto
[S10]: https://www.hellotita.com/products/tita-tesla-data-transmitter
[S11]: https://www.hellotita.com/el/products/dashla
[S12]: https://www.scanmytesla.com/adapters
[S13]: https://data.gov.tw/dataset/7320
[S14]: https://www.tesla.com/ownersmanual/model3/en_ie/GUID-94F63B13-EA2C-45D9-83AB-5DCA6295D587.html
[S15]: https://developer.android.com/reference/android/location/Location
[S16]: https://developer.android.com/develop/sensors-and-location/sensors/sensors_motion
[S17]: https://wiki.openstreetmap.org/wiki/Key:maxspeed
[S18]: https://developers.google.com/maps/documentation/routes/understand-route-response
[S19]: https://opendata.cwa.gov.tw/index
[S20]: https://developer.apple.com/documentation/carplay
[S21]: https://developer.android.com/training/cars/apps/library
[S22]: https://www.transportation.gov/briefing-room/us-dot-releases-guidelines-minimize-vehicle-distractions
[S23]: https://www.federalregister.gov/documents/2016/12/05/2016-29051/visual-manual-nhtsa-driver-distraction-guidelines-for-portable-and-aftermarket-devices
[S24]: https://law.moj.gov.tw/LawClass/LawAll.aspx?pcode=K0040012
[S25]: https://www.motc.gov.tw/201506260001/app/govdata_list/view?id=1615&module=datagov&serno=201902110001
[S26]: https://wiki.openstreetmap.org/wiki/Key:name
[S27]: https://www.tesla.com/ownersmanual/model3/en_sg/GUID-3598EF55-6B1D-462B-88D8-704DB0896DD1.html
