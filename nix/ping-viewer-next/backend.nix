{
  lib,
  ping-viewer-next-frontend,
  rustPlatform,
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
in
rustPlatform.buildRustPackage {
  name = "ping-viewer-next";

  src = lib.fileset.toSource {
    root = ../../ping-viewer-next;
    fileset = lib.fileset.union (lib.fileset.gitTracked ../../ping-viewer-next) (
      lib.fileset.maybeMissing ../../ping-viewer-next/.git
    );
  };

  cargoLock.lockFile = ../../ping-viewer-next/Cargo.lock;

  postPatch = ''
    ln -s ${ping-viewer-next-frontend}/share/ping-viewer-next-frontend ping-viewer-next-frontend/dist

    mavlinkCrate=$(find "$cargoDepsCopy" -maxdepth 2 -type d -name 'mavlink-0.16.2')
    rm -rf "$mavlinkCrate/mavlink"
    cp -R ${mavlinkDefinitions} "$mavlinkCrate/mavlink"
  '';

  nativeBuildInputs = [
    git
    perl
  ];

  buildFeatures = [
    "embed-frontend"
    "blueos-extension"
  ];

  doCheck = false;

  meta.mainProgram = "ping-viewer-next";
}
