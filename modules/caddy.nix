{ config, lib, pkgs, ... }:

let
  cfg = config.testing.services.caddy;
in
{
  options.testing.services.caddy = {
    enable = lib.mkEnableOption "the Caddy installed-system service";
    configuration = lib.mkOption {
      type = lib.types.lines;
      default = builtins.readFile ../config-templates/Caddyfile.example;
      description = "Caddy configuration. Secrets must use runtime files, not this value.";
    };
  };

  config = {
    environment.systemPackages = [ pkgs.caddy ];
    environment.etc."testing/examples/Caddyfile.example".source =
      ../config-templates/Caddyfile.example;
    services.caddy = lib.mkIf cfg.enable {
      enable = true;
      extraConfig = cfg.configuration;
    };
  };
}
