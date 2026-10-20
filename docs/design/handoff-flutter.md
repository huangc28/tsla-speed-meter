# 交接:flutter 第五輪

交接時間:2026-10-18 約 14:45(台北)。原執行者:Codex CLI(額度用完)。接手者:agy / Gemini。你接手後的身分仍是 `flutter`(實作可行性審查員)。

## 你需要知道的背景

- **規則**:先讀 `roles/flutter.md` 和 `00-brief.md` 的「共同規則」,它們優先於 AGENTS.md / CLAUDE.md。不進 plan mode、不問使用者、不開 subagent。只寫 `04-feasibility.md` 和 `team-board.md`;board 只能在檔尾追加,格式是 `- [YYYY-MM-DD HH:MM] flutter → <對象>: <內容>`,用台北時間。
- **不改任何程式碼**。不 commit,也不 `git checkout` / `switch` / `stash`,因為大家共用同一個工作目錄。要看 BLE 分支,用 `git show origin/feature/goal-2-ble:<path>`。工作目錄在 main,HEAD 是 `8b4acb5`(2026-06-10),寫 04 之後沒有變過,所以 04 引用的 main 行號大致有效,寫進去前還是要再核對。
- **L28 只做橫式**(`00-rulings.md:132`):app 鎖定橫式,landscapeLeft 和 landscapeRight 都支援,放棄直式。所有畫面都要有橫式版。新稿放 `frames/landscape/`,主稿改成 `frames/landscape-mockups.html`。
- **L29 拿掉鏡像**(`00-rulings.md:137`):S11 鏡像預覽、設定裡的開關和所有鏡像說明都刪掉。L1–L27 不變,原本只為直式訂的規則(L25 量表固定在左邊、L19 大字稿)改用橫式重新套用。
- **ux 已改完 01**(board 14:41):橫式規則在 `01-flows.md` §7(第 930 行起)。重點如下:
  - 量表永遠在左邊。左右兩側都預留瀏海和動態島中較大的那個距離,畫面翻轉時版面不跳。
  - 按鈕避開底部手勢條。以 667×375 pt 為最小基準。
  - S08 改成兩欄,窄手機時退回單欄;其他表單頁單欄,寬度上限約 600 pt。
  - 確認框置中,寬約 460 pt,高度不超過 80%。
  - S14 鍵盤打開時只留步驟、VIN 欄(一行 17 碼加「12/17」字數)、錯誤和「下一步」,全部在鍵盤上方。
  - 刪掉 S11 後共 27 個畫面。
- **visual 還在重畫**:到 14:42,`frames/landscape/` 有 24 張,只有 S04、S05、S06。表單、配對、購買頁還沒畫,02 也還沒有第五輪段。04 有 516 行,最後一行是 `DONE: docs/design/04-feasibility.md`。不要整份重讀,用 grep 找位置。

## 任務

評估 L28、L29 對實作的影響,寫進 04 新增的「第五輪」段,共四項:

