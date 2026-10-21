#!/usr/bin/env bash
# Fast smoke test: show a theme for a fixed number of seconds.
#
# Usage: ./testtheme.sh [--keep] <theme-name> [seconds]   (default: 5 seconds)
#
# Restores your previous default theme afterwards.
# Do not run with sudo: the script calls sudo itself where needed.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

usage() {
  echo "Usage: $0 [--keep] <theme-name> [seconds]"
  echo "  --keep   leave the theme installed and set as default afterwards"
}

THEME_ARG=""
SECONDS_ARG=5
positional=0
for arg in "$@"; do
  case "$arg" in
    --keep) KEEP=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) usage; die "Unknown option '$arg'." ;;
    *)
      positional=$((positional + 1))
      if [ "$positional" -eq 1 ]; then THEME_ARG="$arg"; else SECONDS_ARG="$arg"; fi
      ;;
  esac
done

[[ $SECONDS_ARG =~ ^[1-9][0-9]*$ ]] || die "Duration must be a positive whole number of seconds."

need_cmd plymouth
need_cmd plymouthd
need_cmd plymouth-set-default-theme
select_theme "$THEME_ARG"

arm_cleanup
install_theme
# No initramfs rebuild is needed just for previewing.
start_daemon
sleep "$SECONDS_ARG"
stop_daemon
echo "Done. Debug log: $LOG_FILE"