# nitch-mac

A small Python system-fetch utility for macOS, inspired by [`nitch`](https://github.com/unxsh/nitch).

It prints macOS version art, host/user details, kernel, uptime, shell, package count, memory, and terminal colors.

## Install with curl

```sh
curl -fsSL https://raw.githubusercontent.com/gl-epka/nitch-mac/main/install.sh | sh
```

By default this installs `nitch-mac` to `~/.local/bin`. Make sure that directory is in your `PATH`:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

To install somewhere else:

```sh
curl -fsSL https://raw.githubusercontent.com/gl-epka/nitch-mac/main/install.sh | BIN_DIR=/usr/local/bin sh
```

## Usage

```sh
nitch-mac            # Nerd Font icons
nitch-mac --no-nerd  # plain ASCII icons
nitch-mac --help
nitch-mac --version
```

You can also run it directly from the checkout:

```sh
python3 main.py
```

## Python support

`nitch-mac` is tested on Python 3.9 through 3.13 on macOS.

## CI and binaries

GitHub Actions runs:

- Python smoke tests across supported Python versions
- PyInstaller one-file macOS binary builds
- artifact upload for generated binaries

Tagged releases (`v*`) also attach the PyInstaller archives to a GitHub Release.

## Development

```sh
python3 -m py_compile main.py
python3 main.py --version
python3 main.py --help
```
