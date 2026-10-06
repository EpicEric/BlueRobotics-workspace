{
  system ? builtins.currentSystem,
  inputs ? import ../../.tack,
  pkgs ? import inputs.nixpkgs { inherit system; },
  dockerTag ? "nix",
  dockerTool ? "buildLayeredImage",
  ...
}:
let
  frontend = pkgs.callPackage ./frontend.nix { };
  backend = pkgs.callPackage ./backend.nix {
    ping-viewer-next-frontend = frontend;
  };
  docker = pkgs.callPackage ./docker.nix {
    ping-viewer-next = backend;
    inherit dockerTag;
  };

  mkCross =
    suffix: pkgsCross:
    let
      craneLib = (import inputs.crane { pkgs = pkgsCross; }).overrideToolchain (
        _:
        pkgsCross.pkgsBuildHost.symlinkJoin {
          name = "rust-toolchain";
          paths = with pkgsCross.pkgsBuildHost; [
            cargo
            rustc
            clippy
            rustfmt
          ];
        }
      );
      backendCross = pkgsCross.callPackage ./backend.nix {
        inherit craneLib;
        ping-viewer-next-frontend = frontend;
      };
    in
    {
      "backend-${suffix}" = backendCross;
      "docker-${suffix}" = pkgsCross.callPackage ./docker.nix {
        ping-viewer-next = backendCross;
        inherit dockerTag dockerTool;
      };
    };
in
{
  inherit
    frontend
    backend
    docker
    ;
}
// (mkCross "x86_64" pkgs.pkgsCross.gnu64)
// (mkCross "aarch64" pkgs.pkgsCross.aarch64-multiplatform)
// (mkCross "armv7l" pkgs.pkgsCross.armv7l-hf-multiplatform)
