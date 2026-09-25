{ config, pkgs, ... }:

{
  # Enable hardware monitoring
  services.thermald.enable = true;
  services.power-profiles-daemon.enable = true;
  
  # Install monitoring tools
  environment.systemPackages = with pkgs; [
    lm_sensors
    htop
  ];

  # Enable sensor detection
  hardware.sensor.iio.enable = true;
}
