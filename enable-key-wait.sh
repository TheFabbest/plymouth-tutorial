#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (using sudo)."
  exit 1
fi

SERVICE_FILE="/etc/systemd/system/plymouth-wait-for-animation.service"

echo "Creating systemd service file..."

# This script tells bash to read single characters.
# If the user presses 'Enter', the variable $REPLY will be completely empty "".
# If you wanted a different key, like the letter 'g', you would change it to:
# while [ "$REPLY" != "g" ]; do ...
cat << 'EOF' > "$SERVICE_FILE"
[Unit]
Description=Hold Plymouth boot until Enter is pressed
Before=plymouth-quit.service display-manager.service

[Service]
Type=oneshot
StandardInput=tty-force
TTYPath=/dev/tty1
ExecStart=/usr/bin/bash -c 'while true; do read -n 1 -s -r; if [ -z "$REPLY" ]; then break; fi; done'

[Install]
WantedBy=plymouth-start.service
EOF

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling wait service..."
systemctl enable plymouth-wait-for-animation.service

echo "Success! The boot process will now pause during the animation until you press ENTER."