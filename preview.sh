#!/usr/bin/env bash
# =============================================================================
# Plymouth theme full preview (simulated boot flow).
# Run from anywhere; themes are looked up relative to this script.
#
# Usage: ./preview.sh [--keep] <theme-name>
#
# Installs the theme, runs a boot-like sequence (messages, progress, a fake
# password prompt) and then restores your previous default theme.
# Do not run with sudo: the script calls sudo itself where needed.
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

usage() {
  echo "Usage: $0 [--keep] <theme-name>"
  echo "  --keep   leave the theme installed and set as default afterwards"
}

THEME_ARG=""
for arg in "$@"; do
  case "$arg" in
    --keep) KEEP=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) usage; die "Unknown option '$arg'." ;;
    *) THEME_ARG="$arg" ;;
  esac
done

need_cmd plymouth
need_cmd plymouthd
need_cmd plymouth-set-default-theme
select_theme "$THEME_ARG"

echo "Theme directory : $THEME_SRC"
echo "Theme name      : $THEME_NAME"
echo "Installing to   : $THEME_DST"
echo "Debug log       : $LOG_FILE"

arm_cleanup
install_theme
start_daemon

# Send a boot progress value (integer 0-100).
send_progress() {
  $SUDO plymouth system-update --progress="$1"
}

# ---- Phase 1: early boot (0% -> 30%) ----------------------------------------
$SUDO plymouth message --text="Starting early boot services..."
sleep 0.3
for pct in 5 10 15 20 25 30; do
  send_progress "$pct"
  sleep 0.2
done
$SUDO plymouth message --text="Encrypted volume found..."
sleep 0.4

# ---- Phase 2: password prompt -----------------------------------------------
# This triggers the theme's password callback. We show it for two seconds and
# then cancel it. Do not type a real passphrase: the answer is written to a
# temporary file (removed afterwards).
pw_out="$(mktemp)"
$SUDO plymouth ask-for-password --prompt="Enter passphrase for /dev/sda2:" >"$pw_out" &
ask_pid=$!
sleep 2
$SUDO kill "$ask_pid" 2>/dev/null
wait "$ask_pid" 2>/dev/null
rm -f "$pw_out"
sleep 0.3

$SUDO plymouth message --text="Passphrase accepted. Mounting volumes..."
sleep 0.3

# ---- Phase 3: post-password progress (30% -> 100%) --------------------------
for pct in 40 50 60; do
  send_progress "$pct"
  sleep 0.2
done
$SUDO plymouth message --text="Mounting /home..."
sleep 0.3
$SUDO plymouth hide-message --text="Mounting /home..."
for pct in 70 80 90 100; do
  send_progress "$pct"
  sleep 0.2
done
$SUDO plymouth message --text="Boot complete."
sleep 0.5

# ---- Quit and summarize -----------------------------------------------------
stop_daemon

echo
echo "=== Plymouth debug log (errors and warnings, first 30 lines) ==="
if [ -f "$LOG_FILE" ]; then
  grep -iE "error|failed|cannot|warning" "$LOG_FILE" | head -30
  echo "(full log: $LOG_FILE)"
else
  echo "Log file not found."
fi