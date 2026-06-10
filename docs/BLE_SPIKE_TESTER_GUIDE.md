# Tesla BLE 測試指南（人 + AI agent 都能 follow）

這是一個**一次性測試 app**（不是正式產品），目的：確認手機能不能用藍牙連上 Tesla、
讀到車速 / 電量 / 檔位。需要**真車** + **Tesla 實體鑰匙卡**，全程約 15 分鐘。

> ⚠️ **不需要 Tesla 帳號密碼**。加鑰匙是靠你拿實體卡片在車上感應授權。

---

## 🤖 如果你是 AI agent，先讀這段

你可以完成 **A. 環境 setup + build 安裝**，但 **B. 車上互動步驟必須交給人**（實體鑰匙卡、
開車、在手機螢幕上點按鈕）。請照下面做，到 `=== STOP: HUMAN REQUIRED ===` 就停下來把
控制權交還給使用者。

### A. Machine steps（agent 可自動執行）

```bash
# 1. 取得程式碼
git clone https://github.com/huangc28/tsla-speed-meter.git
cd tsla-speed-meter
git checkout feature/goal-2-ble
flutter pub get

# 2. 環境檢查（要看到 Flutter 3.41+、已連接的 iPhone）
flutter --version
flutter doctor
flutter devices          # 記下使用者 iPhone 的 device id

# 3. build + 安裝到實體 iPhone（一定要 --release）
flutter run --release -t lib/spike_main.dart -d <DEVICE_ID_FROM_ABOVE>
```

### ⚠️ Agent 會遇到、且需要「人」處理的點
1. **iOS 簽章**：build 到實體 iPhone 需要使用者自己的 Apple ID。若 `flutter run` 報簽章錯誤，
   請使用者用 Xcode 開 `ios/Runner.xcworkspace` → 選 Runner target → Signing & Capabilities →
   勾 *Automatically manage signing* → 選自己的 **Team**；free Apple ID 可能還要把 bundle id
   `com.tslaspeedmeter.tslaSpeedMeter` 改成獨一無二的字串。**這步 agent 無法代登 Apple ID。**
2. **Developer Mode**：iPhone 要先開（設定 → 隱私權與安全性 → 開發者模式），且裝置解鎖。
3. **`--release` 不可省**：iOS debug build 會卡白畫面（需接 debugger JIT），不是 bug。
4. App 第一次開啟時的**藍牙權限**要在手機上由人按允許。

```
=== STOP: HUMAN REQUIRED ===
build 成功、app 已裝到 iPhone 後，agent 停在這裡。
告訴使用者：「app 裝好了，請拿到車旁照 B 段操作。」
```

---

## 🧑 B. 車上操作步驟（必須真人，在車旁/車上做）

1. **輸入 VIN**（17 碼；儀表板底座、門框、或 Tesla app 裡有）
2. 按 **`1. Connect`** — 連線。找不到車就：開車門叫醒車 + 關掉官方 Tesla app（它佔住藍牙）
3. 按 **`2. Enroll key`** → **拿鑰匙卡感應中控**、螢幕按確認（只需一次）
4. 按 **`3. Session info`** — 建立加密連線
5. 按 **`4. Read data`** — 讀一次資料
6. 按 **`5. Poll speed ×20`** — **請當乘客操作 / 找人幫開**，⚠️ 不要自己邊開邊用
7. 按右上角 **匯出（分享圖示）** → 把 log 檔傳回給對方

---

## ‼️ 最重要的一句話

**就算第 4、5 步出現 `could not decode` 或任何錯誤，也完全沒關係。**
app 會把所有原始藍牙封包記進 log，那正是我們要的。**不管成功失敗，務必 Export 把 log 傳回。**

---

## 常見問題

| 狀況 | 解法 |
|---|---|
| 卡白畫面 | 忘了 `--release`，重跑 |
| 簽章錯誤 | 用 Xcode 設自己的 Team / 改 bundle id（見上方 agent 注意事項 1） |
| 找不到車 | 開車門叫醒車 + 關官方 Tesla app + 確認藍牙開著 |
| 加鑰匙沒反應 | 卡片貼著中控感應區、螢幕按確認；再按一次 `2. Enroll key` |
| 簽章/權限/解密錯誤 | 正常，這正是我們在測的；照樣 Export 傳回 |
