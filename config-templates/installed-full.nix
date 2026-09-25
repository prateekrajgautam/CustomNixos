{ ... }:
{
  nixpkgs.config.allowUnfree = true;
  imports = [
    ../modules/defaultapp.nix
    ../modules/docker.nix
    ../modules/pythonPackages.nix
    ../modules/sane-extra-config.nix
    ../modules/systemPackagesforiso.nix
  ];
}
