{ config, lib, pkgs, modulesPath, installedProfile, installedModuleFiles ? [ ], ... }:

let
  # `modulesPath` is <nixpkgs>/nixos/modules.  Keep the exact nixpkgs tree
  # used to build the ISO reachable by the privileged installer instead of
  # relying on /root/.nix-defexpr or the asynchronously-created root channel.
  # pkgs.path preserves the Nix store dependency context. Reconstructing this
  # with builtins.dirOf produces the same text but loses that context, causing
  # isoImage.storeContents to fail while exporting its closure.
  nixpkgsPath = pkgs.path;

  # isoImage.storeContents coerces a bare source path to a new store name. If
  # /etc/nixpkgs points at the original name, that produces a dangling link.
  # Put the tree in an explicit derivation output so the path referenced by
  # /etc and the path exported to nix-store.squashfs are necessarily identical.
  offlineNixpkgs = pkgs.runCommand "offline-nixpkgs" { } ''
    mkdir -p "$out"
    cp -a ${nixpkgsPath}/. "$out/"
  '';

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
    mkdir -p $out/etc/nixos/modules
    cp ${installedProfile} $out/etc/nixos/offline-profile.nix
    ${lib.concatMapStrings (modulePath: ''
      cp ${modulePath} $out/etc/nixos/modules/${builtins.baseNameOf modulePath}
    '') installedModuleFiles}
  '';

  offlineCalamares = pkgs.writeShellScript "calamares-offline" ''
    # The installer must use only paths embedded in the ISO. If the closure is
    # incomplete, fail locally instead of silently downloading from a cache.
    #
    # Calamares is later elevated with pkexec, which sanitizes this process's
    # environment.  Setting NIX_PATH here still makes the live launcher and
    # any non-elevated checks deterministic; the patched command below passes
    # the same value explicitly through pkexec.
    export NIX_PATH='nixpkgs=/etc/nixpkgs'
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
              '            "nixos-install",' \
              $'            "env",\n            "NIX_PATH=nixpkgs=/etc/nixpkgs",\n            "nixos-install",'

          substituteInPlace $out/lib/calamares/modules/nixos/main.py \
            --replace-fail \
              $'            "--root",\n            root_mount_point' \
              $'            "--root",\n            root_mount_point,\n            # Enforce offline behavior on the privileged command itself.\n            # Local builds must remain enabled: nixos-install has to assemble\n            # the final system for the choices made in Calamares, using the\n            # package closures already embedded in the ISO.\n            "--option",\n            "substituters",\n            "",\n            "--option",\n            "fallback",\n            "false",\n            "--option",\n            "connect-timeout",\n            "1"'
        '';
      });
    })
  ];

  # Give the installer a stable path to the exact nixpkgs tree used to build
  # this ISO.
  environment.etc."nixpkgs".source = offlineNixpkgs;

  # Explicitly put the source plus complete BIOS and UEFI target closures in
  # nix-store.squashfs. system.extraDependencies alone registers dependencies
  # for the live system but does not make them members of the ISO store.
  # The basic no-desktop installation is a subset of the Cinnamon closures.
  isoImage.storeContents = [ offlineNixpkgs efiTargetSystem biosTargetSystem ];
  system.extraDependencies = [ offlineNixpkgs efiTargetSystem biosTargetSystem ];

  # Offline restrictions are deliberately applied to the Calamares process
  # and its nixos-install command above, not to the whole live system.  This
  # leaves Wi-Fi, browsers and ordinary Nix commands usable when the user
  # chooses to connect the live session to the internet.

  _module.args.offlineCalamares = offlineCalamares;
}
