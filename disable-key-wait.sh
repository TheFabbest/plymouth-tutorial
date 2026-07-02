#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (using sudo)."
  exit 1
fi

SERVICE_FILE="/etc/systemd/system/plymouth-wait-for-animation.service"

if [ -f "$SERVICE_FILE" ]; then
  echo "Disabling service..."
  systemctl disable plymouth-wait-for-animation.service
  
  echo "Removing service file..."
  rm "$SERVICE_FILE"
  
  echo "Reloading systemd daemon..."
  systemctl daemon-reload
  
  echo "Success! The key-press block has been removed."
else
  echo "No active key-press boot block service found."
fi