#!/usr/bin/env bash
# Build Android release APKs into dist/ for GitHub Releases.
# iOS IPA cannot be built on Linux — use macOS + Xcode (see README).
#
# Requires android/key.properties + keystore (see tool/create_release_keystore.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROPS="$ROOT/android/key.properties"
if [[ ! -f "$PROPS" ]]; then
  echo "Missing $PROPS"
  echo "Create a release keystore first:"
  echo "  ./tool/create_release_keystore.sh"
  echo "Or copy android/key.properties.example → android/key.properties"
  exit 1
fi

# shellcheck disable=SC1090
store_file="$(grep -E '^storeFile=' "$PROPS" | head -1 | cut -d= -f2-)"
if [[ -z "$store_file" ]]; then
  echo "key.properties missing storeFile="
  exit 1
fi
if [[ "$store_file" != /* ]]; then
  store_file="$ROOT/android/$store_file"
fi
if [[ ! -f "$store_file" ]]; then
  echo "Keystore not found: $store_file"
  exit 1
fi

echo "==> flutter analyze"
flutter analyze

echo "==> flutter test"
flutter test

VERSION="$(grep -E '^version:' pubspec.yaml | head -1 | sed -E 's/version:[[:space:]]*([^+]+).*/\1/')"
OUT="$ROOT/dist"
mkdir -p "$OUT"

echo "==> Building split-per-abi APKs (v$VERSION)..."
flutter build apk --release --split-per-abi \
  --obfuscate --split-debug-info="$OUT/symbols"

echo "==> Building universal APK..."
flutter build apk --release \
  --obfuscate --split-debug-info="$OUT/symbols"

cp -f build/app/outputs/flutter-apk/app-release.apk \
  "$OUT/FitnessPlan-${VERSION}-android.apk"
cp -f build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
  "$OUT/FitnessPlan-${VERSION}-android-arm64-v8a.apk"
cp -f build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk \
  "$OUT/FitnessPlan-${VERSION}-android-armeabi-v7a.apk"
cp -f build/app/outputs/flutter-apk/app-x86_64-release.apk \
  "$OUT/FitnessPlan-${VERSION}-android-x86_64.apk"

echo
echo "Done. Upload these to GitHub Release:"
ls -lh "$OUT"/FitnessPlan-"${VERSION}"-android*.apk
echo
echo "Tip (most phones): FitnessPlan-${VERSION}-android-arm64-v8a.apk"
echo "Or universal:      FitnessPlan-${VERSION}-android.apk"
echo "Keep $OUT/symbols/ for crash deobfuscation."
