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
flutter analyze --no-fatal-infos

echo "==> flutter test"
flutter test

# package:sqlite3 downloads prebuilt .so from GitHub via Dart HttpClient.
# Some networks fail that TLS handshake; curl usually works. Prefetch into
# the hooks shared cache so the build hook can reuse the files.
prefetch_sqlite3_android_libs() {
  local ver hashes_file name hash src dest_dir dest mirror shared base line
  ver="$(awk '
    /^  sqlite3:/{f=1; next}
    f && /^    version:/{
      gsub(/"/, "", $2); print $2; exit
    }
  ' pubspec.lock)"
  if [[ -z "$ver" ]]; then
    echo "Could not resolve sqlite3 version from pubspec.lock" >&2
    exit 1
  fi

  hashes_file="$(find "${PUB_CACHE:-$HOME/.pub-cache}/hosted" \
    -path "*/sqlite3-${ver}/lib/src/hook/asset_hashes.dart" 2>/dev/null | head -1 || true)"
  if [[ -z "$hashes_file" || ! -f "$hashes_file" ]]; then
    echo "sqlite3 asset hashes not found for v${ver}; run flutter pub get first" >&2
    exit 1
  fi

  mirror="$ROOT/tool/sqlite3_mirror/sqlite3-${ver}"
  shared="$ROOT/.dart_tool/hooks_runner/shared/sqlite3/build"
  base="https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-${ver}"
  mkdir -p "$mirror" "$shared"

  echo "==> Prefetching sqlite3 ${ver} Android natives (curl)..."
  while IFS= read -r line; do
    name="${line%%:*}"
    hash="${line#*:}"
    [[ "$name" == libsqlite3.*.android.so ]] || continue
    src="$mirror/$name"
    dest_dir="$shared/download-${hash:0:8}"
    dest="$dest_dir/libsqlite3.so"
    if [[ -f "$dest" ]] && [[ "$(sha256sum "$dest" | awk '{print $1}')" == "$hash" ]]; then
      continue
    fi
    if [[ ! -f "$src" ]] || [[ "$(sha256sum "$src" | awk '{print $1}')" != "$hash" ]]; then
      curl -fsSL -L -o "$src" "$base/$name"
    fi
    if [[ "$(sha256sum "$src" | awk '{print $1}')" != "$hash" ]]; then
      echo "Hash mismatch after download: $name" >&2
      exit 1
    fi
    mkdir -p "$dest_dir"
    cp -f "$src" "$dest"
    rm -f "${dest}.tmp"
  done < <(awk -F"'" '
    /libsqlite3\..*\.android\.so/ { print $2 ":" $4 }
  ' "$hashes_file")
}

prefetch_sqlite3_android_libs

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
