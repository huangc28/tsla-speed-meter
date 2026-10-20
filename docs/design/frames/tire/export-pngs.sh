#!/bin/bash
# Round 7: fresh r7-* names, 2× resolution, bundled fonts, old exports retained.
# auto probes Chrome once; if it cannot run, uses the explicit SVG/TTF fallback.
set -eu
TIRE_FRAME_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$TIRE_FRAME_DIR/export-pngs.py" "$@"
