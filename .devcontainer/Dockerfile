# syntax=docker/dockerfile:1
FROM golang:1.25.5-bookworm@sha256:d9132cce84391efab786495288756d60e1da215b1f94e87860aeefc3d4c45b6d AS manager
COPY toolchain.json /tmp/toolchain.json
# Upstream chooses a random loopback port. Use a fixed container listener so
# Docker can publish the OAuth flow to the user's HOST browser on localhost.
RUN version=$(awk -F '"' '/"manager"/ {print $4}' /tmp/toolchain.json) \
    && go mod download -json github.com/lindell/connect-iq-sdk-manager-cli@${version} > /tmp/module.json \
    && module=$(awk -F '"' '/"Dir":/ {print $4}' /tmp/module.json) \
    && cp -a "$module" /tmp/manager && chmod -R u+w /tmp/manager \
    && cd /tmp/manager \
    && grep -Fq 'net.Listen("tcp", "localhost:0")' internal/oauth/oauth.go \
    && sed -i 's/net.Listen("tcp", "localhost:0")/net.Listen("tcp", "0.0.0.0:42817")/' internal/oauth/oauth.go \
    && CGO_ENABLED=0 go build -trimpath -o /out/connect-iq-sdk-manager-cli .

# Jammy retains the WebKitGTK 4.0/libsoup 2 ABI required by Garmin.
FROM mcr.microsoft.com/devcontainers/base:jammy@sha256:833a9eb9b48b57160531c9ea552d942d4d428ec58d76305d43f4976419b32173
USER root
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      openjdk-17-jdk-headless make openssl jq unzip zip binutils python3 curl ca-certificates \
      libwebkit2gtk-4.0-37 libsecret-1-0 libudev1 libusb-1.0-0 libxkbcommon0 \
      libxxf86vm1 libsm6 libice6 libgl1 libglu1-mesa libjpeg-turbo8 \
      libasound2 libxtst6 libxi6 libxrender1 fonts-dejavu-core \
      gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
      x11-utils xauth dbus-x11 \
    && rm -rf /var/lib/apt/lists/*
# Jammy's patchelf is too old to rename dynamic symbols. Pin this binary by hash.
RUN curl -fsSL https://github.com/NixOS/patchelf/releases/download/0.18.0/patchelf-0.18.0-x86_64.tar.gz -o /tmp/patchelf.tar.gz \
    && echo 'ce84f2447fb7a8679e58bc54a20dc2b01b37b5802e12c57eece772a6f14bf3f0  /tmp/patchelf.tar.gz' | sha256sum -c - \
    && tar -xzf /tmp/patchelf.tar.gz -C /usr/local ./bin/patchelf \
    && rm /tmp/patchelf.tar.gz
COPY --from=manager /out/connect-iq-sdk-manager-cli /usr/local/bin/
COPY toolchain.json /opt/flowmodoro/toolchain.json
COPY scripts /opt/flowmodoro/scripts
RUN chmod +x /opt/flowmodoro/scripts/* \
    && for tool in monkeyc monkeydo simulator; do ln -s /opt/flowmodoro/scripts/ciq-tool /usr/local/bin/$tool; done \
    && mkdir -p /home/vscode/.Garmin/ConnectIQ /home/vscode/.config/garmin /home/vscode/.cache/flowmodoro \
    && chown -R vscode:vscode /home/vscode/.Garmin /home/vscode/.config/garmin /home/vscode/.cache
ENV LIBGL_ALWAYS_SOFTWARE=1 WEBKIT_DISABLE_COMPOSITING_MODE=1 GDK_BACKEND=x11
USER vscode
