#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash coreutils curl gnused libisoburn squashfsTools
#
# Runs the same way on NixOS or on Ubuntu/WSL: the two lines above are a
# nix-shell shebang, so the kernel launches this file through `nix-shell -i
# bash -p ...` instead of a plain shell. That gives the script its own
# curl/sed/coreutils regardless of what the host distro happens to have
# installed — the only real prerequisite is Nix itself (nix-build,
# nix-instantiate, nix-prefetch-url), which must already be on PATH for
# nix-shell to have been invoked in the first place.
set -Eeuo pipefail

usage() {
  echo "Usage: $0 minimal|full|bare" >&2
  echo "       REPIN=1 $0 minimal|full|bare   # force re-pin nixpkgs first" >&2
  exit 2
}

check_deps() {
  local missing=()
  for cmd in nix-build nix-instantiate nix-prefetch-url curl sed xorriso unsquashfs; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if (( ${#missing[@]} )); then
    echo "ERROR: missing required tools: ${missing[*]}" >&2
    echo "       Install Nix (https://nixos.org/download) and re-run, or run" >&2
    echo "       this script under 'nix-shell -p nix curl gnused libisoburn squashfsTools' yourself." >&2
    exit 1
  fi
}

[[ $# -eq 1 ]] || usage
EDITION="${1,,}"
case "$EDITION" in
  minimal|full|bare) ;;
  *) usage ;;
esac

check_deps

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/iso-$EDITION.nix"
BRANDING_JSON="$SCRIPT_DIR/branding/branding.json"
PIN_FILE="$SCRIPT_DIR/nixpkgs-pin.json"
NIXOS_CHANNEL="nixos-26.05"

LOG_DIR="$SCRIPT_DIR/build-logs"
BUILD_DATE="$(date -u +%Y%m%d)"
BUILD_STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$LOG_DIR"

# --- Preflight: pin nixpkgs to one exact revision ---------------------------
#
# The previous script used `-I nixpkgs=channel:nixos-26.05`, which resolves
# to whatever nixexprs.tar.xz nixos.org is currently serving for that
# rolling channel — a different snapshot on a different day. Every part of
# the offline guarantee (system.extraDependencies' pre-built closures, the
# embedded channel copied onto the ISO, and whatever nixos-install evaluates
# at real install time) needs to be built from the *same* nixpkgs revision,
# or their derivations don't match and paths that should already be cached
# aren't. Pinning to one fetched, hash-verified revision, reused on every
# build until you explicitly ask to re-pin, removes that variable entirely.
# This also makes the pin independent of any nix-channel state on the host,
# so it behaves the same on a fresh Ubuntu box as on NixOS.
if [[ "${REPIN:-0}" == "1" ]]; then
  rm -f "$PIN_FILE"
fi

if [[ ! -f "$PIN_FILE" ]]; then
  echo "No nixpkgs-pin.json found — pinning $NIXOS_CHANNEL now (one-time; delete"
  echo "the file, or run with REPIN=1, to re-pin to whatever's current later)."
  PIN_REV="$(curl -fsSL "https://channels.nixos.org/${NIXOS_CHANNEL}/git-revision")"
  [[ -n "$PIN_REV" ]] || { echo "ERROR: could not fetch the current $NIXOS_CHANNEL revision" >&2; exit 1; }
  PIN_URL="https://github.com/NixOS/nixpkgs/archive/${PIN_REV}.tar.gz"
  PIN_SHA256="$(nix-prefetch-url --unpack "$PIN_URL")"
  cat > "$PIN_FILE" <<JSON
{
  "channel": "$NIXOS_CHANNEL",
  "rev": "$PIN_REV",
  "url": "$PIN_URL",
  "sha256": "$PIN_SHA256"
}
JSON
  echo "Pinned $NIXOS_CHANNEL @ $PIN_REV"
fi

NIXPKGS_PATH="$(nix-instantiate --eval --json -E '
  let pin = builtins.fromJSON (builtins.readFile "'"$PIN_FILE"'");
  in builtins.fetchTarball { url = pin.url; sha256 = pin.sha256; }
' | sed -e 's/^"//' -e 's/"$//')"
PIN_REV_USED="$(nix-instantiate --eval --json -E \
  '(builtins.fromJSON (builtins.readFile "'"$PIN_FILE"'")).rev' | tr -d '"')"

BRAND_ID="$(nix-instantiate --eval --json --expr \
  "(builtins.fromJSON (builtins.readFile $BRANDING_JSON)).id" | tr -d '"')"
BRAND_NAME="$(nix-instantiate --eval --json --expr \
  "(builtins.fromJSON (builtins.readFile $BRANDING_JSON)).name" | tr -d '"')"
LOG_FILE="$LOG_DIR/$BRAND_ID-$EDITION-$BUILD_STAMP.log"

exec > >(tee -a "$LOG_FILE") 2>&1

on_error() {
  status=$?
  echo "[$(date -u +%FT%TZ)] ERROR: $BRAND_NAME $EDITION build failed with status $status"
  echo "Build log: $LOG_FILE"
  exit "$status"
}
trap on_error ERR

echo "[$(date -u +%FT%TZ)] Building $BRAND_NAME ${EDITION^} ISO"
echo "Host:              $(uname -s) ($( [[ -f /etc/NIXOS ]] && echo NixOS || echo "non-NixOS, e.g. Ubuntu/WSL" ))"
echo "Nix version:       $(nix --version 2>/dev/null || echo unknown)"
echo "nixpkgs revision:  $PIN_REV_USED  ($NIXOS_CHANNEL, pinned in nixpkgs-pin.json)"
echo "nixpkgs path:      $NIXPKGS_PATH"
echo "Configuration:     $CONFIG"
echo "Output directory:  $SCRIPT_DIR"
echo "Log:               $LOG_FILE"

# Tunable, not hardcoded — override with e.g. NIX_CORES=1 NIX_MAX_JOBS=1 on a
# very RAM-constrained machine (WSL2 especially: see .wslconfig memory/swap).
NIX_CORES="${NIX_CORES:-2}"
NIX_MAX_JOBS="${NIX_MAX_JOBS:-2}"
echo "cores/max-jobs:    $NIX_CORES / $NIX_MAX_JOBS"

# Fail quickly before the expensive ISO build if the selected edition has a
# broken module option, package, installer path, firmware or networking setup.
# This evaluates derivations but does not build their outputs.
echo "Running pre-build validation..."
NIXPKGS_PATH_OVERRIDE="$NIXPKGS_PATH" \
  bash "$SCRIPT_DIR/test-project.sh" "$EDITION"

if [[ "${PREFLIGHT_ONLY:-0}" == "1" ]]; then
  echo "Preflight-only mode requested; ISO build skipped."
  exit 0
fi

RESULT="$(nix-build "$NIXPKGS_PATH/nixos" \
  -A config.system.build.isoImage \
  -I "nixos-config=$CONFIG" \
  -I "nixpkgs=$NIXPKGS_PATH" \
  --cores "$NIX_CORES" \
  --max-jobs "$NIX_MAX_JOBS" \
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

echo "Running completed-image validation..."
bash "$SCRIPT_DIR/verify-iso.sh" "$DESTINATION"

echo "[$(date -u +%FT%TZ)] Build complete"
echo "ISO: $DESTINATION"
echo "Size: $(du -h "$DESTINATION" | cut -f1)"
echo "SHA256: $(cut -d' ' -f1 "$DESTINATION.sha256")"
echo "nixpkgs revision used: $PIN_REV_USED"
echo "Build log: $LOG_FILE"
