{
  lib,
  rustPlatform,
  ping-viewer-next-frontend,
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
in
rustPlatform.buildRustPackage {
  pname = "ping-viewer-next";
  inherit ((lib.importTOML ../../ping-viewer-next/Cargo.toml).package) version;

  inherit src;
  cargoLock.lockFile = ../../ping-viewer-next/Cargo.lock;

  postPatch = ''
    rm -rf "$cargoDepsCopy/mavlink-0.16.2/mavlink"
    cp -R ${mavlinkDefinitions} "$cargoDepsCopy/mavlink-0.16.2/mavlink"
    chmod -R u+w "$cargoDepsCopy/mavlink-0.16.2/mavlink"

    ln -s ${ping-viewer-next-frontend}/share/ping-viewer-next-frontend ping-viewer-next-frontend/dist
  '';

  nativeBuildInputs = [ git ];
  cargoBuildFeatures = [ "embed-frontend" ];

  doCheck = false;

  meta.mainProgram = "ping-viewer-next";
}
