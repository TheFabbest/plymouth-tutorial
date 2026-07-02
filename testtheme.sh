#!/usr/bin/fish

set THEME_NAME $argv[1]
set TIME $argv[2]

# Copy theme to the correct system directory
sudo cp -r $THEME_NAME /usr/share/plymouth/themes/

# Set it as the active theme
sudo plymouth-set-default-theme $THEME_NAME

# Test it (no initramfs rebuild needed for just previewing)
sudo plymouthd --no-daemon --debug &
sleep 1
sudo plymouth show-splash && sleep $TIME && sudo plymouth quit