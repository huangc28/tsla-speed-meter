# Can the iPhone app read a Tesla VIN live through the camera?

Date: 2026-10-24. Scope: native Swift, iOS 17+, iPhone 17 Pro Max on iOS 26. "[unverified]" marks anything I could not confirm from a primary source.

**Short answer:** yes. VisionKit `DataScannerViewController` reads text and barcodes live with no shutter button. It has no VIN type, so we filter the text ourselves, and the Bluetooth-name hash is the final proof.

## Sources
- A1 Apple docs: `DataScannerViewController`, `isSupported`, `isAvailable`, `TextContentType`, `isGuidanceEnabled`, `regionOfInterest`, `RecognizedItem.Text` (developer.apple.com/documentation/visionkit/...)
- A2 Apple article "Scanning data with the camera" (same site)
- A3 WWDC22 10025 "Capture machine-readable codes and text with VisionKit"
- A4 WWDC19 234 "Text Recognition in Vision Framework"
- A5 Apple Vision docs: sample "Extracting phone numbers from text in images", `VNRecognizeTextRequest`, `usesLanguageCorrection`, `customWords`, `VNBarcodeSymbology`
- T1 Tesla Model 3 / Model Y owner's manual "Identification Labels" (GUID-B27A666D-...), read via Wayback copy of tesla.com/ownersmanual (tesla.com blocks direct fetch)
- T2 Tesla Model 3 Service Manual "Vehicle Identification Number (VIN)", 2017-2023 and 2024 editions, via Wayback
- R1 49 CFR 565.13 and 565.15 (eCFR)
- R2 GB 16735-2019 full text (catarc.org.cn/upload/202108/10/202108101324047215.pdf)
- V1 Vendor pages: anyline.com/news/vin-scanning; docs.scandit.com and scandit.com/pricing; docs.scanbot.io (iOS VIN Scanner) and scanbot.io/pricing; dynamsoft.com/pricing; developers.google.com/ml-kit/vision/text-recognition/v2/ios
- ISO 3779 is paywalled and I did not read it [unverified]; the character set and check digit come from R1/R2.

## 1. DataScannerViewController
- **Availability.** iOS 16+. `isSupported` needs an A12 Bionic or later (A1). `isAvailable` is false if the camera is denied or restricted by Screen Time (A1). Check both (A2).
- **Permission.** `NSCameraUsageDescription` is required; without it a runtime error occurs (A2).
- **Live, no shutter.** `startScanning()` plus `didAdd/didUpdate` delegate calls or the `recognizedItems` stream. Preview, tap-to-focus, pinch-to-zoom, highlights and "Slow Down" guidance are built in (A1-A3).
- **On-device.** The pages I read never say "on-device" [unverified], and mention no network step.
- **No VIN type.** Content types are only URL, date/time, email, flight number, street address, tracking number, phone and currency (A1). Use `.text()` with no type and regex each `transcript`. No doc or session offers a regex filter (A3).
- **Barcodes.** "All the same symbologies as Vision's barcode detector" (A3): Code 39 (and variants), Code 128, Data Matrix, QR, PDF417, Aztec (A5).
- **Tuning.** `qualityLevel` `.accurate` raises camera resolution for small print (A1); `regionOfInterest` limits the scan area (A1). Text items give `transcript` and an `observation` (A1). No language-correction switch, custom words or confidence value.

## 2. Vision `VNRecognizeTextRequest` (for stills, or finer control)
- **Modes.** `.fast` for live capture, `.accurate` for still images (A4). Apple's live sample uses `.fast`, `usesLanguageCorrection = false` and a region of interest (A5).
- **Language correction off for codes.** WWDC19: "C001" can be misread as "cool" (A4). `customWords` are ignored when correction is off (A5), so they do not help.
- **iOS 18+ `RecognizeTextRequest`.** Same options; I found no advantage here.
- **Confusions** (0/O, 1/I, 8/B, 5/S, 2/Z): I found no Apple statement on error rates [unverified].
- **VIN alphabet helps.** Digits and capitals only, no I, O, Q (GB 16735 section 4, R2). So O/Q map safely to 0 and I to 1. B/8, S/5 and Z/2 stay ambiguous; the check digit and Bluetooth name resolve them.
- **WWDC19 pattern.** Fix S to 5 with domain rules, filter by structure, and accept a number after it shows in 10 consecutive frames (A4).

