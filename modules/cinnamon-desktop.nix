{ config, pkgs, lib, ... }:
{
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Cinnamon Desktop Environment.
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.cinnamon.enable = true;

  programs.dconf.enable = true;

  # Cinnamon does not enable the standalone NetworkManager tray applet for us.
  # Keep an explicit Wi-Fi control visible in the live session and installed
  # desktop instead of leaving users with only the nmcli command-line tool.
  programs.nm-applet.enable = true;

  networking.wireless.enable = lib.mkForce false;
  networking.networkmanager.enable = true;

  # Installation media must be able to bring up common Wi-Fi adapters before
  # the target hardware has had a chance to generate its own configuration.
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  environment.systemPackages = with pkgs; [
    iw
    networkmanagerapplet
    pciutils
    usbutils
    util-linux
    wirelesstools
  ];
}
