{ config, lib, pkgs, ... }:

let
  dataDir = "/var/lib/rustdesk";
in {
  options.services.rustdesk = {
    enable = lib.mkEnableOption "RustDesk server";

    hbbs = {
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "-r" "127.0.0.1:21117" ];
        description = "Extra arguments for hbbs";
      };
    };

    hbbr.extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra arguments for hbbr";
    };
  };

  config = lib.mkIf config.services.rustdesk.enable {
    systemd.services.hbbs = {
      description = "RustDesk ID Server (hbbs)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.rustdesk-server}/bin/hbbs ${lib.concatStringsSep " " config.services.rustdesk.hbbs.extraArgs}";
        WorkingDirectory = dataDir;
        Restart = "always";
        User = "rustdesk";
        Group = "rustdesk";
      };
    };

    systemd.services.hbbr = {
      description = "RustDesk Relay Server (hbbr)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.rustdesk-server}/bin/hbbr ${lib.concatStringsSep " " config.services.rustdesk.hbbr.extraArgs}";
        WorkingDirectory = dataDir;
        Restart = "always";
        User = "rustdesk";
        Group = "rustdesk";
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 21115 21116 21117 21118 21119 ];
      allowedUDPPorts = [ 21116 ];
    };

    users.users.rustdesk = {
      isSystemUser = true;
      group = "rustdesk";
      home = dataDir;
      createHome = true;
    };

    users.groups.rustdesk = {};

    environment.systemPackages = [ pkgs.rustdesk-server ];
  };
}
