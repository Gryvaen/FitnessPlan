#!/usr/bin/env bash
# Create an Android upload keystore and key.properties for release builds.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$ROOT/android"
KEYSTORE="$ANDROID_DIR/upload-keystore.jks"
PROPS="$ANDROID_DIR/key.properties"
ALIAS="fitnessplan"

if [[ -f "$KEYSTORE" ]]; then
  echo "Already exists: $KEYSTORE"
  echo "Aborting to avoid overwriting. Delete it first if you intend to recreate."
  exit 1
fi

if [[ -f "$PROPS" ]]; then
  echo "Already exists: $PROPS"
  echo "Aborting to avoid overwriting."
  exit 1
fi

read -r -s -p "Store / key password: " PASS
echo
if [[ -z "$PASS" ]]; then
  echo "Password required."
  exit 1
fi

keytool -genkey -v \
  -keystore "$KEYSTORE" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias "$ALIAS" \
  -storepass "$PASS" \
  -keypass "$PASS" \
  -dname "CN=FitnessPlan, OU=Mobile, O=FitnessPlan, L=Unknown, ST=Unknown, C=CN"

cat >"$PROPS" <<EOF
storePassword=$PASS
keyPassword=$PASS
keyAlias=$ALIAS
storeFile=upload-keystore.jks
EOF

chmod 600 "$PROPS" "$KEYSTORE"
echo
echo "Created:"
echo "  $KEYSTORE"
echo "  $PROPS"
echo "Keep a secure backup of both. Do not commit them."
