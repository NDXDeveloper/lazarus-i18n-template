#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# copy-locale.sh — copy the locale/ folder next to a built executable.
#
# This template builds the executable into the project root, where locale/
# already lives, so for plain local development you do NOT need this script.
# It is useful when you change the project's output directory (e.g. to
# bin/<target>/) and therefore need the .lang files copied beside the binary.
#
# Wire it as a Lazarus post-build step (Project ▸ Options ▸ Compiler Options ▸
# Execute After ▸ Command):
#     $ProjPath()/scripts/copy-locale.sh $ProjPath()/bin/$(TargetCPU)-$(TargetOS)
# On Windows use the matching scripts/copy-locale.cmd (see docs/localization.md).
#
# Usage:
#   scripts/copy-locale.sh <output-directory>
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/../locale"

if [ "$#" -lt 1 ]; then
  echo "usage: $(basename "$0") <output-directory>" >&2
  exit 2
fi

DEST_DIR="$1/locale"
mkdir -p "$DEST_DIR"
cp -f "$SRC_DIR"/*.lang "$DEST_DIR"/
echo "Copied $(ls -1 "$SRC_DIR"/*.lang | wc -l) language file(s) to $DEST_DIR"
