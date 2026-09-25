{pkgs,lib,config,...}:
{
  services.xserver = {
    enable = true;
    xkb.options = lib.mkDefault "grp:alt_shift_toggle";
    xkb.variant = lib.mkDefault "winkeys";
    enableCtrlAltBackspace = lib.mkDefault true;
  };

  services.xrdp.enable = true;

  environment.systemPackages = with pkgs; [
    tigervnc
    novnc
    python3Packages.websockify
  ];

  networking.firewall.allowedTCPPorts = [ 3389 5901 6080 ];

  systemd.services.novnc = {
    description = "noVNC WebSocket Proxy";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.python3Packages.websockify}/bin/websockify --web=${pkgs.novnc}/share/novnc 6080 localhost:5901";
      User = "root";
      Restart = "on-failure";
    };
  };

  systemd.services.vncserver = {
    description = "TigerVNC server";
    after = [ "network.target" "graphical.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.tigervnc}/bin/vncserver :1";
      ExecStop = "${pkgs.tigervnc}/bin/vncserver -kill :1";
      User = "prateek";
      Restart = "on-failure";
    };
  };
}

# vncpasswd # set password
# sudo nixos-rebuild switch
# ps aux | grep vnc
# http://your-domain-or-ip:6080/vnc.html

# 
# 
