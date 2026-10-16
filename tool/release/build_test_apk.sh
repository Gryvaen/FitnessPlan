#!/usr/bin/env bash
# Build a single Android APK into dist/ for test distribution (e.g. Gitee).
# No analyze / test / obfuscation. Signs with android/key.properties when
# present, otherwise falls back to the debug key.
#
# Usage:
#   ./tool/release/build_test_apk.sh              # arm64-v8a only (most phones, smaller)
#   ./tool/release/build_test_apk.sh --universal  # all ABIs in one APK
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

UNIVERSAL=false
case "${1:-}" in
  "") ;;
  --universal) UNIVERSAL=true ;;
  *)
    echo "Usage: $0 [--universal]"
    exit 1
    ;;
esac

# Gradle 9.1 does not run on very new JDKs; prefer JDK 21 when JAVA_HOME is unset.
if [[ -z "${JAVA_HOME:-}" && -d /usr/lib/jvm/java-21-openjdk ]]; then
  export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
fi
echo "==> JAVA_HOME=${JAVA_HOME:-<system default>}"

if [[ -f "$ROOT/android/key.properties" ]]; then
  echo "==> Signing with android/key.properties"
else
  echo "==> android/key.properties not found; signing with debug key"
  echo "    (cannot upgrade over release-signed installs)"
fi

flutter pub get

# shellcheck source=tool/release/prefetch_sqlite3_android_libs.sh
source "$ROOT/tool/release/prefetch_sqlite3_android_libs.sh"
prefetch_sqlite3_android_libs

VERSION="$(grep -E '^version:' pubspec.yaml | head -1 | sed -E 's/version:[[:space:]]*([^+]+).*/\1/')"
REV="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"
if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
  REV="${REV}-dirty"
fi
OUT="$ROOT/dist"
mkdir -p "$OUT"

if $UNIVERSAL; then
  echo "==> Building universal APK (v$VERSION, $REV)..."
  flutter build apk --release
  DEST="$OUT/FitnessPlan-${VERSION}-${REV}-test-android.apk"
else
  echo "==> Building arm64-v8a APK (v$VERSION, $REV)..."
  flutter build apk --release --target-platform android-arm64
  DEST="$OUT/FitnessPlan-${VERSION}-${REV}-test-android-arm64-v8a.apk"
fi

cp -f build/app/outputs/flutter-apk/app-release.apk "$DEST"

echo
echo "Done:"
ls -lh "$DEST"
