{ config, pkgs, lib, modulesPath, ... }:
let
  brand = builtins.fromJSON (builtins.readFile ./branding/branding.json);
in
{
  nixpkgs.config.allowUnfree = true;
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-calamares.nix"
    ./modules/cinnamon-desktop.nix
    ./modules/default-user.nix
    ./modules/live-installer.nix
    ./modules/offline-installer.nix
    ./modules/testing-branding.nix
    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  _module.args.edition = "Bare";
  _module.args.installedProfile = ./config-templates/installed-bare.nix;
  _module.args.installedModuleFiles = [ ];

  image.fileName = lib.mkForce "${brand.id}-bare-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
  boot.zfs.forceImportRoot = false;

  # Default squashfs compression (xz) is by far the most memory- and
  # CPU-hungry step in this pipeline — it's what was stalling low-RAM WSL2
  # VMs during the mksquashfs/xorriso step. gzip trades a somewhat larger
  # ISO for dramatically lower peak memory use during the build.
  isoImage.squashfsCompression = "gzip -Xcompression-level 6";

  # This edition is intentionally reduced to "Cinnamon desktop + networking".
  # No printing (cups/sane), no browser, no office/dev/media stack — those
  # belong to Stage 2 (nixos-rebuild after first boot, once online), per the
  # Stage 1/Stage 2 split in PRD.md section 12.
  environment.systemPackages = with pkgs; [
    # Core utilities needed to operate the live session and installer
    vim
    nano
    wget
    curl
    coreutils
    bash
    dos2unix

    # Required by Calamares' manual partitioning step
    gparted
    ntfs3g

    # Networking (NetworkManager itself + applet come from cinnamon-desktop.nix)
    iw
    wirelesstools

    # Quick hardware/system sanity check on first boot
    fastfetch
  ];

  # Keep the offline guarantee: no substituters, no fallback to network
  # during install. (Inherited from offline-installer.nix, shared by every
  # edition — no change needed here.)

  # No cups/sane here on purpose. If a specific machine needs printing before
  # it ever goes online, add hardware.sane / services.printing to
  # config-templates/installed-bare.nix instead of to this live image.

  # The root account remains locked; live administration goes through the
  # passwordless wheel policy in modules/default-user.nix.
}
