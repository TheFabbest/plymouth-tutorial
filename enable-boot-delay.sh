#!/usr/bin/env bash
# Keeps the Plymouth splash on screen for at least N seconds after Plymouth starts.
# Usage: sudo ./enable-boot-delay.sh [seconds]
# Undo:  sudo ./disable-boot-delay.sh

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (using sudo)."
  exit 1
fi

UNIT="plymouth-boot-delay.service"
SERVICE_FILE="/etc/systemd/system/$UNIT"

DELAY_SECONDS="${1:-}"
if [ -z "$DELAY_SECONDS" ]; then
  read -r -p "Enter the number of seconds you want the animation to play: " DELAY_SECONDS
fi

# Whole number between 1 and 600
if ! [[ "$DELAY_SECONDS" =~ ^[0-9]+$ ]] || [ "$DELAY_SECONDS" -lt 1 ] || [ "$DELAY_SECONDS" -gt 600 ]; then
  echo "Error: please enter a whole number of seconds between 1 and 600."
  exit 1
fi

echo "Creating systemd service file..."
cat << EOF2 > "$SERVICE_FILE"
[Unit]
Description=Keep the Plymouth splash on screen for $DELAY_SECONDS seconds
DefaultDependencies=no
After=plymouth-start.service
Before=plymouth-quit.service plymouth-quit-wait.service display-manager.service
Conflicts=shutdown.target
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=/usr/bin/sleep $DELAY_SECONDS

[Install]
WantedBy=plymouth-start.service
EOF2

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling $UNIT..."
systemctl enable "$UNIT"

echo "Success! The splash will now stay on screen for about $DELAY_SECONDS seconds"
echo "(counted from when Plymouth starts). Undo with: sudo ./disable-boot-delay.sh"
