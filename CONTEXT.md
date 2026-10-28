# SpeedHUD

An iPhone speed display for Tesla drivers. It shows the car's own data, read over Bluetooth, and falls back to the phone's GPS for speed. Words in parentheses are the on-screen Chinese terms.

## Data sources

**Car Bluetooth** (車輛藍牙):
The direct Bluetooth link between the phone and the car. It carries speed, gear, battery, range and tire pressure, with no Tesla account or internet.
_Avoid_: BLE source, Tesla source

**Car feed**:
The app's one Car Bluetooth connection and the only thing that asks the car for data: drive state about 5 times a second; battery, tire pressure and the doors, trunks and windows every 10 s; while parked, the outside and inside temperature every 30 s. Everything that shows or records car data listens to it.
_Avoid_: poller, BLE manager

**GPS fallback** (GPS):
Speed from the phone's own GPS. It is used only while Car Bluetooth has no valid speed, and it never supplies gear, battery, range or tires.
_Avoid_: GPS mode

**Speed source** (速度來源):
Whichever of Car Bluetooth or GPS fallback supplies the speed on screen right now. Car Bluetooth wins whenever it is valid.
_Avoid_: freshest source

**Source chip**:
The top-left icons that always name the current speed source. The chip has no words on screen; its words are its accessibility label.

## The car and its keys

**Paired car**:
The one car this phone knows by VIN and whose key list holds this phone's app key. Being paired says nothing about being connected right now.
_Avoid_: connected car

**App key** (鑰匙):
The key this app creates, keeps on the phone, and adds to the car's key list.
_Avoid_: phone key (Tesla's own app has a different "Phone Key")

**Key card** (鑰匙卡):
The car's physical card. It is tapped on the console to approve adding an app key.

**Pairing** (配對):
The steps that make a car the paired car: get its VIN, find it nearby, add the app key, and read the car once. A new car replaces the old one only when its pairing succeeds.
_Avoid_: setup, enrollment (adding the app key is only one step of pairing)

**VIN scan** (掃描 VIN):
Reading the VIN live through the camera, pointed at the car's own screen (控制 → 軟體). The fallback is typing it.
_Avoid_: photo, OCR

**Nearby match** (✓ 就是旁邊這台):
Proof that a VIN belongs to the car next to the phone, because that car's Bluetooth name is derived from it. Pairing never adds a key before a nearby match.
_Avoid_: VIN validation (that only checks the format)

## Screens

**Drive screen** (行車畫面):
The default layout: the gauge with speed, the gear row and battery / range.

**Parked screen** (停車畫面):
The layout shown only when Car Bluetooth reports the car is in P. It lights P in the gear row (「P 檔」 in the centre when there is no speed) and shows the tire pressures.

**Trip** (本趟 / 行程):
What the left panel adds up: distance, drive time, average, max and battery change (L89). It starts at the first valid speed after the app opens (never while the car reports a fresh P), and ends when the car auto-parks; a trip that never reached 5 km/h is not kept. The ended trip keeps showing until a new one starts, after the layout has left parked, at the first valid speed of 5 km/h or more. With GPS only (no Car Bluetooth reading since the car last moved), 10 minutes without a speed above 0 also starts a new one at the next.
_Avoid_: journey, drive session

**Car navigation** (車上導航):
The route the car's own navigation is following (destination, time and distance left, battery on arrival), read from the car over Car Bluetooth. The drive screen's right panel shows it when it is chosen on entering the drive screen, or after the one switch to it per trip (L73 Q11). Never the phone's navigation.
_Avoid_: nav, phone navigation, route guidance

**Parked card** (卡):
What one side panel shows on the parked screen, chosen with its title button or a vertical swipe: 行程 or 車況 on the left, 胎壓 or 車上導航 on the right. The choice is remembered for the next parked screen; the drive screen has no cards, and nothing on its panels can be tapped.
_Avoid_: page, tab, widget

**Car-status icons** (車況圖示):
Small icons inside the ring for the front trunk, rear trunk and doors (L87): solid red when open, a dashed outline when unknown (no value, or more than 30 s old), nothing when closed. They have no words on screen; each lit icon has its own spoken sentence. Hidden with the rest of the car data when the car is not connected or GPS supplies the speed.
_Avoid_: telltales, warning lights, alerts

**Drive logger** (行車紀錄(測試)):
A test page that records car and GPS data to files for analysis. It is not a product feature.
