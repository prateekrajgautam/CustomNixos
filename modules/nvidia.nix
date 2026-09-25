{ config, pkgs, lib, ... }:

with lib;

{

  
  # Allow unfree packages and accept NVIDIA's license
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.nvidia.acceptLicense = true;

  # Enable NVIDIA support
  services.xserver.videoDrivers = [ "nvidia" ];

  # Graphics settings
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_470; #working with old
#    package = config.boot.kernelPackages.nvidiaPackages.stable;

  };

  # NVIDIA container toolkit (replaces docker.enableNvidia)
  hardware.nvidia-container-toolkit.enable = true;
  
  # Docker configuration
  virtualisation.docker.enable = true;
  virtualisation.docker.enableNvidia = true;# depriciated now recommended hardware.nvidia-container-toolkit.enable

  
  boot.blacklistedKernelModules = [ "nouveau" ];

  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit # newly added
    nvidia-vaapi-driver
    libva
  ];
}
