# gletch

A small system-fetch utility for macOS, inspired by [`nitch`](https://github.com/unxsh/nitch).

It prints macOS version art, host/user details, kernel, uptime, shell, package count, memory, and terminal colors.

## About

`gletch` is a lightweight macOS fetch tool focused on fast terminal output and Apple-style version artwork. It started as a macOS-focused take on `nitch`, but now ships as an Apple Silicon PyInstaller release so end users can install it without managing a Python environment.

## Install with curl

```sh
curl -fsSL https://raw.githubusercontent.com/gl-epka/gletch/main/install.sh | sh
```

The installer downloads the latest Apple Silicon (`arm64`) PyInstaller onedir archive from GitHub Releases.

By default this installs app files to `~/.local/share/gletch` and creates a `gletch` symlink in `~/.local/bin`. Make sure `~/.local/bin` is in your `PATH`:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

To install the symlink somewhere else:

```sh
curl -fsSL https://raw.githubusercontent.com/gl-epka/gletch/main/install.sh | BIN_DIR=/usr/local/bin sh
```

To install from a specific release tag:

```sh
curl -fsSL https://raw.githubusercontent.com/gl-epka/gletch/main/install.sh | RELEASE=v0.5.0 sh
```

## Usage

```sh
gletch            # Nerd Font icons
gletch --no-nerd  # plain ASCII icons
gletch --help
gletch --version
```

You can also run it directly from the checkout:

```sh
python3.14 main.py
```

## Python support

The project targets Python 3.14. End users install the PyInstaller binary and do not need Python installed.

## CI and binaries

GitHub Actions runs:

- PyInstaller onedir macOS binary build for Apple Silicon (`arm64`) using Python 3.14
- smoke tests for the generated binary
- artifact upload for the generated onedir archive

Tagged releases (`v*`) attach the PyInstaller onedir archive to the GitHub Release page. The installer expects this release asset:

- `gletch-macos-arm64.zip`

## Development

```sh
python3.14 -m py_compile main.py
python3.14 main.py --version
python3.14 main.py --help
```
