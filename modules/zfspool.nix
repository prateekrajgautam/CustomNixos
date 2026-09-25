{ config, lib, ... }:

let
  cfg = config.testing.zfs;
in
{
  options.testing.zfs = {
    enable = lib.mkEnableOption "support for an explicitly named ZFS data pool";
    hostId = lib.mkOption {
      type = lib.types.nullOr (lib.types.strMatching "[0-9a-fA-F]{8}");
      default = null;
      example = "0123abcd";
      description = "Unique eight-digit hexadecimal host ID, generated per installed machine.";
    };
    poolName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "tank";
      description = "Existing ZFS data pool to import, scrub and trim.";
    };
    forceImportRoot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Force-import a ZFS root pool only when explicitly required.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.hostId != null;
        message = "testing.zfs.hostId must be a unique eight-digit hexadecimal value.";
      }
      {
        assertion = cfg.poolName != null && cfg.poolName != "";
        message = "testing.zfs.poolName must name the ZFS data pool to manage.";
      }
    ];
    networking.hostId = cfg.hostId;
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs = {
      forceImportAll = false;
      forceImportRoot = cfg.forceImportRoot;
      extraPools = [ cfg.poolName ];
    };
    services.zfs = {
      autoScrub = {
        enable = true;
        pools = [ cfg.poolName ];
      };
      trim.enable = true;
    };
  };
}
