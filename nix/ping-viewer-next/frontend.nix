{
  lib,
  buildNpmPackage,
  importNpmLock,
}:
buildNpmPackage {
  name = "ping-viewer-next-frontend";

  src = lib.fileset.toSource {
    root = ../../ping-viewer-next/ping-viewer-next-frontend;
    fileset = lib.fileset.intersection ../../ping-viewer-next/ping-viewer-next-frontend (
      lib.fileset.gitTracked ../../ping-viewer-next
    );
  };

  npmDeps = importNpmLock {
    npmRoot = ../../ping-viewer-next/ping-viewer-next-frontend;
  };

  inherit (importNpmLock) npmConfigHook;

  installPhase = ''
    mkdir -p $out/share
    cp -R ./dist $out/share/ping-viewer-next-frontend
  '';
}
