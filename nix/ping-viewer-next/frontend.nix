{
  lib,
  stdenvNoCC,
  bun,
  nodejs,
}:
let
  src = lib.fileset.toSource {
    root = ../../ping-viewer-next/ping-viewer-next-frontend;
    fileset = lib.fileset.intersection ../../ping-viewer-next/ping-viewer-next-frontend (
      lib.fileset.gitTracked ../../ping-viewer-next
    );
  };

  node_modules = stdenvNoCC.mkDerivation {
    name = "ping-viewer-next-frontend-node-modules";

    inherit src;

    nativeBuildInputs = [ bun ];

    dontConfigure = true;
    dontFixup = true;

    buildPhase = ''
      runHook preBuild

      bun install --frozen-lockfile --no-progress

      runHook postBuild
    '';

    installPhase = ''
      rm -rf node_modules/.cache
      cp -R node_modules $out
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash =
      {
        "x86_64-linux" = "sha256-Fmx1b+Xw0ij9HpK724tQD+Jc7EfDgaMRER/OAySsb84=";
        "aarch64-linux" = "sha256-v4ufUxoImkPmYjoHs7b8ILXn1QfAZ2aq1ZlkYkowjuY=";
      }
      ."${stdenvNoCC.hostPlatform.system}";
  };
in
stdenvNoCC.mkDerivation {
  name = "ping-viewer-next-frontend";

  inherit src;

  nativeBuildInputs = [ nodejs ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    cp -R ${node_modules} node_modules
    chmod -R u+w node_modules
    node node_modules/.bin/vite build

    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/share
    cp -R ./dist $out/share/ping-viewer-next-frontend
  '';
}
