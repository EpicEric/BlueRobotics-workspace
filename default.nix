{
  system ? builtins.currentSystem,
  inputs ? import ./.tack,
  pkgs ? import inputs.nixpkgs { inherit system; },
}:
{
  ping-viewer = pkgs.callPackage ./nix/ping-viewer/package.nix { };
}
