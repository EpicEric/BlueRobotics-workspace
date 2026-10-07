{ runner, ... }:
{
  jobs = {
    setup-blueos = { pkgs, ... }: {
      steps = [
        {
          path = [
            pkgs.gitMinimal
            pkgs.jujutsu
          ];
          run = ''
            if [ -d "BlueOS" ]; then
              printf "\033[1;33mwarning:\033[0m BlueOS/ already exists.\n"
            else
              git clone --recurse-submodules --shallow-submodules git@github.com:EpicEric/BlueOS.git
              cd BlueOS
              jj git init
            fi
          '';
        }
      ];
    };

    update-blueos = { pkgs, ... }: {
      steps = [
        {
          path = [ pkgs.gitMinimal ];
          run = ''
            if [ -d "BlueOS" ]; then
              git -C BlueOS submodule update --init --depth 1
            else
              printf "\033[1;31merror:\033[0m BlueOS/ doesn't exist.\n"
            fi
          '';
        }
      ];
    };

    setup-ping-viewer-next = { pkgs, ... }: {
      steps = [
        {
          path = [
            pkgs.gitMinimal
            pkgs.jujutsu
          ];
          run = ''
            if [ -d "ping-viewer-next" ]; then
              printf "\033[1;33mwarning:\033[0m ping-viewer-next/ already exists.\n"
            else
              jj git clone git@github.com:EpicEric/ping-viewer-next.git
            fi
          '';
        }
        {
          path = [
            pkgs.bun
            pkgs.nodejs_24
          ];
          run = ''
            if [ -d "ping-viewer-next/ping-viewer-next-frontend/dist" ]; then
              printf "\033[1;33mwarning:\033[0m ping-viewer-next/ping-viewer-next-frontend/dist/ already exists.\n"
            else
              cd ping-viewer-next/ping-viewer-next-frontend
              if [ -f "bun.lockb" ]; then
                bun ci
                bun run build
              else
                npm ci
                npm run build
              fi
            fi
          '';
        }
      ];
    };

    push-ping-viewer-next = { pkgs, ... }: {
      steps = [
        {
          path = [
            pkgs.nix
            pkgs.openssh
          ];
          env.BLUEOS_HOST = runner.secret "BLUEOS_HOST";
          run = ''
            PVN_IMAGE=$(nix-build --no-out-link -A ping-viewer-next.docker-''${BLUEOS_ARCH:-armv7l} --argstr dockerTag ''${DOCKER_TAG:-dev} --argstr dockerTool streamLayeredImage)
            $PVN_IMAGE | ssh ''${BLUEOS_USER:-pi}@$BLUEOS_HOST docker image load
          '';
        }
      ];
    };

    package-ping-viewer-next-desktop =
      { pkgs, ... }:
      let
        schemas = pkgs.runCommand "gsettings-schemas-merged" { } ''
          mkdir -p $out
          cp -r --no-preserve=mode ${pkgs.glib.dev}/share/glib-2.0/schemas/. $out/
          for d in ${pkgs.gtk3}/share/gsettings-schemas/*/glib-2.0/schemas \
                   ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/*/glib-2.0/schemas; do
            cp -r --no-preserve=mode $d/. $out/
          done
        '';

        # linuxdeploy-plugin-gtk finds libs with
        # `find $(pkg-config --variable=libdir gobject-2.0) -name 'libgobject-*.so*'`
        # which also matches the libgobject-*.so*-gdb.py script and makes linuxdeploy crash
        # trying to parse it as an ELF file
        gobjectLibs = pkgs.runCommand "gobject-libs-filtered" { } ''
          mkdir -p $out
          for f in ${pkgs.glib.out}/lib/libgobject-2.0.so*; do
            case "$f" in
              *.py) ;;
              *) ln -s "$f" $out/ ;;
            esac
          done
        '';

        fhsEnv = pkgs.buildFHSEnv {
          name = "packager-fhs";
          targetPkgs = pkgs: [
            # Store files are read-only, and cp copies that to dirs it creates (e.g. with --parents/--archive).
            # Copy normally (keeping the executable bit), then make the destination writable again.
            (pkgs.lib.hiPrio (
              pkgs.writeShellScriptBin "cp" ''
                ${pkgs.coreutils}/bin/cp "$@" 2>/dev/null
                rc=$?
                dest=""
                prev=""
                for a in "$@"; do
                  case "$a" in
                    --target-directory=*) dest="''${a#--target-directory=}" ;;
                    -t|--target-directory) ;;
                    -*) ;;
                    *) if [ "$prev" = "-t" ] || [ "$prev" = "--target-directory" ]; then dest="$a"; elif [ -z "$tflag" ]; then last="$a"; fi ;;
                  esac
                  case "$a" in
                    -t|--target-directory|--target-directory=*) tflag=1 ;;
                  esac
                  prev="$a"
                done
                [ -n "$dest" ] || dest="$last"
                if [ -n "$dest" ] && [ -e "$dest" ] && [ ! -L "$dest" ]; then
                  # The copy may land outside of $dest (e.g. relative "../nix/store/..." sources with --parents),
                  # so make the whole enclosing *.AppDir writable if there is one
                  root="$(${pkgs.coreutils}/bin/realpath -m "$dest")"
                  while [ "$root" != "/" ] && [ "''${root%.AppDir}" = "$root" ]; do
                    root="$(${pkgs.coreutils}/bin/dirname "$root")"
                  done
                  [ "$root" != "/" ] || root="$dest"
                  ${pkgs.coreutils}/bin/chmod -R u+w "$root" 2>/dev/null || true
                fi
                # A dir created read-only mid-copy can make the first attempt fail; retry now that it's writable
                if [ $rc -ne 0 ]; then
                  exec ${pkgs.coreutils}/bin/cp "$@"
                fi
                exit $rc
              ''
            ))
            pkgs.cargo
            pkgs.expat
            pkgs.expat.dev
            pkgs.file
            pkgs.fontconfig
            pkgs.fontconfig.dev
            pkgs.freetype
            pkgs.freetype.dev
            pkgs.fribidi
            pkgs.fribidi.dev
            pkgs.gcc
            pkgs.glib
            pkgs.gobject-introspection
            pkgs.gobject-introspection.dev
            pkgs.glib-networking
            pkgs.gst_all_1.gst-plugins-base
            pkgs.gst_all_1.gst-plugins-good
            pkgs.gst_all_1.gstreamer
            pkgs.gtk3
            pkgs.harfbuzz
            pkgs.harfbuzz.dev
            pkgs.libdrm
            pkgs.libdrm.dev
            pkgs.libgbm
            pkgs.libglvnd
            pkgs.libglvnd.dev
            pkgs.libgpg-error
            pkgs.libgpg-error.dev
            pkgs.librsvg
            pkgs.libsoup_3
            pkgs.libxcb
            pkgs.libxcb.dev
            pkgs.libx11
            pkgs.libx11.dev
            pkgs.libz
            pkgs.openssl
            pkgs.patchelf
            pkgs.pkg-config
            pkgs.rustc
            pkgs.webkitgtk_4_1
            pkgs.wget
            pkgs.xdg-utils
          ];
          runScript = "bash";
          profile = ''
            SCHEMAS_DIR="$HOME/.cache/ping-viewer-gschemas"
            rm -rf "$SCHEMAS_DIR"
            mkdir -p "$SCHEMAS_DIR"
            cp -r --no-preserve=mode ${schemas}/. "$SCHEMAS_DIR"/
            export PKG_CONFIG_GIO_2_0_SCHEMASDIR="$SCHEMAS_DIR"
            export PKG_CONFIG_GOBJECT_2_0_LIBDIR="${gobjectLibs}"
          '';
          meta.mainProgram = "packager-fhs";
        };
      in
      {
        steps = [
          {
            shell = fhsEnv;
            path = [
              (pkgs.callPackage ./nix/cargo-packager.nix { })
              pkgs.cargo
              pkgs.rustc
            ];
            run = ''
              cd ping-viewer-next
              # mksquashfs (via appimagetool) rejects SOURCE_DATE_EPOCH combined with its timestamp flags
              unset SOURCE_DATE_EPOCH
              chmod -R u+w target/release/.cargo-packager
              # Drop stale AppDirs from previous attempts
              rm -rf target/release/.cargo-packager/appimage/*.AppDir
              cargo packager --packages ping-viewer-next-desktop --release --formats appimage
            '';
          }
        ];
      };

    setup-cockpit = { pkgs, ... }: {
      steps = [
        {
          path = [
            pkgs.gitMinimal
            pkgs.jujutsu
          ];
          run = ''
            if [ -d "cockpit" ]; then
              printf "\033[1;33mwarning:\033[0m cockpit/ already exists.\n"
            else
              git clone --recurse-submodules --shallow-submodules git@github.com:EpicEric/cockpit.git
              cd cockpit
              jj git init
            fi
          '';
        }
      ];
    };
  };
}
