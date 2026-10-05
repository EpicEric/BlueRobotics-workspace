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
    pkgs.mesa
    pkgs.libGL
  ];

  shellHook = ''
    export XDG_DATA_DIRS="$GSETTINGS_SCHEMAS_PATH" # Needed on Wayland to report the correct display scale
    # Use the pinned Mesa instead of /run/opengl-driver, whose version may not match the pinned WebKitGTK
    export __EGL_VENDOR_LIBRARY_FILENAMES="${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
    export GBM_BACKENDS_PATH="${pkgs.mesa}/lib/gbm"
    export LIBGL_DRIVERS_PATH="${pkgs.mesa}/lib/dri"
  '';
}
