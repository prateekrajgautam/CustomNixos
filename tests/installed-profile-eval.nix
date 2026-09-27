{ nixpkgs, profile, edition }:

let
  eval = import "${nixpkgs}/nixos/lib/eval-config.nix" {
    system = "x86_64-linux";
    modules = [
      profile
      ({ ... }: {
        system.stateVersion = "26.05";
        boot.loader.grub.enable = false;
        fileSystems."/" = {
          device = "none";
          fsType = "tmpfs";
        };
      })
    ];
  };

  inherit (eval) config;

  checks = [
    {
      name = "installed system evaluates";
      ok = config.system.build.toplevel.drvPath != "";
    }
    {
      name = "installed NetworkManager service is enabled";
      ok = config.networking.networkmanager.enable;
    }
    {
      name = "installed Wi-Fi firmware is enabled";
      ok = config.nixpkgs.config.allowUnfree
        && config.hardware.enableAllFirmware
        && config.hardware.enableRedistributableFirmware;
    }
    {
      name = "installed system keeps normal online substituters";
      ok = config.nix.settings.substituters != [ ];
    }
  ];

  failures = map (check: check.name) (builtins.filter (check: !check.ok) checks);
  packageDrvs = map (package: package.drvPath) config.environment.systemPackages;
  result = {
    inherit edition;
    checkCount = builtins.length checks;
    packageCount = builtins.length packageDrvs;
    systemDrv = config.system.build.toplevel.drvPath;
  };
in
if failures != [ ] then
  throw "${edition} installed-profile preflight failed: ${builtins.concatStringsSep "; " failures}"
else
  builtins.deepSeq packageDrvs result
