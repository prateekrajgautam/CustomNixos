{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    qemu_full
    nemu
  ];

  # Optional: enable KVM support if needed
  virtualisation.libvirtd.enable = true;

  # Add user to 'libvirtd' group if you want them to manage VMs without sudo
  users.users.prateek.extraGroups = [ "libvirtd" ];
}

