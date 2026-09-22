{
  lib,
  ping-viewer-next,
  writeShellApplication,
  coreutils,
  su-exec,
  dockerTools,
  dockerTag ? "nix",
}:
let
  entrypoint = writeShellApplication {
    name = "entrypoint";
    runtimeInputs = [ coreutils ];
    text = ''
      echo "Starting ping viewer..."
      mkdir -p /app/logs /app/recordings
      chmod -R 755 /app/logs /app/recordings
      chown -R 1000:1000 /app/logs /app/recordings
      exec ${lib.getExe su-exec} 1000:1000 \
        ${lib.getExe ping-viewer-next} --enable-auto-create --rest-server 0.0.0.0:6060
    '';
  };
in
dockerTools.buildLayeredImage {
  name = "docker.io/epiceric/blueos-ping-viewer-next";
  tag = dockerTag;

  contents = [
    dockerTools.binSh
    (dockerTools.fakeNss.override {
      extraPasswdLines = [ "pingviewer:x:1000:1000:pingviewer:/home/pingviewer:/bin/sh" ];
      extraGroupLines = [ "pingviewer:x:1000:" ];
    })
  ];

  fakeRootCommands = ''
    mkdir -p ./app/logs ./app/recordings ./home/pingviewer
    chown -R 1000:1000 ./app ./home/pingviewer
    chmod -R 755 ./app ./home/pingviewer
  '';

  config = {
    WorkingDir = "/app";
    Entrypoint = [ (lib.getExe entrypoint) ];
    Labels = {
      version = "1.0.0-beta.6";
      permissions = builtins.toJSON {
        ExposedPorts = {
          "6060/tcp" = { };
        };
        HostConfig = {
          Privileged = true;
          NetworkMode = "host";
          Binds = [
            "/var/logs/blueos/extensions/ping-viewer-next:/app/logs"
            "/usr/blueos/extensions/ping-viewer-next/recordings:/app/recordings"
          ];
        };
      };
      authors = builtins.toJSON [
        {
          name = "Raul Victor Trombin";
          email = "raulvtrombin@gmail.com";
        }
      ];
      company = builtins.toJSON {
        about = "Control PingProtocol based hardware using webservices";
        name = "Blue Robotics";
        email = "support@bluerobotics.com";
      };
      readme = "https://raw.githubusercontent.com/bluerobotics/ping-viewer-next/refs/heads/master/blueos-ping-viewer-next/README.md";
      type = "device-integration";
      tags = builtins.toJSON [
        "sonar"
        "ping-protocol"
      ];
    };
  };
}
