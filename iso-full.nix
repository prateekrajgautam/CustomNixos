{ config, pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    ./modules/cinnamon-desktop.nix
    ./modules/defaultapp.nix
    ./modules/docker.nix
    ./modules/pythonPackages.nix
    ./modules/sane-extra-config.nix
    ./modules/systemPackagesforiso.nix
    ./modules/default-user.nix
    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];
  environment.systemPackages = [ pkgs.neovim ];
}
