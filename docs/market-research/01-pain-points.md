# 01 — 用戶痛點分析(pain)

> 研究日期:2026-10-16。標記說明:〔事實〕有來源的直接陳述;〔估計〕依樣本粗算;〔推論〕研究員的判斷。超過 2 年的資料標 ⏳。

> **修訂(2026-10-17)**:對齊 `07-data-voice.md`(需求聲量)、`09-data-feasibility.md`(拿不拿得到)、`10-data-priorities.md`(版本)。依主持人裁決,可行性以 09 為準;BLE 項目在 repo 都還是「schema 有、待實車驗證」。
> - 美國 §Q3 表格:「v1 能否提供」整欄改依 09 和 10,每列加上 D 編號。原本的 ❓/❌ 是依 brief 推論的。
> - 台灣 §Q3 條列:每項補一句 09/10 的結論。
> - 重點結論 #4、台灣 §Q6「和 v1 範圍的衝突」、Persona P1:台灣固定測速提醒(D03)已由 04 §T3 和 10 列入 v1;道路速限(D02)仍延後。
> - 美國 §Q3「要極簡」那一條:原本寫「支持 drive 只顯示速度」,改依 07(部分支持)和 10(drive 版面)。
> - Persona P2、JTBD J2/J5:加註零硬體做不到的項目(09/10)。
> - 假設 4–6、待驗證問題 #7:07 已補讀 YouTube 留言和 Dashla 台區全部 83 則評論;「v1 能否提供」已不是推論。
> - 痛點表、統計、測速數據、其餘 persona 證據都沒有改。

## 重點結論

1. **少數人長期痛,多數人只痛幾週。** 美國 7 串討論中,約 1/3 的回覆者想要眼前顯示,約 2/3 說幾分鐘到幾週就適應了〔估計〕。所以「新車主前 1–4 週」是最大、但最短暫的需求窗口〔推論〕。
2. **新款沒有改變這件事。** Highland 與 Juniper 的車速仍只顯示在中控螢幕。到 2026 年,原廠都沒有儀表或 HUD〔事實,次級來源〕。副廠硬體反而更難裝:有些產品不支援 Juniper,有些不支援 2026 年的 AP4.5 車款〔事實,賣家頁〕。
3. **大家對現有解法的不滿集中在硬體。** 主要是怕破保、擋到冷氣出風口、要拆內裝、Tesla 更新韌體後失效,以及外觀突兀。不需硬體的 BLE 手機方案正好避開這幾點〔推論〕。另外,FSD 車內鏡頭會在駕駛看中控時跳出警告,這是較新的痛點〔事實,單一引述〕。
4. **台灣比美國更痛,關鍵在測速照相。** 2025 年全台有 1,809 處固定測速照相,超速 40 km/h 以下的舉發有 264 萬件〔事實〕。車主對儀表的需求和「測速提醒」綁在一起〔事實,多源〕。競品 Dashla 已經內建測速提醒。原本 brief 把速限與超速功能延到 v1 之後,這是最大的落差〔推論〕;**修訂:04 §T3 和 10 已把台灣固定測速提醒(D03)列入 v1,道路速限(D02)仍延後**。
5. **最痛的三群人**(「最痛」指個人嚴重度,不是人數):①台灣怕被測速照相開單的車主;②從有 HUD 的車(BMW、Ioniq 5 等)換過來的人;③視力吃力或年長的駕駛。單純「從油車換過來」並不會比較痛〔推論,見 §誰最痛〕。

---

## 痛點表(依 頻率 × 嚴重度 排序)

計分:頻率 高=3 / 中=2 / 低=1;嚴重度 高=3(安全疑慮、影響購車,或長期無法適應)/ 中=2(惱人,但多數人會適應或有替代方案)/ 低=1(個人偏好)。

