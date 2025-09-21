#!/bin/bash
set -euxo pipefail

COMPOSE_VERSION="v2.27.0"

# Helper: detect arch for Compose binary
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)   COMPOSE_ARCH="x86_64" ;;
  aarch64|arm64) COMPOSE_ARCH="aarch64" ;;
  *)        COMPOSE_ARCH="x86_64" ;;  # default fallback
esac

# Update & basic utils
(dnf -y update || yum -y update || true)
(dnf -y install curl ca-certificates || yum -y install curl ca-certificates || true)

# Install Docker
if command -v dnf >/dev/null 2>&1; then
  dnf -y install docker
else
  # Amazon Linux 2 / older yum-based systems
  amazon-linux-extras enable docker || true
  yum -y install docker
fi

# Enable & start
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group (if present)
if id ec2-user >/dev/null 2>&1; then
  usermod -aG docker ec2-user || true
fi

# --- Install Docker Compose v2 ---
# Preferred: distro package (where available)
compose_pkg_installed=false
if command -v dnf >/dev/null 2>&1; then
  if dnf -y install docker-compose-plugin; then
    compose_pkg_installed=true
  fi
fi

# Fallback: install the v2 plugin binary system-wide (works on Amazon Linux too)
if [ "$compose_pkg_installed" != "true" ]; then
  # System plugin search path for Docker: /usr/libexec/docker/cli-plugins (preferred), or /usr/local/lib/docker/cli-plugins
  PLUGINDIR="/usr/libexec/docker/cli-plugins"
  mkdir -p "$PLUGINDIR"

  # Download Compose v2 plugin
  curl -fL --retry 5 \
    "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${COMPOSE_ARCH}" \
    -o "${PLUGINDIR}/docker-compose"

  chmod +x "${PLUGINDIR}/docker-compose"

  # Optional: legacy alias so `docker-compose` (hyphen) also works
  if ! command -v docker-compose >/dev/null 2>&1; then
    ln -s "${PLUGINDIR}/docker-compose" /usr/local/bin/docker-compose || true
  fi
fi

# Verify
docker --version || true
# Prefer v2 plugin; fall back to hyphen binary if needed
docker compose version || docker-compose --version || true
