#!/usr/bin/env bash
# Keep the boot splash on screen for at least N seconds.
# Usage: sudo ./enable-boot-delay.sh [seconds]
# Undo:  sudo ./disable-boot-delay.sh

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (using sudo)."
  exit 1
fi

UNIT_NAME="plymouth-boot-delay.service"
LEGACY_UNIT="plymouth-wait-for-animation.service"
UNIT_DIR="${UNIT_DIR:-/etc/systemd/system}"
SERVICE_FILE="$UNIT_DIR/$UNIT_NAME"

if [ -f "$UNIT_DIR/$LEGACY_UNIT" ]; then
  echo "A unit from an older version of these scripts exists ($LEGACY_UNIT)."
  echo "Run ./disable-boot-delay.sh first to remove it, then try again."
  exit 1
fi

DELAY_SECONDS="${1:-}"
if [ -z "$DELAY_SECONDS" ]; then
  read -r -p "Enter the number of seconds the animation should stay on screen: " DELAY_SECONDS
fi

if ! [[ "$DELAY_SECONDS" =~ ^[0-9]+$ ]] || [ "$DELAY_SECONDS" -lt 1 ]; then
  echo "Error: please enter a whole number of seconds (1 or more)."
  exit 1
fi
if [ "$DELAY_SECONDS" -gt 300 ]; then
  echo "Error: refusing delays over 300 seconds (a mistyped value would stall every boot)."
  exit 1
fi

SLEEP_BIN="$(command -v sleep)"

echo "Creating systemd service file..."
cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Keep Plymouth animation on screen for $DELAY_SECONDS seconds
Before=plymouth-quit.service display-manager.service

[Service]
Type=oneshot
ExecStart=$SLEEP_BIN $DELAY_SECONDS

[Install]
WantedBy=plymouth-start.service
EOF

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling $UNIT_NAME..."
systemctl enable "$UNIT_NAME"

echo "Success! The delay starts once early boot reaches this unit, so the splash"
echo "stays up for roughly $DELAY_SECONDS seconds before Plymouth quits."
echo "Undo with: sudo ./disable-boot-delay.sh"