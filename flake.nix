{
  description = "Garmin Connect IQ development and Linux simulator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # WebKitGTK 4.0 (libsoup 2), not the incompatible WebKitGTK 4.1.
    simulatorPkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { nixpkgs, simulatorPkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      legacy = import simulatorPkgs {
        inherit system;
        # This retired WebKit version is intentionally confined to the simulator.
        config.permittedInsecurePackages = [ "webkitgtk-2.44.2+abi=4.0" ];
      };
      sdkCommands = pkgs.runCommand "connect-iq-commands" { } ''
        mkdir -p $out/bin
        for command in monkeyc monkeydo simulator; do
          cat > "$out/bin/$command" <<'SCRIPT'
        #!/bin/bash
        set -euo pipefail
        manager="$(go env GOPATH)/bin/connect-iq-sdk-manager-cli"
        if [[ ! -x "$manager" ]]; then
          echo "Run ciq-setup first (see README.md)." >&2
          exit 1
        fi
        sdk="$("$manager" sdk current-path)"
        exec "$sdk/bin/$(basename "$0")" "$@"
        SCRIPT
          chmod +x "$out/bin/$command"
        done
        cat > $out/bin/ciq-setup <<'SCRIPT'
        #!/bin/bash
        set -euo pipefail
        mkdir -p "$HOME/.Garmin/ConnectIQ/Sdks"
        go install github.com/lindell/connect-iq-sdk-manager-cli@latest
        echo 'SDK manager installed. Follow the login/download steps in README.md.'
        SCRIPT
        chmod +x $out/bin/ciq-setup
      '';
      environment = pkgs.buildFHSEnv {
        name = "connect-iq-dev";
        targetPkgs = p: [
          p.bashInteractive p.coreutils p.curl p.unzip p.zip p.git
          p.go p.gcc p.jdk p.openssl p.jq p.cacert sdkCommands
        ] ++ (with legacy; [
          webkitgtk gtk3 glib libsecret expat zlib stdenv.cc.cc.lib
          xorg.libX11 xorg.libXext xorg.libSM xorg.libICE
          xorg.libXrender xorg.libXi xorg.libXtst
          libGL libGLU fontconfig freetype dejavu_fonts
          gst_all_1.gstreamer gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-good
        ]);
        runScript = "bash";
        profile = ''
          export PATH="$(go env GOPATH)/bin:$PATH"
          # Avoid the simulator's problematic hardware-accelerated OAuth rendering.
          export LIBGL_ALWAYS_SOFTWARE=1
          echo 'Connect IQ shell: monkeyc, monkeydo, simulator; first run: ciq-setup'
        '';
      };
    in {
      devShells.${system}.default = environment.env;
    };
}
