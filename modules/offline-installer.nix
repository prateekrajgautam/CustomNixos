{ config, lib, pkgs, modulesPath, installedProfile, installedModuleFiles ? [ ], ... }:

let
  mkTargetSystem = bootModule:
    (import "${modulesPath}/../lib/eval-config.nix" {
      system = pkgs.stdenv.hostPlatform.system;
      modules = [
        installedProfile
        ({ ... }: {
          system.stateVersion = config.system.stateVersion;
          networking.hostName = "offline-install-seed";
          fileSystems."/" = {
            device = "/dev/disk/by-label/nixos";
            fsType = "ext4";
          };
          networking.networkmanager.enable = true;
          hardware.enableAllFirmware = true;
          programs.nm-applet.enable = true;
          services.xserver.enable = true;
          services.xserver.displayManager.lightdm.enable = true;
          services.xserver.desktopManager.cinnamon.enable = true;
          nixpkgs.config.allowUnfree = true;
        })
        bootModule
      ];
    }).config.system.build.toplevel;

  efiTargetSystem = mkTargetSystem ({ ... }: {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = false;
  });

  biosTargetSystem = mkTargetSystem ({ ... }: {
    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/sda";
  });

  installedProfileBundle = pkgs.runCommand "offline-installed-profile" { } ''
    mkdir -p $out/etc/nixos $out/etc/modules
    cp ${installedProfile} $out/etc/nixos/offline-profile.nix
    ${lib.concatMapStrings (modulePath: ''
      cp ${modulePath} $out/etc/modules/${builtins.baseNameOf modulePath}
    '') installedModuleFiles}
  '';

  offlineCalamares = pkgs.writeShellScript "calamares-offline" ''
    # The installer must use only paths embedded in the ISO. If the closure is
    # incomplete, fail locally instead of silently downloading from a cache.
    export NIX_CONFIG=$'substituters =\nconnect-timeout = 1\nfallback = false'
    exec ${pkgs.calamares-nixos}/bin/calamares "$@"
  '';
in
{
  nixpkgs.overlays = [
    (final: prev: {
      calamares-nixos-extensions = prev.calamares-nixos-extensions.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          install -m 0644 ${../config-templates/calamares/welcome.conf} \
            $out/etc/calamares/modules/welcome.conf
          install -m 0644 ${../config-templates/calamares/packagechooser.conf} \
            $out/etc/calamares/modules/packagechooser.conf

          substituteInPlace $out/lib/calamares/modules/nixos/main.py \
            --replace-fail \
              "      ./hardware-configuration.nix" \
              $'      ./hardware-configuration.nix\n      ./offline-profile.nix'

          substituteInPlace $out/lib/calamares/modules/nixos/main.py \
            --replace-fail \
              "    # Write the configuration.nix file" \
              $'    # Persist the edition profile and its modules for future rebuilds.\n    libcalamares.utils.host_env_process_output(\n        ["cp", "-r", "${installedProfileBundle}/.", root_mount_point], None\n    )\n\n    # Write the configuration.nix file'

          substituteInPlace $out/lib/calamares/modules/nixos/main.py \
            --replace-fail \
              $'            "--root",\n            root_mount_point' \
              $'            "--root",\n            root_mount_point,\n            # pkexec sanitizes NIX_CONFIG, so enforce offline behavior on the\n            # privileged nixos-install command itself.\n            "--option",\n            "substituters",\n            "",\n            "--option",\n            "fallback",\n            "false",\n            "--option",\n            "connect-timeout",\n            "1"'
        '';
      });
    })
  ];

  # Keep complete BIOS and UEFI target closures on the ISO. The basic
  # no-desktop installation is a subset of these Cinnamon seed closures.
  system.extraDependencies = [ efiTargetSystem biosTargetSystem ];

  # Runtime defaults provide a second guard in addition to the launcher.
  nix.settings.substituters = lib.mkForce [ ];
  nix.settings.connect-timeout = 1;
  nix.settings.fallback = false;

  _module.args.offlineCalamares = offlineCalamares;
}
