#!/bin/bash
# usage: docs/design/frames/export-landscape.sh [ID...]   (no args = all screens)
# Renders landscape-mockups.html?screen=<ID> to landscape/<name>.png at 2x with headless Google Chrome
# (needs network for Inter + Noto Sans TC + Barlow Semi Condensed + lucide).
# 第八輪(L55):加上 S04minEn、S06minEn(667 英文)和 S06night(夜間);收尾(L56、R8-01)加上 S20、S21、S22、S25 的英文稿,共 66 張。
F="$(cd "$(dirname "$0")" && pwd)"
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# ID  PNG name  canvas width  canvas height
TABLE="S04a S04-a-gps 844 390
S04aSetup S04-a-setup-pending 844 390
S04b S04-b-ble 844 390
S04c S04-c-ble-speed-only 844 390
S04e S04-e-nearby-gps 844 390
S04eBle S04-e-nearby-ble-status 844 390
S04eMph S04-e-nearby-mph 844 390
S04d S04-d-switched-to-gps 844 390
S04g S04-g-cold-start 844 390
S04h S04-h-ble-location-denied 844 390
S04i S04-i-p-stale-left-parked 844 390
S04XL S04-XL-large-text 844 390
S04min S04-b-min-667x375 667 375
S04minEn S04-b-min-667x375-en 667 375
S05 S05-no-speed 844 390
S05s S05-searching-gps 844 390
S05b S05-b-location-denied-no-car 844 390
S05c S05-c-gate-no-gps-unpaired 844 390
S06b S06-b-parked-ble-p 844 390
S06f S06-f-parked-p-no-speed 844 390
S06a S06-a-parked-gps-manual 844 390
S06c S06-c-parked-waiting-car 844 390
S06d S06-d-parked-gps-old-battery 844 390
S06e S06-e-parked-locked 844 390
S06XL S06-XL-large-text-scroll 844 390
S06min S06-b-min-667x375 667 375
S06minEn S06-b-min-667x375-en 667 375
S06night S06-b-parked-night 844 390
S01 S01-first-run-layout 844 390
S03 S03-camera-alerts-intro 844 390
S28 S28-mounting-tips 844 390
S07 S07-parked-confirm 844 390
S08 S08-settings-display 844 390
S08alert S08-settings-alerts 844 390
S08car S08-settings-car 844 390
S08ax S08-settings-display-ax-single 844 390
S09 S09-driving-screen-settings 844 390
S10 S10-camera-alert-settings 844 390
S10b S10-b-camera-data-expired 844 390
S19 S19-car-bluetooth 844 390
S19b S19-b-remove-confirm 844 390
S19c S19-c-repair-confirm 844 390
S19d S19-d-repair-not-completed 844 390
S12 S12-not-in-this-version 844 390
S25 S25-about 844 390
S25En S25-about-en 844 390
S13 S13-pair-start 844 390
S14 S14-pair-vin-keyboard 844 390
S15 S15-pair-searching 844 390
S16 S16-pair-key-card 844 390
S17 S17-pair-done 844 390
S18c S18-c-pair-car-not-found 844 390
S18h S18-h-pair-paused 844 390
S20ios S20-ios-trial-claim 844 390
S20and S20-android-trial-start 844 390
S20iosEn S20-ios-trial-claim-en 844 390
S20andEn S20-android-trial-start-en 844 390
S21 S21-trial-ended 844 390
S21En S21-trial-ended-en 844 390
S22 S22-unlock-tw 844 390
S22En S22-unlock-en 844 390
S23 S23-support-us-b 844 390
S24 S24-purchase-result-dialog 844 390
S24retry S24-purchase-result-retry 844 390
S24close S24-purchase-result-close 844 390
S24all S24-purchase-results-board 844 640"
IDS="$*"; [ -z "$IDS" ] && IDS=$(echo "$TABLE" | awk '{print $1}')
mkdir -p "$F/landscape"
for id in $IDS; do
  line=$(echo "$TABLE" | awk -v k="$id" '$1==k')
  [ -z "$line" ] && { echo "$id -> unknown ID"; continue; }
  set -- $line; name=$2; w=$3; h=$4
  rm -f "$F/landscape/$name.png"
  "$CH" --headless=new --disable-gpu --hide-scrollbars --window-size=$w,$h --force-device-scale-factor=2 \
    --virtual-time-budget=8000 --screenshot="$F/landscape/$name.png" "file://$F/landscape-mockups.html?screen=$id" >/dev/null 2>&1
  echo "$id -> landscape/$name.png $( [ -f "$F/landscape/$name.png" ] && echo ok || echo FAIL)"
done
