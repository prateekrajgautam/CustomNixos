{ config, pkgs, lib, ... }:
#let 
#	username="prateek";
#in
{
    imports = [
        <nixpkgs/nixos/modules/services/hardware/sane_extra_backends/brscan4.nix>
#        ./sane-extra-config.nix
    ];
      


config = {
	


	#environment.systemPackages = with pkgs; [
	#	gnome.simple-scan
	#	naps2
	#	gscan2pdf	
	#];

    hardware.sane = {
        enable = true; # enables support for SANE scanners
        extraBackends = [ pkgs.sane-airscan ];
        disabledDefaultBackends = [ "escl" ];
        #extraConfig."magicolor" = ''
        #    net 10.0.0.30 0x2098
        #''; # Magicolor 1690mf
        
        
        brscan4 = {
            enable = true;
            netDevices = {
                home = { model = "DCP-T820dw"; ip = "192.182.1.212"; };
            };
        };
        
    };
    
    users.users.prateek.extraGroups = [ "scanner" "lp" ];
    
    environment.systemPackages = with pkgs; [
	    cups
    ];
    
    nixpkgs.config.packageOverrides = pkgs: {
        xsaneGimp = pkgs.xsane.override { gimpSupport = true; };
    };
    
    services = {
        printing = {
            enable = true;
            drivers = [ pkgs.brgenml1lpr pkgs.brgenml1cupswrapper ];
 #           listenAddresses = [ "*:631" ];
            allowFrom = [ "all" ];
            browsing = true;
            openFirewall = true;
        };
        ipp-usb.enable = true;
        avahi = { 
            enable = true;
            nssmdns4 = true;
            openFirewall = true;
            publish = {
                enable = true;
                userServices = true;
            };
        };
    };



};
}
