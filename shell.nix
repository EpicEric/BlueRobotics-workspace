{
  system ? builtins.currentSystem,
  inputs ? import ./.tack,
  pkgs ? import inputs.nixpkgs { inherit system; },
}:
pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.bun
    pkgs.cargo
    pkgs.cargo-tauri
    pkgs.pkg-config
    pkgs.rustc
    pkgs.uv
    pkgs.wrapGAppsHook4
  ];

  buildInputs = [
    pkgs.librsvg
    pkgs.webkitgtk_4_1
  ];

  shellHook = ''
    export XDG_DATA_DIRS="$GSETTINGS_SCHEMAS_PATH" # Needed on Wayland to report the correct display scale
  '';
}
