#!/bin/sh
set -eu

REPO="${REPO:-gl-epka/nitch-mac}"
REF="${REF:-main}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
BIN_NAME="${BIN_NAME:-nitch-mac}"
URL="https://raw.githubusercontent.com/${REPO}/${REF}/main.py"
TARGET="${BIN_DIR}/${BIN_NAME}"
TMP="$(mktemp)"

cleanup() {
  rm -f "$TMP"
}
trap cleanup EXIT INT TERM

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required" >&2
  exit 1
fi

mkdir -p "$BIN_DIR"

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$URL" -o "$TMP"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$TMP" "$URL"
else
  echo "error: curl or wget is required" >&2
  exit 1
fi

install -m 0755 "$TMP" "$TARGET"

echo "Installed ${BIN_NAME} to ${TARGET}"
echo "Run: ${BIN_NAME} --help"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "Note: add ${BIN_DIR} to your PATH if ${BIN_NAME} is not found." ;;
esac
