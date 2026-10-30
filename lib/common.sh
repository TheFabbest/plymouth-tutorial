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
PLY_CONF="/etc/plymouth/plymouthd.conf"
PLY_CONF_DEFAULTS="/usr/share/plymouth/plymouthd.defaults"
USE_CONF=0        # 1 = plymouth-set-default-theme is missing; edit PLY_CONF instead
CONF_TOUCHED=0
CONF_EXISTED=0
CONF_RESTORE_FAILED=0

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
    for t in plymouth plymouthd; do
        command -v "$t" >/dev/null 2>&1 \
            || die "'$t' not found. Install Plymouth first (see README, Prerequisites)."
    done
    if ! command -v plymouth-set-default-theme >/dev/null 2>&1; then
        USE_CONF=1
        echo "Note: 'plymouth-set-default-theme' is not installed on this system." >&2
        echo "      Selecting the theme through $PLY_CONF instead; the original is" >&2
        echo "      backed up and restored when the script ends." >&2
    fi
}

# Print the Theme= value from a plymouthd config file (empty if none).
ply_conf_theme() {
    [ -f "$1" ] || return 0
    sed -n 's/^[[:space:]]*Theme=[[:space:]]*\([^[:space:]#;]*\).*/\1/p' "$1" | head -n 1
}

ply_get_default_theme() {
    if [ "$USE_CONF" -eq 1 ]; then
        local t
        t="$(ply_conf_theme "$PLY_CONF")"
        [ -n "$t" ] || t="$(ply_conf_theme "$PLY_CONF_DEFAULTS")"
        echo "$t"
    else
        plymouth-set-default-theme 2>/dev/null | head -n 1 || true
    fi
}

# Select a theme as default. Fails loudly: the result is read back and checked.
ply_set_default_theme() {
    local name="$1"
    if [ "$USE_CONF" -eq 0 ]; then
        plymouth-set-default-theme "$name" || die "plymouth-set-default-theme failed."
        return 0
    fi
    if [ "$CONF_TOUCHED" -eq 0 ]; then
        if [ -f "$PLY_CONF" ]; then
            CONF_EXISTED=1
            cp -p "$PLY_CONF" "$BACKUP_DIR/plymouthd.conf" || die "could not back up $PLY_CONF."
        fi
        CONF_TOUCHED=1
    fi
    mkdir -p "$(dirname "$PLY_CONF")" || die "could not create $(dirname "$PLY_CONF")."
    if [ ! -f "$PLY_CONF" ]; then
        printf '[Daemon]\nTheme=%s\n' "$name" > "$PLY_CONF" || die "could not write $PLY_CONF."
    elif grep -qE '^[[:space:]]*Theme=' "$PLY_CONF"; then
        sed -i -E "s|^[[:space:]]*Theme=.*|Theme=$name|" "$PLY_CONF" || die "could not edit $PLY_CONF."
    elif grep -qE '^[[:space:]]*\[Daemon\]' "$PLY_CONF"; then
        sed -i -E "0,/^[[:space:]]*\[Daemon\]/s||[Daemon]\nTheme=$name|" "$PLY_CONF" || die "could not edit $PLY_CONF."
    else
        printf '\n[Daemon]\nTheme=%s\n' "$name" >> "$PLY_CONF" || die "could not edit $PLY_CONF."
    fi
    [ "$(ply_conf_theme "$PLY_CONF")" = "$name" ] \
        || die "could not set Theme=$name in $PLY_CONF (check the file by hand)."
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
        [ "$CONF_TOUCHED" -eq 1 ] && echo "Note: $PLY_CONF now contains Theme=$THEME_NAME."
        [ -n "$BACKUP_DIR" ] && rm -rf "$BACKUP_DIR"
        return 0
    fi
    echo "Restoring previous state..."
    rm -rf "$THEME_DST"
    if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR/$THEME_NAME" ]; then
        mv "$BACKUP_DIR/$THEME_NAME" "$THEME_DST"
    fi
    if [ "$USE_CONF" -eq 1 ]; then
        if [ "$CONF_TOUCHED" -eq 1 ]; then
            if [ "$CONF_EXISTED" -eq 1 ]; then
                if cp -p "$BACKUP_DIR/plymouthd.conf" "$PLY_CONF"; then
                    echo "Restored $PLY_CONF."
                else
                    CONF_RESTORE_FAILED=1
                    echo "Warning: could not restore $PLY_CONF; your original is in $BACKUP_DIR." >&2
                fi
            else
                rm -f "$PLY_CONF" && echo "Removed $PLY_CONF (it did not exist before)."
            fi
        fi
    elif [ -n "$PREV_THEME" ]; then
        plymouth-set-default-theme "$PREV_THEME" >/dev/null 2>&1 \
            && echo "Default theme restored to '$PREV_THEME'." \
            || echo "Warning: could not restore default theme '$PREV_THEME'." >&2
    else
        echo "Warning: previous default theme unknown; pick one with plymouth-set-default-theme." >&2
    fi
    # Keep the backup directory if the config restore failed.
    if [ "$CONF_RESTORE_FAILED" -eq 0 ] && [ -n "$BACKUP_DIR" ]; then
        rm -rf "$BACKUP_DIR"
    fi
}

# Copy the theme in (backing up any same-named system theme) and select it.
ply_install_theme() {
    PREV_THEME="$(ply_get_default_theme)"
    BACKUP_DIR="$(mktemp -d)"
    trap ply_cleanup EXIT
    trap 'exit 130' INT TERM
    if [ -e "$THEME_DST" ]; then
        echo "Note: a theme named '$THEME_NAME' is already installed; backing it up and restoring it afterwards."
        mv "$THEME_DST" "$BACKUP_DIR/$THEME_NAME" \
            || die "could not back up the existing $THEME_DST."
    fi
    INSTALLED=1
    [ -d "$PLY_THEMES_DIR" ] || die "$PLY_THEMES_DIR does not exist. Is Plymouth installed?"
    cp -r "$THEME_SRC" "$THEME_DST" || die "could not copy the theme to $THEME_DST."
    ply_set_default_theme "$THEME_NAME"
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
