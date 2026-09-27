# Testing NixOS Live Images

This directory builds three NixOS 26.05 Cinnamon live images:

* **Testing Bare** — Cinnamon, networking, partitioning and core live/installer utilities.
* **Testing Minimal** — graphical live environment, Calamares installer, GParted, browser and core utilities.
* **Testing Full** — the same live/installer foundation plus the workstation package and service modules.

Both configurations use the NixOS-aware Calamares integration rather than the generic Calamares package. They include a live-only `nixos` user, Cinnamon automatic login, passwordless live administration, Polkit installer elevation, and an **Install Testing** desktop shortcut.

## Offline installation guarantee

Both editions are configured for installation with networking disconnected:

* Calamares does not check for or require internet connectivity.
* The installer offers the supported **Cinnamon desktop** and **Basic system** targets only.
* Complete BIOS and UEFI Cinnamon target closures are retained in each ISO; the Basic target is a subset of those closures.
* The privileged `nixos-install` process receives the exact pinned nixpkgs source path embedded in the ISO; it does not depend on a root channel being initialized first.
* Calamares runs with an empty Nix substituter list. It may assemble the machine-specific system locally, but cannot obtain packages from a binary cache.
* Offline restrictions apply only to Calamares. The live desktop keeps normal networking and Nix binary-cache access when the user chooses to connect.
* The selected edition profile is copied to `/etc/nixos/offline-profile.nix`. Full also copies its referenced modules to `/etc/modules`, so later `nixos-rebuild` evaluations remain valid.

The embedded target closures increase image size. Do not remove `modules/offline-installer.nix` or replace it with only `channel.nix`: a channel contains Nix expressions, not the complete package closure needed for an offline installation.

## Build from WSL

Run from this directory inside WSL:

```bash
./build-iso-minimal.sh
./build-iso-full.sh
```

Or use the common entry point:

```bash
./build-iso.sh minimal
./build-iso.sh full
```

The build scripts:

1. Run the edition preflight checks described below.
2. Evaluate the selected ISO against the pinned `nixos-26.05` revision.
3. Build without creating a Nix result symlink on the Windows-mounted filesystem.
4. Copy through an `*.partial` file and atomically rename the completed image.
5. Place the ISO directly in this directory.
6. Create a matching `.sha256` file.
7. Save timestamped output under `build-logs/`.

This avoids the DrvFs permission failures caused by read-only store outputs and unsupported Nix result symlinks.

## Pre-build validation

Every `build-iso.sh bare|minimal|full` invocation now runs a fast evaluation
gate before starting the expensive build. It verifies:

* the ISO and every live-system package derivation evaluate;
* Cinnamon, LightDM and live-user automatic login;
* NetworkManager, its tray applet, live-user permissions and firmware;
* NetworkManager and firmware in the copied post-install edition profile;
* the absence of a conflicting standalone wireless service;
* the pinned `/etc/nixpkgs` installer source and retained target closures;
* the Calamares offline launcher while preserving optional live internet use;
* the optional installed-system service modules and project shell syntax.

Run it independently at any time:

```bash
bash ./test-project.sh bare
bash ./test-project.sh all
```

To exercise the exact pre-build path, including pin and logging setup, without
starting the ISO build:

```bash
PREFLIGHT_ONLY=1 ./build-iso.sh bare
```

This gate proves evaluation and configuration invariants; it cannot prove that
a particular physical Wi-Fi chipset works or that a BIOS/UEFI installation
boots. Those remain VM and hardware tests after the ISO has been built.

## Verified build from 2026-09-25 UTC

| Edition | Artifact | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| Minimal | `testing-minimal-26.05-20260925-x86_64.iso` | 3,288,973,312 | `0c2b51e963ee9035827715ae12f025833504ebb0d876646a4e0a1bc2aebbd5cc` |
| Full | `testing-full-26.05-20260925-x86_64.iso` | 7,988,520,960 | `383ed21d4830cb774664d190c5da5d9c07b59cdf2aff09735cd3463c1a35155e` |

Both checksum files were independently checked with `sha256sum -c`. Both files are recognized as bootable ISO 9660 images with DOS/MBR boot sectors. This confirms successful image construction, not graphical boot or installation behavior.

## Validation still required

Before release, test each image in a disposable VM with networking disconnected:

1. Boot in UEFI mode and reach the branded Cinnamon desktop automatically.
2. Confirm wallpaper/theme and the **Install Testing** shortcut.
3. Launch Calamares and GParted from the live user.
4. Disable the VM network adapter before launching Calamares.
5. Complete both **Basic system** and **Cinnamon desktop** installations to an empty virtual disk without networking.
6. Reboot from the virtual disk and verify the intended installed profile.
7. Repeat the boot test in legacy BIOS mode.

The Full build currently includes both VS Code and VSCodium. Nix completes the image but reports many file collisions between them. Choose one editor when the package profiles are split.

The first-boot package selector and installed-system Stage 2 workflow described in `PRD.md` are product requirements and are not yet implemented by these live-image configurations.

## Automatic `nix-shell` build

Running `nix-shell` in this directory builds Minimal first and Full second by calling the same logged build scripts above. Set `TESTING_SKIP_AUTO_BUILD=1` when opening a maintenance shell without building images.

## Branding configuration

Edit `branding/branding.json` to change the product ID/name, tagline, wallpaper, logo, installer icon, colors, GTK theme or icon theme. Asset paths are relative to `branding/`. Both ISO definitions and the shared desktop/installer modules read this file.

## Installed-service templates

`modules/cloudflare.nix`, `modules/caddy.nix` and `modules/zfspool.nix` are opt-in installed-system modules; they are not imported into the public live images.

* Copy the Cloudflare token example to `/etc/testing/secrets/cloudflare-tunnel-token`, replace its contents, set ownership to `cloudflared:cloudflared`, and mode to `0400` before enabling `testing.services.cloudflareTunnel`.
* Override `testing.services.caddy.configuration` with the desired sanitized Caddy configuration before enabling it.
* Set a unique `testing.zfs.hostId` and explicit `testing.zfs.poolName` before enabling ZFS pool management.

Real tokens, credentials, domains, node addresses and private routing topology must not be committed.
