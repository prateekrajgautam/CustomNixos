{ ... }:
{
  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;
  programs.nm-applet.enable = true;
  imports = [
    ../modules/defaultapp.nix
    ../modules/docker.nix
    ../modules/pythonPackages.nix
    ../modules/sane-extra-config.nix
    ../modules/systemPackagesforiso.nix
  ];
}
