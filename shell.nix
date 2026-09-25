{
  system ? builtins.currentSystem,
  inputs ? import ./.tack,
  pkgs ? import inputs.nixpkgs { inherit system; },
}:
pkgs.mkShell {
  packages = [
    pkgs.bun
    pkgs.cargo
    pkgs.cargo-tauri
    pkgs.clippy
    pkgs.lsof
    pkgs.nodejs_24
    (import inputs.now { inherit system; })
    pkgs.parallel
    pkgs.pkg-config
    pkgs.rustc
    pkgs.shellcheck
    pkgs.uv
    pkgs.wrapGAppsHook4
    pkgs.yarn
  ];

  buildInputs = [
    pkgs.librsvg
    pkgs.webkitgtk_4_1
  ];

  shellHook = ''
    export XDG_DATA_DIRS="$GSETTINGS_SCHEMAS_PATH" # Needed on Wayland to report the correct display scale
  '';
}
