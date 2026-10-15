#!/usr/bin/env bash
# Build the air-gapped kit into offline/dist: draw.io Desktop plus every RHEL 8/9
# dependency as local dnf repos, a git bundle of this repo, and SHA256SUMS.txt.
# Needs Docker and internet. Usage: DRAWIO_VERSION=32.4.1 ./offline/build-kit.sh
set -euo pipefail
cd "$(dirname "$0")/.."

DRAWIO_VERSION="${DRAWIO_VERSION:-32.4.1}"
EL_VERSIONS="${EL_VERSIONS:-8 9}"
DIST_DIR="${DIST_DIR:-$PWD/offline/dist}"
DRAWIO_RPM="drawio-x86_64-${DRAWIO_VERSION}.rpm"
RELEASE_URL="https://github.com/jgraph/drawio-desktop/releases/download/v${DRAWIO_VERSION}"

sha256()
{
  if command -v sha256sum >/dev/null; then sha256sum "$@"; else shasum -a 256 "$@"; fi
}

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
mkdir -p "$WORK_DIR/in" "$WORK_DIR/out" "$DIST_DIR"

curl -fsSL -o "$WORK_DIR/in/$DRAWIO_RPM" "$RELEASE_URL/$DRAWIO_RPM"
curl -fsSL -o "$WORK_DIR/in/Files-SHA256-Hashes.txt" "$RELEASE_URL/Files-SHA256-Hashes.txt"
(cd "$WORK_DIR/in" && grep " ${DRAWIO_RPM}\$" Files-SHA256-Hashes.txt | sha256 -c -)

for el in $EL_VERSIONS; do
  docker run --rm --platform linux/amd64 \
    -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
    -v "$WORK_DIR/in:/in:ro" -v "$WORK_DIR/out:/out" \
    -v "$PWD/offline/kit:/kit:ro" -v "$PWD/offline/build-repo.sh:/build-repo.sh:ro" \
    "rockylinux/rockylinux:${el}" bash /build-repo.sh "$el" "$DRAWIO_RPM"
  KIT_NAME="drawio-offline-el${el}"
  mv "$WORK_DIR/out/el${el}" "$WORK_DIR/out/$KIT_NAME"
  cp offline/kit/install.sh offline/kit/drawio-headless offline/kit/packages.txt "$WORK_DIR/out/$KIT_NAME/"
  chmod +x "$WORK_DIR/out/$KIT_NAME/install.sh" "$WORK_DIR/out/$KIT_NAME/drawio-headless"
  COPYFILE_DISABLE=1 tar -C "$WORK_DIR/out" -czf "$DIST_DIR/${KIT_NAME}-x86_64.tar.gz" "$KIT_NAME"
done

git bundle create "$DIST_DIR/drawio-mcp.bundle" --all
(cd "$DIST_DIR" && sha256 drawio-mcp.bundle drawio-offline-el*-x86_64.tar.gz > SHA256SUMS.txt)
ls -lh "$DIST_DIR"
