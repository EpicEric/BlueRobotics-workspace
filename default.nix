{
  system ? builtins.currentSystem,
  inputs ? import ./.tack,
  pkgs ? import inputs.nixpkgs {
    inherit system;
    overlays = [ (import inputs.rust-overlay) ];
  },
  ...
}@args:
{
  ping-viewer = pkgs.callPackage ./nix/ping-viewer/package.nix { };
  ping-viewer-next = import ./nix/ping-viewer-next args;
}
