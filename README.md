# gletch

A tiny macOS fetch tool with Apple-style version art, inspired by [`nitch`](https://github.com/unxsh/nitch).

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/gl-epka/gletch/main/install.sh | sh
```

Installs to `~/.local/share/gletch` and links `gletch` in `~/.local/bin`.

If needed, add this to your shell profile:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Options:

```sh
curl -fsSL https://raw.githubusercontent.com/gl-epka/gletch/main/install.sh | BIN_DIR=/usr/local/bin sh
curl -fsSL https://raw.githubusercontent.com/gl-epka/gletch/main/install.sh | RELEASE=v0.5.0 sh
```

## Usage

```sh
gletch
gletch --no-nerd
gletch --help
gletch --version
```

## Requirements

- macOS Apple Silicon (`arm64`)
- Release asset: `gletch-macos-arm64.zip`
