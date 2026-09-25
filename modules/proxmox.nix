{ config, pkgs, lib, ... }:
let
  sources = import /nix/npins;
  proxmox-nixos = import sources.proxmox-nixos;
in 
{
  imports = [proxmox-nixos.nixosModules.proxmox-ve];

  config = {
    services.proxmox-ve = {
        enable = true;
        ipAddress = "127.0.0.1";
    };
    
    nixpkgs.overlays = [
      proxmox-nixos.overlays.x86_64-linux
    ];

    environment.systemPackages = [ pkgs.npins ];

    # Network configuration
    networking.bridges.vmbr0.interfaces = [ "enp3s0" ];
    networking.interfaces.vmbr0.useDHCP = lib.mkDefault true;

  };
}
