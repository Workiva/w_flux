#!/usr/bin/env bash
#
# Cloud Agent start script for the w_flux repository.
#
# Runs on every container boot (after install). The Dart SDK itself is baked
# into the build snapshot by install.sh, but a Cloud Agent's home directory
# (and therefore the pub cache) is provisioned fresh on each boot, so package
# resolution for the checked-out workspace is re-run here. Dependencies come
# from public pub.dev, so no authentication is required. This command returns
# once dependencies are resolved.
set -euo pipefail

DART_SDK_DIR="/usr/local/dart-sdk"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

export PATH="${DART_SDK_DIR}/bin:${PATH}"

dart --version

echo "Resolving dependencies (w_flux)..."
(cd "${REPO_ROOT}" && dart pub get)

echo "Resolving dependencies (example)..."
(cd "${REPO_ROOT}/example" && dart pub get)

echo "Resolving dependencies (w_flux_codemod)..."
(cd "${REPO_ROOT}/w_flux_codemod" && dart pub get)

echo "Start complete."
