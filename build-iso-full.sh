#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/CustomNixOS"
mkdir -p "$OUTPUT_DIR"

echo "=== Building Full NixOS ISO (26.05) ==="

RESULT=$(nix-build '<nixpkgs/nixos>' \
  -A config.system.build.isoImage \
  -I nixos-config=iso-full.nix \
  -I nixpkgs=channel:nixos-26.05)

ISO_PATH=$(find "$RESULT" -name "nixos-*.iso" -type f | head -1)
if [ -z "$ISO_PATH" ]; then
  echo "ERROR: ISO not found"; exit 1
fi

ISO_NAME="nixos-full-26.05-$(date +%Y%m%d).iso"
cp "$ISO_PATH" "$OUTPUT_DIR/$ISO_NAME"
echo "ISO: $OUTPUT_DIR/$ISO_NAME ($(du -h "$OUTPUT_DIR/$ISO_NAME" | cut -f1))"
