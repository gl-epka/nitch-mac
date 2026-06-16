#!/bin/sh
set -eu

REPO="${REPO:-gl-epka/gletch}"
RELEASE="${RELEASE:-latest}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
BIN_NAME="${BIN_NAME:-gletch}"

OS="$(uname -s)"
ARCH="$(uname -m)"

if [ "$OS" != "Darwin" ]; then
  echo "error: gletch release binaries are currently available for macOS only" >&2
  exit 1
fi

case "$ARCH" in
  arm64) ASSET_ARCH="arm64" ;;
  x86_64) ASSET_ARCH="x86_64" ;;
  *)
    echo "error: unsupported macOS architecture: $ARCH" >&2
    exit 1
    ;;
esac

ASSET_NAME="${ASSET_NAME:-gletch-macos-${ASSET_ARCH}.zip}"
if [ "$RELEASE" = "latest" ]; then
  URL="https://github.com/${REPO}/releases/latest/download/${ASSET_NAME}"
else
  URL="https://github.com/${REPO}/releases/download/${RELEASE}/${ASSET_NAME}"
fi

TMP_DIR="$(mktemp -d)"
ZIP_PATH="${TMP_DIR}/${ASSET_NAME}"
TARGET="${BIN_DIR}/${BIN_NAME}"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM

if ! command -v unzip >/dev/null 2>&1; then
  echo "error: unzip is required" >&2
  exit 1
fi

mkdir -p "$BIN_DIR"

echo "Downloading ${URL}"
if command -v curl >/dev/null 2>&1; then
  curl -fL "$URL" -o "$ZIP_PATH"
elif command -v wget >/dev/null 2>&1; then
  wget -O "$ZIP_PATH" "$URL"
else
  echo "error: curl or wget is required" >&2
  exit 1
fi

unzip -q "$ZIP_PATH" -d "$TMP_DIR"

if [ -f "${TMP_DIR}/gletch-macos-${ASSET_ARCH}" ]; then
  BINARY="${TMP_DIR}/gletch-macos-${ASSET_ARCH}"
elif [ -f "${TMP_DIR}/gletch" ]; then
  BINARY="${TMP_DIR}/gletch"
else
  BINARY="$(find "$TMP_DIR" -type f ! -name "*.zip" | head -n 1)"
fi

if [ -z "${BINARY:-}" ] || [ ! -f "$BINARY" ]; then
  echo "error: binary not found in release archive" >&2
  exit 1
fi

install -m 0755 "$BINARY" "$TARGET"

echo "Installed ${BIN_NAME} to ${TARGET}"
echo "Run: ${BIN_NAME} --help"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "Note: add ${BIN_DIR} to your PATH if ${BIN_NAME} is not found." ;;
esac
