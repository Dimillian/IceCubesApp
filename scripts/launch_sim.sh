#!/usr/bin/env bash

set -euo pipefail

PROJECT="IceCubesApp.xcodeproj"
SCHEME="IceCubesApp"
SIMULATOR_NAME="iPhone Air"
DESTINATION="platform=iOS Simulator,name=${SIMULATOR_NAME},OS=latest"
DERIVED_DATA="build/sim"

# Prefer an already booted simulator, otherwise boot the requested one.
BOOTED_UDID="$(xcrun simctl list devices booted | sed -n 's/.*(\([A-F0-9-]*\)).*/\1/p' | head -n 1)"
if [[ -z "${BOOTED_UDID:-}" ]]; then
  echo "No booted simulators. Booting ${SIMULATOR_NAME}..."
  SIMULATOR_NAME_ESCAPED="$(printf '%s\n' "$SIMULATOR_NAME" | sed -e 's/[][\\.^$*+?(){}|/]/\\&/g')"
  SIMULATOR_UDID="$(xcrun simctl list devices available | sed -n "/${SIMULATOR_NAME_ESCAPED}/s/.*(\([A-F0-9-]*\)).*/\1/p" | head -n 1)"
  if [[ -z "${SIMULATOR_UDID:-}" ]]; then
    echo "Could not find simulator named ${SIMULATOR_NAME}" >&2
    exit 1
  fi
  xcrun simctl boot "${SIMULATOR_UDID}" || true
  xcrun simctl bootstatus "${SIMULATOR_UDID}" -b
  open -a Simulator || true
  BOOTED_UDID="${SIMULATOR_UDID}"
fi

echo "Building ${SCHEME} for ${SIMULATOR_NAME}..."
if command -v xcpretty >/dev/null 2>&1; then
  xcodebuild \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -destination "${DESTINATION}" \
    -derivedDataPath "${DERIVED_DATA}" \
    build | xcpretty
else
  echo "xcpretty not found; running plain xcodebuild."
  xcodebuild \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -destination "${DESTINATION}" \
    -derivedDataPath "${DERIVED_DATA}" \
    build
fi

APP_PATH="$(find "${DERIVED_DATA}/Build/Products/Debug-iphonesimulator" -maxdepth 4 -name "*.app" -type d | head -n 1)"

if [[ -z "${APP_PATH:-}" ]]; then
  echo "Could not find built .app under ${DERIVED_DATA}" >&2
  exit 1
fi

# Derive the bundle identifier from build settings so this script works with custom prefixes.
BUNDLE_ID="$(xcodebuild -project "${PROJECT}" -scheme "${SCHEME}" -destination "${DESTINATION}" -showBuildSettings 2>/dev/null | awk -F ' = ' '/PRODUCT_BUNDLE_IDENTIFIER/ {print $2; exit}')"

if [[ -z "${BUNDLE_ID:-}" ]]; then
  echo "Could not determine PRODUCT_BUNDLE_IDENTIFIER" >&2
  exit 1
fi

echo "Installing ${APP_PATH}..."
xcrun simctl install booted "${APP_PATH}"

echo "Launching ${BUNDLE_ID}..."
xcrun simctl launch booted "${BUNDLE_ID}"

echo "Done."
