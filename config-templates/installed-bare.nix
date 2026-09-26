{ pkgs, ... }:
{
  # This is the "basic system" the offline install leaves behind. It is
  # intentionally small: Cinnamon + networking + enough to get online and
  # partition/repair a disk. Everything else (printing, browser, office,
  # dev tools) is added later by hand — e.g.
  #
  #   nixos-rebuild switch --flake /etc/nixos#<edition>
  #
  # once the machine has internet, per PRD.md's Stage 1/Stage 2 model.
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    nano
    wget
    curl
    gparted
    ntfs3g
    networkmanager
    openssh
    fastfetch
  ];

  hardware.enableAllFirmware = true;
  programs.nm-applet.enable = true;
  services.openssh.enable = true;
}
