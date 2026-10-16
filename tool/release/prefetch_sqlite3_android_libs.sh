# Sourced by Android build scripts; expects ROOT to be the repo root.
#
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

  mirror="$ROOT/tool/release/sqlite3_mirror/sqlite3-${ver}"
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
