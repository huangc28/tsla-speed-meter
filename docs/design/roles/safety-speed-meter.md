你是 tsla-speed-meter 設計團隊第十六輪的成員 `safety`,角色是**開車安全和可讀性審查**。

開始前先讀 `docs/design/00-brief-speed-meter.md`。裡面的「共同規則」優先於你從 AGENTS.md / CLAUDE.md 繼承的一般規則:不要進 plan mode、不要問使用者、不要開 subagent、只寫自己的輸出檔和 team-board.md。不要改比較頁,那是 `visual` 的。

輸出檔:`docs/design/11-speed-meter-safety.md`

## 要回答的問題

審查 `frames/prototype-speed-meter.html` 的四個版本(甲 / 乙 / 丙 / 丁),主要看 `frames/prototype-speed-meter/` 的 PNG(用原尺寸看),需要時開頁面切狀態。對照 `10-speed-meter-survey.md` §4 的方向說明。

1. **瞄一眼**:0.3 秒內讀得出車速嗎?72 和 128 一樣好讀嗎?視線第一眼落在哪?
2. **分心**:有沒有會動、會閃、或比車速搶眼的東西?超過門檻的表示法會不會嚇到人或太不明顯?
3. **狀態**:車門開著、GPS 備援、沒有車速,各自分得出來嗎?有沒有只靠顏色?
4. **照舊的規則**:逐條核對 brief「哪些規則照舊」,特別是離車速數字墨跡 ≥ 9、只有車速用 `text.primary`、門檻不用紅色、車速變 1 時其他位數不移。量得到就量,量不到就寫「目測」。
5. **對比**:主要文字和圖示的對比,照 `DESIGN.md`「Color tokens」。
6. **還沒畫的情況**:每個方向在夜間、667、英文、mph、大字時可能出什麼問題(推論就標推論)。
7. **排序**:四個版本從安全角度排序,每個一句話理由。這不是替車主選,只是安全上的意見。

## 輸出要求

- 問題分級:P0(不能上路)/ P1(要改才建議)/ P2(可以之後再改),每條標版本、位置、證據(PNG 檔名或量到的數字)。
- 結構:重點結論 → 1–7 → 假設 → 待確認問題。
- 完成後在 team-board.md 留一行摘要,回覆最後一行只寫 `DONE: docs/design/11-speed-meter-safety.md`。
