#!/bin/bash
# Install draw.io Desktop on RHEL 8/9 from this kit. Packages available in the
# machine's configured repos (Artifactory / Satellite) are taken from there; the
# kit supplies the rest. Unreachable repos are skipped, and if a reachable repo
# fails mid-download the install is retried from the kit only.
set -euo pipefail
KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
mapfile -t EXTRA_PACKAGES < "${KIT_DIR}/packages.txt"
PACKAGES=(draw.io "${EXTRA_PACKAGES[@]}")
KIT_REPO=(--repofrompath=drawio-offline,"file://${KIT_DIR}" --setopt=drawio-offline.gpgcheck=0)
if dnf install -y "${KIT_REPO[@]}" \
     --setopt=drawio-offline.priority=200 \
     --setopt=skip_if_unavailable=True \
     --setopt='*.skip_if_unavailable=True' \
     "${PACKAGES[@]}"; then
  echo "Installed: packages available in this machine's repos came from there, the rest from the kit."
else
  echo "Install through this machine's repos failed; retrying from the kit only." >&2
  dnf install -y --disablerepo='*' "${KIT_REPO[@]}" "${PACKAGES[@]}"
  echo "Installed from the kit only."
fi
install -m 0755 "${KIT_DIR}/drawio-headless" /usr/local/bin/drawio
echo "Test: drawio --version"
