#!/bin/bash
# usage: docs/design/frames/export-pngs.sh [ID... | --all]   (no args = all current screens, superseded drafts skipped)
# Renders stage2-mockups.html?screen=<ID> to <name>.png at 2x with headless Google Chrome (needs network for Inter + lucide).
F="$(cd "$(dirname "$0")" && pwd)"
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# ID  PNG name  canvas width  canvas height
TABLE="S04a S04-a-drive-gps 390 844
S04b S04-b-drive-ble 390 844
S04e S04-e-camera-ahead 390 844
S04f S04-f-over-limit 390 844
S04fEN S04-f-over-limit-en 390 844
S04fMirror S04-f-mirror-check 390 844
S05 S05-no-speed 390 844
S06b S06-b-parked-ble-p 390 844
S06a S06-a-parked-gps-manual 390 844
S01 S01-first-run-layout 390 844
S16 S16-pair-key-card 390 844
S12 S12-not-in-this-version 390 844
S22 S22-unlock-tw 390 1010
S08 S08-settings 390 1380
S04h S04-h-ble-location-denied 390 844
S06g S06-g-parked-gps-old-battery 390 844
S06h S06-h-parked-no-source 390 844
S06i S06-i-parked-p-stale 390 844
S04n S04-n-camera-nearby 390 844
S02 S02-location-permission 390 844
S02b S02-b-location-denied 390 844
S03 S03-camera-alerts-intro 390 900
S28 S28-mounting-tips 390 844
S07 S07-parked-confirm 390 844
S09 S09-driving-screen-settings 390 900
S10 S10-camera-alert-settings 390 1140
S11 S11-mirror-preview 390 1010
S25 S25-about 390 844
S13 S13-pair-start 390 1040
S14 S14-pair-vin-error 390 844
S15 S15-pair-searching 390 844
S17 S17-pair-done 390 844
S18c S18-c-pair-car-not-found 390 844
S18h S18-h-pair-paused 390 844
S19 S19-car-bluetooth 390 844
S19b S19-b-remove-confirm 390 844
S20 S20-trial-start-tw 390 844
S21 S21-trial-ended-tw 390 844
S23 S23-support-us-b 390 844
S24 S24-purchase-results 390 1130
S05b S05-b-location-denied-no-car 390 844
S06f S06-f-parked-p-no-speed 390 844
S04eMph S04-e-camera-ahead-mph 390 844
S04fMph S04-f-over-limit-mph 390 844
S04nMph S04-n-camera-nearby-mph 390 844
S04L S04-L-drive-landscape 844 390
S06L S06-L-parked-landscape 844 390
S04XL S04-XL-drive-large-text 390 844
S06XL S06-XL-parked-large-text 390 930
S04aSetup S04-a-setup-pending 390 844
S04i S04-i-p-stale-left-parked 390 844
S05c S05-c-gate-no-gps-unpaired 390 844
S06d S06-d-parked-gps-manual-old-battery 390 844
S10b S10-b-camera-data-expired 390 1080
S19c S19-c-repair-confirm 390 844
S19d S19-d-repair-not-completed 390 844
S20ios S20-ios-trial-claim-tw 390 844
S20and S20-android-trial-start-tw 390 900"
# 已取代的舊稿:PNG 保留作對照,預設不重新匯出(要連舊稿一起重畫就加 --all)
SUPERSEDED="S02 S02b S06g S06h S06i S20"
if [ "$1" = "--all" ]; then IDS=$(echo "$TABLE" | awk '{print $1}')
elif [ -z "$*" ]; then IDS=$(echo "$TABLE" | awk -v sup=" $SUPERSEDED " 'index(sup, " " $1 " ") == 0 {print $1}')
else IDS="$*"; fi
for id in $IDS; do
  line=$(echo "$TABLE" | awk -v k="$id" '$1==k')
  [ -z "$line" ] && { echo "$id -> unknown ID"; continue; }
  set -- $line; name=$2; w=$3; h=$4
  rm -f "$F/$name.png"
  "$CH" --headless=new --disable-gpu --hide-scrollbars --window-size=$w,$h --force-device-scale-factor=2 \
    --virtual-time-budget=8000 --screenshot="$F/$name.png" "file://$F/stage2-mockups.html?screen=$id" >/dev/null 2>&1
  echo "$id -> $name.png $( [ -f "$F/$name.png" ] && echo ok || echo FAIL)"
done
