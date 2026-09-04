{
  cmake,
  fetchFromGitHub,
  ninja,
  stdenv,
  qt5,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "ping-viewer";
  version = "2.7.0";

  src = fetchFromGitHub {
    owner = "bluerobotics";
    repo = "ping-viewer";
    tag = "v${finalAttrs.version}";
    hash = "sha256-5HZ5i2nnVeXemLTgtecJvteZyxIdubqDXOXTREJTYIw=";
    fetchSubmodules = true;
    leaveDotGit = true;
    postFetch = ''
      git -C "$out" rev-parse --short HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };

  nativeBuildInputs = [
    cmake
    ninja
    qt5.wrapQtAppsHook
  ];

  buildInputs = [
    qt5.qtbase
    qt5.qtcharts
    qt5.qtdeclarative
    qt5.qtgraphicaleffects
    qt5.qtmultimedia
    qt5.qtquickcontrols
    qt5.qtquickcontrols2
    qt5.qtserialport
    qt5.qtsvg
  ];

  postPatch = ''
    cat > cmake/git.cmake <<EOF
    add_compile_definitions(
        GIT_VERSION="$(cat COMMIT)"
        GIT_VERSION_DATE="unknown"
        GIT_TAG="v${finalAttrs.version}"
        GIT_URL="https://github.com/bluerobotics/ping-viewer"
    )
    EOF
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 pingviewer $out/bin/pingviewer
    runHook postInstall
  '';
})
