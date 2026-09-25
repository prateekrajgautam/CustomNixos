{ config, pkgs, lib, edition ? "Live", ... }:

let
  brandingRoot = ../branding;
  brand = builtins.fromJSON (builtins.readFile (brandingRoot + "/branding.json"));
  wallpaper = brandingRoot + "/${brand.wallpaper}";
  logo = brandingRoot + "/${brand.logo}";
in
{
  networking.hostName = "${brand.id}-${lib.toLower edition}";
  environment.etc."${brand.id}-release".text = ''
    ID="${brand.id}"
    NAME="${brand.name}"
    TAGLINE="${brand.tagline}"
    EDITION="${edition}"
    NIXOS_VERSION="${config.system.nixos.release}"
  '';
  environment.etc."dconf/profile/user".text = ''
    user-db:user
    system-db:${brand.id}
  '';
  environment.etc."dconf/db/${brand.id}.d/00-branding".text = ''
    [org/cinnamon/desktop/background]
    picture-uri='file://${wallpaper}'
    picture-options='zoom'
    primary-color='${brand.primaryColor}'
    secondary-color='${brand.secondaryColor}'

    [org/cinnamon/desktop/interface]
    gtk-theme='${brand.gtkTheme}'
    icon-theme='${brand.iconTheme}'

    [org/cinnamon/theme]
    name='${brand.gtkTheme}'
  '';
  environment.systemPackages = [ pkgs.mint-themes pkgs.mint-y-icons ];
  environment.etc."${brand.id}/branding/branding.json".source = brandingRoot + "/branding.json";
  environment.etc."${brand.id}/branding/wallpaper.svg".source = wallpaper;
  environment.etc."${brand.id}/branding/logo.svg".source = logo;
}
