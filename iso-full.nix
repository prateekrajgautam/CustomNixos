{ config, pkgs, lib, modulesPath, ... }:
let
  brand = builtins.fromJSON (builtins.readFile ./branding/branding.json);
in
{
  nixpkgs.config.allowUnfree = true;
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-calamares.nix"
    ./modules/cinnamon-desktop.nix
    ./modules/live-installer.nix
    ./modules/offline-installer.nix
    ./modules/testing-branding.nix
    ./modules/defaultapp.nix
    ./modules/docker.nix
    ./modules/pythonPackages.nix
    ./modules/sane-extra-config.nix
    ./modules/systemPackagesforiso.nix
    ./modules/default-user.nix
    # Host-specific services that require secrets belong in an installed
    # profile, never in public live media.
    # ./modules/cloudflare.nix
    # Caddy and Cloudflare are opt-in installed-system services. Import their
    # modules in the installed profile, not in public live media.
    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];
  _module.args.edition = "Full";
  _module.args.installedProfile = ./config-templates/installed-full.nix;
  _module.args.installedModuleFiles = [
    ./modules/defaultapp.nix
    ./modules/docker.nix
    ./modules/pythonPackages.nix
    ./modules/sane-extra-config.nix
    ./modules/systemPackagesforiso.nix
  ];
  image.fileName = lib.mkForce "${brand.id}-full-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
  boot.zfs.forceImportRoot = false;
  environment.systemPackages = [ pkgs.neovim ];
}
