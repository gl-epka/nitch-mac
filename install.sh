#!/bin/sh
set -eu

REPO="${REPO:-gl-epka/gletch}"
RELEASE="${RELEASE:-latest}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
APP_DIR="${APP_DIR:-$HOME/.local/share/gletch}"
BIN_NAME="${BIN_NAME:-gletch}"

OS="$(uname -s)"
ARCH="$(uname -m)"

if [ -t 1 ]; then
  BOLD='\033[1m'
  DIM='\033[2m'
  RED='\033[31m'
  GREEN='\033[32m'
  CYAN='\033[36m'
  MAGENTA='\033[35m'
  RESET='\033[0m'
else
  BOLD=''
  DIM=''
  RED=''
  GREEN=''
  CYAN=''
  MAGENTA=''
  RESET=''
fi

say() { printf '%b\n' "$*"; }
info() { say "${CYAN}›${RESET} $*"; }
fail() { say "${RED}✗${RESET} $*" >&2; exit 1; }

banner() {
  say "${MAGENTA}${BOLD}"
  say "       __     __       __"
  say "  ____/ /__  / /______/ /_"
  say " / __  / _ \/ __/ ___/ __ \\"
  say "/ /_/ /  __/ /_/ /__/ / / /"
  say "\__, /\___/\__/\___/_/ /_/"
  say "/____/"
  say "${RESET}${DIM}        macOS fetch, installed with style${RESET}\n"
}

spinner_frame() {
  case "$1" in
    0) printf '⠋' ;;
    1) printf '⠙' ;;
    2) printf '⠹' ;;
    3) printf '⠸' ;;
    4) printf '⠼' ;;
    5) printf '⠴' ;;
    6) printf '⠦' ;;
    7) printf '⠧' ;;
    8) printf '⠇' ;;
    *) printf '⠏' ;;
  esac
}

run_with_spinner() {
  MESSAGE="$1"
  shift

  if [ -t 1 ]; then
    "$@" &
    PID="$!"
    INDEX=0

    while kill -0 "$PID" 2>/dev/null; do
      FRAME="$(spinner_frame "$INDEX")"
      printf '\r%b%s%b %s' "$CYAN" "$FRAME" "$RESET" "$MESSAGE"
      INDEX=$(( (INDEX + 1) % 10 ))
      sleep 0.08
    done

    if wait "$PID"; then
      printf '\r%b✓%b %s\033[K\n' "$GREEN" "$RESET" "$MESSAGE"
      return 0
    fi

    printf '\r%b✗%b %s\033[K\n' "$RED" "$RESET" "$MESSAGE"
    return 1
  fi

  echo "$MESSAGE"
  "$@"
}

cleanup() {
  rm -rf "$TMP_DIR"
}

[ "$OS" = "Darwin" ] || fail "gletch release binaries are currently available for macOS only"

case "$ARCH" in
  arm64) ASSET_ARCH="arm64" ;;
  *) fail "release binaries are available for Apple Silicon (arm64) Macs only" ;;
esac

ASSET_NAME="${ASSET_NAME:-gletch-macos-${ASSET_ARCH}.zip}"
APP_NAME="gletch-macos-${ASSET_ARCH}"
if [ "$RELEASE" = "latest" ]; then
  URL="https://github.com/${REPO}/releases/latest/download/${ASSET_NAME}"
else
  URL="https://github.com/${REPO}/releases/download/${RELEASE}/${ASSET_NAME}"
fi

command -v unzip >/dev/null 2>&1 || fail "unzip is required"

TMP_DIR="$(mktemp -d)"
ZIP_PATH="${TMP_DIR}/${ASSET_NAME}"
INSTALL_APP_DIR="${APP_DIR}/${APP_NAME}"
TARGET="${BIN_DIR}/${BIN_NAME}"
trap cleanup EXIT INT TERM

banner
info "repo: ${REPO}"
info "release: ${RELEASE}"
info "target: ${TARGET}\n"

run_with_spinner "Creating install folders" mkdir -p "$BIN_DIR" "$APP_DIR"

if command -v curl >/dev/null 2>&1; then
  run_with_spinner "Downloading ${ASSET_NAME}" curl -fsSL "$URL" -o "$ZIP_PATH"
elif command -v wget >/dev/null 2>&1; then
  run_with_spinner "Downloading ${ASSET_NAME}" wget -qO "$ZIP_PATH" "$URL"
else
  fail "curl or wget is required"
fi

run_with_spinner "Unpacking release" unzip -q "$ZIP_PATH" -d "$TMP_DIR"

if [ -x "${TMP_DIR}/${APP_NAME}/gletch" ]; then
  EXTRACTED_APP_DIR="${TMP_DIR}/${APP_NAME}"
elif [ -x "${TMP_DIR}/gletch/gletch" ]; then
  EXTRACTED_APP_DIR="${TMP_DIR}/gletch"
else
  fail "gletch executable not found in release archive"
fi

rm -rf "$INSTALL_APP_DIR"
run_with_spinner "Installing ${BIN_NAME}" cp -R "$EXTRACTED_APP_DIR" "$INSTALL_APP_DIR"
chmod 0755 "${INSTALL_APP_DIR}/gletch"
run_with_spinner "Linking command" ln -sf "${INSTALL_APP_DIR}/gletch" "$TARGET"

say "\n${GREEN}${BOLD}✨ gletch is ready!${RESET}"
say "${DIM}app:${RESET} ${INSTALL_APP_DIR}"
say "${DIM}bin:${RESET} ${TARGET}"
say "${CYAN}run:${RESET} ${BIN_NAME}"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) say "\n${MAGENTA}tip:${RESET} add ${BIN_DIR} to PATH if ${BIN_NAME} is not found." ;;
esac
