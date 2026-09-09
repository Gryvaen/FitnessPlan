#!/usr/bin/env bash
# Generate UI screenshots for copyright manual via Flutter golden tests.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p docs/copyright/screenshots
flutter test test/copyright_screenshots_test.dart --tags=copyright --run-skipped --update-goldens
echo "Screenshots saved to docs/copyright/screenshots/"
