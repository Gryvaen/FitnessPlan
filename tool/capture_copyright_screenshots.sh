#!/usr/bin/env bash
# Capture screenshots for copyright manual (Linux desktop).
# Usage: ./tool/capture_copyright_screenshots.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/docs/copyright/screenshots"
mkdir -p "$OUT"

cd "$ROOT"
flutter pub get

echo "Building Linux debug binary..."
flutter build linux --debug

APP_BIN="$ROOT/build/linux/x64/debug/bundle/fitness_plan"
if [[ ! -x "$APP_BIN" ]]; then
  # Flutter project folder name may differ
  APP_BIN="$(find "$ROOT/build/linux" -maxdepth 4 -type f -executable -name 'fitness_plan' | head -1)"
fi

if [[ -z "${APP_BIN:-}" || ! -x "$APP_BIN" ]]; then
  echo "Could not find Linux binary. Run manually:" >&2
  echo "  flutter run -d linux" >&2
  echo "Then save screenshots to docs/copyright/screenshots/" >&2
  exit 1
fi

echo "Launching app under xvfb..."
export DISPLAY=:99
Xvfb :99 -screen 0 1280x800x24 &
XVFB_PID=$!
sleep 2

"$APP_BIN" &
APP_PID=$!
sleep 15

capture() {
  local name="$1"
  import -window root "$OUT/$name"
  echo "Captured $name"
}

capture "01-onboarding.png"
# Additional captures require UI automation; manual screenshots recommended.

kill "$APP_PID" 2>/dev/null || true
kill "$XVFB_PID" 2>/dev/null || true

echo "Done. Review images in $OUT"
echo "For full set (02-12), run the app and capture each screen manually."
