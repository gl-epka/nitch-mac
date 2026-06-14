#!/usr/bin/env python3
"""
nitch-mac — Python port of nitch for macOS
  github.com/unxsh/nitch → ported to Python 3 / macOS

Usage:
  python3 nitch_mac.py            # Nerd Font icons
  python3 nitch_mac.py --no-nerd  # plain ASCII icons
  python3 nitch_mac.py --help
  python3 nitch_mac.py --version
"""

import os
import sys
import re
import time
import socket
import platform
import subprocess
import pwd
from datetime import timedelta

VERSION = "0.3.0"

# ── ANSI ──────────────────────────────────────────────────────────────────────
RESET = "\033[0m"


def fg(n: int) -> str:
    return f"\033[38;5;{n}m"


def bg(n: int) -> str:
    return f"\033[48;5;{n}m"


# ── Per-row value colors (matches nitch rainbow) ──────────────────────────────
ROW_COLORS = [
    fg(203),  # user   — coral red
    fg(221),  # hname  — yellow
    fg(114),  # os     — green
    fg(108),  # kernel — muted green
    fg(74),   # uptime — steel blue
    fg(141),  # shell  — purple
    fg(215),  # pkgs   — orange
    fg(221),  # memory — yellow
]

# ── Theme ─────────────────────────────────────────────────────────────────────
C_ICON   = fg(246)   # gray — icon
C_LABEL  = fg(252)   # light gray — label
C_BORDER = fg(240)   # dark gray — box
C_LOGO   = fg(114)   # green — the version-name ASCII art (Apple-ish accent)

# ── Nerd Font icons (NF v3, U+F0000+ — works on patched fonts) ───────────────
NERD = {
    "user":   "\U000f0004 ",  # nf-md-account
    "host":   "\U000f0379 ",  # nf-md-desktop_classic
    "os":     "\U000f0035 ",  # nf-md-apple
    "kernel": "\U000f0322 ",  # nf-md-chip
    "uptime": "\U000f051a ",  # nf-md-clock_outline
    "shell":  "\U000f018d ",  # nf-md-console
    "pkgs":   "\U000f03d6 ",  # nf-md-package_variant
    "mem":    "\U000f035b ",  # nf-md-memory
    "colors": "\U000f03d8 ",  # nf-md-palette
}

PLAIN = {k: "> " for k in NERD}

# ── macOS version map ─────────────────────────────────────────────────────────
MACOS_NAMES = {
    26: "Tahoe",
    15: "Sequoia",
    14: "Sonoma",
    13: "Ventura",
    12: "Monterey",
    11: "Big Sur",
    10: "Catalina",
    9:  "Mojave",
    8:  "High Sierra",
}

# ── ASCII art for each version name (font: figlet "standard") ─────────────────
MACOS_ART = {
    "Tahoe": [
        " _____     _                ",
        "|_   _|_ _| |__   ___   ___ ",
        "  | |/ _` | '_ \\ / _ \\ / _ \\",
        "  | | (_| | | | | (_) |  __/",
        "  |_|\\__,_|_| |_|\\___/ \\___|",
    ],
    "Sequoia": [
        " ____                         _       ",
        "/ ___|  ___  __ _ _   _  ___ (_) __ _ ",
        "\\___ \\ / _ \\/ _` | | | |/ _ \\| |/ _` |",
        " ___) |  __/ (_| | |_| | (_) | | (_| |",
        "|____/ \\___|\\__, |\\__,_|\\___/|_|\\__,_|",
        "               |_|                    ",
    ],
    "Sonoma": [
        " ____                                    ",
        "/ ___|  ___  _ __   ___  _ __ ___   __ _ ",
        "\\___ \\ / _ \\| '_ \\ / _ \\| '_ ` _ \\ / _` |",
        " ___) | (_) | | | | (_) | | | | | | (_| |",
        "|____/ \\___/|_| |_|\\___/|_| |_| |_|\\__,_|",
    ],
    "Ventura": [
        "__     __         _                   ",
        "\\ \\   / /__ _ __ | |_ _   _ _ __ __ _ ",
        " \\ \\ / / _ \\ '_ \\| __| | | | '__/ _` |",
        "  \\ V /  __/ | | | |_| |_| | | | (_| |",
        "   \\_/ \\___|_| |_|\\__|\\__,_|_|  \\__,_|",
    ],
    "Monterey": [
        " __  __             _                      ",
        "|  \\/  | ___  _ __ | |_ ___ _ __ ___ _   _ ",
        "| |\\/| |/ _ \\| '_ \\| __/ _ \\ '__/ _ \\ | | |",
        "| |  | | (_) | | | | ||  __/ | |  __/ |_| |",
        "|_|  |_|\\___/|_| |_|\\__\\___|_|  \\___|\\__, |",
        "                                     |___/ ",
    ],
    "Big Sur": [
        " ____  _         ____             ",
        "| __ )(_) __ _  / ___| _   _ _ __ ",
        "|  _ \\| |/ _` | \\___ \\| | | | '__|",
        "| |_) | | (_| |  ___) | |_| | |   ",
        "|____/|_|\\__, | |____/ \\__,_|_|   ",
        "         |___/                    ",
    ],
    "Catalina": [
        "  ____      _        _ _             ",
        " / ___|__ _| |_ __ _| (_)_ __   __ _ ",
        "| |   / _` | __/ _` | | | '_ \\ / _` |",
        "| |__| (_| | || (_| | | | | | | (_| |",
        " \\____\\__,_|\\__\\__,_|_|_|_| |_|\\__,_|",
    ],
    "Mojave": [
        " __  __       _                 ",
        "|  \\/  | ___ (_) __ ___   _____ ",
        "| |\\/| |/ _ \\| |/ _` \\ \\ / / _ \\",
        "| |  | | (_) | | (_| |\\ V /  __/",
        "|_|  |_|\\___// |\\__,_| \\_/ \\___|",
        "           |__/                 ",
    ],
    "macOS": [
        "                       ___  ____  ",
        " _ __ ___   __ _  ___ / _ \\/ ___| ",
        "| '_ ` _ \\ / _` |/ __| | | \\___ \\ ",
        "| | | | | | (_| | (__| |_| |___) |",
        "|_| |_| |_|\\__,_|\\___|\\___/|____/ ",
    ],
}

