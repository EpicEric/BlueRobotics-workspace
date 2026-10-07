{
  fetchFromGitHub,
  lib,
  rustPlatform,
  versionCheckHook,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "cargo-generate-rpm";
  version = "0.21.0";

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "cat-in-136";
    repo = "cargo-generate-rpm";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Ok/ATMI2Z9hQPMVaFgngdc/UmaIX4KXhHwyKZZ53zfc=";
  };

  postPatch = ''
    ln -s ${./Cargo.lock} Cargo.lock
  '';
  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  doCheck = false;

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  meta = {
    description = "Cargo helper command to generate a binary RPM package";
    homepage = "https://github.com/cat-in-136/cargo-generate-rpm";
    changelog = "https://github.com/cat-in-136/cargo-generate-rpm/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    mainProgram = "cargo-generate-rpm";
    platforms = lib.platforms.all;
  };
})
