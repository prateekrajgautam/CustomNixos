{ config, pkgs, lib, ... }:

let 
  token = builtins.readFile /etc/.cloudflared/token;
in
{
  config = {
    environment.systemPackages = [ pkgs.cloudflared ];

    users.users.cloudflared = {
      group = "cloudflared";
      isSystemUser = true;
    };
    users.groups.cloudflared = { };  

    systemd.services.cloudflared-tunnel = {
      description = "Cloudflared Tunnel";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "systemd-resolved.service" ];

      serviceConfig = {
        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token ${token}";
        Restart = "always";
        User = "cloudflared";
        Group = "cloudflared";
      };
    };
  };
}
