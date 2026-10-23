#!/usr/bin/env python3
"""Create this case's v2.3.4 installer adaptation; never execute the installer.

Upstream: https://github.com/nullmoth/nvidia-macos-driver/releases/tag/v2.3.4
Only four direct nvram deletions are omitted. Keep the package and its license from upstream.
The upstream fallback mechanism is consequently not identical. Read scripts/README.md.
"""
from pathlib import Path
import sys

src = Path(sys.argv[1])
text = src.read_text(encoding="utf-8")
commands = ['nvram -d 7C436110-AB2A-4BBB-A880-FE41995C9F82:nullmoth-remove 2>/dev/null || true\n', 'nvram -d 7C436110-AB2A-4BBB-A880-FE41995C9F82:nullmoth-nv-starts 2>/dev/null || true\n', 'nvram -d 7C436110-AB2A-4BBB-A880-FE41995C9F82:nullmoth-nv-ok 2>/dev/null || true\n', 'nvram -d \\$V:nullmoth-nv-starts 2>/dev/null\n']
for command in commands:
    if text.count(command) != 1:
        raise SystemExit("Expected v2.3.4 command not found exactly once. No output written.")
for command in commands:
    text = text.replace(command, "# Omitted firmware variable write for this machine.\n", 1)
dst = src.with_name("install.no-nvram.sh")
dst.write_text(text, encoding="utf-8", newline="\n")
print("Created", dst)
print("No driver installed and no NVRAM command executed.")
