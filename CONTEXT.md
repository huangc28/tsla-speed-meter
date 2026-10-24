# SpeedHUD

An iPhone speed display for Tesla drivers. It shows the car's own data, read over Bluetooth, and falls back to the phone's GPS for speed. Words in parentheses are the on-screen Chinese terms.

## Data sources

**Car Bluetooth** (車輛藍牙):
The direct Bluetooth link between the phone and the car. It carries speed, gear, battery, range and tire pressure, with no Tesla account or internet.
_Avoid_: BLE source, Tesla source

**GPS fallback** (GPS):
Speed from the phone's own GPS. It is used only while Car Bluetooth has no valid speed, and it never supplies gear, battery, range or tires.
_Avoid_: GPS mode

**Speed source** (速度來源):
Whichever of Car Bluetooth or GPS fallback supplies the speed on screen right now. Car Bluetooth wins whenever it is valid.
_Avoid_: freshest source

**Source chip**:
The top-left label that always names the current speed source.

## The car and its keys

**Paired car**:
The one car this phone knows by VIN and whose key list holds this phone's app key. Being paired says nothing about being connected right now.
_Avoid_: connected car

**App key** (鑰匙):
The key this app creates, keeps on the phone, and adds to the car's key list.
_Avoid_: phone key (Tesla's own app has a different "Phone Key")

**Key card** (鑰匙卡):
The car's physical card. It is tapped on the console to approve adding an app key.

## Screens

**Drive screen** (行車畫面):
The default layout: the gauge with speed, the gear row and battery / range.

**Parked screen** (停車畫面):
The layout shown only when Car Bluetooth reports the car is in P. It shows 「P 檔」 and the tire pressures.

**Drive logger** (行車紀錄(測試)):
A test page that records car and GPS data to files for analysis. It is not a product feature.
