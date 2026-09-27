{ nixpkgs, configuration, edition }:

let
  eval = import "${nixpkgs}/nixos/lib/eval-config.nix" {
    system = "x86_64-linux";
    modules = [ configuration ];
  };

  inherit (eval) config;
  lib = eval.pkgs.lib;

  checks = [
    {
      name = "ISO image derivation evaluates";
      ok = config.system.build.isoImage.drvPath != "";
    }
    {
      name = "Cinnamon desktop is enabled";
      ok = config.services.xserver.desktopManager.cinnamon.enable;
    }
    {
      name = "LightDM is enabled";
      ok = config.services.xserver.displayManager.lightdm.enable;
    }
    {
      name = "live-user automatic login is enabled";
      ok = config.services.displayManager.autoLogin.enable
        && config.services.displayManager.autoLogin.user == "nixos";
    }
    {
      name = "live user may administer networking";
      ok = lib.elem "networkmanager" config.users.users.nixos.extraGroups;
    }
    {
      name = "NetworkManager is enabled";
      ok = config.networking.networkmanager.enable;
    }
    {
      name = "standalone wpa_supplicant does not conflict with NetworkManager";
      ok = !config.networking.wireless.enable;
    }
    {
      name = "NetworkManager tray applet is enabled";
      ok = config.programs.nm-applet.enable;
    }
    {
      name = "unfree and redistributable Wi-Fi firmware are enabled";
      ok = config.nixpkgs.config.allowUnfree
        && config.hardware.enableAllFirmware
        && config.hardware.enableRedistributableFirmware;
    }
    {
      name = "pinned nixpkgs is materialised in /etc/nixpkgs";
      ok = config.environment.etc ? "nixpkgs"
        && toString config.environment.etc."nixpkgs".source == toString nixpkgs;
    }
    {
      name = "offline target closures are retained";
      ok = builtins.length config.system.extraDependencies >= 3;
    }
    {
      name = "live Nix retains its normal online substituter";
      ok = config.nix.settings.substituters != [ ];
    }
    {
      name = "Calamares offline launcher evaluates";
      ok = lib.any
        (package: lib.hasInfix "install-nixos" (toString package))
        config.environment.systemPackages;
    }
  ];

  failures = map (check: check.name) (builtins.filter (check: !check.ok) checks);

  # Forcing every package drvPath catches removed/renamed packages, unsupported
  # platforms and allowUnfree mistakes without building their outputs.
  packageDrvs = map (package: package.drvPath) config.environment.systemPackages;

  result = {
    inherit edition;
    checkCount = builtins.length checks;
    packageCount = builtins.length packageDrvs;
    isoDrv = config.system.build.isoImage.drvPath;
    nixpkgsSource = toString config.environment.etc."nixpkgs".source;
  };
in
if failures != [ ] then
  throw "${edition} ISO preflight failed: ${builtins.concatStringsSep "; " failures}"
else
  builtins.deepSeq packageDrvs result
