{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  packages = with pkgs; [ bash coreutils findutils gnused ];
  shellHook = ''
    project_dir="${toString ./.}"
    if [ "''${TESTING_SKIP_AUTO_BUILD:-0}" != "1" ]; then
      echo "Building Testing Minimal and Full ISO images..."
      "$project_dir/build-iso-minimal.sh"
      "$project_dir/build-iso-full.sh"
      echo "Both Testing ISO builds completed."
    else
      echo "Automatic ISO builds skipped because TESTING_SKIP_AUTO_BUILD=1."
    fi
  '';
}
