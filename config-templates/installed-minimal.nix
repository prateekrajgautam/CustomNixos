{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    vim nano wget curl git htop tmux unzip zip p7zip gnutar coreutils bash
    dos2unix gparted ntfs3g networkmanager openssh openssl firefox neovim
    fastfetch lshw cups sane-backends
  ];
  services.printing.enable = true;
  hardware.sane.enable = true;
  services.openssh.enable = true;
}

