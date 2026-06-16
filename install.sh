#!/bin/sh
set -eu

REPO="${REPO:-gl-epka/gletch}"
RELEASE="${RELEASE:-latest}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
APP_DIR="${APP_DIR:-$HOME/.local/share/gletch}"
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
APP_NAME="gletch-macos-${ASSET_ARCH}"
if [ "$RELEASE" = "latest" ]; then
  URL="https://github.com/${REPO}/releases/latest/download/${ASSET_NAME}"
else
  URL="https://github.com/${REPO}/releases/download/${RELEASE}/${ASSET_NAME}"
fi

TMP_DIR="$(mktemp -d)"
ZIP_PATH="${TMP_DIR}/${ASSET_NAME}"
INSTALL_APP_DIR="${APP_DIR}/${APP_NAME}"
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

mkdir -p "$BIN_DIR" "$APP_DIR"

if command -v curl >/dev/null 2>&1; then
  run_with_spinner "Downloading ${ASSET_NAME}" curl -fsSL "$URL" -o "$ZIP_PATH"
elif command -v wget >/dev/null 2>&1; then
  run_with_spinner "Downloading ${ASSET_NAME}" wget -qO "$ZIP_PATH" "$URL"
else
  echo "error: curl or wget is required" >&2
  exit 1
fi

run_with_spinner "Extracting ${ASSET_NAME}" unzip -q "$ZIP_PATH" -d "$TMP_DIR"

if [ -x "${TMP_DIR}/${APP_NAME}/gletch" ]; then
  EXTRACTED_APP_DIR="${TMP_DIR}/${APP_NAME}"
elif [ -x "${TMP_DIR}/gletch/gletch" ]; then
  EXTRACTED_APP_DIR="${TMP_DIR}/gletch"
else
  echo "error: gletch executable not found in release archive" >&2
  exit 1
fi

rm -rf "$INSTALL_APP_DIR"
run_with_spinner "Installing ${BIN_NAME}" cp -R "$EXTRACTED_APP_DIR" "$INSTALL_APP_DIR"
chmod 0755 "${INSTALL_APP_DIR}/gletch"
ln -sf "${INSTALL_APP_DIR}/gletch" "$TARGET"

echo "Installed ${BIN_NAME} to ${TARGET}"
echo "App files: ${INSTALL_APP_DIR}"
echo "Run: ${BIN_NAME} --help"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "Note: add ${BIN_DIR} to your PATH if ${BIN_NAME} is not found." ;;
esac
