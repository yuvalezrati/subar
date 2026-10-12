#!/bin/bash
# Builds Subar and (re)starts it. Safe to run any time:
#   first run   -> builds, installs, starts at login, opens the Dexcom sign-in panel
#   later runs  -> rebuilds and restarts the running app in place
#
#   ./scripts/dev-install.sh             build + install/update
#   ./scripts/dev-install.sh uninstall   stop it and remove the app (settings and Keychain item are kept)
set -euo pipefail
cd "$(dirname "$0")/.."

LABEL="local.subar"
BIN_DIR="$HOME/Applications/Subar"
BIN="$BIN_DIR/Subar"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/Library/Logs/Subar.log"
DOMAIN="gui/$(id -u)"

# The app was called GlucoseBar before; remove that install so only one runs.
remove_legacy() {
  local old="local.glucosebar"
  if launchctl print "$DOMAIN/$old" >/dev/null 2>&1 || [[ -e "$HOME/Library/LaunchAgents/$old.plist" ]]; then
    launchctl bootout "$DOMAIN/$old" 2>/dev/null || true
    pkill -x GlucoseBar 2>/dev/null || true
    rm -f "$HOME/Library/LaunchAgents/$old.plist"
    rm -rf "$HOME/Applications/GlucoseBar"
    echo "Removed the old GlucoseBar install (your settings carry over)."
  fi
}

if [[ "${1:-}" == "uninstall" ]]; then
  launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
  pkill -x Subar 2>/dev/null || true
  rm -f "$PLIST"
  rm -rf "$BIN_DIR"
  remove_legacy
  echo "Subar removed. Settings kept in ~/Library/Application Support/Subar/"
  exit 0
fi

if ! command -v swiftc >/dev/null; then
  echo "swiftc not found. Install the command-line tools with: xcode-select --install"
  exit 1
fi

echo "Building Subar…"
mkdir -p "$BIN_DIR"
# Build to a temp file first, so a failed build never replaces the working app.
swiftc -O -parse-as-library subar.swift -o "$BIN.new"
mv -f "$BIN.new" "$BIN"

remove_legacy

if [[ ! -f "$PLIST" ]]; then
  mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
  cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BIN</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <!-- Restart after a crash, but not after you choose "Quit" from the menu -->
  <key>KeepAlive</key>
  <dict>
    <key>SuccessfulExit</key>
    <false/>
  </dict>
  <key>LimitLoadToSessionType</key>
  <string>Aqua</string>
  <key>ProcessType</key>
  <string>Interactive</string>
  <key>StandardErrorPath</key>
  <string>$LOG</string>
</dict>
</plist>
EOF
fi

if launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then
  launchctl kickstart -k "$DOMAIN/$LABEL"
  echo "Updated and restarted."
else
  launchctl bootstrap "$DOMAIN" "$PLIST"
  echo "Installed. Subar will start at login."
  echo "If you're not signed in yet, a Dexcom sign-in panel opens under the menu bar item."
fi
