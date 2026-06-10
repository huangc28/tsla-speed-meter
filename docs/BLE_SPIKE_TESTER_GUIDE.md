# Tesla BLE 測試 — 給測試者的操作指南

嗨！感謝幫忙 🙏 這是一個**一次性的測試 app**（不是正式產品），目的是確認手機能不能
用藍牙連上你的 Tesla、讀到車速 / 電量 / 檔位這些資料。整個過程大概 **15 分鐘**，
需要**車**和你的 **Tesla 實體鑰匙卡**。

> ⚠️ 重點先講：**不需要你的 Tesla 帳號密碼**。加鑰匙是靠你拿實體卡片在車上感應授權的。

---

## 你需要準備
- 一台 **Mac**，裝好 Flutter 3.41+ 和 Xcode 26+
- 你的 **iPhone**：開啟「開發者模式」（設定 → 隱私權與安全性 → 開發者模式），螢幕解鎖
- 車停在旁邊、你是車主或授權駕駛、手邊有 **Tesla 鑰匙卡**

---

## 第一步：把 app build 到你 iPhone

```bash
git clone https://github.com/huangc28/tsla-speed-meter.git
cd tsla-speed-meter
git checkout feature/goal-2-ble
flutter pub get

# iPhone 插上 Mac、信任這台電腦，然後：
flutter run --release -t lib/spike_main.dart -d <你的iPhone>
```

> 💡 **一定要加 `--release`**。iOS 的 debug build 需要接著 debugger 才能跑，
> 不加會看起來卡在白畫面 —— 這是 Flutter on iOS 的已知狀況，不是 bug。

第一次開啟時，**允許藍牙權限**。

---

## 第二步：在 app 裡照順序操作

1. **輸入 VIN**（17 碼，在儀表板底座、門框、或 Tesla app 裡都看得到）

2. 按 **`1. Connect`**
   - 它會用 VIN 算出你車子的藍牙名稱去找車並連線
   - 找不到車的話：**開一下車門把車叫醒**，並**關掉官方 Tesla app**（它可能佔著藍牙連線）

3. 按 **`2. Enroll key`**（加鑰匙，只需做一次）
   - 按下去後，**拿你的 Tesla 鑰匙卡去中控感應區感應**，並在中控螢幕上**確認**

4. 按 **`3. Session info`** — 建立加密連線

5. 按 **`4. Read data`** — 讀一次車輛資料，看畫面 log

6. 按 **`5. Poll speed ×20`** — **這步請在有人開車的時候做**（測車速更新頻率）
   - ⚠️ **安全第一**：請當乘客操作手機，或找人幫你開、你操作；**不要自己邊開邊用**

7. 按右上角的 **匯出（Export / 分享圖示）**，把 log 檔案傳回給我

---

## 最重要的一句話

**就算第 4、5 步顯示 `could not decode` 或任何錯誤，也完全沒關係！**

這個 app 會把所有原始藍牙封包記在 log 裡，那正是我需要的東西。
**不管成功失敗，請務必按 Export 把 log 傳回來。** 失敗的 log 一樣超有價值 🙌

---

## 常見問題

| 狀況 | 解法 |
|---|---|
| 卡在白畫面 | 你忘了加 `--release`，重跑 |
| 找不到車 | 開車門叫醒車 + 關掉官方 Tesla app + 確認藍牙開著 |
| 加鑰匙沒反應 | 鑰匙卡要貼著中控感應區、螢幕要按確認；再按一次 `2. Enroll key` |
| 簽章/權限錯誤 | 正常，這就是我們在測的；照樣 Export 傳回來 |

有任何卡關，截圖 log 給我就好。再次感謝！
