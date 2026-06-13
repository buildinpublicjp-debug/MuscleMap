#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/Users/og3939397/MuscleMap"
APP_BUNDLE_ID="com.buildinpublic.MuscleMap"
DEVICE_TYPE="iPhone 16 Pro Max"
ROOT_DIR="/tmp/musclemap-growth-audit"

usage() {
  cat <<'USAGE'
Usage:
  sim_capture.sh init [run-id]
  sim_capture.sh shot <label>
  sim_capture.sh launch

Before "shot" or "launch", source the env file printed by init:
  source /tmp/musclemap-growth-audit/<run-id>/env.sh

This script prepares and captures the simulator. UI tapping/swiping is done by the
iOS Simulator MCP or computer-use tool.
USAGE
}

run_id() {
  date "+%Y%m%d-%H%M%S"
}

require_env() {
  : "${MM_GROWTH_UDID:?MM_GROWTH_UDID is missing. Source the run env.sh first.}"
  : "${MM_GROWTH_RUN_DIR:?MM_GROWTH_RUN_DIR is missing. Source the run env.sh first.}"
}

cmd="${1:-}"
case "$cmd" in
  init)
    RUN_ID="${2:-$(run_id)}"
    RUN_DIR="$ROOT_DIR/$RUN_ID"
    DERIVED_DATA="/tmp/mm-growth-audit-$RUN_ID"
    mkdir -p "$RUN_DIR/screenshots"

    UDID="$(xcrun simctl create "MuscleMap-Growth-Audit-$RUN_ID" "$DEVICE_TYPE")"
    xcrun simctl boot "$UDID" || true
    open -a Simulator --args -CurrentDeviceUDID "$UDID" || open -a Simulator || true

    cd "$PROJECT_DIR"
    xcodebuild \
      -project MuscleMap.xcodeproj \
      -scheme MuscleMap \
      -destination "id=$UDID" \
      -derivedDataPath "$DERIVED_DATA" \
      build

    xcrun simctl install "$UDID" "$DERIVED_DATA/Build/Products/Debug-iphonesimulator/MuscleMap.app"
    xcrun simctl launch "$UDID" "$APP_BUNDLE_ID"
    sleep 3

    cat > "$RUN_DIR/env.sh" <<ENV
export MM_GROWTH_RUN_ID="$RUN_ID"
export MM_GROWTH_RUN_DIR="$RUN_DIR"
export MM_GROWTH_UDID="$UDID"
export MM_GROWTH_APP_BUNDLE_ID="$APP_BUNDLE_ID"
ENV

    echo "RUN_DIR=$RUN_DIR"
    echo "UDID=$UDID"
    echo "APP_BUNDLE_ID=$APP_BUNDLE_ID"
    echo "ENV=$RUN_DIR/env.sh"
    export MM_GROWTH_RUN_ID="$RUN_ID"
    export MM_GROWTH_RUN_DIR="$RUN_DIR"
    export MM_GROWTH_UDID="$UDID"
    export MM_GROWTH_APP_BUNDLE_ID="$APP_BUNDLE_ID"
    "$0" shot 00_launch
    ;;

  launch)
    require_env
    xcrun simctl terminate "$MM_GROWTH_UDID" "$APP_BUNDLE_ID" || true
    sleep 1
    xcrun simctl launch "$MM_GROWTH_UDID" "$APP_BUNDLE_ID"
    sleep 3
    ;;

  shot)
    require_env
    LABEL="${2:-}"
    if [[ -z "$LABEL" ]]; then
      usage
      exit 2
    fi
    RAW="$MM_GROWTH_RUN_DIR/screenshots/${LABEL}_raw.png"
    SMALL="$MM_GROWTH_RUN_DIR/screenshots/${LABEL}_small.png"
    xcrun simctl io "$MM_GROWTH_UDID" screenshot "$RAW"
    sips -Z 800 "$RAW" --out "$SMALL" >/dev/null
    echo "RAW=$RAW"
    echo "SMALL=$SMALL"
    ;;

  *)
    usage
    exit 2
    ;;
esac
