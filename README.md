# Flowmodoro: Connect IQ development

The Nix shell provides Java, Go, signing tools, SDK command wrappers, and an
FHS filesystem with the old WebKitGTK **4.0 / libsoup 2** libraries needed by
Garmin's Linux simulator. Based on
[monkeyc and monkeydo on Linux](https://nettek.ca/blog/monkeyc-and-monkeydo-garmin-linux/).
It avoids the graphical Garmin SDK manager and does not need Distrobox.

## Enter the shell

On **x86_64 Linux**, with Nix flakes enabled:

```sh
# Flakes only see files tracked by Git; stage these new files first.
git add flake.nix README.md
nix develop
```

The first invocation creates `flake.lock`; commit it to pin both nixpkgs inputs.
Nix and the simulator have not been tested in this repository's authoring
environment (Nix was not installed there).

The FHS environment uses Linux user namespaces / bubblewrap. Hosts that disable
unprivileged user namespaces may need host configuration changes. A graphical
session with X11 or XWayland is required to display the simulator.

## Install the SDK (once, explicitly)

Inside the shell:

```sh
ciq-setup
connect-iq-sdk-manager-cli agreement view
connect-iq-sdk-manager-cli agreement accept
connect-iq-sdk-manager-cli login
connect-iq-sdk-manager-cli sdk list
# Pick a version from the list; 9.2.0 is the article's example.
connect-iq-sdk-manager-cli sdk download 9.2.0
connect-iq-sdk-manager-cli sdk set 9.2.0
connect-iq-sdk-manager-cli device download --download-all -F
```

Read Garmin's agreement before accepting. SDKs and device metadata stay under
`~/.Garmin/ConnectIQ`; credentials remain managed by the upstream CLI. `-F`
downloads device fonts, without which the simulator can crash. The CLI is
installed into `$(go env GOPATH)/bin`. Its `@latest` installation is intentionally
not pinned by `flake.lock`; substitute a specific Go module version if desired.
SDK selection and device downloads are also mutable, not Nix build inputs.

## Sign, build, and simulate

Create a private signing key outside the repository and keep it backed up: 

```sh
mkdir -p ~/.config/garmin
(umask 077
 openssl genrsa -out ~/.config/garmin/developer_key.pem 4096
 openssl pkcs8 -topk8 -inform PEM -outform DER \
   -in ~/.config/garmin/developer_key.pem \
   -out ~/.config/garmin/developer_key.der -nocrypt)
```

Start `simulator` in one shell. In another `nix develop` shell:

```sh
mkdir -p build
monkeyc -f monkey.jungle -d fr265s_sim \
  -o build/fr265s_sim.prg -y ~/.config/garmin/developer_key.der -w
monkeydo "$PWD/build/fr265s_sim.prg" fr265s
```

Choose a device supported by `manifest.xml`; `fr265s` is only an example.
For physical-device builds, omit `_sim` and copy the resulting `.prg` into the
watch's `GARMIN/Apps` directory via MTP. For store export, use `monkeyc -e`.

## Limits and security

- The simulator requires an obsolete WebKit stack. The flake explicitly permits
  that package; do not use it as a general browser or open untrusted content.
  An FHS environment is **not** a security sandbox. Software rendering is enabled
  to avoid the OAuth graphics failures described in the article.
- Only `x86_64-linux` is exposed. A native ARM shell would suffice for Java-based
  compilation, but cannot run Garmin's x86_64 simulator. The article's Asahi
  solution additionally needs host-configured muvm/FEX and an Ubuntu rootfs;
  a Nix dev shell alone does not provide that infrastructure.
- The exact proprietary SDK runtime dependencies can vary by SDK release.
  This environment supplies the article's dependencies plus common simulator
  graphics/font dependencies, but still needs a real Nix/GUI smoke test.
