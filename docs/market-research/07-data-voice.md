# 07 — 車主想在眼前看到哪些資料(需求聲量)(pain)

> 研究日期:2026-10-17。延伸 `01-pain-points.md` §Q3(美國、台灣),不是重做;01 的引述直接併入下表。標記:〔事實〕有來源的直接陳述;〔估計〕依樣本粗算;〔推論〕研究員判斷。⏳ = 資料超過 2 年(早於 2024-10-17)。

## 重點結論

1. **車速以外,行駛中最常被要求的是「變換車道與轉彎」那一刻的資訊。** 不含基準項目,美國依序是盲點(20 則)、導航下一個轉彎(19)、速限(15)、Autopilot/FSD 狀態(13)、方向燈(12)。台灣是測速照相提醒(約 19 則;Dashla 台區 83 則有內文的評論中 11 則,占 13%)、導航(9)、方向燈(6)〔估計〕。
2. **電量、續航、檔位是「基準項目」**:很少人主動要求,但數字不準會被罵,例如 SOC 顯示 101%、比車上多 2%、Tesla 更新後卡在 17% 或續航跳到 3,000 英里。這三項必須有、必須準,但不需要大〔事實,多源;推論〕。
3. **胎壓、充電、行程、總里程、車門、車外溫度、空調幾乎沒有「行駛中要看」的聲量**,只在停車時被提起,或完全找不到 → 適合放 parked 模式〔估計 + 推論〕。
4. **極簡派存在,但「只要車速」是少數。** 明確說出想看什麼的約 40 人中,只要車速的有 10 人(約 1/4),約 24 人要「車速 + 1–4 個指示」,約 6 人要豐富儀表〔估計〕。證據支持「drive 模式以車速為主角」,**不支持「只顯示車速」**:建議保留只在觸發時才出現的小指示,例如打方向燈時的方向燈/盲點、接近照相點時的測速提醒〔推論〕。
5. **族群差異明顯。** 視力吃力者要「少而大」;HUD 換車族要「車速 + 速限 + 導航箭頭」;台灣測速焦慮族要「車速 + 測速提醒」;性能派要功率、溫度、0–60 計時,但多半停車時才看;交車新車主多半只要車速(樣本都很小,見 §族群差異)。

---

## 總表(D01–D28;X01–X04 沿用 08 的編號,X05–X06 為本報告新增)

**計數方法**
- **語料**(全部在 2026-10-17 抓取,詳見 §來源):

| 來源 | 市場 | 則數 | 期間 |
|---|---|---|---|
| App Store 評論:Dashla 台區 83、TeraScreen 台區 9 | 台 | 92 | 2026-03~10 |
| App Store 評論:DriveCluster 7、Teslogic 12、S3XY Gadgets 39、Dashla 美區 4、Dash for Tesla 2 | 美 | 64(另排除韓文 3、簡中 8) | 2021~2026 |
| YouTube 留言:台灣 6 支影片(DDCAR、TVBS、Enhance 中文評測等) | 台 | 238 | 影片 2025-11~2026-08 |
| YouTube 留言:美國 15 支 HUD/儀表評測影片 | 美 | 855 | 影片 2020~2026 |
| Reddit:r/TeslaModel3、r/TeslaModelY、r/TeslaLounge、r/teslamotors 搜尋結果加 29 個留言串 | 美 | 約 1,250 | 2016~2026 |
| TMC(Wayback 存檔,3 串第 1 頁) | 美 | 47 | 2020~2021 ⏳ |
| PTT car 板(6 串推文) | 台 | 約 120 則推文 | 2024~2026 |

- **計數單位**:同一來源中**不同的人**。只有明確表示「想在眼前看到/希望儀表顯示」,或對既有顯示的準確度表示抱怨或稱讚(基準項目)時才算。只是提到這個詞不算。
- **則數寫法**:「總則數(2024 年以後的則數)」。分級依 **2024 年以後的則數**,避免舊討論灌水:美國 高 ≥8、中 4–7、低 1–3;只有 2024 年以前的證據時一律列「低」。台灣證據幾乎都是 2026 年,語料約是美國的 1/6,所以門檻較低:高 ≥6、中 3–5、低 1–2。無 = 試過關鍵字和一次定向搜尋,仍找不到。門檻是研究員的判斷〔推論〕。
- 個別引述早於 2024-10-17 的標 ⏳。所以「2024 年以後」的則數裡,也可能有標 ⏳ 的引述(2024 年 1–10 月)。
- **基準項目**(D01、D04、D09、D10):現有 App 已經顯示,所以很少人「要求」。這幾項改用「準確度抱怨或稱讚」來衡量,以免排名被競品缺什麼功能扭曲。
- **「想在哪看」**:引述本身有說「變換車道時」「瞄一眼」「照相前」等情境,才標〔事實〕;其餘是〔推論〕。

