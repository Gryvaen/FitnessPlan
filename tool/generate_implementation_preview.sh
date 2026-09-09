#!/usr/bin/env bash
# Capture running-widget screenshots into design-handoff/implementation-preview/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p design-handoff/implementation-preview
flutter test test/implementation_preview_test.dart \
  --tags=implementation_preview \
  --run-skipped \
  --update-goldens
echo "Screenshots saved to design-handoff/implementation-preview/"
