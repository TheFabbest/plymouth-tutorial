#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (using sudo)."
  exit 1
fi

# Ask the user for the desired duration
read -p "Enter the number of seconds you want the animation to play: " DELAY_SECONDS

# Validate that the input is a number
if ! [[ "$DELAY_SECONDS" =~ ^[0-9]+$ ]]; then
  echo "Error: Please enter a valid whole number."
  exit 1
fi

SERVICE_FILE="/etc/systemd/system/plymouth-wait-for-animation.service"

echo "Creating systemd service file..."

# Write the service file
cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Waits for Plymouth animation to finish
Before=plymouth-quit.service display-manager.service

[Service]
Type=oneshot
ExecStart=/usr/bin/sleep $DELAY_SECONDS

[Install]
WantedBy=plymouth-start.service
EOF

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling plymouth-wait-for-animation.service..."
systemctl enable plymouth-wait-for-animation.service

echo "Success! Your boot animation will now stay on screen for at least $DELAY_SECONDS seconds."