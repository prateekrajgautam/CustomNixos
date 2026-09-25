#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  echo "Usage: $0 minimal|full" >&2
  exit 2
}

[[ $# -eq 1 ]] || usage
EDITION="${1,,}"
case "$EDITION" in
  minimal|full) ;;
  *) usage ;;
esac

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/iso-$EDITION.nix"
BRANDING_JSON="$SCRIPT_DIR/branding/branding.json"
BRAND_ID="$(nix-instantiate --eval --json --expr \
  "(builtins.fromJSON (builtins.readFile $BRANDING_JSON)).id" | tr -d '"')"
BRAND_NAME="$(nix-instantiate --eval --json --expr \
  "(builtins.fromJSON (builtins.readFile $BRANDING_JSON)).name" | tr -d '"')"
LOG_DIR="$SCRIPT_DIR/build-logs"
BUILD_DATE="$(date -u +%Y%m%d)"
BUILD_STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_FILE="$LOG_DIR/$BRAND_ID-$EDITION-$BUILD_STAMP.log"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

on_error() {
  status=$?
  echo "[$(date -u +%FT%TZ)] ERROR: $BRAND_NAME $EDITION build failed with status $status"
  echo "Build log: $LOG_FILE"
  exit "$status"
}
trap on_error ERR

echo "[$(date -u +%FT%TZ)] Building $BRAND_NAME ${EDITION^} ISO"
echo "Configuration: $CONFIG"
echo "Output directory: $SCRIPT_DIR"
echo "Log: $LOG_FILE"

RESULT="$(nix-build '<nixpkgs/nixos>' \
  -A config.system.build.isoImage \
  -I "nixos-config=$CONFIG" \
  -I nixpkgs=channel:nixos-26.05 \
  --no-out-link)"

ISO_PATH="$(find "$RESULT" -type f -name '*.iso' -print -quit)"
if [[ -z "$ISO_PATH" ]]; then
  echo "ERROR: no ISO was produced under $RESULT" >&2
  exit 1
fi

ISO_NAME="$BRAND_ID-$EDITION-26.05-$BUILD_DATE-x86_64.iso"
DESTINATION="$SCRIPT_DIR/$ISO_NAME"
TEMP_DESTINATION="$DESTINATION.partial"

# Store outputs are read-only. Removing the destination first and copying via
# a temporary file avoids the overwrite/permission failure seen on DrvFs.
rm -f "$TEMP_DESTINATION"
cp --no-preserve=mode,ownership,timestamps "$ISO_PATH" "$TEMP_DESTINATION"
chmod u+rw,go+r "$TEMP_DESTINATION" 2>/dev/null || true
mv -f "$TEMP_DESTINATION" "$DESTINATION"

sha256sum "$DESTINATION" > "$DESTINATION.sha256"

echo "[$(date -u +%FT%TZ)] Build complete"
echo "ISO: $DESTINATION"
echo "Size: $(du -h "$DESTINATION" | cut -f1)"
echo "SHA256: $(cut -d' ' -f1 "$DESTINATION.sha256")"
echo "Build log: $LOG_FILE"
