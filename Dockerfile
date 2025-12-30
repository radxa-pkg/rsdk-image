FROM debian:12-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install -y git && \
  git clone --recurse-submodules https://github.com/RadxaOS-SDK/rsdk.git /tmp/rsdk && \
  cd /tmp/rsdk && \
  apt-get build-dep -y . && \
  make deb && \
  mv ../rsdk_*.deb /opt/rsdk.deb && \
  cd externals/librtui && \
  apt-get build-dep -y . && \
  make deb && \
  mv ../librtui_*.deb /opt/librtui.deb

FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i '/bookworm-updates/s/$/ bookworm-backports/' /etc/apt/sources.list.d/debian.sources

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    ca-certificates curl && \
  rm -rf /var/lib/apt/lists/*

RUN keyring="$(mktemp)" && \
  version="$(curl -fsSL https://github.com/radxa-pkg/radxa-archive-keyring/releases/latest/download/VERSION)" && \
  curl -fsSL -o "$keyring" "https://github.com/radxa-pkg/radxa-archive-keyring/releases/latest/download/radxa-archive-keyring_${version}_all.deb" && \
  dpkg -i "$keyring" && \
  rm -f "$keyring"

COPY --from=builder /opt/rsdk.deb /opt/librtui.deb /opt/

RUN apt-get update && \
  apt-get install -y \
    /opt/rsdk.deb /opt/librtui.deb && \
  rm /opt/rsdk.deb /opt/librtui.deb && \
  rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1000 rsdk && \
  useradd --uid 1000 --gid 1000 -m -s /bin/bash rsdk && \
  echo 'rsdk ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/rsdk

USER rsdk
WORKDIR /home/rsdk
