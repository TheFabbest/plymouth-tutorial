#!/usr/bin/env bash
# Hold the boot on the splash screen until Enter is pressed on tty1.
# Usage: sudo ./enable-key-wait.sh [timeout-seconds]
#   timeout-seconds  boot continues on its own after this long (default: 60).
#                    Use 0 to wait forever (dangerous on headless machines).
# Undo:  sudo ./disable-key-wait.sh

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (using sudo)."
  exit 1
fi

UNIT_NAME="plymouth-key-wait.service"
LEGACY_UNIT="plymouth-wait-for-animation.service"
UNIT_DIR="${UNIT_DIR:-/etc/systemd/system}"
SERVICE_FILE="$UNIT_DIR/$UNIT_NAME"

if [ -f "$UNIT_DIR/$LEGACY_UNIT" ]; then
  echo "A unit from an older version of these scripts exists ($LEGACY_UNIT)."
  echo "Run ./disable-key-wait.sh first to remove it, then try again."
  exit 1
fi

TIMEOUT="${1:-60}"
if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]]; then
  echo "Error: timeout must be a whole number of seconds (0 = wait forever)."
  exit 1
fi

if [ "$TIMEOUT" -eq 0 ]; then
  echo "WARNING: no timeout. If nobody presses Enter on tty1, this machine will never finish booting."
  read -r -p "Type 'yes' to continue: " answer
  [ "$answer" = "yes" ] || { echo "Aborted."; exit 1; }
  READ_OPTS="-n 1 -s -r"
else
  READ_OPTS="-n 1 -s -r -t $TIMEOUT"
fi

[ -c /dev/tty1 ] || echo "Note: /dev/tty1 does not exist here; the unit reads its key from tty1 at boot."

BASH_BIN="$(command -v bash)"

echo "Creating systemd service file..."
# Notes on the ExecStart line:
# - Enter produces an empty value for the variable, so an empty value means "Enter".
# - To wait for a different key, change the test, e.g. [ "\$\$key" = "g" ].
# - systemd treats a single $ specially, so the shell variable is written as $$key.
# - read failing (timeout or end of input) also ends the wait.
cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Hold Plymouth boot until Enter is pressed
Before=plymouth-quit.service display-manager.service

[Service]
Type=oneshot
StandardInput=tty-force
TTYPath=/dev/tty1
TimeoutStartSec=infinity
ExecStart=$BASH_BIN -c 'while true; do read $READ_OPTS key || break; if [ -z "\$\$key" ]; then break; fi; done'

[Install]
WantedBy=plymouth-start.service
EOF

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling $UNIT_NAME..."
systemctl enable "$UNIT_NAME"

if [ "$TIMEOUT" -eq 0 ]; then
  echo "Success! Boot will pause on the splash until you press ENTER on tty1."
else
  echo "Success! Boot will pause on the splash until you press ENTER on tty1 (or $TIMEOUT seconds pass)."
fi
echo "Undo with: sudo ./disable-key-wait.sh"