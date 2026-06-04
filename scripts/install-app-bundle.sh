#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_APP="$("$ROOT_DIR/scripts/build-app-bundle.sh" | tail -n 1)"
INSTALL_DIR="${COPY_INSTALL_DIR:-"$HOME/Applications"}"
INSTALL_APP="$INSTALL_DIR/Copy.app"

mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_APP"
ditto "$SOURCE_APP" "$INSTALL_APP"

echo "$INSTALL_APP"
