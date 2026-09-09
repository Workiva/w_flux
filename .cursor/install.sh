#!/usr/bin/env bash
#
# Cloud Agent install script for the w_flux repository.
#
# Installs the pinned Dart SDK (matching .github/workflows/dart_ci.yml) and
# fetches dependencies for the library and its sub-packages. This runs at
# environment-build time and is safe to re-run (idempotent).
set -euo pipefail

# Pinned to the Dart SDK version used by CI (.github/workflows/dart_ci.yml).
DART_VERSION="2.19.6"
DART_SDK_DIR="$HOME/dart-sdk"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

install_dart_sdk() {
  echo "Installing Dart SDK ${DART_VERSION}..."
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  curl -fsSL -o "${tmp_dir}/dartsdk.zip" \
    "https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/dartsdk-linux-x64-release.zip"
  rm -rf "$DART_SDK_DIR"
  unzip -q "${tmp_dir}/dartsdk.zip" -d "$HOME"
  rm -rf "$tmp_dir"
}

if [ ! -x "${DART_SDK_DIR}/bin/dart" ] || ! "${DART_SDK_DIR}/bin/dart" --version 2>&1 | grep -q "${DART_VERSION}"; then
  install_dart_sdk
else
  echo "Dart SDK ${DART_VERSION} already present, skipping download."
fi

# Make the Dart SDK available on PATH for interactive agent shells (idempotent).
if ! grep -qs 'dart-sdk/bin' "${HOME}/.bashrc"; then
  echo 'export PATH="$HOME/dart-sdk/bin:$PATH"' >> "${HOME}/.bashrc"
fi
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
