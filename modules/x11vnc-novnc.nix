{ pkgs, config, lib, ... }:

let
  vncUser = "prateek";
  vncPasswordFile = "/home/${vncUser}/.vnc/passwd";
in
{
  services.xserver = {
    enable = true;
#    displayManager.gdm.enable = true;  # or lightdm/xdm etc.
#    desktopManager.plasma5.enable = true;  # or xfce/gnome etc.
  };

  environment.systemPackages = with pkgs; [
    tigervnc
    x11vnc
    novnc
    python3Packages.websockify
  ];

  systemd.services.x11vnc = {
    description = "x11vnc server";
    after = [ "graphical.target" ];
    wantedBy = [ "multi-user.target" ];
    wants = [ "graphical.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.x11vnc}/bin/x11vnc -display :0 -auth guess -rfbauth ${vncPasswordFile} -forever -loop -noxdamage -repeat -shared -localhost";
      User = vncUser;
      Restart = "on-failure";
      RestartSec = "5s";
    };
    unitConfig = {
      ConditionPathExists = vncPasswordFile;
    };
  };

  systemd.services.novnc = {
    description = "noVNC WebSocket proxy";
    after = [ "x11vnc.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.python3Packages.websockify}/bin/websockify --web=${pkgs.novnc}/share/novnc 6080 localhost:5900";
      User = vncUser;
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # PAM config for x11vnc (optional if using x11vnc password file only)
  security.pam.services.x11vnc = {
    startSession = true;
    allowNullPassword = false;
  };
}

