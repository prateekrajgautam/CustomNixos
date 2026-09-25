{ config, pkgs, lib, ... }:

{
  networking.hostId = "89ABCDEF";  # Must be unique 8-char hex string
    boot = {
    supportedFilesystems = [ "zfs" ];
    zfs = {
      forceImportAll = false;  # Prefer explicit import
      extraPools = [ "tank" ]; # Explicitly import this pool at boot
    };
  };

  services.zfs = {
    autoScrub.enable = true;
    autoScrub.pools = [ "tank" ];
    trim.enable = true;
  };

#  fileSystems."/zdata" = {
#    device = "tank/data";
#    fsType = "zfs";
#    options = [ "zfsutil" ];
#  };
  
}
