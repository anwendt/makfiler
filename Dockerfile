# Tooling image with common supply-chain/build utilities.
# Includes: make, docker (CLI), buildctl, skopeo, grype, syft, cosign, jq, yq, buildah, git, drill.
#
# Usage:
#   docker build -f Dockerfile.tools -t toolbox:latest .

ARG DEBIAN_VERSION=bookworm
FROM debian:${DEBIAN_VERSION}-slim

ARG BUILDKIT_VERSION=v0.26.2
ARG YQ_VERSION=v4.49.2
ARG COSIGN_VERSION=v3.0.2
ARG SYFT_VERSION=v1.38.0
ARG GRYPE_VERSION=v0.104.1

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    gnupg \
    bash \
    make \
    git \
    jq \
    skopeo \
    docker.io \
    ldnsutils \
    buildah \
  ; \
  rm -rf /var/lib/apt/lists/*

# Buildah Version testen
RUN buildah --version || true

# Install buildctl
RUN set -eux; \
  arch="$(dpkg --print-architecture)"; \
  case "$arch" in \
    amd64) buildkit_arch="amd64" ;; \
    arm64) buildkit_arch="arm64" ;; \
    *) echo "unsupported arch: ${arch}" >&2; exit 1 ;; \
  esac; \
  curl -sSL "https://github.com/moby/buildkit/releases/download/${BUILDKIT_VERSION}/buildkit-${BUILDKIT_VERSION}.linux-${buildkit_arch}.tar.gz" \
    | tar -xz -C /usr/local/bin --strip-components=1 bin/buildctl

# Install yq
RUN set -eux; \
  arch="$(dpkg --print-architecture)"; \
  case "$arch" in \
    amd64) yq_arch="amd64" ;; \
    arm64) yq_arch="arm64" ;; \
    *) echo "unsupported arch: ${arch}" >&2; exit 1 ;; \
  esac; \
  curl -sSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${yq_arch}" -o /usr/local/bin/yq; \
  chmod +x /usr/local/bin/yq

# Install cosign
RUN set -eux; \
  arch="$(dpkg --print-architecture)"; \
  case "$arch" in \
    amd64) cosign_arch="amd64" ;; \
    arm64) cosign_arch="arm64" ;; \
    *) echo "unsupported arch: ${arch}" >&2; exit 1 ;; \
  esac; \
  curl -sSL "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-${cosign_arch}" -o /usr/local/bin/cosign; \
  chmod +x /usr/local/bin/cosign

# Install syft
RUN set -eux; \
  arch="$(dpkg --print-architecture)"; \
  case "$arch" in \
    amd64) syft_arch="amd64" ;; \
    arm64) syft_arch="arm64" ;; \
    *) echo "unsupported arch: ${arch}" >&2; exit 1 ;; \
  esac; \
  curl -sSfL "https://raw.githubusercontent.com/anchore/syft/main/install.sh" | \
    SYFT_VERSION="${SYFT_VERSION}" INSTALL_DIR=/usr/local/bin sh -s -- -b /usr/local/bin "v${SYFT_VERSION#v}" syft; \
  syft --version

# Install grype
RUN set -eux; \
  arch="$(dpkg --print-architecture)"; \
  case "$arch"in \
    amd64) grype_arch="amd64" ;; \
    arm64) grype_arch="arm64" ;; \
    *) echo "unsupported arch: ${arch}" >&2; exit 1 ;; \
  esac; \
  curl -sSfL "https://raw.githubusercontent.com/anchore/grype/main/install.sh" | \
    GRYPE_VERSION="${GRYPE_VERSION}" INSTALL_DIR=/usr/local/bin sh -s -- -b /usr/local/bin "v${GRYPE_VERSION#v}" grype; \
  grype version

# Empfehlung für Kubernetes NonRoot Buildah
# ENV BUILDAH_ISOLATION=chroot
# ENV STORAGE_DRIVER=vfs

ENTRYPOINT ["/bin/bash"]
