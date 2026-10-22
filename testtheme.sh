#!/usr/bin/env bash
# =============================================================================
# Plymouth theme quick test: shows the splash for a few seconds.
#
# Usage: ./testtheme.sh [--keep] <theme-name> [seconds]   (default: 5 seconds)
#   Run as a normal user; the script asks for sudo itself.
#   --keep  leave the theme installed and selected as default afterwards.
#
# The previous default theme is restored on exit unless --keep is given.
# =============================================================================
set -u
# shellcheck source=lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

usage() { echo "Usage: $0 [--keep] <theme-name> [seconds]"; }

ARGS=()
for a in "$@"; do
    case "$a" in
        --keep) KEEP=1 ;;
        -h|--help) usage; exit 0 ;;
        *) ARGS+=("$a") ;;
    esac
done
{ [ "${#ARGS[@]}" -ge 1 ] && [ "${#ARGS[@]}" -le 2 ]; } || { usage >&2; exit 1; }

SECONDS_TO_SHOW="${ARGS[1]:-5}"
[[ "$SECONDS_TO_SHOW" =~ ^[0-9]+$ ]] || die "seconds must be a whole number, got '$SECONDS_TO_SHOW'."

ply_need_root "$@"
ply_check_tools
ply_select_theme "${ARGS[0]}"

ply_install_theme
ply_start_daemon ""
plymouth show-splash
sleep "$SECONDS_TO_SHOW"
plymouth quit
