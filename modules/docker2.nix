{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf optionalAttrs optionals;

  enableNvidiaDocker =
    config.hardware.nvidia.enableDocker or false;

in
{
  users.users.prateek.extraGroups = [
    "docker"
  ];


  virtualisation.docker = {

    enable = true;

    # Server deployment uses the system Docker daemon
    rootless.enable = false;

    daemon.settings = {

      # Keep Docker's images, containers and volumes on ZFS storage
      "data-root" = "/zdata/docker";

      # Enable log rotation globally
      "log-driver" = "json-file";

      "log-opts" = {
        "max-size" = "10m";
        "max-file" = "3";
      };

    } // optionalAttrs enableNvidiaDocker {

      runtimes = {

        nvidia = {

          path =
            "${pkgs.nvidia-container-toolkit}/bin/nvidia-container-runtime";

          runtimeArgs = [];

        };

      };

    };

  };


  environment.systemPackages = with pkgs; [

    docker
    docker-compose

  ] ++ optionals enableNvidiaDocker [

    nvidia-container-toolkit

  ];


  services.dockerRegistry.enable = true;

}
