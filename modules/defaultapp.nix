{ config, pkgs, ... }:

{
  xdg.mime.defaultApplications = {
    # Video files
    "video/*" = [ "vlc.desktop" ];
    "audio/*" = [ "vlc.desktop" ];

    # Image files (using gthumb as an example)
    "image/*" = [ "gthumb.desktop" ];
  };

  environment.systemPackages = with pkgs; [
#    vlc
    gthumb
  ];
}
