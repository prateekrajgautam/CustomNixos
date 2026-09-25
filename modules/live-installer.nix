{ pkgs, ... }:

let
  brand = builtins.fromJSON (builtins.readFile ../branding/branding.json);
  installerLauncher = pkgs.makeDesktopItem {
    name = "install-${brand.id}";
    desktopName = "Install ${brand.name}";
    genericName = "System Installer";
    comment = "Install ${brand.name} — ${brand.tagline}";
    icon = brand.installerIcon;
    exec = "pkexec ${pkgs.calamares-nixos}/bin/calamares";
    terminal = false;
    categories = [ "System" ];
  };
in
{
  environment.systemPackages = [ installerLauncher ];
  system.activationScripts.testingInstallerShortcut.text = ''
    install -d -m 0755 -o nixos -g users /home/nixos/Desktop
    install -m 0755 ${installerLauncher}/share/applications/install-${brand.id}.desktop \
      /home/nixos/Desktop/install-${brand.id}.desktop
    chown nixos:users /home/nixos/Desktop/install-${brand.id}.desktop
  '';
}
