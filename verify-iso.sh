#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/image.iso" >&2
  exit 2
fi

ISO_PATH="$(realpath "$1")"
CHECKSUM_PATH="$ISO_PATH.sha256"

for command_name in awk grep realpath sha256sum unsquashfs xorriso; do
  command -v "$command_name" >/dev/null 2>&1 || {
    echo "ERROR: required verification command is unavailable: $command_name" >&2
    exit 1
  }
done

[[ -f "$ISO_PATH" ]] || { echo "ERROR: ISO not found: $ISO_PATH" >&2; exit 1; }
[[ -f "$CHECKSUM_PATH" ]] || {
  echo "ERROR: checksum not found: $CHECKSUM_PATH" >&2
  exit 1
}

expected_hash="$(awk 'NR == 1 { print $1 }' "$CHECKSUM_PATH")"
actual_hash="$(sha256sum "$ISO_PATH" | awk '{ print $1 }')"
[[ -n "$expected_hash" && "$actual_hash" == "$expected_hash" ]] || {
  echo "ERROR: ISO checksum mismatch" >&2
  exit 1
}

boot_report="$(xorriso -indev "$ISO_PATH" -report_el_torito plain 2>&1)"
grep -Eq 'El Torito boot img.*BIOS.*y' <<<"$boot_report" || {
  echo "ERROR: bootable BIOS image not found in ISO" >&2
  exit 1
}
grep -Eq 'El Torito boot img.*UEFI.*y' <<<"$boot_report" || {
  echo "ERROR: bootable UEFI image not found in ISO" >&2
  exit 1
}

inspect_dir="$(mktemp -d /tmp/nixos-iso-verify.XXXXXX)"
squashfs_path="$inspect_dir/nix-store.squashfs"
cleanup() {
  if [[ "$inspect_dir" == /tmp/nixos-iso-verify.* ]]; then
    rm -f -- "$squashfs_path"
    rmdir -- "$inspect_dir" 2>/dev/null || true
  fi
}
trap cleanup EXIT

xorriso -osirrox on -indev "$ISO_PATH" \
  -extract /nix-store.squashfs "$squashfs_path" \
  >/dev/null 2>&1

matches="$(unsquashfs -ll "$squashfs_path" 2>/dev/null | awk '
  $1 ~ /^d/ && $NF ~ /-offline-nixpkgs$/ {
    print "DIR " $NF
  }
  $1 ~ /^l/ && $(NF - 2) ~ /\/etc\/nixpkgs$/ && $(NF - 1) == "->" && $NF ~ /-offline-nixpkgs$/ {
    print "LINK " $NF
  }
')"

embedded_path="$(awk '$1 == "DIR" { print $2; exit }' <<<"$matches")"
link_target="$(awk '$1 == "LINK" { print $2; exit }' <<<"$matches")"
expected_target="/nix/store/${embedded_path#squashfs-root/}"

[[ -n "$embedded_path" && -n "$link_target" && "$link_target" == "$expected_target" ]] || {
  echo "ERROR: /etc/nixpkgs does not resolve to an embedded offline-nixpkgs store path" >&2
  printf '%s\n' "$matches" >&2
  exit 1
}

echo "Completed-image validation passed"
echo "  checksum: $actual_hash"
echo "  boot: BIOS + UEFI"
echo "  nixpkgs: $link_target"
