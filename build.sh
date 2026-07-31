#!/bin/bash
# ===========================================================
#  build.sh — Auto-increment versionCode & build app bundle
# ===========================================================
#  Penggunaan:
#    ./build.sh            → build App Bundle (default)
#    ./build.sh apk        → build APK
#    ./build.sh --no-build → hanya naikkan versionCode, tanpa build
# ===========================================================

set -e

PUBSPEC="pubspec.yaml"

# -----------------------------------------------------------
# 1. Baca versi saat ini
# -----------------------------------------------------------
CURRENT_VERSION=$(grep '^version:' "$PUBSPEC" | sed 's/version: //')
BUILD_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

echo ""
echo "📦 Versi saat ini : $BUILD_NAME+$BUILD_NUMBER"

# -----------------------------------------------------------
# 2. Increment versionCode (+1)
# -----------------------------------------------------------
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
NEW_VERSION="$BUILD_NAME+$NEW_BUILD_NUMBER"

# Update pubspec.yaml
sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC"

echo "🔼 Versi baru      : $BUILD_NAME+$NEW_BUILD_NUMBER"
echo ""

# -----------------------------------------------------------
# 3. Build
# -----------------------------------------------------------
if [ "$1" = "--no-build" ]; then
  echo "✅ versionCode dinaikkan. Build dilewati (--no-build)."
  exit 0
fi

if [ "$1" = "apk" ]; then
  echo "🔨 Membangun APK..."
  echo ""
  flutter build apk --release
  echo ""
  echo "✅ APK selesai! (versi $NEW_VERSION)"
else
  echo "🔨 Membangun App Bundle..."
  echo ""
  flutter build appbundle --release
  echo ""
  echo "✅ App Bundle selesai! (versi $NEW_VERSION)"
fi
