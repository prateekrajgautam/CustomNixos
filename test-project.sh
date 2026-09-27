#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash coreutils gnugrep gnused nix
set -Eeuo pipefail

usage() {
  echo "Usage: $0 bare|minimal|full|all" >&2
  exit 2
}

[[ $# -eq 1 ]] || usage
REQUESTED_EDITION="${1,,}"
case "$REQUESTED_EDITION" in
  bare|minimal|full) EDITIONS=("$REQUESTED_EDITION") ;;
  all) EDITIONS=(bare minimal full) ;;
  *) usage ;;
esac

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PIN_FILE="$SCRIPT_DIR/nixpkgs-pin.json"

for command_name in nix nix-instantiate grep sed; do
  command -v "$command_name" >/dev/null 2>&1 || {
    echo "ERROR: required command is unavailable: $command_name" >&2
    exit 1
  }
done

[[ -s "$PIN_FILE" ]] || {
  echo "ERROR: $PIN_FILE is missing or empty; run build-iso.sh once to create it." >&2
  exit 1
}

NIXPKGS_PATH="${NIXPKGS_PATH_OVERRIDE:-}"
if [[ -z "$NIXPKGS_PATH" ]]; then
  NIXPKGS_PATH="$(nix-instantiate --eval --json -E '
    let pin = builtins.fromJSON (builtins.readFile "'"$PIN_FILE"'");
    in builtins.fetchTarball { url = pin.url; sha256 = pin.sha256; }
  ' | sed -e 's/^"//' -e 's/"$//')"
fi

[[ -f "$NIXPKGS_PATH/nixos/lib/eval-config.nix" ]] || {
  echo "ERROR: pinned nixpkgs is unavailable at $NIXPKGS_PATH" >&2
  exit 1
}

echo "Running static project checks..."
bash -n "$SCRIPT_DIR/build-iso.sh" \
  "$SCRIPT_DIR/build-iso-bare.sh" \
  "$SCRIPT_DIR/build-iso-minimal.sh" \
  "$SCRIPT_DIR/build-iso-full.sh" \
  "$SCRIPT_DIR/test-project.sh" \
  "$SCRIPT_DIR/verify-iso.sh"

nix-instantiate --eval --strict --json --expr \
  "builtins.fromJSON (builtins.readFile $SCRIPT_DIR/branding/branding.json)" \
  >/dev/null

echo "Evaluating optional installed-system service modules..."
nix-instantiate "$SCRIPT_DIR/tests/module-eval.nix" \
  -I "nixpkgs=$NIXPKGS_PATH" \
  --no-gc-warning \
  >/dev/null

for edition in "${EDITIONS[@]}"; do
  config="$SCRIPT_DIR/iso-$edition.nix"
  echo "Evaluating ${edition^} ISO, installer, networking, firmware and packages..."
  result="$(nix-instantiate --eval --strict --json \
    "$SCRIPT_DIR/tests/iso-eval.nix" \
    --argstr nixpkgs "$NIXPKGS_PATH" \
    --arg configuration "$config" \
    --argstr edition "$edition" \
    -I "nixpkgs=$NIXPKGS_PATH")"
  echo "$result"

  profile="$SCRIPT_DIR/config-templates/installed-$edition.nix"
  echo "Evaluating ${edition^} installed-system profile and post-install networking..."
  result="$(nix-instantiate --eval --strict --json \
    "$SCRIPT_DIR/tests/installed-profile-eval.nix" \
    --argstr nixpkgs "$NIXPKGS_PATH" \
    --arg profile "$profile" \
    --argstr edition "$edition" \
    -I "nixpkgs=$NIXPKGS_PATH")"
  echo "$result"
done

echo "Preflight passed for: ${EDITIONS[*]}"