# ─────────────────────────────────────────────────────────────────────────────
#  Fetchers
# ─────────────────────────────────────────────────────────────────────────────


def _run(cmd: list) -> str:
    """Run a command, return stripped stdout or '' on any failure."""
    try:
        return subprocess.check_output(
            cmd, stderr=subprocess.DEVNULL, text=True
        ).strip()
    except (subprocess.CalledProcessError, FileNotFoundError, OSError):
        return ""


def get_user() -> str:
    try:
        return pwd.getpwuid(os.getuid()).pw_name
    except (KeyError, OSError):
        return os.environ.get("USER", "unknown")


def get_hostname() -> str:
    h = socket.gethostname()
    if h.endswith(".local"):
        h = h[:-len(".local")]
    return h


def get_macos_name() -> str:
    """Return the marketing name (e.g. 'Tahoe') or 'macOS' as fallback."""
    ver = platform.mac_ver()[0]
    if not ver:
        return "macOS"
    try:
        major = int(ver.split(".")[0])
        return MACOS_NAMES.get(major, "macOS")
    except (ValueError, IndexError):
        return "macOS"


def get_os() -> str:
    ver = platform.mac_ver()[0]
    if not ver:
        return "macOS"
    try:
        parts = ver.split(".")
        major = int(parts[0])
        minor = parts[1] if len(parts) > 1 else "0"
        name  = MACOS_NAMES.get(major, "")
        short = f"{major}.{minor}"
        return f"macOS {name} {short}" if name else f"macOS {short}"
    except (ValueError, IndexError):
        return f"macOS {ver}"


def get_kernel() -> str:
    return platform.uname().release


def get_uptime() -> str:
    raw = _run(["sysctl", "-n", "kern.boottime"])
    m = re.search(r"sec\s*=\s*(\d+)", raw)
    if not m:
        return "unknown"
    up = int(time.time()) - int(m.group(1))
    if up < 0:
        return "unknown"
    td = timedelta(seconds=up)
    h, rem = divmod(td.seconds, 3600)
    mins, _ = divmod(rem, 60)
    parts = []
    if td.days:
        parts.append(f"{td.days}d")
    if h:
        parts.append(f"{h}h")
    parts.append(f"{mins}m")
    return " ".join(parts)


def get_shell() -> str:
    s = os.environ.get("SHELL", "")
    return os.path.basename(s) if s else "unknown"


def get_packages() -> str:
    total = 0

    brew = _run(["brew", "list", "--formula"])
    if brew:
        total += len([l for l in brew.splitlines() if l.strip()])

    ports = _run(["port", "installed"])
    if ports:
        total += len([
            l for l in ports.splitlines()
            if l.strip() and not l.lower().startswith("the")
        ])

    return str(total)


