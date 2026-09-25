{ config, pkgs, lib, ... }:

let
  tunnelId = "9b5ee2cf-d0bc-4618-9899-720d8de43533";
  # 9b5ee2cf-d0bc-4618-9899-720d8de43533.cfargotunnel.com
in
{
  ############################################################
  # Packages
  ############################################################

  environment.systemPackages = with pkgs; [
    cloudflared
  ];

  ############################################################
  # Cloudflared user/group
  ############################################################

  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
    description = "Cloudflared Tunnel User";
  };

  users.groups.cloudflared = { };

  ############################################################
  # Tunnel credentials + config
  ############################################################

  environment.etc."cloudflared/${tunnelId}.json".source =
    /etc/.cloudflared/${tunnelId}.json;

  environment.etc."cloudflared/config.yml".text = ''
    tunnel: ${tunnelId}
    credentials-file: /etc/cloudflared/${tunnelId}.json

    ingress:
      - hostname: npm.mgeek.in
        service: http://127.0.0.1:81

      - hostname: ssh.mgeek.in
        service: ssh://127.0.0.1:22

      - service: http_status:404
  '';

  ############################################################
  # Cloudflared tunnel service
  ############################################################

  systemd.services.cloudflared-tunnel = {
    description = "Cloudflare Tunnel";

    wantedBy = [ "multi-user.target" ];

    after = [
      "network-online.target"
    ];

    wants = [
      "network-online.target"
    ];

    serviceConfig = {
      Type = "simple";

      ExecStart =
        "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate --config /etc/cloudflared/config.yml run ${tunnelId}";

      Restart = "always";
      RestartSec = "5s";

      User = "cloudflared";
      Group = "cloudflared";

      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];

      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
    };
  };

  ############################################################
  # Firewall
  ############################################################

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
