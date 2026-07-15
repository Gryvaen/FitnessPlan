#!/usr/bin/env bash
# Build Android release APKs into dist/ for GitHub Releases.
# iOS IPA cannot be built on Linux — use macOS + Xcode (see README).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="$(grep -E '^version:' pubspec.yaml | head -1 | sed -E 's/version:[[:space:]]*([^+]+).*/\1/')"
OUT="$ROOT/dist"
mkdir -p "$OUT"

echo "==> Building split-per-abi APKs (v$VERSION)..."
flutter build apk --release --split-per-abi

echo "==> Building universal APK..."
flutter build apk --release

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
