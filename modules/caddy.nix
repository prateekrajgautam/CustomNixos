{ config, pkgs, ... }:

# Standard Caddy — no custom build needed.
# Cloudflared tunnel terminates TLS at Cloudflare's edge.
# Traffic arrives here as plain HTTP on port 80.
# Caddy just routes by hostname — no TLS config required.

{
   environment.systemPackages = [
      pkgs.caddy
   ];

  services.caddy = {
    enable = true;
    configFile = pkgs.writeText "Caddyfile" (builtins.readFile ./Caddyfile);
#    configFile = /etc/nixos/modules/Caddyfile;
#    configFile = ./modules/Caddyfile;
  };
}
