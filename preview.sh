#!/usr/bin/env bash
# =============================================================================
# Plymouth theme full preview: simulates a boot (messages, progress, a password
# prompt) for a theme from ./themes.
#
# Usage: ./preview.sh [--keep] <theme-name>
#   Run as a normal user; the script asks for sudo itself.
#   --keep  leave the theme installed and selected as default afterwards.
#
# The previous default theme is restored on exit unless --keep is given.
# =============================================================================
set -u
# shellcheck source=lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

usage() { echo "Usage: $0 [--keep] <theme-name>"; }

ARGS=()
for a in "$@"; do
    case "$a" in
        --keep) KEEP=1 ;;
        -h|--help) usage; exit 0 ;;
        *) ARGS+=("$a") ;;
    esac
done
[ "${#ARGS[@]}" -eq 1 ] || { usage >&2; exit 1; }

ply_need_root "$@"
ply_check_tools
ply_select_theme "${ARGS[0]}"

LOG_FILE=/tmp/plymouth-preview.log
: > "$LOG_FILE"; chmod 644 "$LOG_FILE"

echo "Theme directory : $THEME_SRC"
echo "Installing to   : $THEME_DST"
ply_install_theme
ply_start_daemon "$LOG_FILE"
plymouth show-splash
sleep 0.5

send_progress() { plymouth system-update --progress="$1"; }

# ---- Phase 1: early boot (0-30%) --------------------------------------------
plymouth message --text="Starting early boot services..."
sleep 0.3
for pct in 5 10 15 20 25 30; do send_progress "$pct"; sleep 0.2; done
plymouth message --text="Encrypted volume found..."
sleep 0.4

# ---- Phase 2: password prompt -------------------------------------------------
# This triggers the theme's password callback. The prompt is cancelled after a
# couple of seconds and its output discarded; never type a real passphrase here.
plymouth ask-for-password --prompt="Enter passphrase for /dev/sda2:" >/dev/null 2>&1 &
ask_pid=$!
sleep 2
kill "$ask_pid" 2>/dev/null || true
wait "$ask_pid" 2>/dev/null || true
sleep 0.3
plymouth message --text="Passphrase accepted. Mounting volumes..."
sleep 0.3

# ---- Phase 3: post-password progress (40-100%) ---------------------------------
for pct in 40 50 60; do send_progress "$pct"; sleep 0.2; done
plymouth message --text="Mounting /home..."
sleep 0.3
plymouth hide-message --text="Mounting /home..."
for pct in 70 80 90 100; do send_progress "$pct"; sleep 0.2; done
plymouth message --text="Boot complete."
sleep 0.5

plymouth quit
sleep 0.3

echo ""
echo "=== Plymouth debug log: problems (full log: $LOG_FILE) ==="
grep -iE "error|fail|cannot|warn" "$LOG_FILE" | head -30 || true
echo "(end)"
