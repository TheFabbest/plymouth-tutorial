#!/usr/bin/env bash
# Holds the boot on the Plymouth splash until Enter is pressed on the main console
# (tty1), or until a timeout expires so the machine can never hang forever.
# Usage: sudo ./enable-key-wait.sh [timeout_seconds]   (default: 60)
# Undo:  sudo ./disable-key-wait.sh
# Emergency undo: add  systemd.mask=plymouth-key-wait.service  to the kernel command line.

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (using sudo)."
  exit 1
fi

UNIT="plymouth-key-wait.service"
SERVICE_FILE="/etc/systemd/system/$UNIT"

TIMEOUT="${1:-60}"
if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]] || [ "$TIMEOUT" -lt 1 ] || [ "$TIMEOUT" -gt 3600 ]; then
  echo "Error: timeout must be a whole number of seconds between 1 and 3600."
  exit 1
fi

echo "Creating systemd service file..."
# Reads single characters from tty1; an empty $REPLY means Enter was pressed.
# To wait for another key, e.g. 'g', change the test to: [ "$REPLY" = "g" ]
# If nobody presses Enter, systemd stops the unit after TimeoutStartSec and boot continues.
cat << EOF2 > "$SERVICE_FILE"
[Unit]
Description=Hold Plymouth boot until Enter is pressed (timeout ${TIMEOUT}s)
DefaultDependencies=no
After=plymouth-start.service
Before=plymouth-quit.service plymouth-quit-wait.service display-manager.service
Conflicts=shutdown.target
Before=shutdown.target
ConditionPathExists=/dev/tty1

[Service]
Type=oneshot
StandardInput=tty-force
TTYPath=/dev/tty1
TimeoutStartSec=$TIMEOUT
ExecStart=/usr/bin/bash -c 'while true; do read -n 1 -s -r; if [ -z "\$REPLY" ]; then break; fi; done'

[Install]
WantedBy=plymouth-start.service
EOF2

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling $UNIT..."
systemctl enable "$UNIT"

echo "Success! Boot will now pause on the splash until you press ENTER (or $TIMEOUT s pass)."
echo "Undo with: sudo ./disable-key-wait.sh"
