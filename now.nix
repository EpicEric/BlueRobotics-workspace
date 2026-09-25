{ runner, ... }:
let
  stringOrPlaceholder = original: placeholder': if (original == "") then placeholder' else original;
in
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
              jj git remote add upstream git@github.com:bluerobotics/BlueOS.git
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
              jj -R ping-viewer-next git remote add upstream git@github.com:bluerobotics/ping-viewer-next.git
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
          env = {
            BLUEOS_USER = stringOrPlaceholder (runner.var "BLUEOS_USER") "pi";
            BLUEOS_HOST = runner.secret "BLUEOS_HOST";
            BLUEOS_ARCH = stringOrPlaceholder (runner.var "BLUEOS_ARCH") "armv7l";
            DOCKER_TAG = stringOrPlaceholder (runner.var "DOCKER_TAG") "dev";
          };
          run = ''
            PVN_IMAGE=$(nix-build --no-out-link -A ping-viewer-next.docker-$BLUEOS_ARCH --argstr dockerTag $DOCKER_TAG)
            ssh $BLUEOS_USER@$BLUEOS_HOST docker image load < $PVN_IMAGE
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
              jj git remote add upstream git@github.com:bluerobotics/cockpit.git
            fi
          '';
        }
      ];
    };
  };
}
