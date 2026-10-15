#!/bin/bash
# Runs inside a Rocky Linux container (see build-kit.sh): downloads the draw.io
# RPM's full dependency closure, as if installing onto an empty system, into a
# local dnf repo at /out/el<version>.
set -euo pipefail
EL_VERSION="$1"
DRAWIO_RPM="$2"
REPO_DIR="/out/el${EL_VERSION}"
mkdir -p "${REPO_DIR}/packages"
mapfile -t EXTRA_PACKAGES < /kit/packages.txt
dnf -y -q install createrepo_c >/dev/null
dnf install -y --downloadonly --nogpgcheck \
  --installroot=/tmp/emptyroot --releasever="$EL_VERSION" \
  --setopt=reposdir=/etc/yum.repos.d --setopt=varsdir=/etc/dnf/vars \
  --setopt=install_weak_deps=False \
  --downloaddir="${REPO_DIR}/packages" \
  "/in/${DRAWIO_RPM}" "${EXTRA_PACKAGES[@]}"
cp "/in/${DRAWIO_RPM}" "${REPO_DIR}/packages/"
createrepo_c -q "$REPO_DIR"
chown -R "${HOST_UID:-0}:${HOST_GID:-0}" "$REPO_DIR"
echo "el${EL_VERSION}: $(ls "${REPO_DIR}/packages" | wc -l) packages"
