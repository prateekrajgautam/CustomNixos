{ config, lib, pkgs, ... }:

let
  cfg = config.testing.services.cloudflareTunnel;
in
{
  options.testing.services.cloudflareTunnel = {
    enable = lib.mkEnableOption "the Cloudflare Tunnel installed-system service";
    tokenFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/testing/secrets/cloudflare-tunnel-token";
      description = "Runtime token path; its contents are never copied into the Nix store.";
    };
  };

  config = {
    environment.systemPackages = [ pkgs.cloudflared ];
    environment.etc."testing/examples/cloudflare-tunnel-token.example".source =
      ../config-templates/cloudflare-tunnel-token.example;
    environment.etc."testing/examples/cloudflared-config.yml.example".source =
      ../config-templates/cloudflared-config.yml.example;

    users.users.cloudflared = {
      group = "cloudflared";
      isSystemUser = true;
    };
    users.groups.cloudflared = { };
    systemd.tmpfiles.rules = [ "d /etc/testing/secrets 0750 root cloudflared -" ];

    systemd.services.cloudflared-tunnel = lib.mkIf cfg.enable {
      description = "Cloudflare Tunnel";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      unitConfig.ConditionPathExists = cfg.tokenFile;
      serviceConfig = {
        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file ${cfg.tokenFile}";
        Restart = "on-failure";
        RestartSec = "5s";
        User = "cloudflared";
        Group = "cloudflared";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
      };
    };
  };
}
