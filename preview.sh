#!/usr/bin/fish
# =============================================================================
# Plymouth Theme Full Preview Script
# Run from inside your theme directory.
# =============================================================================

set LOG_FILE /tmp/plymouth-debug.log

set THEME_DIR ./themes/$argv[1]
set THEME_NAME (basename $THEME_DIR)
set THEME_DST /usr/share/plymouth/themes/$THEME_NAME

echo "Theme directory : $THEME_DIR"
echo "Theme name      : $THEME_NAME"
echo "Installing to   : $THEME_DST"

# ---- Install theme ----------------------------------------------------------
sudo rm -rf $THEME_DST
sudo cp -r $THEME_DIR $THEME_DST
sudo plymouth-set-default-theme $THEME_NAME

# ---- Start plymouthd --------------------------------------------------------
sudo pkill plymouthd 2>/dev/null
sleep 0.3
sudo plymouthd --no-daemon --debug --debug-file=$LOG_FILE &
sleep 1
sudo plymouth show-splash
sleep 0.5

# =============================================================================
# Helper: send boot progress (Plymouth expects a float 0.0-1.0 and a duration)
# --update only sends a status string, NOT a progress value.
# The correct command is `plymouth --update` for status and the progress bar
# is driven by systemd internally. For testing we use the plymouth binary directly.
# =============================================================================
function send_progress
    # $argv[1] = integer percentage 0-100
    set pct $argv[1]
    # plymouth system-update --progress takes 0-100 integer
    sudo plymouth system-update --progress=$pct
end

# =============================================================================
# Phase 1: Early boot (0% → 30%)
# =============================================================================

sudo plymouth message --text="Starting early boot services..."
sleep 0.3

for pct in 5 10 15 20 25 30
    send_progress $pct
    sleep 0.2
end

sudo plymouth message --text="Encrypted volume found..."
sleep 0.4

# =============================================================================
# Phase 2: Password mode
# plymouth ask-for-password blocks the calling process waiting for input.
# We run it in the background and feed it a password via its stdin after a delay.
# =============================================================================

# This actually triggers display_password_callback in the theme
sudo plymouth ask-for-password --prompt="Enter passphrase for /dev/sda2:" > /tmp/ply-pw-result.txt &
set ask_pid $last_pid
sleep 2

# Feed the password by writing to Plymouth's password pipe
# Plymouth reads the answer from file descriptor / named pipe it creates
# The simplest reliable way: just kill the ask after showing it long enough
sudo kill $ask_pid 2>/dev/null
sleep 0.3

sudo plymouth message --text="Passphrase accepted. Mounting volumes..."
sleep 0.3

# =============================================================================
# Phase 3: Post-password progress (30% → 100%)
# =============================================================================

for pct in 40 50 60
    send_progress $pct
    sleep 0.2
end

sudo plymouth message --text="Mounting /home..."
sleep 0.3
sudo plymouth hide-message --text="Mounting /home..."

for pct in 70 80 90 100
    send_progress $pct
    sleep 0.2
end

sudo plymouth message --text="Boot complete."
sleep 0.5

# =============================================================================
# Quit
# =============================================================================
sudo plymouth quit

# =============================================================================
# Debug log summary
# =============================================================================
echo ""
echo "=== Plymouth debug log ==="
if test -f $LOG_FILE
    grep -i "error\|failed\|cannot\|script\|theme" $LOG_FILE | head -30
else
    echo "Log file not found."
end