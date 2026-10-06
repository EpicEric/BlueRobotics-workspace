{
  lib,
  stdenv,
  buildPackages,
  runCommandLocal,
  craneLib,
  ping-viewer-next-frontend,
  perl,
  git,
  fetchFromGitHub,
}:
let
  mavlinkDefinitions = fetchFromGitHub {
    owner = "mavlink";
    repo = "mavlink";
    rev = "bad2532fca7721937e45f128c5345e6a8e6544c9"; # v0.16.2
    hash = "sha256-7JiM9wqN7NaBaGnBqnZRal9xRBAOuBVeHc/iYiW5NvM=";
  };

  src = lib.fileset.toSource {
    root = ../../ping-viewer-next;
    fileset = lib.fileset.union (lib.fileset.gitTracked ../../ping-viewer-next) (
      lib.fileset.maybeMissing ../../ping-viewer-next/.git
    );
  };

  rustTarget = stdenv.hostPlatform.rust.rustcTarget;
  rustTargetEnv = lib.toUpper (lib.replaceStrings [ "-" ] [ "_" ] rustTarget);

  cargoVendorDir = craneLib.vendorCargoDeps {
    inherit src;
    overrideVendorCargoPackage =
      pkg: drv:
      if pkg.name == "mavlink" && pkg.version == "0.16.2" then
        runCommandLocal "vendor-mavlink-0.16.2" { } ''
          cp -R ${drv} $out
          chmod -R u+w $out
          rm -rf $out/mavlink
          cp -R ${mavlinkDefinitions} $out/mavlink
          chmod -R u+w $out/mavlink
        ''
      else
        drv;
  };

  commonArgs = {
    inherit src cargoVendorDir;
    strictDeps = true;

    cargoExtraArgs = "--features embed-frontend,blueos-extension";
    doCheck = false;

    nativeBuildInputs = [
      git
      perl
    ];

    depsBuildBuild = [ buildPackages.stdenv.cc ];

    CARGO_BUILD_TARGET = rustTarget;
    "CARGO_TARGET_${rustTargetEnv}_LINKER" = "${stdenv.cc.targetPrefix}cc";
    HOST_CC = "${buildPackages.stdenv.cc.targetPrefix}cc";
  };

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
craneLib.buildPackage (
  commonArgs
  // {
    inherit cargoArtifacts;

    postPatch = ''
      ln -s ${ping-viewer-next-frontend}/share/ping-viewer-next-frontend ping-viewer-next-frontend/dist
    '';

    meta.mainProgram = "ping-viewer-next";
  }
)
