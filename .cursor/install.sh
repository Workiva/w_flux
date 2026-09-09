#!/usr/bin/env bash
#
# Cloud Agent install script for the w_flux repository.
#
# Runs at environment-build time to produce the baseline snapshot. It installs
# the pinned Dart SDK (matching .github/workflows/dart_ci.yml) into a
# system location so it is baked into the build snapshot, then fetches
# dependencies. Safe to re-run (idempotent).
#
# The Dart SDK is installed under /usr/local (which persists in the build
# snapshot) rather than $HOME, because a Cloud Agent's home directory is
# provisioned fresh on each boot. Per-boot dependency resolution lives in
# start.sh.
set -euo pipefail

# Pinned to the Dart SDK version used by CI (.github/workflows/dart_ci.yml).
DART_VERSION="2.19.6"
DART_SDK_DIR="/usr/local/dart-sdk"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Use sudo only when not already root.
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
fi

install_dart_sdk() {
  echo "Installing Dart SDK ${DART_VERSION} to ${DART_SDK_DIR}..."
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  curl -fsSL -o "${tmp_dir}/dartsdk.zip" \
    "https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/dartsdk-linux-x64-release.zip"
  unzip -q "${tmp_dir}/dartsdk.zip" -d "${tmp_dir}"
  ${SUDO} rm -rf "${DART_SDK_DIR}"
  ${SUDO} mv "${tmp_dir}/dart-sdk" "${DART_SDK_DIR}"
  rm -rf "${tmp_dir}"
}

if [ ! -x "${DART_SDK_DIR}/bin/dart" ] || ! "${DART_SDK_DIR}/bin/dart" --version 2>&1 | grep -q "${DART_VERSION}"; then
  install_dart_sdk
else
  echo "Dart SDK ${DART_VERSION} already present at ${DART_SDK_DIR}, skipping download."
fi

# Symlink the launcher onto the default PATH (/usr/local/bin) so `dart` works
# in login and non-login shells without profile changes.
${SUDO} ln -sf "${DART_SDK_DIR}/bin/dart" /usr/local/bin/dart

export PATH="${DART_SDK_DIR}/bin:${PATH}"
dart --version

# Fetch dependencies for the library and each sub-package. Dependencies come
# from public pub.dev, so no authentication is required.
echo "Fetching dependencies (w_flux)..."
(cd "${REPO_ROOT}" && dart pub get)

echo "Fetching dependencies (example)..."
(cd "${REPO_ROOT}/example" && dart pub get)

echo "Fetching dependencies (w_flux_codemod)..."
(cd "${REPO_ROOT}/w_flux_codemod" && dart pub get)

echo "Install complete."
