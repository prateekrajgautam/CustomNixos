let
  eval = import <nixpkgs/nixos/lib/eval-config.nix> {
    system = "x86_64-linux";
    modules = [
      ../modules/cloudflare.nix
      ../modules/caddy.nix
      ../modules/zfspool.nix
      ({ ... }: {
        system.stateVersion = "26.05";
        boot.loader.grub.enable = false;
        fileSystems."/" = {
          device = "none";
          fsType = "tmpfs";
        };
        testing.services.cloudflareTunnel.enable = true;
        testing.services.caddy.enable = true;
        testing.zfs = {
          enable = true;
          hostId = "0123abcd";
          poolName = "tank";
        };
      })
    ];
  };
in
eval.config.system.build.toplevel
