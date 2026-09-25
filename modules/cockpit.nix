{ config, pkgs, lib, ... }:
#let 
#	username="prateek";
#in
{

config = {
       
    
    environment.systemPackages = with pkgs; [
	cockpit
    ];
    
    
    services.cockpit = {
		#openFirewall = true;
		enable = true;
		port = 9090;
		
	};


};
}
