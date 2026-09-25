{ config, pkgs, lib, ... }:
{

config = {
     
    
    
    
    environment.systemPackages = with pkgs; [
    zerotierone
	];
    
    
services.zerotierone = {
  enable = true;
  joinNetworks = [
  "8286ac0e47f0f46b"
	];
};
};
}
