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
  *)
    echo "error: release binaries are available for Apple Silicon (arm64) Macs only" >&2
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

run_with_spinner() {
  MESSAGE="$1"
  shift

  if [ -t 1 ]; then
    "$@" &
    PID="$!"
    FRAMES='|/-\\'
    INDEX=0

    while kill -0 "$PID" 2>/dev/null; do
      INDEX=$(( (INDEX + 1) % 4 ))
      FRAME="$(printf '%s' "$FRAMES" | cut -c $((INDEX + 1)))"
      printf '\r%s %s' "$FRAME" "$MESSAGE"
      sleep 0.1
    done

    if wait "$PID"; then
      printf '\r✓ %s\033[K\n' "$MESSAGE"
      return 0
    fi

    printf '\r✗ %s\033[K\n' "$MESSAGE"
    return 1
  fi

  echo "$MESSAGE"
  "$@"
}

if ! command -v unzip >/dev/null 2>&1; then
  echo "error: unzip is required" >&2
  exit 1
fi

mkdir -p "$BIN_DIR"

if command -v curl >/dev/null 2>&1; then
  run_with_spinner "Downloading ${ASSET_NAME}" curl -fsSL "$URL" -o "$ZIP_PATH"
elif command -v wget >/dev/null 2>&1; then
  run_with_spinner "Downloading ${ASSET_NAME}" wget -qO "$ZIP_PATH" "$URL"
else
  echo "error: curl or wget is required" >&2
  exit 1
fi

run_with_spinner "Extracting ${ASSET_NAME}" unzip -q "$ZIP_PATH" -d "$TMP_DIR"

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

run_with_spinner "Installing ${BIN_NAME}" install -m 0755 "$BINARY" "$TARGET"

echo "Installed ${BIN_NAME} to ${TARGET}"
echo "Run: ${BIN_NAME} --help"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "Note: add ${BIN_DIR} to your PATH if ${BIN_NAME} is not found." ;;
esac
