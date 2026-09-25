{ config, pkgs, ... }:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nixos = {
    isNormalUser = true;
    description = "NixOS User";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    # password is not set by default, but user can set it via passwd
  };

  users.users.prateek = {
    isNormalUser = true;
    description = "Prateek";
    extraGroups = [ "networkmanager" "wheel" "docker" "audio" "bluetooth" "scanner" "lp" "libvirtd" "virtualbox" ];
  };
  users.groups.prateek = {};
}
