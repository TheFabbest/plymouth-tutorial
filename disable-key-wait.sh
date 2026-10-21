#!/usr/bin/env bash
# Remove the key-press wait added by enable-key-wait.sh.
# Also removes the unit created by older versions of these scripts.

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (using sudo)."
  exit 1
fi

UNIT_DIR="${UNIT_DIR:-/etc/systemd/system}"
removed=0

for UNIT_NAME in plymouth-key-wait.service plymouth-wait-for-animation.service; do
  SERVICE_FILE="$UNIT_DIR/$UNIT_NAME"
  if [ -f "$SERVICE_FILE" ]; then
    echo "Disabling $UNIT_NAME..."
    systemctl disable "$UNIT_NAME"

    echo "Removing $SERVICE_FILE..."
    rm -f "$SERVICE_FILE"
    removed=1
  fi
done

if [ "$removed" -eq 1 ]; then
  echo "Reloading systemd daemon..."
  systemctl daemon-reload
  echo "Success! The key-press block has been removed."
else
  echo "No key-press boot block service found. Nothing to remove."
fi