| # | 痛點 | 頻率 | 嚴重度 | 分數 | 代表引述(附連結) | 市場 |
|---|---|---|---|---|---|---|
| 1 | **看車速要把視線移離路面,轉頭或斜眼看中控**(新車主前幾週最明顯) | 高 | 中 | 6 | "I picked up my Model Y a few weeks ago and have a hard time keeping an eye on speed." — [r/TeslaModelY](https://www.reddit.com/r/TeslaModelY/comments/13wq2n4/) 2023-05-31<br>「我也覺得拔掉儀表板 要一直歪頭看平板的設計很怪」— [PTT car](https://www.ptt.cc/bbs/car/M.1771258724.A.546.html) 2026-02-17 | 美、台 |
| 2 | **副廠硬體儀表/HUD 的顧慮讓人不敢裝**:破保、擋出風口、拆內裝、韌體更新失效、外觀突兀 | 高 | 中 | 6 | "both the sales and SC confirmed that installing a HUD will invalidate the Tesla new car warranty" — [r/TeslaModelY](https://www.reddit.com/r/TeslaModelY/comments/156vs5p/) 2023-07-23<br>"How frequently will Tesla change their software to 'break' the instrument cluster?" — [r/TeslaModelY](https://www.reddit.com/r/TeslaModelY/comments/13wq2n4/) 2023-05-31<br>「不少人並非不需要儀表,而是不願為了補上這塊資訊顯示,而介入到如此深層的硬體改裝」— [electrify.tw](https://electrify.tw/dashla-tesla-dashboard/) 2026-03-30 | 美、台 |
| 3 | **怕被測速照相開單,需要隨時掌握車速並收到測速提醒** | 中 | 高 | 6 | 「其實駕駛座儀表需求在台灣可能還是因為測速照相吧!」「要不是密密麻麻的測速,有需要一直在意車速嗎?」— [PTT car](https://www.ptt.cc/bbs/car/M.1771258724.A.546.html) 2026-02-17<br>「如果還能整合測速神盾就完美了」— [Dashla App Store 評論](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-03-16 | 台(美國較弱,見 §美國) |
| 4 | **從有 HUD 的車換過來,失去「抬眼即知」** | 中 | 中 | 4 | "Love the car but didn't realize how much I depend on hud." — [r/TeslaModel3](https://www.reddit.com/r/TeslaModel3/comments/x35hix/) 2022-09-01<br>"After driving our Ioniq 5 with a HUD... yes, it bothers me a lot that our Model Y doesn't have one." — [r/TeslaModelY](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/) 2024-03-18<br>「BMW新世代也是拔儀表板 但做了超大的抬頭顯示」— [PTT car](https://www.ptt.cc/bbs/car/M.1771258724.A.546.html) 2026-02-17 | 美、台 |
| 5 | **方向燈與盲點不在視線內**,變換車道時要看中控 | 中 | 中 | 4 | "looking at the screen isn't as convenient or safe. Nothing is as easy as simply look at the mirror." — [r/TeslaModel3](https://www.reddit.com/r/TeslaModel3/comments/p0zvus/) 2021-08-09 ⏳<br>「方向燈提升,盲點提示那就太棒了」、「建議能新增左右轉時的影像」— [Dashla 評論](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-03 | 美、台 |
| 6 | **現有手機或反射式方案體驗差**:要裝支架、手機發燙、白天看不清、反射影像廉價、戴偏光墨鏡看不到 | 中 | 中 | 4 | 「不過只能晚上用 白天怕太陽把螢幕照壞了」(手機反射當 HUD)— [PTT car](https://www.ptt.cc/bbs/car/M.1715425739.A.DD9.html) 2024-05-11<br>"Not one that reflects off the windshield that looks like a 90s digital clock." — [r/TeslaModel3](https://www.reddit.com/r/TeslaModel3/comments/1m6d1hq/) 2025-07-22<br>"If you wear polarized sunglasses, hud sucks." — [r/TeslaModelY](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/) 2024-03-18<br>評論標題「手機容易發燙啊」— [Dashla 評論](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-04-11 | 美、台 |
| 7 | **導航轉彎提示要看中控** | 中 | 中 | 4 | "The only actual reason to have a HUD is if it's the same as the S and X where the map also displays on the HUD." — [r/TeslaModel3](https://www.reddit.com/r/TeslaModel3/comments/1m6d1hq/) 2025-07-22<br>「希望抬頭顯示的導航提醒字幕都可以大一點」— [Dashla 評論](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-04-11 | 美、台 |
| 8 | **視力或年齡問題**:螢幕距離近、字小、老花,長期無法適應 | 低 | 高 | 3 | "After a year and a half I learned to hate how close to my eyes is the speed indicator… My right eye start hurting" — [r/TeslaModelY](https://www.reddit.com/r/TeslaModelY/comments/156vs5p/) 2023-07-22;同一人 "2 years and still didn't get used to it" — [r/TeslaModelY](https://www.reddit.com/r/TeslaModelY/comments/13wq2n4/) 2023-11-26<br>"Close up I can't read anything but vehicle speed without putting on glasses - a dangerous distraction" — [TMC(存檔)](https://teslamotorsclub.com/tmc/threads/small-screen-font-on-ui.186209/) 2020-07-15 ⏳ | 美(台灣找不到直接證據) |
| 9 | **FSD/Autopilot 車內鏡頭監控**:看中控確認車速就被警告 | 低 | 中 | 2 | "If I so much as look at my screen to get the speed, I get hit with the, 'Please keep your eyes on the road' message. It gets annoying." — [r/TeslaModelY](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/) 2024-03-18;Tesla 在 FSD v13.2.9 放寬了警告靈敏度 — [Not a Tesla App](https://notateslaapp.com/news/2734/tesla-loosens-driver-monitoring-on-fsd-v1329) 2025-05-17 | 美(台灣 FSD 未全面開放,適用度低〔推論〕) |

---

## 美國

### Q1 抱怨有多普遍、多強烈?新款有沒有改變?

**普遍度:有人聲量大,但不是多數。** 下表是逐則數回覆的結果(只算明確表態的回覆,〔估計〕)。

| 討論串 | 年份 | 想要眼前顯示/抱怨 | 已適應/不在意 | 備註 |
|---|---|---|---|---|
| [TMC no-cluster-screen](https://teslamotorsclub.com/tmc/threads/no-cluster-screen.231168/)(Wayback 存檔,僅第 1 頁) | 2021 ⏳ | 0 | 7 | 其中 2 人希望字更大,或想要極簡的眼前顯示 |
| [r/TeslaModel3 12qsm0m](https://www.reddit.com/r/TeslaModel3/comments/12qsm0m/) | 2023 | ~5 | ~11 | 改款前的期待串 |
| [r/TeslaModelY 13wq2n4](https://www.reddit.com/r/TeslaModelY/comments/13wq2n4/) | 2023 | 2 | ~8 | 新車主發問 |
| [r/TeslaModelY 15nahtd](https://www.reddit.com/r/TeslaModelY/comments/15nahtd/) | 2023 | ~5 | ~11 | |
| [r/TeslaModelY 1bhcymk](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/) | 2024 | ~9 | ~18 | 標題本身偏向「不懂大家在吵什麼」 |
| [r/TeslaModel3 1m6d1hq](https://www.reddit.com/r/TeslaModel3/comments/1m6d1hq/) | 2025 | ~11 | ~7 | 發文者正在做 HUD,有自選偏差 |
| [r/TeslaModelY 1m8xcde](https://www.reddit.com/r/TeslaModelY/comments/1m8xcde/) | 2025 | ~4 | ~7 | 同一位發文者發起的 HUD 付費意願投票(投票結果無法取得) |
| **合計** | | **~36(約 1/3)** | **~69(約 2/3)** | n≈105 |

- **強度呈兩極。** 抱怨的人用詞很重,例如 "one of my only three complaints"、"I dislike taking my eyes off the road for any reason"([1m6d1hq](https://www.reddit.com/r/TeslaModel3/comments/1m6d1hq/) 2025-07-22)。不在意的一方則說 "It's imaginary"、"People just don't want to change habits"([1bhcymk](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/) 2024-03-18)。
- **適應期很短**〔事實,多源〕:"took about an hour"、"within minutes of driving, it no longer was [an issue]"、"weird the first couple of weeks… quickly gotten used to it"([1bhcymk](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/)、[TMC](https://teslamotorsclub.com/tmc/threads/no-cluster-screen.231168/))。
- **想要的人多半要「真 HUD + 極簡」,不要傳統儀表。** 例如 "A HUD? Yes! Gauges, displays behind the wheel? Rather not."、"A simple one, just speed and signals."([1m6d1hq](https://www.reddit.com/r/TeslaModel3/comments/1m6d1hq/) 2025-07)。
- **早期民調**⏳:2017 年 CleanTechnica 讀者投票(n=1,705),22% 認為 HUD「關鍵,沒有就不買」,43% 「想要但可以沒有」([CleanTechnica](https://cleantechnica.com/2017/05/03/tesla-model-3-hud-huge-demand-even-wont-arrive-poll-results/) 2017-05-03)。這份資料有三個限制:在交車前做的、受訪者是讀者而非車主、距今已超過 2 年。

**新款(Highland、Juniper)沒有改變這件事**〔事實〕
- 車速仍顯示在中控狀態列。依據:Model 3 使用手冊([Car Status](https://www.tesla.com/ownersmanual/model3/en_hk/GUID-80B80D48-E3A9-4857-864B-F4CC9B56FD7E.html))、2025+ Model Y 台灣版手冊,軟體 2026.32([PDF](https://www.tesla.com/ownersmanual/modely/zh_tw/Owners_Manual.pdf))。
- 截至 2026 年,Model 3/Y 沒有原廠 HUD 或儀表。來源是零售商整理的指南,屬次級來源([HUDScreen](https://hudscreen.com/tesla-head-up-display/) 2026)。
- Tesla 對「拿掉實體控制」的反彈有回應,不過只處理了方向燈撥桿:中國開放付費加裝,約 2,499 人民幣,美國未確認([InsideEVs](https://insideevs.com/news/769401/tesla-turn-signal-stalk-model-3/) 2025)。至於用氛圍燈做盲點警示,目前只有論壇報導,未經官方證實([teskas](https://teskas.net/t/topic/17184?tl=en))。
- **副廠硬體變難裝**:Tesloid 小儀表標示適用 "2020-2025 (Excluding Juniper)"(搜尋摘要,頁面無法直接存取);Yeslak 8.9 吋儀表 "not compatible with 2026 HW4.5 Chip Version (AP45)"([Yeslak](https://www.yeslak.com/products/tesla-8-9-instrument-cluster-for-model-3-y))。

### Q2 現在怎麼解決?對這些方案有什麼不滿?

| 方案 | 價格線索 | 用戶不滿(引述) |
|---|---|---|
| **習慣看中控,搭配超速提示音**(最多人的最後做法) | 免費 | 對多數人有效:"Set the speed limit warning chime… the beep will tell you"([156vs5p](https://www.reddit.com/r/TeslaModelY/comments/156vs5p/) 2023)。但視力差的人做不到(痛點 8) |
| **硬體小儀表或 5–10 吋螢幕**(Hansshow、Tesery、Topfit 等,接 CAN bus) | 原廠接線款「over $500」([The Drive](https://www.thedrive.com/news/40610/aftermarket-instrument-clusters-fix-tesla-model-3s-main-omission) 2021-05-13 ⏳) | 擋出風口:"I like the AC blasting straight into my face"([13wq2n4](https://www.reddit.com/r/TeslaModelY/comments/13wq2n4/));外觀:"I am disgusted when I see any of those third party displays. They just look out of place."(同串);送修麻煩:"Tesla said they would not fix it unless I take the screen out"([156vs5p](https://www.reddit.com/r/TeslaModelY/comments/156vs5p/) 2023-07-23);售後支援:"it now bricked after 1 year and there is no after sales support... so that is now 200€ down the drain"([1eqpcct](https://www.reddit.com/r/TeslaModelY/comments/1eqpcct/) 2024-08-13);耐用度:有評論說螢幕約兩個月後失效,疑似過熱([ShopSavvy 彙整](https://shopsavvy.com/reviews-tldr/%22tesla-model-y3-9.6%22-heads-up-display)) |
| **藍牙 HUD 盒**(例如 Teslogic) | 約 $200 | 價格門檻:"Teslogic looks great but don't want to spend $200 for the unit."([18n58os](https://www.reddit.com/r/TeslaModelY/comments/18n58os/) 2023-12-20) |
| **擋風玻璃反射式 HUD** | 低價款約 $38(Walmart 搜尋摘要) | "looks like a 90s digital clock";偏光墨鏡看不到;擋風玻璃上有反光:"the reflections bug me"([p0zvus](https://www.reddit.com/r/TeslaModel3/comments/p0zvus/) 2021 ⏳) |
| **手機 + 支架 + GPS 速度 app 或 Waze** | 免費到低價 | "I stick my iPhone there horizontally for Waze (which shows speed)"([15nahtd](https://www.reddit.com/r/TeslaModelY/comments/15nahtd/) 2023-08-10)。有人擔心 GPS 延遲:"How fast is the waze speedometer? Does it lag"(同串)。手機只能顯示速度,讀不到車輛資料 |
| **BLE 手機 app**(Dashla、DriveCluster) | 免費加訂閱 | 美國聲量小:Dashla 美區只有 20 則評分,DriveCluster 22 則([iTunes lookup](https://itunes.apple.com/lookup?id=6760206753,6762794279&country=us) 2026-10-16)。美國 Reddit 樣本裡還沒看到用戶的不滿 |

- **付費意願偏低**〔事實,少量樣本〕:"I would like HUD but I don't want to pay extra for it"、"Zero, because I can't see the stupid things when wearing polarized sunglasses"([1m8xcde](https://www.reddit.com/r/TeslaModelY/comments/1m8xcde/) 2025-07-25);新車主覺得 $200 太貴(見上表)。

> 推論:前三種方案的主要不滿(破保、擋出風口、韌體失效、要拆內裝)都來自「硬體接上車」。不接硬體的 BLE 加手機方案可以正面回應這些不滿。不過它要接手痛點 6 的問題:支架、發燙、白天看不清、偏光墨鏡。

### Q3 除了速度,還想在眼前看到什麼?

| 資訊 | 需求證據 | v1 能否提供(拿不拿得到依 09;版本依 10;2026-10-17 修訂) |
|---|---|---|
| 速度(D01) | 所有討論串 | **可**:手機 GPS 已實作;BLE `DriveState.speedFloat` 已映射,待實車驗證(09)。10 列 P0,v1:免費 GPS 版,BLE 付費版 |
| 方向燈(D05) | "just speed and signals"([1m6d1hq](https://www.reddit.com/r/TeslaModel3/comments/1m6d1hq/));"speed/turn/high beam indicators"([1bhcymk](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/)) | **否**:BLE 沒有欄位;雲端 Fleet Telemetry `LightsTurnSignal` 有欄位,但不能當即時提示;CAN 硬體(TITA)只有廠商宣稱(09)。10 列 P3,不做(硬體選配之後評估) |
| 定速/ACC 設定速度(D07)、AP/FSD 狀態(D08) | "speed, ACC and basic stuff"、"FSD/Autopilot state"([1m6d1hq](https://www.reddit.com/r/TeslaModel3/comments/1m6d1hq/)) | **否**。D07:BLE 沒有欄位,雲端 `CruiseSetSpeed` 不即時(09),10 列不做。D08:BLE 沒有欄位,完整狀態拿不到,CAN 只有廠商的部分宣稱(09),10 列不做(美 P3、台 ✕) |
| 電量 SOC(D09) | "speed, SOC, abbreviated alarms"([1m6d1hq](https://www.reddit.com/r/TeslaModel3/comments/1m6d1hq/));"speed and charge"([1bhcymk](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/)) | **可**:BLE `ChargeState.batteryLevel` 已映射,待實車驗證(09)。10 列 P0,v1,BLE 付費版(drive 狀態列小字 + parked) |
| 導航轉彎(D12) | "nice for the turn directions"([12qsm0m](https://www.reddit.com/r/TeslaModel3/comments/12qsm0m/));"turn by turn nav"([p0zvus](https://www.reddit.com/r/TeslaModel3/comments/p0zvus/));原廠導航在高速公路分岔時不清楚,所以想找 Android Auto HUD:"Tesla nav has recently failed me multiple times at highway splits"([1f2jycg](https://www.reddit.com/r/TeslaModelY/comments/1f2jycg/) 2024-08-27) | **否**:原車 BLE 沒有轉彎和車道欄位;自建手機導航技術上可行,但要圖資或導航 SDK(09)。10 列 P3,不做。替代:原車導航的 ETA/剩餘距離/抵達電量(D13)BLE 讀得到,10 列 v1.x(spike 讀得到才排) |
| 盲點(D06) | [p0zvus](https://www.reddit.com/r/TeslaModel3/comments/p0zvus/) 整串 | **否**:BLE 沒有欄位;CAN 硬體可取得部分盲點狀態,但只有廠商宣稱(09)。10 列 P3,不做 |
| 速限(D02) | "great for speed limit"([p0zvus](https://www.reddit.com/r/TeslaModel3/comments/p0zvus/)) | **BLE 拿不到,手機端可做**:GPS + 開放圖資(OSM `maxspeed`),要做道路匹配(09)。10 列美 P1、台 P3,版本是「之後」(Issue #2,美國上架前重評) |
| 警示訊息(D16) | "I hear alerts and by the time I can look there is NOTHING on the screen"([1bhcymk](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/)) | **部分**:BLE 可取門狀態(`ClosuresState`)和胎壓警告(`tpmsHardWarning*`);完整故障燈拿不到(09)。10 列 v1.x,只做行駛中門未關和胎壓 hard warning,不能叫「警示燈」 |

- **反方向的訊號同樣強:要極簡**〔事實〕。例如 "Some of the huds today are overwhelming with data"([1m6d1hq](https://www.reddit.com/r/TeslaModel3/comments/1m6d1hq/)),以及「拿掉一切」的極簡派。但 07 擴大樣本後,「drive 模式只顯示速度」這個預設只得到**部分支持**〔估計,修訂〕。明確說出想看內容的約 40 人中,只要車速的約 1/4,要「車速 + 1–4 個指示」的約 6 成(07)。10 的 drive 版面是「大字車速 + BLE 小字狀態列(檔位、電量/續航)+ 單一觸發區 + 純車速開關」。觸發區在 v1 只有台灣測速提醒,因為方向燈、盲點、轉彎零硬體拿不到(09)。

### Q4 美國最痛的族群

- **新車主,交車後 1–4 週**:人數最多,但痛的時間最短。代表發言有 "picked up my Model Y a few weeks ago"([13wq2n4](https://www.reddit.com/r/TeslaModelY/comments/13wq2n4/))、"Just picked up vehicle last week and got a phone mount"([18n58os](https://www.reddit.com/r/TeslaModelY/comments/18n58os/))。也有人在交車前就先研究:"I seriously considered buying a HUD before taking delivery"([1bhcymk](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/))。
- **從 HUD 車換過來的人**:BMW i4/M4/X3、Ioniq 5、Kia 等車主,見痛點 4。
- **視力吃力或年長的駕駛**:見痛點 8。
- **「從油車換過來」本身不是好的預測指標。** 有人開了 30 年油車,幾分鐘就適應:"nearly 30 years of driving experience… within minutes… no longer was [an issue]"([TMC](https://teslamotorsclub.com/tmc/threads/no-cluster-screen.231168/) 2021 ⏳)。差別在於舊車有沒有 HUD〔推論〕。
- **長途通勤族**:找不到美國的直接證據。唯一相關的是日本車主說「只在長途時才裝手機顯示」([teskas.net](https://teskas.net/t/topic/15801?tl=en),日期未確認),非美台樣本。
- **美國的執法焦慮比台灣弱,但存在。** 有人用雷達偵測器([1tfgeqw](https://www.reddit.com/r/TeslaModel3/comments/1tfgeqw/) 2026-05-17),也有人提到城市 25 MPH 的取締:"which the city enforces 25MPH"([15nahtd](https://www.reddit.com/r/TeslaModelY/comments/15nahtd/) 2023-08-10)。電動車加速快,容易不小心超速:"it's too damn easy to speed in these bad boys"([1bhcymk](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/))。

---

## 台灣

### Q1 抱怨有多普遍、多強烈?

- **PTT 的聲量比美國更偏負面**〔估計〕。[PTT car M.1771258724](https://www.ptt.cc/bbs/car/M.1771258724.A.546.html)(2026-02-17)中,約 10 人批評沒有儀表或 HUD,約 5 人說沒差。這串是 Model 3 車主抱怨文的回文,有自選偏差。原 po:「我對於特斯拉最不滿意是把儀錶板拔掉,只給一個中控台」。
  - 強度高的推文:「這種完全無視安全的垃圾我相信它存活時間不會太久」(Danto18)、「租過一週…還是很不爽沒有儀表板啊」(a523928)、「拔掉真的是敗筆」(tlcam4507)。
  - 反方:「看時速很難嗎?…現在叫我開有儀表的車我反而覺得詭異」(ATT8392)。
- **購車前就擔心**:「沒有儀錶板換檔滑平板能接受嗎?」(skyangler,[PTT 試駕文](https://www.ptt.cc/bbs/car/M.1760975758.A.334.html) 2025-10-21)。
- **有安全驚嚇的經驗**〔事實,TVBS 報導,受訪者未具名〕:「以前稍微這樣瞄一下大螢幕的時候,多少還是會遇到…被嚇到說可能突然一下離前車太近了」([TVBS](https://cars.tvbs.com.tw/life/310983) 2026-03-16)。
- **需求訊號:Dashla 在台灣起量快**〔事實〕。上線約 4 天就有約 5 千人下載測試([TVBS](https://cars.tvbs.com.tw/life/310983) 2026-03-16)。台區 App Store 有 269 則評分、平均 4.8,美區只有 20 則([iTunes lookup](https://itunes.apple.com/lookup?id=6760206753&country=tw) 2026-10-16)。開發者自稱全球 1.7 萬用戶([hunted.space](https://hunted.space/product/dashla-dashboard-for-tesla)),未經驗證。
- **新款沒有改變這件事**:台灣賣的 2025+ Model Y 手冊(軟體 2026.32)仍寫車速顯示在螢幕上([PDF](https://www.tesla.com/ownersmanual/modely/zh_tw/Owners_Manual.pdf))〔事實〕。

### Q2 現在怎麼解決?不滿什麼?

| 方案 | 價格線索 | 不滿或顧慮 |
|---|---|---|
| 副廠小螢幕或 HUD(淘寶、蝦皮、改裝店) | 3 千–1 萬元(特斯拉達人說法,[TVBS](https://cars.tvbs.com.tw/life/310983) 2026-03-16);電商專用 HUD 約 1–2 千元(搜尋摘要) | 破保:「可以避免掉說可能原廠到時候會說,我們有改裝會破保的這樣子的疑慮」(TVBS 車主);改裝門檻:見 [electrify.tw](https://electrify.tw/dashla-tesla-dashboard/) 對 OBD 方案的整理:「安全性、保固影響,以及未來韌體更新後的不確定性」 |
| 低價無線充電 HUD 支架 | — | DDCAR 心得文標題「Model 3 車主千萬不要買!…(踩雷)」([DDCAR](https://www.ddcar.com.tw/blogs/articles/detail/772/))。內文抓不到,只引用標題 |
| 手機反射到擋風玻璃(自製 HUD) | 免費 | 「OLED螢幕可以當抬頭顯示器…舊手機是LCD螢幕沒什麼感覺…只能晚上用 白天怕太陽把螢幕照壞了」;另提到「神盾懸浮視窗沒有抬頭顯示器模式」([PTT](https://www.ptt.cc/bbs/car/M.1715425739.A.DD9.html) 2024-05-11) |
| 神盾測速照相 app(語音) | 免費 | 「傳統測速提醒多半只提供語音提示,駕駛仍需自行判斷位置與距離」([electrify.tw](https://electrify.tw/dashla-tesla-dashboard/));Tesla 中控沒有 CarPlay,手機提醒無法顯示在車機上(搜尋摘要,〔推論〕) |
| Dashla(BLE 手機儀表加測速提醒) | 免費(含廣告),另有訂閱與買斷 | 2026-03~05 的評論:評論標題「手機容易發燙啊」、「車機導航跟手機蘋果的導航路徑不一樣」、「短暫下車…手機未拿下車,再次上車…無法入檔,提示要放卡片才能駕駛」、希望有買斷方案([App Store](https://apps.apple.com/tw/app/id6760206753?see-all=reviews)) |

### Q3 除了速度,還想在眼前看到什麼?

台灣的證據來自 Dashla 評論與 PTT。和美國相比,**測速提醒、方向燈、盲點、轉彎影像**特別突出:
- 測速:「如果還能整合測速神盾就完美了」(BensonHMLin,2026-03-16);Dashla 的測速提醒被媒體評為「台灣車主幾乎必備」([electrify.tw](https://electrify.tw/dashla-tesla-dashboard/))。**可(D03)**:警政署測速點 CSV + 手機 GPS,不需要 BLE(09);10 列台灣 P0,v1,放免費 GPS 版。
- 定速設定:「抬頭顯示器還是很重要的 至少給時速和定速多少」(coolsparrow,[PTT](https://www.ptt.cc/bbs/car/M.1771258724.A.546.html))。**否(D07)**:BLE 沒有欄位,雲端不即時(09);10 列不做。
- 方向燈、盲點、轉彎影像:「行進間有在左邊或右邊有車車行進的動畫,另外還有方向燈提升,盲點提示」、「建議能新增左右轉時的影像」([App Store](https://apps.apple.com/tw/app/id6760206753?see-all=reviews))。**都是否**:方向燈(D05)、盲點(D06)BLE 沒有欄位,要 CAN 硬體(09),10 列 P3 不做;轉彎影像(D25)沒有公開影像介面,連 CAN 也拿不到(09),10 列不做;周遭車輛動畫(D23)同樣拿不到,10 列不做。
- 胎壓:「它的胎壓什麼的,都可以直接從正面看手機的時候,就會比較清楚」([TVBS](https://cars.tvbs.com.tw/life/310983))。**可,但有條件(D15)**:BLE `TirePressureState` 四輪胎壓讀得到,但還沒映射,車型和感測器相容也待驗證(09)。10 列台灣 P2、美國 P1:parked 版 v1(條件式,spike 讀得到才做),drive 警示 v1.x。
- 時間、導航字幕放大:「希望可以讓時間的顯示更大更醒目」、「導航提醒字幕都可以大一點」([App Store](https://apps.apple.com/tw/app/id6760206753?see-all=reviews))。**時間可(D14)**:手機時鐘即可(09);10 列 parked 已完成,drive 小字 v1.x(選用,預設關)。**導航提醒否(D12)**:同美國 §Q3,10 列不做。

### Q6 測速照相文化是否讓「隨時看得到車速」更重要?是的〔事實 + 推論〕

| 指標 | 數字 | 來源 |
|---|---|---|
| 全台固定式測速照相 | 1,809 處(新北 251、台中 214、屏東 138) | 警政署,[中央社](https://www.cna.com.tw/news/ahel/202512040174.aspx) / [工商時報](https://www.ctee.com.tw/news/20251204701173-431401) 2025-12-04 〔事實〕 |
| 每千公里道路的測速照相數 | 台灣 82.8 支 vs 日本 0.27 支,約 307 倍 | SCDB,經 [工商時報](https://www.ctee.com.tw/news/20251204701173-431401) 2025-12-04 轉述〔事實,次級來源〕 |
| 2025 全年交通違規舉發 | 16,319,546 件,年增 8.1% | 內政部統計處,經 [風傳媒](https://www.storm.mg/article/11171140) 2026-10-09 〔事實〕 |
| 2025 超速 40 km/h 以下舉發 | 2,644,849 件 | 同上〔事實〕 |
| 2025 年 1–10 月汽車超速取締 | 台北 300,620、桃園 239,973、台中 219,515 件 | 警政署,經 [工商時報](https://www.ctee.com.tw/news/20251204701173-431401) 〔事實〕 |
| 單一熱點 | 台中忠明南路桿 2025 年開出 9,550 件 | [聯合新聞網](https://autos.udn.com/autos/story/121040/9247824)(搜尋摘要,發布日期未確認)〔事實〕 |

- 推論:測速照相這麼密集,台灣駕駛最在意的是「在照相點前確認車速」,而不只是「知道車速」。PTT 推文直接把兩者連在一起(a4cloud),Dashla 評論也要求整合測速神盾。所以在台灣,**車速顯示加測速提醒是一組需求**。
- 加重因素:Tesla 的「車速輔助」依賴圖資,無法辨識台灣部分隱含速限,因此 TNCAP 評等時有被點名([知新聞](https://www.knews.com.tw/news/9A3B84F0E0C1CC65E4D70DD53098E552),日期未確認,報導稱約兩年前)。原廠的超速提示音在台灣可能比較不可靠〔推論〕。
- **和 v1 範圍的衝突**:brief 把速限與超速警示延到 v1 之後,但台灣的直接競品 Dashla 已經提供測速提醒,用戶也把它當成核心功能〔推論〕。**修訂:已解決。** 04 §T3 和 10 把台灣固定測速提醒(D03)列入 v1(P0),只用警政署開放資料加 GPS。道路速限(D02)和一般超速警示仍延後(Issue #2)。測速提醒期間,車速超過該點限速時數字轉琥珀色,但不冒充全路段速限(10)。

### Q4 台灣最痛的族群

- **測速照相焦慮族**:幾乎涵蓋所有台灣車主,城市通勤和國道都包含。證據見上。
- **HUD 換車族**:「BMW新世代…做了超大的抬頭顯示」、「儀表板我是覺得根本沒差(舊車有hud)」(water6,反例:有 HUD 經驗的人也可能不在意)。
- **年長或視力不佳的駕駛**:在台灣找不到直接證據〔找不到可靠資料〕。

---

## Personas(以證據為基礎)

### P1「測速焦慮的台灣通勤車主」(台灣)
- **證據**:PTT a4cloud、coolsparrow;Dashla 評論者 BensonHMLin(要求整合測速神盾);TVBS 受訪車主(「餘光往下瞄,我就看得到時速」)。
- **情境**:每天會經過固定測速桿或區間測速。現在的做法是開神盾語音,再轉頭看中控確認車速。
- **想要**:在眼前看到車速,並在照相點前提早知道。不要動車,不要破保。
- **雇用門檻**:免費起步可以接受;對訂閱制有疑慮,希望能買斷(MarcoDDHHH:「希望可以推出一次性買斷的價格方案」)。
- **會開除產品的原因**:手機發燙、白天看不清楚、沒有測速提醒(這一點競品已經有;10 已把台灣測速提醒列入 v1)。

### P2「失去 HUD 的升級換車族」(美國為主,台灣也有)
- **證據**:Smile335(BMW i4M50 → M3P)、Anniam6(BMW M4/X3)、ZannX(Ioniq 5)、Jefe169("blind spot and HUD are top of list")、TheBokononInitiative("A HUD option would have enticed me to upgrade to a 3 Performance")。
- **想要**:真正的擋風玻璃 HUD 體驗,只顯示速度、方向燈和 ACC,不要擋到出風口,不要像「90 年代電子鐘」。(修訂:方向燈和 ACC 設定速度零硬體拿不到,10 列不做;這群人只能拿到車速,BLE 版再加檔位和電量,見 09、10)
- **雇用門檻**:看重外觀和質感;願意付硬體價,但怕破保。
- **會開除產品的原因**:畫面廉價、白天看不清、戴偏光墨鏡看不到。

### P3「長期無法適應的視力吃力駕駛」(美國證據;台灣待驗證)
- **證據**:Naosik(右駕車、右眼較弱,兩年仍不適應,眼睛疲勞);TMC 字體討論串 ⏳ 的 Backpacker42(50 歲以上、老花)、FRE0(遠近視眼鏡切換)、AC2DC(驗光師:"Not everyone who drives a Tesla is 25 yrs old")。
- **想要**:大字、高對比,放在接近路面視線的位置,不用切換眼鏡。
- **雇用門檻**:安全是最大動機,人數少但黏著度可能最高〔推論〕。
- **會開除產品的原因**:字不夠大、手機離眼睛更近反而更難對焦〔推論,待驗證〕。

> 不列為 persona、但是 GTM 關鍵的「時間窗」:**新車主前 1–4 週**。這群人最多,但痛點會自然消失("you'd get use to it within a week",[13wq2n4](https://www.reddit.com/r/TeslaModelY/comments/13wq2n4/))。價格門檻也低,例如不想為 Teslogic 付 $200。適合用免費試用在交車時切入,但留存風險高〔推論〕。

---

## Jobs-to-be-done

| # | 工作陳述(用戶「雇用」產品來…) | 證據 | 市場 |
|---|---|---|---|
| J1 | **視線不離開路面,也能用餘光確認車速** | TVBS「餘光往下瞄,我就看得到時速」;"I dislike taking my eyes off the road for any reason" | 美、台 |
| J2 | **經過測速照相時不被開單**(知道車速,也知道前面有照相) | PTT a4cloud;Dashla 評論;1,809 處測速照相。修訂:10 已把 D03 列入台灣 v1 | 台 |
| J3 | **不改裝、不破保、不怕韌體更新,就把資訊放回眼前** | wongl888(服務中心說會破保);short_bus_genius(怕韌體更新失效);electrify.tw | 美、台 |
| J4 | **找回舊車 HUD「抬眼即知」的習慣** | Smile335、ZannX、PTT green0616 | 美為主 |
| J5 | **變換車道或轉彎時,在眼前看到方向燈、盲點和轉彎提示** | p0zvus;Dashla 評論;sm753。修訂:這三項零硬體都拿不到(09),10 列不做,上架描述要寫清楚 | 美、台 |
| J6 | **用 FSD/AP 時,確認車速不會觸發「請注意路況」警告** | jrender5(2024-03-18);Not a Tesla App 2025-05-17 | 美(推論為主) |
| J7 | **還沒習慣中控之前,幫我撐過交車後的頭幾週**(短期工作) | NSA_GOV、Dull_Reflection3454、Radiobamboo | 美、台 |

---

## 假設

1. **把 Reddit 和 TMC 當作美國樣本。** 這些社群是全球性的,例如 Naosik 開右駕車。我沒有過濾地區,所以美國的比例只是粗略代理。
2. **1/3 對 2/3 的比例有雙向偏差。** 「發問串」偏向抱怨者,「不懂大家在吵什麼」這類串偏向適應者。樣本 n≈105,只算明確表態的回覆。
3. 台灣的負面比例主要來自 1 篇 PTT 回文串,樣本小,而且有自選偏差。
4. **Facebook 車主社團、Mobile01、TMC 原站、Amazon 評論都無法直接抓取**,前三者被擋或需要登入,Amazon 回應 503。Mobile01 和 Amazon 只用到搜尋摘要;TMC 改用 Wayback 存檔頁,只拿到第 1 頁。**YouTube 留言沒有讀取**,這是缺口(修訂:07 已補讀 21 支影片約 1,090 則留言;Amazon、蝦皮、Mobile01 仍然抓不到)。
5. Dashla 的評論只看到 App Store 網頁顯示的 10 則,不是全部 269 則評分(修訂:07 已用評論 API 讀完台區全部 83 則有內文的評論)。
6. 「v1 能否提供」這一欄依 09(拿不拿得到)和 10(版本),不再是推論(修訂)。方向燈、盲點、AP 狀態、導航下一轉彎,零硬體都拿不到。所有 BLE 項目在 repo 仍是「schema 有、待實車驗證」(主持人裁決,2026-10-17)。
7. TVBS 的車主引述沒有具名,也沒有車款資訊。

## 待驗證問題(需要訪談真實車主)

1. 你交車後幾天、幾週才不再刻意找車速?現在每次開車大約看幾次車速?
2. 台灣車主:你在測速照相前是怎麼確認車速的?神盾、看中控,還是憑感覺?過去一年收過幾張超速單?
3. 你有沒有因為怕破保或怕擋到出風口,而放棄副廠儀表?如果是不用動車的手機方案,你願意付多少?買斷或訂閱?
4. 手機放在儀表板上,白天看得清楚嗎?會擋視線、會發燙嗎?戴偏光墨鏡時看得到 mirror mode 嗎?
5. 戴老花或多焦眼鏡的駕駛:手機放在方向盤後面,比中控好讀還是更難讀?
6. 用 FSD 或 AP 時,看中控確認車速有被警告過嗎?多常發生?
7. 「除了速度,drive 模式最想加哪一項」07 已用聲量回答(修訂)(美國依序是盲點、導航、速限、AP/FSD、方向燈;台灣是測速提醒)。因為前幾名零硬體拿不到,改問 10 的題目:「沒有方向燈和盲點,你會改用 Dashla+TITA 嗎?」
8. 從 HUD 車換過來的車主:手機方案能取代 HUD 的感覺嗎?缺的是什麼?
9. Dashla 用戶:你為什麼裝?留下來或刪掉的原因是什麼?(BLE 手機鑰匙會影響入檔嗎?)

## 來源

**美國:Reddit**(透過 RSS 取得,回覆日期見正文)
- r/TeslaModel3:[12qsm0m](https://www.reddit.com/r/TeslaModel3/comments/12qsm0m/)(2023-04)、[1m6d1hq](https://www.reddit.com/r/TeslaModel3/comments/1m6d1hq/)(2025-07)、[1tfgeqw](https://www.reddit.com/r/TeslaModel3/comments/1tfgeqw/)(2026-05)、[x35hix](https://www.reddit.com/r/TeslaModel3/comments/x35hix/)(2022-09 ⏳)、[p0zvus](https://www.reddit.com/r/TeslaModel3/comments/p0zvus/)(2021-08 ⏳)
- r/TeslaModelY:[13wq2n4](https://www.reddit.com/r/TeslaModelY/comments/13wq2n4/)(2023-05)、[156vs5p](https://www.reddit.com/r/TeslaModelY/comments/156vs5p/)(2023-07)、[15nahtd](https://www.reddit.com/r/TeslaModelY/comments/15nahtd/)(2023-08)、[18n58os](https://www.reddit.com/r/TeslaModelY/comments/18n58os/)(2023-12)、[1bhcymk](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/)(2024-03)、[1eqpcct](https://www.reddit.com/r/TeslaModelY/comments/1eqpcct/)(2024-08)、[1f2jycg](https://www.reddit.com/r/TeslaModelY/comments/1f2jycg/)(2024-08)、[1m8xcde](https://www.reddit.com/r/TeslaModelY/comments/1m8xcde/)(2025-07)

**美國:論壇與媒體**
- TMC [no-cluster-screen](https://teslamotorsclub.com/tmc/threads/no-cluster-screen.231168/)(2021-06 ⏳,Wayback 存檔)、[small-screen-font-on-ui](https://teslamotorsclub.com/tmc/threads/small-screen-font-on-ui.186209/)(2020 ⏳,Wayback 存檔)
- [CleanTechnica HUD 民調結果](https://cleantechnica.com/2017/05/03/tesla-model-3-hud-huge-demand-even-wont-arrive-poll-results/)(2017-05-03 ⏳)
- [The Drive:Aftermarket Instrument Clusters](https://www.thedrive.com/news/40610/aftermarket-instrument-clusters-fix-tesla-model-3s-main-omission)(2021-05-13 ⏳)
- [Not a Tesla App:FSD v13.2.9 放寬駕駛監控](https://notateslaapp.com/news/2734/tesla-loosens-driver-monitoring-on-fsd-v1329)(2025-05-17)
- [InsideEVs:Model 3 方向燈撥桿回歸](https://insideevs.com/news/769401/tesla-turn-signal-stalk-model-3/)(2025)
- [HUDScreen:Tesla HUD 指南](https://hudscreen.com/tesla-head-up-display/)(2026,零售商)、[Yeslak 8.9 吋儀表](https://www.yeslak.com/products/tesla-8-9-instrument-cluster-for-model-3-y)(賣家頁)、[ShopSavvy 評論彙整](https://shopsavvy.com/reviews-tldr/%22tesla-model-y3-9.6%22-heads-up-display)
- Tesla 使用手冊:[Model 3 Car Status](https://www.tesla.com/ownersmanual/model3/en_hk/GUID-80B80D48-E3A9-4857-864B-F4CC9B56FD7E.html)、[2025+ Model Y 台灣版(軟體 2026.32)](https://www.tesla.com/ownersmanual/modely/zh_tw/Owners_Manual.pdf)
- 日本參考(非美台樣本):[teskas.net 15801](https://teskas.net/t/topic/15801?tl=en)、[teskas.net 17184](https://teskas.net/t/topic/17184?tl=en)

**台灣**
- PTT car:[M.1771258724](https://www.ptt.cc/bbs/car/M.1771258724.A.546.html)(2026-02-17)、[M.1760975758](https://www.ptt.cc/bbs/car/M.1760975758.A.334.html)(2025-10-20)、[M.1715425739](https://www.ptt.cc/bbs/car/M.1715425739.A.DD9.html)(2024-05-11)
- [TVBS:特斯拉車主自行開發「超神APP」](https://cars.tvbs.com.tw/life/310983)(2026-03-16)
- [electrify.tw:Dashla 補上儀表板](https://electrify.tw/dashla-tesla-dashboard/)(2026-03-30)
- [Dashla App Store(台區)評論](https://apps.apple.com/tw/app/id6760206753?see-all=reviews)(2026-03~05);iTunes lookup [TW](https://itunes.apple.com/lookup?id=6760206753,6762794279&country=tw) / [US](https://itunes.apple.com/lookup?id=6760206753,6762794279&country=us)(2026-10-16 查詢);[hunted.space](https://hunted.space/product/dashla-dashboard-for-tesla)(開發者自述)
- [DDCAR:無線充電 HUD 踩雷](https://www.ddcar.com.tw/blogs/articles/detail/772/)(只取得標題,日期不明)
- [中央社:測速照相設置標準檢討](https://www.cna.com.tw/news/ahel/202512040174.aspx)、[工商時報:台灣測速密度為日本307倍](https://www.ctee.com.tw/news/20251204701173-431401)(2025-12-04)
- [風傳媒:1年1600萬張罰單](https://www.storm.mg/article/11171140)(2026-10-09)
- [聯合新聞網:2025 台中測速桿王](https://autos.udn.com/autos/story/121040/9247824)
- [知新聞:Model Y 車速輔助在台無法辨識隱含速限](https://www.knews.com.tw/news/9A3B84F0E0C1CC65E4D70DD53098E552)(日期未確認)
