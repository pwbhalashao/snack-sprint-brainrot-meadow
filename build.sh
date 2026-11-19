#!/bin/sh
# Build the place file. Run on a Windows/Mac computer with Rojo 7.7.
#   rojo build default.project.json --output game.rbxl
# (Rojo is not installed on the Linux VM where this repo was written.)
set -e
cd "$(dirname "$0")"
if ! command -v rojo >/dev/null 2>&1; then
  echo "rojo not found. Install Rojo 7.7 (rokit add rojo-rbx/rojo && rokit install,"
  echo "or the prebuilt binary from https://github.com/rojo-rbx/rojo/releases)."
  exit 1
fi
rojo build default.project.json --output game.rbxl
ls -lh game.rbxl
