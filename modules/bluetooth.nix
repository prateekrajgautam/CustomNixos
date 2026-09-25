{ config, pkgs, ... }:

{
  # Force load Bluetooth modules
  boot.kernelModules = [ "btusb" "bluetooth" ];
  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=n
  '';

  # Bluetooth configuration
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    # Add experimental features for better hardware support
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  # Ensure Bluetooth service starts
  systemd.services.bluetooth = {
    wantedBy = [ "bluetooth.target" ];
    serviceConfig.ExecStart = [
      ""
      "${pkgs.bluez}/libexec/bluetooth/bluetoothd --experimental"
    ];
  };

  # Add Bluetooth tools
  environment.systemPackages = with pkgs; [
    alsa-utils
    alsa-lib
    alsa-tools
    alsa-scarlett-gui
    pavucontrol
    pulseaudio
    bluez
    bluez-tools
  ];

  # Audio configuration
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber = {
      enable = true;
      extraConfig."51-audio-device-priority" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "alsa_input.usb-0c76_Audio_Array_AM-C1_Device-00.mono-fallback"; }
            ];
            actions.update-props = {
              "priority.driver" = 1;
              "priority.session" = 1;
            };
          }
          {
            matches = [
              { "node.name" = "alsa_input.pci-0000_00_1b.0.analog-stereo"; }
            ];
            actions.update-props = {
              "priority.driver" = 2000;
              "priority.session" = 2000;
            };
          }
        ];
      };
    };
  };

  services.udev.extraRules = ''
    # Audio Array AM-C1 USB microphone: avoid suspend/resume glitches.
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0c76", ATTR{idProduct}=="1719", ATTR{power/control}="on"
  '';

  # User permissions
  users.users.prateek.extraGroups = [ "audio" "bluetooth" ];
}
