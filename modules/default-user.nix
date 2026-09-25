{ ... }:
{
  # This account exists only in the live environment.
  users.users.nixos = {
    isNormalUser = true;
    description = "Testing Live User";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # Live-media convenience only. Do not import this module into an installed
  # system: installed users must get the normal sudo/password policy.
  security.sudo.wheelNeedsPassword = false;

  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };
}
