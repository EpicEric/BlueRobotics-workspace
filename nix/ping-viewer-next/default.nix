{
  system ? builtins.currentSystem,
  inputs ? import ../../.tack,
  pkgs ? import inputs.nixpkgs { inherit system; },
  dockerTag ? "nix",
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

  backend-x86_64 = pkgs.pkgsCross.x86_64-multiplatform.callPackage ./backend.nix {
    ping-viewer-next-frontend = frontend;
  };
  docker-x86_64 = pkgs.pkgsCross.x86_64-multiplatform.callPackage ./docker.nix {
    ping-viewer-next = backend-aarch64;
    inherit dockerTag;
  };
  backend-aarch64 = pkgs.pkgsCross.aarch64-multiplatform.callPackage ./backend.nix {
    ping-viewer-next-frontend = frontend;
  };
  docker-aarch64 = pkgs.pkgsCross.aarch64-multiplatform.callPackage ./docker.nix {
    ping-viewer-next = backend-aarch64;
    inherit dockerTag;
  };
  backend-armv7l = pkgs.pkgsCross.armv7l-hf-multiplatform.callPackage ./backend.nix {
    ping-viewer-next-frontend = frontend;
  };
  docker-armv7l = pkgs.pkgsCross.armv7l-hf-multiplatform.callPackage ./docker.nix {
    ping-viewer-next = backend-armv7l;
    inherit dockerTag;
  };
in
{
  inherit
    frontend
    backend
    docker
    backend-x86_64
    docker-x86_64
    backend-aarch64
    docker-aarch64
    backend-armv7l
    docker-armv7l
    ;
}