1. 怎麼鎖定橫式:Flutter、iOS、Android 各要改哪裡;main 現有的直式/橫式重排(#10)哪些可以刪。
2. 要刪的鏡像程式(設定、Transform、相關測試),列出檔案和行號。
3. 橫式下的鍵盤(VIN 輸入)、SafeArea 和表單頁的實作注意事項。
4. 更新工作量和實作順序。

不改程式碼、不切分支,回覆最後一行寫 `DONE`。

## 已完成

04 的第一到第四階段和最終版實作順序都已寫完(12:29),內容仍然有效:現況盤點、S01–S28 可行性表、L11/L14 試用機制、套件和點庫、最終實作順序。第五輪還沒有寫任何東西。

## 已發現、尚未寫入

無。Codex 的對話紀錄 `~/.codex/sessions/2026/10/18/rollout-2026-10-18T11-11-45-01a14cfe-6f71-7fe2-be40-28d7c686adfb.jsonl` 第 765–768 行顯示,它在 14:38:38 收到第五輪指令,1.2 秒後回報 `usage_limit_exceeded`,沒有呼叫任何工具,也沒有輸出。

**起點線索**:以下是寫這份交接的人 2026-10-18 在 main 上 grep 找到的,不是 Codex 的發現。寫進 04 前請自己再核對一次。

- **鏡像**:
  - `lib/src/ui/app_shell.dart:87-88`:`if (s.mirror)` 時套 `Transform.flip(flipX: true)`。
  - `lib/src/settings/settings.dart:13,21,29,37,47,60`:預設值、欄位、copyWith、toMap、fromMap。
  - `lib/src/settings/settings_panel.dart:78-79`:「鏡像 HUD 模式」開關。
  - `test/app_shell_test.dart:36-62`:三個鏡像測試。另外 `_store` 的 `mirror` 參數在 `:23,26`,keep-awake 測試也會用到這個 helper。
  - `test/settings_store_test.dart:29,34,50`:用 mirror 當保存或通知的範例欄位,應該改用別的欄位,不是刪掉測試。
- **舊設定的 `mirror` 鍵**:可以沿用 04 對 `autoMinimal` 寫的做法(`04:238-245`、`lib/src/settings/shared_prefs_settings_storage.dart:9`):讀取時忽略,下次寫入時自然移除。
- **方向設定**:
  - `ios/Runner/Info.plist:56-60` 的主陣列有 Portrait、LandscapeLeft、LandscapeRight;`:62-67` 的 `~ipad` 陣列還有 Portrait 和 PortraitUpsideDown。
  - `android/app/src/main/AndroidManifest.xml:14` 只有 `configChanges`,沒有 `screenOrientation`。
  - `lib/` 裡沒有 `setPreferredOrientations` 或 `DeviceOrientation`。
- **#10**:commit `67c8e95` 只改了 `lib/src/ui/parked_screen.dart`、`test/drive_screen_test.dart`、`test/parked_screen_test.dart`。04 已經引用 `parked_screen.dart:40`(LayoutBuilder)、`:83`(橫式分支)、`test/parked_screen_test.dart:29`、`test/drive_screen_test.dart:62`。

## 待辦

1. **鎖定橫式**:寫出 Flutter 端(`SystemChrome.setPreferredOrientations`)、iOS `Info.plist`(兩個陣列都要改)、Android activity 的 `screenOrientation` 各要怎麼改,並寫明為什麼選這個值。再列出 #10 直式分支裡可以刪的程式和測試。
2. **鏡像刪除清單**:依照上面的線索核對後,列出檔案和行號,也寫出設定遷移的做法。
3. **鍵盤、SafeArea、表單頁**:
   - S14 VIN:`viewInsets`、可捲動、鍵盤打開時的精簡版面。依 L6,一出現移動證據就收起鍵盤、回到 HUD。
   - SafeArea:左右兩側取較大值,翻轉時版面不跳;不能用固定 60 的邊距。
   - 版面:S08 兩欄,窄手機退回單欄;表單頁寬度上限約 600 pt;確認框約 460 pt。
4. **更新工作量和順序**,要改的地方:
   - `04:62`(設定表的鏡像列)
   - `04:71-82`(橫式、鏡像與 gauge)
   - `04:154`(S11 刪除)
   - `04:303-315`(鏡像列,原估 M)
   - `04:390`(S11 PNG)
   - `04:478-492` 實作順序表:第 2 步的「L19 四稿」改成 landscape 稿;第 6 步拿掉「鏡像反射」和「直橫式」。
   - `04:512`
5. 在 04 加入 `## 第五輪(只做橫式、拿掉鏡像)`,位置在「建議的實作順序」之後、「假設」(`04:493`)之前。檔尾的 `DONE:` 行要保持在最後一行。在 `team-board.md` 追加一行 `flutter → lead`。回覆的最後一行只寫 `DONE: docs/design/04-feasibility.md`。

## 下一步

先跑 `git grep -n -i -E 'mirror|flipX|Orientation' -- lib test ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml`,核對上面的行號;再讀 `01-flows.md` §7(第 930–970 行左右)。然後在 `04:493` 前開始寫第五輪段,順序是第 1 項到第 4 項。
