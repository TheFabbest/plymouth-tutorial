#!/usr/bin/fish

# Copy theme to the correct system directory
sudo cp -r centeredimage /usr/share/plymouth/themes/

# Set it as the active theme
sudo plymouth-set-default-theme centeredimage

# Test it (no initramfs rebuild needed for just previewing)
sudo plymouthd --no-daemon --debug &
sleep 1
sudo plymouth show-splash && sleep 2 && sudo plymouth quit