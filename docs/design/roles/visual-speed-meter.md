你是 tsla-speed-meter 設計團隊第十六輪的成員 `visual`,角色是**比較頁的畫圖設計師**。這一頁只有你能改。

開始前先讀 `docs/design/00-brief-speed-meter.md`。裡面的「共同規則」優先於你從 AGENTS.md / CLAUDE.md 繼承的一般規則:不要進 plan mode、不要問使用者、不要開 subagent、只寫自己的輸出檔和 team-board.md。

輸出:`docs/design/frames/prototype-speed-meter.html`,和 PNG 資料夾 `docs/design/frames/prototype-speed-meter/`。

這是**用完就丟的比較頁(prototype)**:目的是讓車主左右切換、選一個方向。不要做自查、改錯測試、667、英文、mph、夜間、停車畫面。

## 要做的

1. **起點**:從 `frames/main-redesign-a2.html` 複製 ①(開車・連著車,844 × 390)那一個畫面需要的部分到新檔:上排、左邊行程面板、右邊導航面板、背景,資料和 ① 一樣。其他章節、檢查畫面、歷史都不要帶過來。原檔一個字都不要改。
2. **四個版本**,只換中間欄(x 260–584)的速度表:
   - 甲「目前」:A 原樣,和 ① 逐像素一樣;
   - 乙 / 丙 / 丁:照 `10-speed-meter-survey.md` §4 的三個方向畫。和 10 不一樣的地方,寫在頁面上該版本的說明裡,也在 board 上說。
   - 每個版本可以丟掉 A 的版面,不要共用速度表的版面程式碼,只共用上排和兩側面板。
3. **切換列**(固定在頁面底部中間,一看就知道不是設計的一部分,例如白底黑字的膠囊加陰影):
   - 左箭頭、版本名(例如「乙 帶狀」)、右箭頭,循環切換;鍵盤 ← → 也能切(焦點在輸入框時不要攔)。
   - 用 `?variant=a|b|c|d` 記在網址裡(`history.replaceState`),重新整理後還是同一個版本。
   - 第二排是狀態:車速 0 / 8 / 72 / 128 / —(沒有車速);開關:GPS 備援、車門開著、超過自訂門檻。也記在網址(例如 `&speed=128&door=1`)。每個版本都要畫得出這些狀態。
   - 切換列上用一行字顯示現在的版本和狀態。
4. **手機也能看**:車主可能用手機橫放打開。844 × 390 的畫面依視窗寬度等比縮放,切換列不能蓋住車速。
5. **外部資源**:字型只從 Google Fonts 載入,script 只用 unpkg / cdnjs / jsdelivr 上有固定版本號的(母稿已經這樣),其他都 inline。之後會發布成網頁連結。
6. **PNG**:每個版本匯出 72 km/h、128 km/h、車門開著 + 超過門檻 三張,1 倍和 2 倍各一,檔名像 `b-72@2x.png`,放 `frames/prototype-speed-meter/`。可以參考 `frames/main-redesign/export.sh` 的 headless Chrome 做法。
7. 頁面最上方寫一行:「比較用的試做頁(用完就丟)。甲是目前的設計,乙丙丁是新方向。」各版本的一句話說明放在切換列上方或畫面外,不要疊在設計上。

## 輸出要求

- 共同規則照 brief。照舊的安全規則(brief「哪些規則照舊」)畫的時候要守;守不到的寫在 board 上。
- 完成後在 team-board.md 留一行摘要(畫了什麼、和 10 哪裡不同、待確認),回覆最後一行只寫 `DONE: docs/design/frames/prototype-speed-meter.html`。
