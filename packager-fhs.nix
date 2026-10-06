{
  pkgs ? import <nixpkgs> { },
}:
(pkgs.buildFHSEnv {
  name = "packager-fhs";
  targetPkgs = pkgs: [
    pkgs.rustc
    pkgs.cargo
    pkgs.pkg-config
    pkgs.gcc
    pkgs.gtk3
    pkgs.webkitgtk_4_1
    pkgs.glib
    pkgs.glib-networking
    pkgs.librsvg
    pkgs.gst_all_1.gstreamer
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
    pkgs.libsoup_3
    pkgs.libz
    pkgs.openssl
    pkgs.patchelf
    pkgs.file
    pkgs.xdg-utils
    pkgs.wget
  ];
  runScript = "bash";
}).env
