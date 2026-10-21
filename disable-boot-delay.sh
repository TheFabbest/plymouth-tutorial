#!/usr/bin/env bash
# Remove the boot delay added by enable-boot-delay.sh.
# Also removes the unit created by older versions of these scripts.

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (using sudo)."
  exit 1
fi

UNIT_DIR="${UNIT_DIR:-/etc/systemd/system}"
removed=0

for UNIT_NAME in plymouth-boot-delay.service plymouth-wait-for-animation.service; do
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
  echo "Success! The boot delay has been removed."
else
  echo "No boot delay service found. Nothing to remove."
fi