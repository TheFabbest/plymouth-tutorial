#!/usr/bin/env bash
# Shared helpers for preview.sh and testtheme.sh. Source this file; do not run it.

PLY_THEMES_DIR="/usr/share/plymouth/themes"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

THEME_NAME=""
THEME_SRC=""
THEME_DST=""
PREV_THEME=""
BACKUP_DIR=""
KEEP=0
INSTALLED=0

die() { echo "Error: $*" >&2; exit 1; }

# Re-run the calling script as root (prompts for sudo once).
ply_need_root() {
    if [ "$EUID" -ne 0 ]; then
        command -v sudo >/dev/null 2>&1 || die "this script needs root and sudo was not found."
        exec sudo -- "$0" "$@"
    fi
}

ply_check_tools() {
    local t
    for t in plymouth plymouthd plymouth-set-default-theme; do
        command -v "$t" >/dev/null 2>&1 \
            || die "'$t' not found. Install Plymouth first (see README, Prerequisites)."
    done
}

# Validate the theme name and locate it under ./themes
ply_select_theme() {
    THEME_NAME="${1:-}"
    [ -n "$THEME_NAME" ] || die "no theme given."
    [[ "$THEME_NAME" =~ ^[A-Za-z0-9._-]+$ && "$THEME_NAME" != .* ]] \
        || die "invalid theme name '$THEME_NAME' (letters, digits, '.', '_' and '-' only)."
    THEME_SRC="$REPO_ROOT/themes/$THEME_NAME"
    THEME_DST="$PLY_THEMES_DIR/$THEME_NAME"
    if [ ! -d "$THEME_SRC" ]; then
        echo "Error: theme '$THEME_NAME' not found in $REPO_ROOT/themes/" >&2
        echo "Available themes:" >&2
        find "$REPO_ROOT/themes" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' 2>/dev/null | sort >&2
        exit 1
    fi
    compgen -G "$THEME_SRC/*.plymouth" >/dev/null \
        || die "'$THEME_SRC' contains no .plymouth descriptor file."
}

# Restore everything we touched. Safe to call more than once.
ply_cleanup() {
    trap - EXIT INT TERM
    plymouth quit >/dev/null 2>&1 || true
    pkill -x plymouthd >/dev/null 2>&1 || true
    [ "$INSTALLED" -eq 1 ] || return 0
    if [ "$KEEP" -eq 1 ]; then
        echo "Keeping '$THEME_NAME' installed and selected (--keep)."
        [ -n "$BACKUP_DIR" ] && rm -rf "$BACKUP_DIR"
        return 0
    fi
    echo "Restoring previous state..."
    rm -rf "$THEME_DST"
    if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR/$THEME_NAME" ]; then
        mv "$BACKUP_DIR/$THEME_NAME" "$THEME_DST"
    fi
    [ -n "$BACKUP_DIR" ] && rm -rf "$BACKUP_DIR"
    if [ -n "$PREV_THEME" ]; then
        plymouth-set-default-theme "$PREV_THEME" >/dev/null 2>&1 \
            && echo "Default theme restored to '$PREV_THEME'." \
            || echo "Warning: could not restore default theme '$PREV_THEME'." >&2
    else
        echo "Warning: previous default theme unknown; pick one with plymouth-set-default-theme." >&2
    fi
}

# Copy the theme in (backing up any same-named system theme) and select it.
ply_install_theme() {
    PREV_THEME="$(plymouth-set-default-theme 2>/dev/null | head -n 1 || true)"
    BACKUP_DIR="$(mktemp -d)"
    trap ply_cleanup EXIT
    trap 'exit 130' INT TERM
    if [ -e "$THEME_DST" ]; then
        echo "Note: a theme named '$THEME_NAME' is already installed; backing it up and restoring it afterwards."
        mv "$THEME_DST" "$BACKUP_DIR/$THEME_NAME"
    fi
    INSTALLED=1
    cp -r "$THEME_SRC" "$THEME_DST"
    plymouth-set-default-theme "$THEME_NAME"
    echo "Previous default theme: ${PREV_THEME:-<unknown>}"
}

# Start plymouthd in the background and wait until it answers.
ply_start_daemon() {
    local logfile="$1"
    pkill -x plymouthd >/dev/null 2>&1 || true
    sleep 0.3
    if [ -n "$logfile" ]; then
        plymouthd --no-daemon --debug --debug-file="$logfile" &
    else
        plymouthd --no-daemon --debug &
    fi
    for _ in $(seq 1 50); do
        plymouth --ping >/dev/null 2>&1 && return 0
        sleep 0.1
    done
    die "plymouthd did not start within 5 seconds."
}
