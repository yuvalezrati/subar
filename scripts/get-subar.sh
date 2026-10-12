#!/bin/bash
# Installs the latest Subar release into Applications and opens it:
#
#   curl -fsSL https://raw.githubusercontent.com/yuvalezrati/subar/main/scripts/get-subar.sh | bash
#
# Run it again any time to update. You stay signed in.
set -euo pipefail

REPO="${SUBAR_REPO:-yuvalezrati/subar}"
URL="https://github.com/$REPO/releases/latest/download/Subar.zip"

# Everything runs from main, so a download that's cut off halfway does nothing.
main() {
  if [[ "$(uname)" != "Darwin" ]]; then
    echo "Subar only runs on macOS."
    exit 1
  fi
  if [[ "$(sw_vers -productVersion | cut -d. -f1)" -lt 12 ]]; then
    echo "Subar needs macOS 12 or later."
    exit 1
  fi

  local tmp dest
  tmp="$(mktemp -d)"
  trap "rm -rf '$tmp'" EXIT

  echo "Downloading Subar…"
  if ! curl -fsSL "$URL" -o "$tmp/Subar.zip"; then
    echo "Couldn't download $URL"
    exit 1
  fi
  ditto -x -k "$tmp/Subar.zip" "$tmp"
  if ! codesign --verify --strict "$tmp/Subar.app" 2>/dev/null; then
    echo "The download looks damaged. Please try again."
    exit 1
  fi

  dest="/Applications"
  if [[ ! -w "$dest" ]]; then
    dest="$HOME/Applications"
    mkdir -p "$dest"
  fi

  # Quit a running copy before replacing it
  pkill -x Subar 2>/dev/null || true
  rm -rf "$dest/Subar.app"
  ditto "$tmp/Subar.app" "$dest/Subar.app"

  open "$dest/Subar.app"
  echo "Subar is installed in $dest and running. Look for it in the menu bar."
}

main "$@"
