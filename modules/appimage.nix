{ config, pkgs, lib, ...}:

{
config = {
	environment.systemPackages = with pkgs; [
#		appimagekit	# not available in 25.11
		appimage-run

	];


programs.appimage.binfmt = true;


};
}
