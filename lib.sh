#!/usr/bin/env bash
# Shared helpers for preview.sh and testtheme.sh.
# Source this file; do not run it directly.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLY_THEMES_DIR="${PLY_THEMES_DIR:-/usr/share/plymouth/themes}"
LOG_FILE="${LOG_FILE:-/tmp/plymouth-debug.log}"

if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

KEEP=0
THEME_NAME=""
THEME_SRC=""
THEME_DST=""
PREV_THEME=""
BACKUP_DIR=""
INSTALLED=0
DAEMON_PID=""

die() {
  echo "Error: $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "'$1' not found. Install Plymouth first (see README, Prerequisites)."
}

list_themes() {
  echo "Available themes:" >&2
  for d in "$REPO_DIR"/themes/*/; do
    [ -d "$d" ] && echo "  $(basename "$d")" >&2
  done
}

# Validate the theme name and set THEME_* variables.
select_theme() {
  local name="${1:-}"
  [ -n "$name" ] || { list_themes; die "No theme name given."; }
  [[ $name =~ ^[A-Za-z0-9_][A-Za-z0-9._-]*$ ]] || die "Invalid theme name '$name'."
  THEME_SRC="$REPO_DIR/themes/$name"
  [ -d "$THEME_SRC" ] || { list_themes; die "Theme '$name' not found in themes/."; }
  [ -f "$THEME_SRC/$name.plymouth" ] || die "Expected $THEME_SRC/$name.plymouth (the .plymouth file must be named after the theme folder)."
  THEME_NAME="$name"
  THEME_DST="$PLY_THEMES_DIR/$name"
}

# Copy the theme into the system theme directory and make it the default.
# Anything that gets replaced is remembered so cleanup can undo it.
install_theme() {
  PREV_THEME="$($SUDO plymouth-set-default-theme 2>/dev/null || true)"

  if [ -e "$THEME_DST" ]; then
    BACKUP_DIR="$THEME_DST.preview-backup"
    $SUDO rm -rf "$BACKUP_DIR"
    $SUDO mv "$THEME_DST" "$BACKUP_DIR" || die "Could not back up existing $THEME_DST."
  fi

  $SUDO cp -r "$THEME_SRC" "$THEME_DST" || die "Could not copy theme to $THEME_DST."
  INSTALLED=1
  $SUDO plymouth-set-default-theme "$THEME_NAME" || die "plymouth-set-default-theme failed."
}

start_daemon() {
  $SUDO pkill -x plymouthd 2>/dev/null
  sleep 0.3
  $SUDO plymouthd --no-daemon --debug --debug-file="$LOG_FILE" &
  DAEMON_PID=$!
  sleep 1
  pgrep -x plymouthd >/dev/null || die "plymouthd did not start. Check $LOG_FILE."
  $SUDO plymouth show-splash
}

stop_daemon() {
  if pgrep -x plymouthd >/dev/null 2>&1; then
    $SUDO plymouth quit 2>/dev/null
    sleep 0.3
    $SUDO pkill -x plymouthd 2>/dev/null
  fi
  if [ -n "$DAEMON_PID" ]; then
    wait "$DAEMON_PID" 2>/dev/null
    DAEMON_PID=""
  fi
}

# Runs on exit, Ctrl+C and termination: stop the daemon and undo the install.
cleanup() {
  trap - EXIT INT TERM
  stop_daemon

  [ "$INSTALLED" -eq 1 ] || return 0

  if [ "$KEEP" -eq 1 ]; then
    echo "Keeping theme '$THEME_NAME' installed and set as default (--keep)."
    [ -n "$BACKUP_DIR" ] && echo "The theme folder it replaced is saved at $BACKUP_DIR."
    return 0
  fi

  $SUDO rm -rf "$THEME_DST"
  if [ -n "$BACKUP_DIR" ]; then
    $SUDO mv "$BACKUP_DIR" "$THEME_DST"
  fi
  if [ -n "$PREV_THEME" ]; then
    $SUDO plymouth-set-default-theme "$PREV_THEME" >/dev/null 2>&1 \
      && echo "Restored default theme: $PREV_THEME"
  fi
}

arm_cleanup() {
  trap cleanup EXIT
  trap 'exit 130' INT TERM
}