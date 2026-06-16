# gletch

A small system-fetch utility for macOS.

It prints macOS version art, host/user details, kernel, uptime, shell, package count, memory, and terminal colors.

## Install with curl

```sh
curl -fsSL https://raw.githubusercontent.com/gl-epka/gletch/main/install.sh | sh
```

The installer downloads the latest Apple Silicon (`arm64`) PyInstaller binary from GitHub Releases.

By default this installs `gletch` to `~/.local/bin`. Make sure that directory is in your `PATH`:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

To install somewhere else:

```sh
curl -fsSL https://raw.githubusercontent.com/gl-epka/gletch/main/install.sh | BIN_DIR=/usr/local/bin sh
```

To install from a specific release tag:

```sh
curl -fsSL https://raw.githubusercontent.com/gl-epka/gletch/main/install.sh | RELEASE=v0.3.0 sh
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
python3 main.py
```

## Python support

The source is tested on Python 3.9 through 3.13 on macOS.

## CI and binaries

GitHub Actions runs:

- Python smoke tests across supported Python versions
- PyInstaller one-file macOS binary build for Apple Silicon (`arm64`)
- artifact upload for the generated binary

Tagged releases (`v*`) attach the PyInstaller archive to the GitHub Release page. The installer expects this release asset:

- `gletch-macos-arm64.zip`

## Development

```sh
python3 -m py_compile main.py
python3 main.py --version
python3 main.py --help
```