| ID | 資料點 | 美國聲量(則) | 台灣聲量(則) | 想在哪看 | 反對/「資訊太多」證據 | 代表引述與來源 |
|---|---|---|---|---|---|---|
| D01 | 車速 | **高**(基準;01 ~36 人想要 + 本次 10 人「只要車速」+ 準確度回饋 ≥5) | **高**(基準;PTT ~10、TVBS、Dashla) | 行駛中瞄一眼〔事實〕 | 01:約 2/3 美國回覆者幾週內就適應中控;"I LOVE not having a distracting display directly in front of me"([YT G1Un](https://www.youtube.com/watch?v=G1UnqSz0CuQ) 2025) | "I only need to know speed"([YT G1Un](https://www.youtube.com/watch?v=G1UnqSz0CuQ),留言約 2025);「餘光往下瞄,我就看得到時速」([TVBS](https://cars.tvbs.com.tw/life/310983) 2026-03-16);準確度:「時速表顯示與車中控螢幕顯示有速差…紅燈停下…還顯示0以外的數字」([TeraScreen 評論](https://apps.apple.com/tw/app/id6761311983?see-all=reviews) 2026-08-03) |
| D02 | 道路速限 | **高** 15(11) | 低 1(超速提示) | 行駛中瞄一眼〔事實〕 | "You have chimes to let you know if you're going over the speed limit"([12qsm0m](https://www.reddit.com/r/TeslaModel3/comments/12qsm0m/) 2023-04 ⏳) | "I need speed and speed limit in my view at all times"([YT U6tr](https://www.youtube.com/watch?v=U6tr-7gk7ds),約 2025);"Looking to my right to catch a glimpse of my speed and further right to see the Speed Limit"([1ptlwiv](https://www.reddit.com/r/TeslaLounge/comments/1ptlwiv/) 2025-12-23);"with commander you can set up a phone to project your speed and speed limit (from the cars data, not GPS)"(同串);台:「APP設定超速聲音提醒,沒有作用」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-04-15) |
| D03 | 測速照相提醒 | 低 3(3)(Waze 警察/取締警示、施工與測速陷阱;另 2 則只提到雷達偵測器) | **高** ~19(Dashla 11/83 = 13%,另 1 則是超速提示;YT 7;PTT 1) | 行駛中瞄一眼(照相點前)〔事實〕 | 可靠度疑慮:「有時候通過沒有提示聲…會把對向的測速機也偵測進去」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-09-10);「我覺得還是神盾實用」([YT DDCAR](https://www.youtube.com/watch?v=18xc2ORF7Ww),2026) | 「主要還是為了測速功能」(allan078,[YT DDCAR](https://www.youtube.com/watch?v=18xc2ORF7Ww) 2026);「我最喜歡的就是綠燈提示和測速提醒」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-06-12);美:"Waze, Waze and Waze. (Alerts and stuff to slow down in order to avoid a ticket)"([YT 1h6i](https://www.youtube.com/watch?v=1h6iMji7VZU),約 2026) |
| D04 | 檔位 P/R/N/D | 低 4(2)(基準) | 低 1(基準) | 行駛中瞄一眼(起步、倒車換檔時)〔推論〕 | "Don't need P/N/R/D/L/1/2/3 shift indicator"([1bhcymk](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/) 2024-03-18 ⏳);「…whether I'm in drive or park right in front of me?」([YT G1Un](https://www.youtube.com/watch?v=G1UnqSz0CuQ)) | Highland 中控的檔位區被方向盤遮住:"the gear selection along with nav selection is on that part of the display"([1oulcn1](https://www.reddit.com/r/TeslaLounge/comments/1oulcn1/) 2025-11-11);台:評 TeraScreen「只有時速 檔位和續航三個基本功能…感覺蠻陽春的」([App Store](https://apps.apple.com/tw/app/id6761311983?see-all=reviews) 2026-06-23) |
| D05 | 方向燈 | **高** 12(8) | **高** 6(Dashla 5/83 = 6%;YT 1) | 行駛中瞄一眼(變換車道)〔事實〕 | 弱:"They only display speed, gear selected and turn signals… I think they are unnecessary"([13wq2n4](https://www.reddit.com/r/TeslaModelY/comments/13wq2n4/) 2023 ⏳) | "it is nice to quickly see this when changing lanes on the highway, without having to look at the center display"([YT 1h6i](https://www.youtube.com/watch?v=1h6iMji7VZU),約 2026);"the turn indicators on the center screen are dim, tiny"([YT 9F0](https://www.youtube.com/watch?v=9F0imlRJt9A),約 2024 ⏳);「建議能增加方向燈符號」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-03-13) |
| D06 | 盲點/側後方來車 | **高** 20(14) | **中** 3 | 行駛中瞄一眼(變換車道前)〔事實〕 | 視覺化/後視鏡就夠:"Blind spots covered in visualization."([p0zvus](https://www.reddit.com/r/TeslaModel3/comments/p0zvus/) 2021 ⏳)。原廠在補:Highland 以後有車門喇叭罩 BSM 燈([1eha2vu](https://www.reddit.com/r/TeslaModel3/comments/1eha2vu/) 2024-08-01 ⏳;[1oulcn1](https://www.reddit.com/r/TeslaLounge/comments/1oulcn1/) 2025-11-11),2026.14 春季更新加入氛圍燈盲點警示([1t9nqnd](https://www.reddit.com/r/TeslaModel3/comments/1t9nqnd/) 2026-05-11)〔事實,車主轉述〕 | "My primary purpose was to get a 'blind spot monitor' in my field of view as the Tesla LEDs in the door speakers are next to worthless"(2026 Model Y 車主,[YT G1Un](https://www.youtube.com/watch?v=G1UnqSz0CuQ) 約 2025);"No blind spot indicators? No good."([YT 9F0](https://www.youtube.com/watch?v=9F0imlRJt9A),約 2024 ⏳);"drivers wanted something more in their vision so with Highland they added in the pilars near the mirrors..but its kind of small"([15w4svy](https://www.reddit.com/r/TeslaModelY/comments/15w4svy/) 2025-01-04);2023 Model Y 車主自購副廠盲點燈,想要「something simple like the Model 3 Highland blind spot indicator light」([1hmunzo](https://www.reddit.com/r/TeslaModelY/comments/1hmunzo/) 2024-12-26);「舊y盲點警示只有在車機上 希望可以手機介面提示左右側」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-04-15) |
| D07 | 定速/TACC 設定速度 | 低 6(3) | 低 1 | 行駛中瞄一眼〔事實〕 | 無 | "Because of the cruise control set speed display and adjustment, you have to constantly look to the right at the big screen"([YT dpvS](https://www.youtube.com/watch?v=dpvSntqXmto),約 2025);"just a HUD to show speed, ACC and basic stuff"([1m6d1hq](https://www.reddit.com/r/TeslaModel3/comments/1m6d1hq/) 2025-07-22);「抬頭顯示器還是很重要的 至少給時速和定速多少」([PTT](https://www.ptt.cc/bbs/car/M.1771258724.A.546.html) 2026-02-17) |
| D08 | Autopilot/FSD 狀態、接手警告 | **高** 13(9) | 低 2 | 行駛中瞄一眼〔事實〕 | 「有 FSD 就不需要」:"if the end goal is FSD/Robotaxi then adding a HUD doesn't make sense"([1m8xcde](https://www.reddit.com/r/TeslaModelY/comments/1m8xcde/) 2025-07-25);"After a year with my MYJ I don't notice the lack…especially with FSD"([YT UcW3](https://www.youtube.com/watch?v=UcW3yo5Qv98) 2026);"Plus with FSD all of that is useless info anyway"([1ptlwiv](https://www.reddit.com/r/TeslaLounge/comments/1ptlwiv/) 2025-12-23)(美約 11 則) | "Can it show FSD ALERTS?"([YT dpvS](https://www.youtube.com/watch?v=dpvSntqXmto));"struck out for tiny things like glancing over at the speedometer"([1h4kzb1](https://www.reddit.com/r/TeslaModel3/comments/1h4kzb1/) 2024-12-02,歐洲);「有沒有機會加入AP手扶提示音」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-10-07) |
| D09 | 電量 % | **高** 13(11)(基準;幾乎都是準確度抱怨,其中 4 則來自同一次韌體更新事件) | 低 1(基準;只有 TVBS 報導提及) | 兩者〔推論〕 | "Don't (really) need a battery gauge"([1bhcymk](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/) 2024-03 ⏳) | "the screen shows the battery level as '101%'? How can you rely on something like that?"([YT -_3x](https://www.youtube.com/watch?v=-_3xYtT5AkY) 約 2025);"Car says 100% and display says 87"([1ezmqn9](https://www.reddit.com/r/TeslaModel3/comments/1ezmqn9/) 2024-08-23 ⏳);Tesla 2024.20.1 更新後 Hansshow F68 "the battery on the display is constantly at 100% and the range is over 3000 miles"、"Stuck at 17 percent and range mile bounces all over the place"([1cryq59](https://www.reddit.com/r/TeslaModel3/comments/1cryq59/) 2024-06 ⏳);"speed, SOC, abbreviated alarms"([1m6d1hq](https://www.reddit.com/r/TeslaModel3/comments/1m6d1hq/) 2025) |
| D10 | 續航里程 | **中** 10(7)(基準;含 3 則同一次韌體事件) | 低 1(基準) | 兩者〔推論〕 | 無 | "the dashboard shows me range in miles while the main screen shows the cars battery percentage"([1uoxym5](https://www.reddit.com/r/TeslaModelY/comments/1uoxym5/) 2026-07-06);"show only what actually matters and in larger font (speed, speed limit, remaining range)"([1441tj7](https://www.reddit.com/r/TeslaModelY/comments/1441tj7/) 2023-06 ⏳) |
| D11 | 即時功率/動能回收 | 低 6(3) | 無 | 行駛中瞄一眼(性能派)〔事實,單一引述:"see…speed and power output without tilting my head"〕 | "Don't need RPM's"([1bhcymk](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/));"leave behind the tachometers"([1m6d1hq](https://www.reddit.com/r/TeslaModel3/comments/1m6d1hq/) 2025-07-23) | "Why is the power usage bar on the side of the screen? It's impossible to see now."([1coukyl](https://www.reddit.com/r/TeslaLounge/comments/1coukyl/) 2024-05-10 ⏳);"turn signals, brake lights, and RPM/power data"([1rtpolp](https://www.reddit.com/r/TeslaModel3/comments/1rtpolp/) 2026-03-14) |
| D12 | 導航下一個轉彎 | **高** 19(12) | **高** 9(需求 6、與車機不同步的抱怨 3) | 行駛中瞄一眼〔事實〕 | "got distracting when I used nav, the turn instructions were off putting"(試駕 Audi Q6 的 HUD,[1ptlwiv](https://www.reddit.com/r/TeslaLounge/comments/1ptlwiv/) 2025-12-23);手機導航 ≠ 車機導航會造成混亂:「手機顯示路線跟特斯拉畫面路線不同 該看特斯拉的還是手機的」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-03-23);「畫蛇添足 直接用特斯拉網路 導航 FSD」([YT S3XY 中文](https://www.youtube.com/watch?v=MTSHsp305pE)) | "Would be awesome if we can add some navigation symbols (left turn / right turn etc)"([DriveCluster](https://apps.apple.com/us/app/id6762794279?see-all=reviews) 2026-06-16);"HUD also shows navigation, so you only need to look at the center display to change music or HVAC settings. You need to monitor your speed continuously"(BMW HUD 車主,[1tpoejs](https://www.reddit.com/r/TeslaLounge/comments/1tpoejs/) 2026-05-30);"navigation arrows in a tiles without the map (Like left in 300 Meters)"([YT ij1w](https://www.youtube.com/watch?v=ij1w0mmpW8U));「希望抬頭顯示的導航提醒字幕都可以大一點」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-04-11) |
| D13 | 導航 ETA/剩餘距離/抵達電量 | 低 2(0)(僅 ⏳) | 無 | 兩者〔推論〕 | 無 | "ETA below the time. Arrival battery below the battery."([14rru2q](https://www.reddit.com/r/TeslaModel3/comments/14rru2q/) 2023-07 ⏳);"I look at the time, and ETA during nav, way more than I look at the speedometer"([8t44wg](https://www.reddit.com/r/TeslaModel3/comments/8t44wg/) 2018 ⏳) |
| D14 | 時間 | **中** 5(4)(含 2 則要 12 小時制) | 低 1(另 1 則反對) | 兩者〔推論〕 | 「直式的時候iOS似乎不需要多提供時間在左上角,畫面可以更簡約」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-03-20);"distracted with the time of day"([YT G1Un](https://www.youtube.com/watch?v=G1UnqSz0CuQ)) | "the time (clock) is way too small on the Tesla screen, to the point that I installed a secondary clock"([YT UcW3](https://www.youtube.com/watch?v=UcW3yo5Qv98) 2026);「希望可以讓時間的顯示更大更醒目,改善本來車機畫面上太小的問題」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-05-07) |
| D15 | 胎壓 | **中** 9(5)(2024 後多為「能不能顯示」的提問,另 1 則抱怨不準) | 低 1 | 停車時(出發前)〔推論〕 | 無 | "Can it show the tire pressure?"([YT 1h6i](https://www.youtube.com/watch?v=1h6iMji7VZU));"you still can't check your tire pressure without using the instrument cluster"(舊款 Model S,[1m80bj4](https://www.reddit.com/r/TeslaLounge/comments/1m80bj4/) 2025-07-24);「它的胎壓什麼的…從正面看手機的時候,就會比較清楚」([TVBS](https://cars.tvbs.com.tw/life/310983) 2026-03-16) |
| D16 | 車輛警示/警告燈 | **中** 9(4) | 無(AP 手扶歸 D08) | 行駛中瞄一眼(警示當下)〔事實〕 | 無 | "I hear alerts and by the time I can look there is NOTHING on the screen saying what is wrong"([1bhcymk](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/) 2024-03-18 ⏳);"I have trouble seeing the warning on the central touchscreen"([YT U6tr](https://www.youtube.com/watch?v=U6tr-7gk7ds) 約 2025) |
| D17 | 大燈/遠光燈 | 低 7(2) | 無 | 行駛中瞄一眼(夜間)〔推論〕 | 無 | "Having a hud with speed/turn/high beam indicators would be 'nice'"([1bhcymk](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/) 2024-03-18 ⏳);"What kind of indication do you get when you use the high beams?"([YT 9F0](https://www.youtube.com/watch?v=9F0imlRJt9A),約 2024 ⏳) |
| D18 | 車外溫度 | 低 1(1) | 無 | 停車時〔推論〕 | "Why would I want to be distracted with the time of day, outside temperature…"([YT G1Un](https://www.youtube.com/watch?v=G1UnqSz0CuQ)) | "Can you update so the temperature does Fahrenheit"([DriveCluster](https://apps.apple.com/us/app/id6762794279?see-all=reviews) 2026-04-24) |
| D19 | 本趟行程 | 低 4(1) | 無 | 停車時〔推論〕 | 無 | "none of the wh/mi stats on the app match what's shown on the teslas screen"([Teslogic](https://apps.apple.com/us/app/id1623563438?see-all=reviews) 2025-01-22);"Trip odometer. This really shouldn't be 2 buttons deep"([rqppw4](https://www.reddit.com/r/TeslaLounge/comments/rqppw4/) 2021 ⏳) |
| D20 | 總里程 | 低 2(2)(只說「有顯示」,沒人要求) | 無 | 停車時〔推論〕 | 無 | "It also displays the accumulated mileage on your car"([YT 9F0](https://www.youtube.com/watch?v=9F0imlRJt9A),約 2025) |
| D21 | 充電狀態 | 無(找不到可靠資料) | 無 | 停車時〔推論〕 | — | 語料與一次定向搜尋都找不到「想在儀表看充電」的車主發言;供給面有 DriveCluster Live Activities 充電進度(見 02) |
| D22 | 車門/車廂/車窗狀態 | 低 1(1) | 無 | 停車時(下車前)〔推論〕 | "too many items to remember" | "The default screen is perfect if you just want the speedometer, gears, psi, doors"([YT 9F0](https://www.youtube.com/watch?v=9F0imlRJt9A),約 2024 ⏳) |
| D23 | 周遭車輛視覺化 | 低 2(0)(僅 ⏳) | 低 1 | 行駛中瞄一眼(有爭議)〔推論〕 | "Wife doesn't like the moving graphics of the surrounding traffic, finding it distracting"([1441tj7](https://www.reddit.com/r/TeslaModelY/comments/1441tj7/) 2023 ⏳);"I dont care to see the display of other cars around me"([1upe1dn](https://www.reddit.com/r/TeslaModelY/comments/1upe1dn/) 2026-07-07) | "Can you make a screen that provides the traffic visualization? That is the most important feature."([YT 59ZO](https://www.youtube.com/watch?v=59ZOp4_O_48) 約 2023 ⏳);「行進間有在左邊或右邊有車車行進的動畫」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-03-23) |
| D24 | 跟車距離/前車碰撞警示 | 無 | 無(只有動機) | 行駛中瞄一眼〔推論〕 | — | 找不到「想看跟車距離」的要求。台灣只有一則動機描述:「瞄一下大螢幕的時候…被嚇到說可能突然一下離前車太近了」([TVBS](https://cars.tvbs.com.tw/life/310983) 2026-03-16) |
| D25 | 轉彎/倒車影像 | **高** 10(9) | 低 2 | 行駛中瞄一眼(打方向燈時)〔事實〕 | "a distracting pop-up image from your rear-facing side-view camera"(認為中控彈出影像反而干擾,[YT U6tr](https://www.youtube.com/watch?v=U6tr-7gk7ds));Model X 前方儀表 "Screen comes on when blinkers are on, which becomes distracting, and adds little value"([1ptlwiv](https://www.reddit.com/r/TeslaLounge/comments/1ptlwiv/) 2025-12-23) | "If this would also display the blind spot cameras when a turn signal is activated, then it'd be the winner."([YT 9F0](https://www.youtube.com/watch?v=9F0imlRJt9A),約 2024 ⏳);「建議可以再打方向燈時,將中控螢幕顯示側邊葉子版的鏡頭投影到app內,轉彎時就不用特地將視角轉至中控螢幕」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-04-25) |
| D26 | 媒體/音樂 | **中** 7(6) | 低 1 | 兩者〔推論〕 | 供給面:Dashla 塞入歌詞被指造成發燙(見 02) | "additional info such as direction and music info";"having the dash for speed/directions/music/side view cameras is so much better than looking at the main screen";"display song lyrics while in fsd"(皆 [1ptlwiv](https://www.reddit.com/r/TeslaLounge/comments/1ptlwiv/) 2025-12-23);「歌詞 測速 車機資料都有 超符合需求」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-06-25) |
| D27 | 空調/車內溫度 | 低 1(1) | 無 | 兩者(調整空調時)〔推論〕 | 無 | 調整風量時在眼前回饋:"if you change the fan speed with the knob…you will get a corresponding indication on the screen"([YT dpvS](https://www.youtube.com/watch?v=dpvSntqXmto)) |
| D28 | 性能數據(馬達/電池溫度、G 值、0–60) | **中** 9(6) | 無 | 停車時(賽道例外)〔推論〕 | "Don't need RPM's"、"leave behind the tachometers"(同 D11) | "Like horse power and wattage and regen numbers, temps"([YT dpvS](https://www.youtube.com/watch?v=dpvSntqXmto) 約 2025);"I can still see the battery temperature, all the time"([YT U6tr](https://www.youtube.com/watch?v=U6tr-7gk7ds));"It doesn't show peak horsepower"([S3XY](https://apps.apple.com/us/app/id1573536047?see-all=reviews) 2024-10-30) |
| X01 | 紅綠燈號誌/綠燈起步提示 | 無 | 低 2 | 行駛中瞄一眼(停等紅燈時)〔推論〕 | 無 | 「我最喜歡的就是綠燈提示和測速提醒」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-06-12);「紅綠燈顯示對於第幾個路口轉彎很好用」(同上 2026-04-09) |
| X02 | 煞車燈/Hold 駐車狀態 | 低 1(1) | 低 1 | 行駛中瞄一眼〔推論〕 | 無 | "turn signals, brake lights, and RPM/power data"([1rtpolp](https://www.reddit.com/r/TeslaModel3/comments/1rtpolp/) 2026-03-14);「燈號顯示有煞車燈、方向燈、盲點偵測」([YT Enhance 中文](https://www.youtube.com/watch?v=6zffi730PFo) 約 2026) |
| X03 | 天氣/海拔/指南針 | 低 3(2) | 無 | 停車時〔推論〕 | 無 | "Display of altitude / elevation, bonus points if it's visualized on the map"([1nu2phn](https://www.reddit.com/r/TeslaLounge/comments/1nu2phn/) 2025-09-30,許願清單,未指定前方);方向盤後的手機跑 "a weather radar app"([YT dpvS](https://www.youtube.com/watch?v=dpvSntqXmto) 約 2025);"Compass is now hidden when active navigation is in progress"([rqppw4](https://www.reddit.com/r/TeslaLounge/comments/rqppw4/) 2021 ⏳) |
| X04 | 第三方 App 投放(CarPlay/Waze) | **中** 7(7) | 低 2 | 行駛中瞄一眼〔推論〕 | 「畫蛇添足」(同 D12) | "Apple CarPlay in Waze is a must"([YT UcW3](https://www.youtube.com/watch?v=UcW3yo5Qv98) 2026);"Waze or Google Maps are must features - especially since Tesla removed all street names from their map!"([YT 1h6i](https://www.youtube.com/watch?v=1h6iMji7VZU));「請問這有可能會支援carplay嗎」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-03-28) |
| X05 | 目前道路/國道里程數(新) | 低 1(1) | 低 1 | 行駛中瞄一眼〔推論〕 | 無 | 「可否在國道上時,可否加上正在幾公里處?」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-04-07);"It shows me my speed, what road I'm on"([1m8xcde](https://www.reddit.com/r/TeslaModelY/comments/1m8xcde/) 2025-07-25) |
| X06 | 後方影像常駐/電子後視鏡(新) | 低 1(0)(僅 ⏳) | 低 1 | 行駛中瞄一眼〔推論〕 | 無 | 「可以新增單獨顯示後鏡頭嗎?可以直接變電子式照後鏡」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-10-12);"Partially solve my wish to look at back cam while driving"([xbpg4x](https://www.reddit.com/r/TeslaModel3/comments/xbpg4x/) 2022 ⏳) |

> 不是資料點、但很常被提的**形式需求**:台灣約 10 則想用 **iPad mini/平板**當儀表(Dashla 評論 3 則、DDCAR 留言約 6 則、TVBS 1 則),例如「手機太小了,裝一台平板吧,這樣地圖也比較清楚」([YT TVBS](https://www.youtube.com/watch?v=hNnH9WiHpx0) 2026)。美國也有零星的「larger screen」要求〔事實〕。這和極簡派相反,要嘛想看更多,要嘛想要更大的字,目前無法分辨〔推論〕。

---

## 美國 Top 10

排序依據:總則數(括號內為 2024 年以後的則數);同分時看 2024 年以後的則數。如果只按 2024 年以後的則數排序,前 7 名幾乎相同,差別是 X04 CarPlay/Waze(7)會擠進前 10〔估計〕。

| # | ID | 資料點 | 則數 | 想在哪看 | 註記 |
|---|---|---|---|---|---|
| 1 | D01 | 車速 | 基準(01 ~36 人 + 10 人「只要車速」) | 行駛中瞄一眼 | 01 已證實;本次重點是準確度與延遲 |
| 2 | D06 | 盲點 | 20(14) | 行駛中瞄一眼(變換車道前) | 原廠已加車門 BSM 燈與氛圍燈警示,但仍有人嫌「next to worthless」「kind of small」 |
| 3 | D12 | 導航下一個轉彎 | 19(12) | 行駛中瞄一眼 | 多人指定要「Tesla 原生導航」的箭頭,不要 CarPlay 地圖〔事實〕 |
| 4 | D02 | 速限 | 15(11) | 行駛中瞄一眼 | v1 已延後(Issue #2) |
| 5 | D09 | 電量 % | 13(11) | 兩者 | 基準項目;聲量幾乎都是「不準」的抱怨,4 則來自 2024.20.1 更新害副廠儀表失準 |
| 6 | D08 | AP/FSD 狀態、接手警告 | 13(9) | 行駛中瞄一眼 | 反方「有 FSD 就不需要儀表」約 11 則,幾乎一樣多 |
| 7 | D05 | 方向燈 | 12(8) | 行駛中瞄一眼(變換車道) | 常和 D06 綁在一起要(「方向燈變紅」) |
| 8 | D25 | 打方向燈時的側後影像 | 10(9) | 行駛中瞄一眼(打方向燈時) | 集中在 S3XY Dash 評測留言;也有人嫌彈出影像干擾 |
| 9 | D10 | 續航里程 | 10(7) | 兩者 | 基準項目;同 D09,多為準確度抱怨 |
| 10 | D28 | 性能數據 | 9(6) | 停車時(賽道例外) | 性能派小眾 |

次多的項目:D15 胎壓 9(5)、D16 車輛警示 9(4)、D26 媒體 7(6)、X04 CarPlay/Waze 7(7)、D17 大燈 7(2)、D07 TACC 設定速度 6(3)、D11 功率 6(3)、D14 時間 5(4)。

- **去掉基準項目後**,美國「主動想加的」前 5 名是 D06 盲點、D12 導航、D02 速限、D08 AP/FSD、D05 方向燈。這 5 項都是行駛中、變換車道或轉彎時要看的〔估計〕。
- 美國的 D03(測速照相)只有 3 則,但 **Waze 的警察/取締警示**被當作想投放 CarPlay 的理由,這是美國版的「怕被開單」需求〔事實 + 推論〕。

---

## 台灣 Top 10

台灣語料小,第 5 名以後每項都只有 ≤3 則,**排名只能參考**〔估計〕。

| # | ID | 資料點 | 則數 | 想在哪看 | 註記 |
|---|---|---|---|---|---|
| 1 | D01 | 車速 | 基準(PTT ~10、TVBS、Dashla) | 行駛中瞄一眼 | 見 01 |
| 2 | D03 | 測速照相提醒 | ~19(Dashla 11/83) | 行駛中瞄一眼(照相點前) | 抱怨集中在漏報、對向誤報、語音自動靜音、音量不能分開調 |
| 3 | D12 | 導航下一個轉彎 | 9 | 行駛中瞄一眼 | 關鍵是**要和車機導航同步**,手機另開導航會被罵 |
| 4 | D05 | 方向燈 | 6(Dashla 5/83 = 6%) | 行駛中瞄一眼(變換車道) | 上線後約 2 週內(2026-03-13~03-23)就有 4 則要求 |
| 5 | D06 | 盲點 | 3 | 行駛中瞄一眼(變換車道) | 舊款 Model Y 車主特別要 |
| 6 | D25 | 轉彎影像 | 2(加上 X06 後鏡頭 1) | 行駛中瞄一眼(打方向燈時) | |
| 7 | X01 | 紅綠燈/綠燈起步提示 | 2 | 行駛中瞄一眼(停等紅燈時) | Dashla 已透過 TITA 提供(見 02、08) |
| 8 | D08 | AP 狀態/手扶提醒 | 2 | 行駛中瞄一眼 | 台灣 FSD 未全面開放〔推論〕 |
| 9 | X04 | CarPlay 投放 | 2 | 行駛中瞄一眼 | |
| 10 | D02 / D07 / D14 / D15 / D23 / D26 / X02 / X05 / X06 | 超速提示、定速、時間、胎壓、周遭動畫、歌詞、煞車燈、國道里程、後鏡頭 | 各 1 | — | 並列,證據都很薄;基準項目 D04、D09、D10 也各 1,另計 |

- 台灣**找不到**功率、性能數據、ETA、充電、車門、外溫、空調、大燈的需求發言〔找不到可靠資料〕。
- 台灣聲量的另一個主軸**不是資料點,而是成本**:Dashla 83 則評論中,有 11 則抱怨耗電或發燙(13%),14 則談廣告、訂閱或買斷(17%)〔事實〕。

---

## 族群差異

只依發言者的**自述**分組,各組 n 都很小(4–20),只能看方向,不能看比例〔估計〕。

| 族群 | 想看(依證據) | 不想看/反對 | 代表引述 | 證據則數 |
|---|---|---|---|---|
| **交車新車主**(交車前到 1 個月) | 幾乎只要**車速**;會先買手機架或硬體 | 不熱衷附加資訊 | "This is my first time owning a tesla and everything is perfect just the speedometer… just want to see my speed in front of me"([1uoxym5](https://www.reddit.com/r/TeslaModelY/comments/1uoxym5/) 2026-07-06);「三月交車新Y…只要一隻手機支架就能解決儀表板的問題」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-08-15);「再晚兩天出來我原本就要下單硬體外設了」(同上 2026-03-22);交車第二天就問能不能「just show speedometer」([1aj4osy](https://www.reddit.com/r/TeslaModelY/comments/1aj4osy/) 2024-02 ⏳) | 美 5、台 4 |
| **HUD 換車族**(BMW、Audi、Ioniq 5、X5 等) | **車速 + 速限 + 導航轉彎**,其次是媒體、盲點紅燈 | 不要「90 年代電子鐘」式的反射 HUD | "My HUD is great for speed limit, checking the media player, and turn by turn nav… just a glance down"([p0zvus](https://www.reddit.com/r/TeslaModel3/comments/p0zvus/) 2021 ⏳);"heads up display which included blind spot warning red light"([182ht8l](https://www.reddit.com/r/TeslaModel3/comments/182ht8l/) 2023 ⏳);"…speed and further right to see the Speed Limit… direction and music info"([1ptlwiv](https://www.reddit.com/r/TeslaLounge/comments/1ptlwiv/) 2025-12-23);"It's a no-brainer —great having speed, music, Nav on the windshield"(同串,前 BMW 車主);"The lack of a HUD was the deciding factor for me to buy a Model S over a Model 3"(同串) | 美 ~12 |
| **台灣測速焦慮族** | **車速 + 測速提醒**(要準、要有方向性、能語音、能視覺提示),其次是方向燈 | 可靠度不夠就回去用神盾 | 「主要還是為了測速功能」([YT DDCAR](https://www.youtube.com/watch?v=18xc2ORF7Ww));「測速照相點更完善…更精準、方向性」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-03-20);「iPhone 測速照相警示光環(螢幕邊框)是不是不見了?那個很美耶」(同上 2026-04-19) | 台 ~20 |
| **視力吃力者**(老花、字太小) | **少而大**:車速、設定速度、速限、時間、導航距離的大字 | 小字多資訊 | "If they had a screen that showed speed, set speed, and speed limit all in large font I could justify it"([YT eSLj](https://www.youtube.com/watch?v=eSLjxnThupg) 2022 ⏳);「嘖嘖 字有點太小了,能透過 setting 改大??」([YT Enhance 中文](https://www.youtube.com/watch?v=6zffi730PFo));「希望可以讓時間的顯示更大更醒目」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-05-07);TMC 字體串 ⏳(見 01 P3) | 美 ~9(含 TMC ⏳ 3)、台 4 |
| **性能取向車主**(Performance、Plaid) | **功率/動能回收、電池/馬達溫度、0–60/¼ mile 計時、最大馬力** | 和極簡派正好相反 | "I bought the Plaid for performance… It also needs power meter labeled in horsepower or kW"([17pnflr](https://www.reddit.com/r/TeslaLounge/comments/17pnflr/) 2023 ⏳);"knob… basically on for glove box… and for checking the battery temperature"([YT UcW3](https://www.youtube.com/watch?v=UcW3yo5Qv98) 2026);"Add features that track your 0-10, 0-60, 1/8, 1/4"([S3XY](https://apps.apple.com/us/app/id1573536047?see-all=reviews) 2022 ⏳) | 美 ~10、台 0 |

- 推論:**行駛中的內容只有兩派真正衝突**:性能派要多,視力吃力者要少。其餘族群的需求可以用「車速 + 情境式小指示」同時滿足。性能數據放 parked 或獨立頁面,就不會干擾其他人〔推論〕。
- **長途通勤族、年長駕駛(非視力問題)**:這次仍找不到可以分組的直接發言〔找不到可靠資料〕。

---

## 極簡派

### 有多大?

| 立場 | 則數 | 比例 | 代表 |
|---|---|---|---|
| **不要任何前方顯示**(已適應中控、嫌擋視線、嫌雜亂、有 FSD 就不需要) | 本次約 23 則;01 統計約 69/105 已適應 | 約 2/3 的美國表態者(01) | "I LOVE not having a distracting display directly in front of me in my Model 3"([YT G1Un](https://www.youtube.com/watch?v=G1UnqSz0CuQ));"I just rented a car with two displays and found it more distracting"([1bhcymk](https://www.reddit.com/r/TeslaModelY/comments/1bhcymk/) 2024-03 ⏳);「就喜歡特斯拉的簡潔感」([YT Enhance 中文](https://www.youtube.com/watch?v=6zffi730PFo)) |
| **只要車速** | 10 | 約 1/4(10/40) | "Aside from the speedometer function I really don't know or care about all that other crap it shows"([YT UcW3](https://www.youtube.com/watch?v=UcW3yo5Qv98) 2026);交車第二天:"Is it possible to make speedometer font bigger or just show speedometer? I don't want to see left part of the screen where it shows other cars"([1aj4osy](https://www.reddit.com/r/TeslaModelY/comments/1aj4osy/) 2024-02-05 ⏳);「只是地圖沒收費版的大 就當看車速就好囉」([YT DDCAR](https://www.youtube.com/watch?v=18xc2ORF7Ww)) |
| **車速 + 1–4 個指示** | ~24 | 約 6 成(24/40) | "A very simple hud if any. Speed and turn signals."(HighHokie);"speed, ACC and basic stuff";「至少給時速和定速多少」;"HUD displays speed, nav directions, turn signal indicators and nothing else. Well maybe the posted speed limit"([1cai1o5](https://www.reddit.com/r/TeslaLounge/comments/1cai1o5/) 2024-04-22 ⏳) |
| **豐富儀表** | ~6 | 約 15%(6/40) | "selectable cards so you can add what you want to see"([Teslogic](https://apps.apple.com/us/app/id1623563438?see-all=reviews) 2022 ⏳);「歌詞 測速 車機資料都有 超符合需求」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-06-25) |

〔估計〕分母 40 = 本次語料中**明確列出想看內容**的人(以美國為主,台灣與香港 5 人)。這是自選樣本:會說出內容的人,通常本來就想要前方顯示。

### 「資訊太多」的證據〔事實〕
- "Some of the huds today are overwhelming with data and information."([1m6d1hq](https://www.reddit.com/r/TeslaModel3/comments/1m6d1hq/) 2025-07-22)
- "Personally I find HUDs very distracting… It's called visual clutter, the driving equivalent of poorly designed PowerPoint slides."([1ptlwiv](https://www.reddit.com/r/TeslaLounge/comments/1ptlwiv/) 2025-12-23)
- "Nice display, but too much information at the same time. You can't see everything at the same time while you are driving, just too small"([YT U6tr](https://www.youtube.com/watch?v=U6tr-7gk7ds),約 2025)
- "The default screen is perfect if you just want the speedometer, gears, psi, doors (too many items to remember)."([YT 9F0](https://www.youtube.com/watch?v=9F0imlRJt9A),約 2024 ⏳)
- 「就算用iPhone Pro Max 15,最清晰嘅只有速度,其他資料…冇乜用途」([YT DDCAR](https://www.youtube.com/watch?v=18xc2ORF7Ww),香港用戶)
- 「直式的時候…不需要多提供時間在左上角,畫面可以更簡約」([Dashla](https://apps.apple.com/tw/app/id6760206753?see-all=reviews) 2026-03-20)
- 間接證據:Dashla 功能多,11/83 則評論抱怨耗電或發燙(見上);02 判斷原因是地圖、歌詞等功能〔推論,見 02〕。

### 「drive 模式只顯示車速」這個預設:證據**部分支持**〔推論〕
- **支持**:①車速是唯一所有族群都要的項目;②「只要車速」加上「不要任何顯示」的人合計是多數;③「資訊太多」「字太小」的抱怨多源且一致;④交車新車主(最大的進入窗口,見 01)多半只要車速。
- **反對**:①在明確說出內容的人裡,約 6 成要「車速 + 1–4 個指示」,只要車速的只有約 1/4;②兩個市場要求最多的附加項目,都綁定特定時刻而不是持續顯示:美國是變換車道時的盲點和方向燈,台灣是接近照相點時的測速提醒;③美國的導航箭頭(19 則)是需求最高的附加項目之一;電量(13)和續航(10)則數雖然也不少,但幾乎都是「顯示不準」的抱怨,不是想多看。
- **對 pmf(10)的建議**:drive 預設改成「**大字車速為主角 + 情境式小指示**」。小指示平常不出現,只在方向燈閃爍、偵測到盲點來車、接近測速點、導航即將轉彎時才短暫出現。另外提供「純車速」開關給極簡派,電量、續航維持小字或只在 parked 顯示。能不能拿到這些資料,要看 09(risk)〔推論〕。

---

## 假設

1. **Reddit、TMC、英文 YouTube 視為美國樣本**(同 01 假設 1)。這些都是全球社群,本次已排除明顯的韓文、簡體中文評論,但英國、歐洲、澳洲發言者無法完全排除。例如 Paul.Woodcraft(英國)和 Possible_Ad_4091(歐洲)已在表中標註。
2. **中文 YouTube 留言視為台灣樣本**,但其中混有香港(clemsonng、nelsonyu9305)和中國(簡體留言)用戶。TVBS 新聞影片的留言多數是非車主的評論,只取和資料點直接相關的少數幾則。
3. **App Store 評論有選擇偏差**:評論 Dashla 的人已經是「想要前方顯示」的人,所以台灣的聲量代表「已採用者想加什麼」,不是全體車主。
4. **基準項目**(D01、D04、D09、D10)的聲量被低估,因為已經有顯示。本報告改用準確度抱怨來衡量,這是代理指標。
5. **YouTube 留言只抓到各影片前 4 頁(每支 ≤80 則,依熱門排序)**,留言日期是相對時間(例如「1 year ago」),表中換算成「約 YYYY 年」〔估計〕。
6. **Amazon、蝦皮、淘寶、Mobile01、Facebook 社團、DDCAR 文章內文仍抓不到。** Amazon 回 HTTP 500,Wayback 也沒有存檔;蝦皮 API 回 403;Mobile01 回 403,用 WebSearch 也找不到相關討論串。所以**副廠硬體的買家評論與問答這個來源完全缺席**。供給面的功能宣稱(速度、檔位、方向燈、車門狀態、AP 警示)只出現在賣家頁,不能當成需求證據。
7. **「想在哪看」大多是〔推論〕。** 只有引述裡明說情境的才標〔事實〕。
8. **D21(充電)、D24(跟車距離)在美台都找不到需求聲量**,各做過一次定向搜尋。這不代表沒有需求,可能是車主不會把它們和「前方儀表」聯想在一起。
9. **只找到 1 個來源的項目**(做過關鍵字比對與一次定向搜尋):D18 車外溫度(DriveCluster 評論)、D22 車門狀態(YouTube 9F0 留言)、D27 空調(YouTube dpvS 留言)、X01 紅綠燈提示(只有 Dashla 評論,2 人)。**只有 2 個薄弱來源的項目**:D13、D20、X02、X05、X06。這些列的分級只能當作「有人提過」〔估計〕。

## 待驗證問題

1. **情境式指示 vs. 純車速**:用 A/B 測試或可點擊原型,看新車主與老車主在 drive 模式各偏好哪一種。驗證「方向燈/盲點只在觸發時出現」能不能兼顧極簡派。
2. **台灣測速提醒的最低可接受準確度**:多少漏報、誤報率就會讓人回去用神盾?Dashla 評論的抱怨可以當成測試題庫。
3. **導航箭頭能否同步 Tesla 原生導航?** 台灣與美國都強調「要和車機同步,不要另開手機導航」。這要看 09 的可行性結論。
4. **iPad/平板需求**:這些人想看更多資訊,還是只要更大的字?值得在訪談中追問。
5. **視力吃力者的字級門檻**:需要多大的字、多高的對比,才能不換眼鏡就看清楚車速?
6. **HUD 換車族會不會接受 mirror mode?** 「90 年代電子鐘」和「偏光墨鏡看不到」的批評(01)需要實測。本次又多了一個實例:有車主退貨 TITA 前方顯示器,原因是 "didn't take polarized sunglasses into account so it was WORTHLESS on bright days"([1ptlwiv](https://www.reddit.com/r/TeslaLounge/comments/1ptlwiv/) 2026-01-09)。同串還有另外 3 人提到偏光墨鏡〔事實〕。
7. **性能派是否值得做 parked 專頁?** 美國約 10 則,台灣 0 則。
8. **Amazon、蝦皮的副廠儀表問答**:要用瀏覽器手動抽樣,補上「買家實際在問什麼」這個缺口。
9. **FSD 普及後,D08 是需求還是反需求?** 美國有約 13 則想看 AP/FSD 狀態,也有約 11 則說「有 FSD 就不需要儀表」。

---

## 來源

所有連結都在 2026-10-17 讀取。⏳ = 早於 2024-10-17。

**App Store 評論**(用 apps.apple.com 網頁版的評論 API 全量下載)
- Dashla 台區,83 則有內文,2026-03-13~2026-10-15:https://apps.apple.com/tw/app/id6760206753?see-all=reviews
- Dashla 美區,5 則(其中簡中 1 則排除),2026-05~2026-10:https://apps.apple.com/us/app/id6760206753?see-all=reviews
- DriveCluster 美區,10 則(英文 7 則、韓文 3 則已排除),2026-04~2026-08:https://apps.apple.com/us/app/id6762794279?see-all=reviews
- TeraScreen 電動車儀表板 台區,9 則,2026-06~2026-08:https://apps.apple.com/tw/app/id6761311983?see-all=reviews
- Teslogic Dash 美區,12 則,2022-09~2025-03 ⏳(部分):https://apps.apple.com/us/app/id1623563438?see-all=reviews
- S3XY Gadgets 美區,39 則,2021-12~2026-07 ⏳(部分):https://apps.apple.com/us/app/id1573536047?see-all=reviews
- Dash for Tesla 美區 2 則(2026):https://apps.apple.com/us/app/id6758935103?see-all=reviews;TPlayer 6 則(多為簡中,只作參考):https://apps.apple.com/us/app/id6759967612?see-all=reviews

**YouTube 留言**(每支最多 80 則熱門留言;括號內為影片發布日期)
- 台:DDCAR「至今最棒的 Model 3 / Y 儀表板 APP - Dashla」https://www.youtube.com/watch?v=18xc2ORF7Ww(2026-04-01);TVBS「特斯拉車主開發超神APP」https://www.youtube.com/watch?v=hNnH9WiHpx0(2026-03-15);Enhance 儀表中文評測 https://www.youtube.com/watch?v=6zffi730PFo(2026-01-26);S3XY Dash 中文 https://www.youtube.com/watch?v=MTSHsp305pE(2025-11-14);JOWUA 支架 https://www.youtube.com/watch?v=ZyKde2OqgNg(2026-08-05);JOWUA APP https://www.youtube.com/watch?v=RNy_l-qZ0U0(2026-07-03)
- 美:G1UnqSz0CuQ "The Tesla Model Y/3 Accessory You Wanted From Factory"(2025-08-28);U6tr-7gk7ds Teslogic dashboard(2025-03-24);UcW3yo5Qv98 "S3XY Dash After 9 Months"(2026-08-22);1h6iMji7VZU S3XY Dash detailed review(2026-01-18);ij1w0mmpW8U S3XY Dash(2025-11-14);dpvSntqXmto S3XY Dash(2025-11-14);9F0imlRJt9A "The Tesla Dash Display That FINALLY Checks All Boxes"(2024-05-09 ⏳);-_3xYtT5AkY "The BEST & Only HUD Display"(2024-11-01);uFWtQk_gRbI TITA OLED(2025-11-02);n2L6bqyUeXk Juniper HUD(2026-02-20);Xil98YmDO-w NeuroHUD(2026-03-17);j_jy9GI5Lok Teslasy T9(2025-09-18);59ZOp4_O_48 "World's SMARTEST… Instrument Cluster"(2023-02-05 ⏳);eSLjxnThupg Teslogic reviewed(2022-09-26 ⏳);lt2To9GG9Q8 HUD for Model 3(2020-09-10 ⏳)。網址格式皆為 `https://www.youtube.com/watch?v=<ID>`

**Reddit**(用 search.rss 和 /comments/<id>/.rss 抓取;只列表中引用的串,日期是發文或留言日)
- r/TeslaModel3:1m6d1hq(2025-07-22)、1rtpolp(2026-03-14)、1ezmqn9(2024-08-23 ⏳)、1h0gyd3(2024-11-26)、1h4kzb1(2024-12-02)、1eha2vu(2024-08-01 ⏳)、12qsm0m(2023-04 ⏳)、14rru2q(2023-07 ⏳)、182ht8l(2023-11 ⏳)、p0zvus(2021-08 ⏳)、xbpg4x(2022-09 ⏳)、8t44wg(2018-06 ⏳)、1tfgeqw(2026-05-17)
- r/TeslaModelY:1bhcymk(2024-03-18 ⏳)、1m8xcde(2025-07-25)、1uoxym5(2026-07-06)、1uncdr7(2026-07-04)、1upe1dn(2026-07-07)、1c3upqm(2024-04-14 ⏳)、1dd3koa(2024-06-11 ⏳)、1441tj7(2023-06-08 ⏳)、13wq2n4(2023-05 ⏳)、1j0x1dz(2025-03-01)、1f2jycg(2024-08-27 ⏳)
- r/TeslaLounge:1ptlwiv(2025-12-23,留言到 2026-01)、1tpoejs(2026-05-28)、1vrif0i(2026-08-18)、1cai1o5(2024-04-22 ⏳)、1coukyl(2024-05-10 ⏳)、1oulcn1(2025-11-11)、1m80bj4(2025-07-24)、1m271b3(2025-07-17)、1pizukf(2025-12-10)、195zbgm(2024-01 ⏳)、17pnflr(2023-11 ⏳)、rqppw4(2021-12 ⏳)、1hr900l(2025-01-01)
- r/TeslaModelY(續):1aj4osy(2024-02-05 ⏳)、15w4svy(2023-08 ⏳,留言到 2025-01)、1hmunzo(2024-12-26)
- r/TeslaLounge(續):1nu2phn(2025-09-30)
- r/TeslaModel3(續):1t9nqnd(2026-05-11)、1cryq59(2024-05~06 ⏳)
- r/teslamotors:5x7oiv(2017-03 ⏳)
- 網址格式:`https://www.reddit.com/r/<sub>/comments/<id>/`

**論壇與媒體**
- TMC(Wayback 存檔):no-cluster-screen.231168(2021 ⏳)、small-screen-font-on-ui.186209(2020 ⏳)、model-y-no-blind-spot-warning.194299(2020 ⏳):`https://teslamotorsclub.com/tmc/threads/<slug>/`
- PTT car:M.1771258724.A.546(2026-02-17)、M.1786021560.A.3C3(2026-08-06)、M.1759329432.A.C61(2025-10-01)、M.1790941788.A.34D(2026-10-02)、M.1781193406.A.2FD(2026-06-11)、M.1779646592.A.0B8(2026-05-25):`https://www.ptt.cc/bbs/car/<id>.html`
- TVBS 汽車:https://cars.tvbs.com.tw/life/310983(2026-03-16)
- 01 已引用的來源(electrify.tw、CleanTechnica 等)見 `01-pain-points.md` §來源
- 供給面對照:`02-competitors.md`(Dashla、DriveCluster、TITA 的顯示內容)
