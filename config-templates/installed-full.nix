{ ... }:
{
  nixpkgs.config.allowUnfree = true;
  networking.networkmanager.enable = true;
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  programs.nm-applet.enable = true;
  imports = [
    ../modules/defaultapp.nix
    ../modules/docker.nix
    ../modules/pythonPackages.nix
    ../modules/sane-extra-config.nix
    ../modules/systemPackagesforiso.nix
  ];
}