## 3. Where to point the camera (ranked)
1. **Car touchscreen, Controls > Software.** Listed in both Tesla manuals (T1, T2). Clean text; watch glare and moire.
2. **Tesla app.** The Cybertruck manual lists "The Tesla mobile app" as a VIN location; the Model 3/Y pages I read do not. Third parties say it is at the bottom of the page. Copyable: unverified. A screenshot read as a still is a no-typing path.
3. **Windshield plate.** "Stamped on a plate located at the top of the dashboard", seen through the windshield (T1); the service manual says driver-side bottom corner (T2). Stamped metal behind glass will glare. I found no source on glare, so that is my judgement [unverified]. GB 16735 5.5 requires M1 vehicles to show the VIN near the windshield pillar, readable from outside in daylight.
4. **Door pillar label.** "Vehicle Certification label" (US), "Statutory" or "Identification Plate" elsewhere; front door open (T1).
5. **Shanghai (LRW) floor stamp.** Under the front-right seat; not practical (T1).
6. **Taiwan 行照.** Not researched.
- **Barcodes.** No Tesla manual mentions a VIN barcode on any label [unverified]. 49 CFR 565 does not require one. GB 16735 6.1 allows "human-readable plus machine-readable" and points to GB/T 18410 (VIN barcode label, not read). Treat barcodes as a bonus.

## 4. Validation
1. **Pattern.** Uppercase, strip spaces, map O/Q to 0 and I to 1, then search the transcript (not match it whole, since lines may read "VIN: ...") for `[A-HJ-NPR-Z0-9]{17}`.
2. **Check digit (position 9).** Values: digits as themselves, A-H 1-8, J-N 1-5, P 7, R 9, S-Z 2-9. Weights: 8,7,6,5,4,3,2,10,0,9,8,7,6,5,4,3,2. Sum mod 11; 10 is "X". I tested this on 1M8GDM9AXKP042788 and got X (matches).
   - **US:** required ("a check digit shall be part of each VIN... position nine", 49 CFR 565.13(c)).
   - **China:** GB 16735-2019 states all technical content is mandatory, and 4.3 requires the 9th digit as a check digit per Annex A (R2).
   - **EU:** not required (secondary sources only [unverified]).
   - **Tesla:** its service manual says the 9th digit is a check digit, for WMIs 5YJ and LRW (T2).
3. **Multi-frame agreement.** Same string in N consecutive frames; the WWDC19 demo uses 10 (A4). I suggest about 5.
4. **Bluetooth proof.** `S` + hex(SHA1(VIN)[:8]) + `C` against nearby advertisements: 32 bits, so false accepts are negligible.
   - **Check digit is not a hard gate.** On failure, try single-character swaps among confusable pairs and test each against the Bluetooth name. A name match wins.

## 5. Third-party SDKs
| Vendor | VIN support | Licence, price |
|---|---|---|
| Anyline | VIN text and barcode, "processed on-device, never in the cloud", native iOS | Annual, quote only |
| Scandit | Label Capture has a predefined VIN label, text and/or barcode | Annual or per-device/scan, quote only, free trial |
| Scanbot | iOS VIN Scanner: OCR in a rectangle over frames, plus barcode, offline | Annual fixed fee, "generally starts at $2,500", 7-day trial |
| Dynamsoft | Label Recognizer with VIN models (secondary sources) | No public price, 30-day trial |
| Microblink | VIN support not confirmed [unverified] | Not checked |
| Google ML Kit | General text only, no VIN feature; ~38 MB per script | Cost not stated on page |

No free or open option beats Apple's scanner plus our own rules. Revisit a paid SDK only if field tests fail on windshield or door labels.

## 6. Real apps
From search snippets and store listings; I did not open them.
- Consumer VIN apps say they use OCR plus barcode.
- Parts and shop apps (WORLDPAC, Advance Professional, Airtex) scan the **barcode**.
- Shopmonkey's technician app has separate barcode and windshield-plate scanners (page returned 403; snippet only).
- No camera VIN scan found in Progressive, GEICO or CARFAX apps.
- Shops scan door-jamb barcodes on US cars. I found no evidence this works on Teslas.

## Recommendation
Use `DataScannerViewController` with `[.text(), .barcode(symbologies: [.code39, .code128, .dataMatrix, .qr])]`, `.accurate` and a region of interest, then add our own code:
1. Normalize and regex each item, then require about 5 frames of agreement.
2. Rank candidates by check digit, with the single-swap repair.
3. Confirm by Bluetooth name, and only then store the VIN.
4. Prompt "Point at the VIN on the car screen: Controls > Software". The windshield and door label are second choices.
5. No-typing fallbacks: pick a Tesla app screenshot and read it with Vision `.accurate` and `usesLanguageCorrection = false`, then paste.

**Main risks**
- **Windshield plate:** glare and low contrast.
- **Tesla barcode:** unverified; do not depend on it.
- **DataScanner limits:** no confidence value or correction switch; move to a custom Vision pipeline if reads are noisy.
- **Check digit:** untested on real LRW/5YJ cars; the Bluetooth match covers it.
- **Camera denied or restricted:** needs the paste path.
- **Next step:** test on a real car (screen, windshield, door label, app screenshot) before considering a paid SDK.
