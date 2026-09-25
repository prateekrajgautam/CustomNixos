{ config, pkgs, lib, ... }:
#let 
#	username="prateek";
#in
{

config = {
    #users.users.${username}.extraGroups = [ "docker" ];
    users.users.prateek.extraGroups = [ "virtualbox" ];
    
    
    
    environment.systemPackages = with pkgs; [
        virtualbox
    ];
    
      # Virtualization settings
  virtualisation = {
    virtualbox = {
      host = {
        enable = true;
        enableExtensionPack = true;
      };
    };
  };


};
}
