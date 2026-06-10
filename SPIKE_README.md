# Tesla BLE Feasibility Spike — tester runbook (GitHub issue #11)

This is a **throwaway probe app**, not the real HUD. Its job: prove the phone can
talk to a Tesla over Bluetooth in Dart, enroll a key, and find out **which fields
BLE exposes and how fast**. You need the physical car for this.

## What we're trying to answer
1. Does BLE connect + one-time key enrollment work?
2. Can we read **battery %, range, gear** over BLE?
3. What **speed** sample/poll rate is achievable? Smooth enough for a gauge?
4. Is **instantaneous drive power** exposed?

Everything you tap is logged on-screen. At the end you **Export** the log and send
it back — even failed steps are useful (raw frames become test fixtures).

## Prerequisites
- A Mac with Flutter (3.41+) and Xcode 26+, an Apple ID for signing.
- Your iPhone: **Developer Mode ON** (Settings → Privacy & Security), unlocked.
- The car nearby; you are an authorized driver and have a **paired NFC key card**.

## Build & run (self-build to your own iPhone)
```bash
git clone <repo-url> && cd tsla-speed-meter
git checkout feature/goal-2-ble
flutter pub get
# plug in iPhone, trust the Mac, then:
flutter run --release -t lib/spike_main.dart -d <your-iphone>
```
> Use `--release` (or `--profile`). iOS debug builds need the debugger attached to
> JIT and will appear to hang — this is a known Flutter-on-iOS gotcha, not a bug.

First launch: approve the Bluetooth permission prompt.

## Steps in the app
1. **Enter your VIN** (17 chars, on the dash base / door jamb / app).
2. **1. Connect** — scans for your car's BLE name (derived from the VIN) and connects.
   - If it can't find the car: make sure the car is awake (open a door) and close
     the official Tesla app (it may hold the BLE connection).
3. **2. Enroll key** — sends an add-key request. **Then tap your NFC key card on the
   center-console card reader** and confirm on the touchscreen. (One-time. You are
   NOT giving us your Tesla account — enrollment is authorized by the physical card.)
4. **3. Session info** — establishes the encrypted session for reading data.
5. **4. Read data** — requests drive + charge state once. Watch the log.
6. **5. Poll speed ×20** — **do this while someone else drives a short loop** (don't
   operate the phone yourself while driving). Lets us measure the achievable rate.
7. Tap the **Export** icon (top-right) and send the log file back.

## Safety
Have a second person operate the phone while driving, or only run the driving step
as a passenger. Never tap through this while you're the one driving.

## What's already proven (so you know what to expect)
The crypto + wire-format core is unit-tested against Tesla's official
`vehicle-command` reference vectors (session key, AES-GCM, protobuf, field mapping).
The **transport + handshake** in this app is the unverified part we're testing — so
the **response decode may fail on the first run**. That's fine: the log captures the
raw encrypted frames, which is exactly what we need to finish the job. Don't worry
if step 4/5 shows "could not decode" — **just export and send the log**.

## After the spike
The log feeds an ADR (in `docs/adr/`) stating which fields `TeslaBleSource` will
provide and at what rate. That unblocks issues #12+.
