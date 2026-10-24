#!/usr/bin/env bash
# Removes the key-press block service installed by enable-key-wait.sh.
# Usage: sudo ./disable-key-wait.sh

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (using sudo)."
  exit 1
fi

UNIT="plymouth-key-wait.service"

remove_unit() {
  local unit="$1" file="/etc/systemd/system/$1"
  echo "Disabling $unit..."
  systemctl disable "$unit" 2>/dev/null || true
  echo "Removing $file..."
  rm -f "$file"
}

found=0
if [ -f "/etc/systemd/system/$UNIT" ]; then
  remove_unit "$UNIT"
  found=1
fi

if [ "$found" -eq 1 ]; then
  echo "Reloading systemd daemon..."
  systemctl daemon-reload
  echo "Success! The key-press block has been removed."
else
  echo "No key-press block service found. Nothing to remove."
fi
