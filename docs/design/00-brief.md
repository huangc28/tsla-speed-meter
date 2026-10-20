# 設計團隊 Brief — tsla-speed-meter UI/UX 更新

## 任務

市場研究(`docs/market-research/`)已經定出 v1 的範圍、免費/付費分界和文案規則。這一輪要把這些結論變成**畫面和流程**。

**這次是更新,不是重做。** 保留現有的深藍儀表風格和 token(`DESIGN.md`、`tsla-speed-meter.pen` 的 D/D2/D3/E/F 畫面),只補上新範圍需要的畫面、狀態和文案。視覺 token 需要調整時,寫成「建議改法」,不要直接改 `DESIGN.md`。

## 產品一句話

Flutter iOS/Android app,把手機變成放在儀表板上的車速 HUD,給沒有前方儀表的 Tesla Model 3/Y 車主用。免費版用手機 GPS 算車速;付費版透過車輛藍牙讀車子回報的車速、檔位、電量。市場是美國和台灣。

## v1 要補的畫面和狀態

1. **第一次開啟**:讓使用者選「純車速」或「車速 + 車況」,附預覽。不強迫配對或付費。只能在停車時選。
2. **免費版行車畫面(GPS)**:大字車速 + 觸發區(平常空白,一次只出現一則)。
3. **藍牙配對流程**:
   - 金鑰登記:要到車上,用卡片感應確認。
   - 連線狀態:連線中、已連線、資料過期、斷線、車在睡覺時改用 GPS。
   - 來源標示寫「車輛藍牙」/「GPS」,不寫 `TESLA`,也不放 Tesla logo。
4. **台灣測速照相提醒**:點位速限 + 距離。符合 06 C06 的條件時,車速數字轉琥珀色;不能只靠顏色表示。
5. **付費版行車畫面(BLE)**:多一行小字狀態列,顯示檔位、電量或續航。
6. **P 檔自動切到停車畫面**:P 檔只是切換版面的條件,不代表車已經安全停好(06 C09)。
7. **停車畫面**:本趟行程,加上車子讀得到時才顯示的胎壓,要標出最後量測時間和缺值狀態(06 C03)。
8. **「本版本不提供」說明**:方向燈、盲點、AP/FSD、轉彎提示。文案照 06 Part C C02。
9. **免費/付費解鎖畫面**:
   - 台灣 NT$290 一次買斷。
   - 美國測兩種:US$9.99 解鎖,或資料全免費 + 自由支持 US$9.99。兩組用同一個付款意願指標(06 C08)。
10. **設定**:版面(純車速/車速 + 車況)、測速提醒開關(獨立,台灣預設開)、單位、鏡像模式、日夜亮度、藍牙裝置管理。
11. **資料不新鮮或失效**:車速顯示「—」,不凍結舊數字,不畫成 0。

已經延後、這次不畫的:道路速限(美國)、原車導航摘要、門未關/胎壓即時警示、功率條、外接硬體。

## 必讀資料

- `docs/market-research/10-data-priorities.md`:§drive 畫面建議、§parked 畫面建議、§免費版要放什麼。這是最直接的畫面規格。
- `docs/market-research/06-risk-review.md` Part C(第 425 行起)和 Part B 最終分類表裡標「(Part C 新增)」的列:文案和條件的硬規則。
- `docs/market-research/00-summary.md`:整體結論和決策表。
- `docs/market-research/07-data-voice.md`:要多少資訊才夠(極簡派)。
- `docs/market-research/09-data-feasibility.md`、`11-turn-signal-ble.md`:哪些資料拿得到。
- `DESIGN.md`、`PRODUCT.md`。`PRODUCT.md` 的「Phase 2 用 Fleet API」已過時,以 `DESIGN.md` 的 Data-source reality 段為準。
- `lib/`(main)和 `origin/feature/goal-2-ble`(藍牙)。

## 團隊

| 成員 | 角色 | 執行 | 輸出 |
|---|---|---|---|
| `ux` | 流程和畫面清單 | Claude | `docs/design/01-flows.md` |
| `visual` | 視覺設計,唯一能改 `.pen` 的人 | Claude(Pencil MCP) | `tsla-speed-meter.pen` 新畫面 + `docs/design/02-visual.md` + `docs/design/frames/*.png` |
| `safety` | 行車安全和無障礙審查 | Codex | `docs/design/03-safety-review.md` |
| `flutter` | 實作可行性審查 | Codex | `docs/design/04-feasibility.md` |
| `tire` | 胎壓車子圖示設計(第六輪加入) | Codex | `docs/design/05-tire-icon.md` + `docs/design/frames/tire/` |
| lead | 主持人(協調、裁定、整合) | Claude | `docs/design/00-summary.md` |

第五輪起 `safety`、`flutter` 改用 agy 執行;第七輪 agy 額度用完,又改回 Codex(L47),名字和位置不變。

階段:
1. `ux` 寫流程;`visual` 盤點現有畫面;`flutter` 盤點現有程式;`safety` 寫審查清單。
2. `visual` 照 01 畫新畫面;`safety`、`flutter` 審查 01。
3. `safety`、`flutter` 審查畫面;主持人裁定;`ux`、`visual` 改一輪。

主持人會在你的輸入檔就緒後才派下一階段的工作。

## 共同規則

這些規則優先於你從 `AGENTS.md` / `CLAUDE.md` 等檔案繼承的一般規則(例如「先進 plan mode」「先問再做」)。

1. **不要卡住**:不要進 plan mode,不要問使用者,不要等確認。不確定就做合理假設,寫進輸出檔的「假設」段落,必要時在 `team-board.md` 留言,然後繼續。
2. **自己做**:不要開 subagent 或 workflow。
3. **只寫自己的檔案**:你的輸出檔和 `team-board.md`(只能在檔尾追加)。`visual` 另外可以改 `tsla-speed-meter.pen`、寫 `docs/design/frames/`。`tire` 只能寫 `docs/design/05-tire-icon.md` 和 `docs/design/frames/tire/`。不要改程式碼、`DESIGN.md`、`PRODUCT.md` 或其他檔案。不要 git commit,不要 `git checkout`/`git switch`(大家共用同一個工作目錄;看其他分支用 `git show <branch>:<path>`)。
4. **文案守 06 Part C**:不寫「跟車上一模一樣」「隧道不中斷」「比 GPS 快」「原廠沒開放手機、一定要接線」「不破保」。所有畫面上的字都要給繁中和英文。
5. **安全原則**:車速是唯一主角。行駛中不放長文字、設定操作、購買畫面。狀態不能只靠顏色表示。
6. **證據**:引用研究報告時標檔名和章節,例如 `[10 §drive]`、`[06 C09]`。外部來源附 URL 和日期。
7. **語言**:繁體中文(台灣用語),專有名詞保留英文。精簡,以表格和條列為主,開頭放 5 行以內的「重點結論」。
8. **完成時**:回覆的最後一行只寫 `DONE: docs/design/<你的檔名>`。主持人之後可能請你修改,改完一樣用 `DONE:` 結尾。

## team-board.md 格式

每則一行,追加在檔尾:

```
- [YYYY-MM-DD HH:MM] <你的名字> → <對象或 all>: <內容>
```

成員之間不會直接溝通,主持人會讀留言板並轉達。