def get_memory() -> str:
    mem_raw = _run(["sysctl", "-n", "hw.memsize"])
    if not mem_raw.isdigit():
        return "unknown"
    total_mib = int(mem_raw) // (1024 * 1024)

    vm = _run(["vm_stat"])
    if not vm:
        return f"? | {total_mib} MiB"

    ps_m = re.search(r"page size of (\d+) bytes", vm)
    page_size = int(ps_m.group(1)) if ps_m else 4096

    def pages(key: str) -> int:
        m = re.search(rf"{re.escape(key)}:\s+(\d+)\.", vm)
        return int(m.group(1)) if m else 0

    used_pages = (
        pages("Pages wired down")
        + pages("Pages active")
        + pages("Pages occupied by compressor")
    )
    used_mib = used_pages * page_size // (1024 * 1024)
    return f"{used_mib} | {total_mib} MiB"


# ─────────────────────────────────────────────────────────────────────────────
#  Drawing
# ─────────────────────────────────────────────────────────────────────────────

def color_dots() -> str:
    """Colored circle dots like nitch."""
    dot_colors = [fg(7), fg(203), fg(215), fg(114), fg(74), fg(74), fg(141), fg(246)]
    return "  ".join(f"{c}\u25cf{RESET}" for c in dot_colors)


def get_logo_lines() -> list:
    """ASCII art for the current macOS version, normalized to equal width."""
    name = get_macos_name()
    art  = MACOS_ART.get(name, MACOS_ART["macOS"])
    width = max(len(l) for l in art)
    return [l.ljust(width) for l in art]


def draw(nerd: bool = True) -> None:
    icons = NERD if nerd else PLAIN
    B = C_BORDER
    R = RESET

    # Inner box width = lead space(1) + icon cell(2) + label(6) + trail space(1)
    LABEL_W = 6
    W = 1 + 2 + LABEL_W + 1   # = 10, matches the row content exactly

    rows = [
        (icons["user"],   "user",   get_user()),
        (icons["host"],   "hname",  get_hostname()),
        (icons["os"],     "os",     get_os()),
        (icons["kernel"], "kernel", get_kernel()),
        (icons["uptime"], "uptime", get_uptime()),
        (icons["shell"],  "shell",  get_shell()),
        (icons["pkgs"],   "pkgs",   get_packages()),
        (icons["mem"],    "memory", get_memory()),
    ]

    # ── Version-name ASCII art on TOP (left-aligned, like original nitch) ──────
    for line in get_logo_lines():
        stripped = line.rstrip()
        if stripped:
            print(f"{C_LOGO}{stripped}{R}")
        else:
            print()
    print()   # gap between logo and box

    # ── Boxed info block ──────────────────────────────────────────────────────
    hline = "\u2500" * W
    print(f"{B}\u256d{hline}\u256e{R}")                     # ╭───╮
    for i, (icon, label, value) in enumerate(rows):
        color   = ROW_COLORS[i] if i < len(ROW_COLORS) else R
        icon_s  = f"{C_ICON}{icon}{R}"
        label_s = f"{C_LABEL}{label:<{LABEL_W}}{R}"
        val_s   = f"{color}{value}{R}"
        print(f"{B}\u2502{R} {icon_s}{label_s} {B}\u2502{R} {val_s}")
    print(f"{B}\u251c{hline}\u2524{R}")                     # ├───┤
    icon_s  = f"{C_ICON}{icons['colors']}{R}"
    label_s = f"{C_LABEL}{'colors':<{LABEL_W}}{R}"
    print(f"{B}\u2502{R} {icon_s}{label_s} {B}\u2502{R} {color_dots()}")
    print(f"{B}\u2570{hline}\u256f{R}")                     # ╰───╯

# ─────────────────────────────────────────────────────────────────────────────
#  Entry
# ─────────────────────────────────────────────────────────────────────────────

HELP = f"""\
nitch-mac v{VERSION} — system fetch for macOS

Flags:
  -f, --fetch     show system info (default)
  --no-nerd       plain ASCII icons
  -v, --version   print version
  -h, --help      this help
"""


def main() -> None:
    nerd = True
    for arg in sys.argv[1:]:
        if arg in ("-h", "--help"):
            print(HELP)
            return
        if arg in ("-v", "--version"):
            print(f"nitch-mac v{VERSION}")
            return
        if arg == "--no-nerd":
            nerd = False
        elif arg not in ("-f", "--fetch"):
            print(f"Unknown flag: {arg}\nUse --help.", file=sys.stderr)
            sys.exit(1)
    draw(nerd=nerd)


if __name__ == "__main__":
    main()
