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
    ./modules/sane-extra-config.nix
    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  _module.args.edition = "Minimal";
  _module.args.installedProfile = ./config-templates/installed-minimal.nix;
  _module.args.installedModuleFiles = [ ];

  image.fileName = lib.mkForce "${brand.id}-minimal-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
  boot.zfs.forceImportRoot = false;

  environment.systemPackages = with pkgs; [
    # Core system utilities
    vim
    nano
    wget
    curl
    git
    htop
    tmux
    unzip
    zip
    p7zip
    gnutar
    coreutils
    bash
    dos2unix

    # File systems
    gparted
    ntfs3g
    dos2unix

    # Networking
    networkmanager
    openssh
    openssl

    # Browsers (one lightweight option)
    firefox

    # Text editors
    neovim

    # System info
    fastfetch
    lshw

    # Printing/scanning support
    cups
    sane-backends
  ];

  # Enable CUPS for printing
  services.printing.enable = true;

  # Enable SANE for scanning
  hardware.sane.enable = true;

  # Enable SSH for remote access during install
  services.openssh.enable = true;

  # The root account remains locked; live administration goes through the
  # passwordless wheel policy in the live-user module.
}
