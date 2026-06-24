# Tesla BLE 測試指南 — Android 版（人 + AI agent 都能 follow）

這是一個**一次性測試 app**（不是正式產品），目的：確認手機能不能用藍牙連上 Tesla、
讀到車速 / 電量 / 檔位。需要**真車** + **Tesla 實體鑰匙卡**，全程約 15 分鐘。

> ⚠️ **不需要 Tesla 帳號密碼**。加鑰匙是靠你拿實體卡片在車上感應授權。

> 📱 這份是 **Android 版**。iPhone 測試者請看 `BLE_SPIKE_TESTER_GUIDE.md`。
> Android 比 iOS 簡單：**不需要 `--release`、不需要簽章、不會卡白畫面。**

---

## 🤖 如果你是 AI agent，先讀這段

你可以完成 **A. 環境 setup + build 安裝**，但 **B. 車上互動步驟必須交給人**（實體鑰匙卡、
開車、在手機螢幕上點按鈕）。請照下面做，到 `=== STOP: HUMAN REQUIRED ===` 就停下來把
控制權交還給使用者。

Android 有兩條安裝路線，擇一即可：
- **路線 1（手機接電腦）**：測試者的 Android 手機能插上這台有 Flutter 的電腦 → 用 `flutter run`。
- **路線 2（寄 APK）**：build 一個 APK 檔，傳給測試者自己 sideload 安裝。手機不在你這時用這條。

### A. Machine steps（agent 可自動執行）

```bash
# 1. 取得程式碼
git clone https://github.com/huangc28/tsla-speed-meter.git
cd tsla-speed-meter
git checkout feature/goal-2-ble
flutter pub get

# 2. 環境檢查（要看到 Flutter 3.41+）
flutter --version
flutter doctor
```

**路線 1 — 手機接在電腦上：**
```bash
flutter devices                 # 記下 Android 手機的 device id
# Android 不需要 --release，debug build 就能完整跑 BLE
flutter run -t lib/spike_main.dart -d <ANDROID_DEVICE_ID>
```

**路線 2 — 產 APK 寄給測試者：**
```bash
# debug APK 可獨立安裝執行（不需連 debugger），最省事、不用簽章
flutter build apk --debug -t lib/spike_main.dart
# 產出檔案：build/app/outputs/flutter-apk/app-debug.apk
# 把這個 .apk 傳給測試者，照下面「測試者安裝 APK」操作
```

### ⚠️ Agent 會遇到、且需要「人」處理的點
1. **USB 偵錯（路線 1）**：手機要先開「開發者選項 → USB 偵錯」，插上電腦後在手機上按「允許這台電腦偵錯」。
   - 開發者選項開法：設定 → 關於手機 → 連點「版本號碼」7 次。
2. **安裝來源（路線 2）**：sideload APK 時，手機會問是否允許「安裝未知應用程式」，要由人去設定允許。
3. App 第一次開啟時的**藍牙權限（附近的裝置）**、必要時**定位權限**，要在手機上由人按允許。
   （定位：Android 11 以下掃描 BLE 需要；Android 12+ 通常只要藍牙權限。）
4. **不需要 `--release`、不會卡白畫面** —— 這是 iOS 才有的限制，Android 忽略。

#### 測試者安裝 APK（路線 2，給人看的）
1. 把收到的 `app-debug.apk` 下載到手機。
2. 點開檔案 → 若跳「無法安裝未知應用程式」→ 去設定允許該來源（檔案管理員 / Chrome）→ 回來再點一次。
3. 安裝完成 → 桌面會出現 **tsla_speed_meter** 圖示，開啟它。

```
=== STOP: HUMAN REQUIRED ===
build 成功、app 已裝到 Android 手機後，agent 停在這裡。
告訴使用者：「app 裝好了，請拿到車旁照 B 段操作。」
```

---

## 🧑 B. 車上操作步驟（必須真人，在車旁/車上做）

> 與 iOS 版完全相同。第一次按 `1. Connect` 時手機會跳**藍牙（附近的裝置）權限**，請按允許。

1. **輸入 VIN**（17 碼；儀表板底座、門框、或 Tesla app 裡有）
2. 按 **`1. Connect`** — 連線。第一次會跳藍牙權限 → 允許。找不到車就：開車門叫醒車 + 關掉官方 Tesla app（它佔住藍牙）
3. 按 **`2. Enroll key`** → **拿鑰匙卡感應中控**、螢幕按確認（只需一次）
4. 按 **`3. Session info`** — 建立加密連線
5. 按 **`4. Read data`** — 讀一次資料
6. 按 **`5. Poll speed ×20`** — **請當乘客操作 / 找人幫開**，⚠️ 不要自己邊開邊用
7. 按右上角 **匯出（分享圖示）** → 用分享面板把 log 檔傳回給對方

---

## ‼️ 最重要的一句話

**就算第 4、5 步出現 `could not decode` 或任何錯誤，也完全沒關係。**
app 會把所有原始藍牙封包記進 log，那正是我們要的。**不管成功失敗，務必 Export 把 log 傳回。**

---

## 常見問題

| 狀況 | 解法 |
|---|---|
| `flutter devices` 看不到手機 | 開「USB 偵錯」、換條能傳資料的 USB 線、手機上按「允許這台電腦偵錯」 |
| APK 裝不起來 | 允許「安裝未知應用程式」來源後重點一次 |
| 按 Connect 沒反應 / 一直失敗 | 確認有按允許**藍牙（附近的裝置）權限**；藍牙開著；Android 11 以下還要開**定位**（包含定位服務總開關） |
| 找不到車 | 開車門叫醒車 + 關官方 Tesla app + 確認藍牙開著 |
| 加鑰匙沒反應 | 卡片貼著中控感應區、螢幕按確認；再按一次 `2. Enroll key` |
| 簽章/權限/解密錯誤 | 正常，這正是我們在測的；照樣 Export 傳回 |

> 註：Android **不需要** iOS 那套 `--release`、Apple ID 簽章、Developer Mode、改 bundle id —— 那些只對 iPhone 有效。
