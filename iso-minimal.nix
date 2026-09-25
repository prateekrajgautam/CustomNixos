{ config, pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    ./modules/cinnamon-desktop.nix
    ./modules/default-user.nix
    ./modules/sane-extra-config.nix
    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

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

  # Set root password for installer
  users.users.root.initialPassword = "nixos";
}
