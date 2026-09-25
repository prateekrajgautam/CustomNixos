{ config, pkgs, lib, ... }:

with lib;

{
  config = {
  
  
    users.users.nixos.extraGroups = [ "docker" ];

    virtualisation.docker = {
      enable = true;
      rootless.enable = true;
    };

    environment.systemPackages = with pkgs; [
      docker
      docker-compose
      nvidia-docker
    ] ++ (optionals (config.hardware.nvidia.enableDocker or false) [
      nvidia-container-toolkit
    ]);

    services.dockerRegistry.enable = true;

    # Conditionally add NVIDIA runtime if requested
    virtualisation.docker.daemon.settings = mkIf (config.hardware.nvidia.enableDocker or false) {
      "default-runtime" = "nvidia";
      "runtimes" = {
        nvidia = {
          path = "${pkgs.nvidia-container-toolkit}/bin/nvidia-container-runtime";
          runtimeArgs = [];
        };
      };
    };
  };
}























#{ config, pkgs, lib, ... }:
#{
#
#config = {
#    #users.users.${username}.extraGroups = [ "docker" ];
#    users.users.prateek.extraGroups = [ "docker" ];
#     
#    virtualisation.docker = {
#      enable = true;
#      rootless.enable = true;
#      #enableNvidia = true;
#    };
#    
#    
#    
#    environment.systemPackages = with pkgs; [
#        docker
#        nvidia-docker
#        docker-compose
#    ];
#    
#    
#    services.dockerRegistry.enable = true;
#
#
#};
#}
