# XP boot screen: the logo on black with the blue blocks running in the bar
#
# Uses BFUR64/WindowsXP-Plymouth (MIT), cloned on first run. XP_PLYMOUTH=/path
# uses a local clone.
# Needs sudo: the theme goes in /usr/share/plymouth and the initramfs is rebuilt.

have plymouth-set-default-theme || have update-alternatives || { warn "plymouth not installed"; return 0; }

if [ "${XP_SKIP_SUDO:-0}" = "1" ]; then
    skip "skipped (XP_SKIP_SUDO=1)"
    return 0
fi

src="${XP_PLYMOUTH:-$CACHE/xp-plymouth}"
if [ ! -f "$src/WindowsXP/WindowsXP.plymouth" ]; then
    have git || { warn "git missing, and no theme at $src"; return 0; }
    info "cloning BFUR64/WindowsXP-Plymouth into $src"
    git clone -q --depth 1 https://github.com/BFUR64/WindowsXP-Plymouth "$src" || { warn "clone failed"; return 0; }
fi

dst=/usr/share/plymouth/themes/WindowsXP
sudo rm -rf "$dst"
sudo cp -r "$src/WindowsXP" "$dst"
sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth "$dst/WindowsXP.plymouth" 100 >/dev/null
sudo update-alternatives --set default.plymouth "$dst/WindowsXP.plymouth" >/dev/null

# The artwork is a fixed 1920x1080 picture. On a HiDPI panel Plymouth doubles
# everything, which pushes the logo and the bar off screen - draw 1:1 instead.
conf=/etc/plymouth/plymouthd.conf
if ! sudo grep -qs '^DeviceScale=1' "$conf"; then
    sudo mkdir -p /etc/plymouth
    if sudo grep -qs '^\[Daemon\]' "$conf"; then
        sudo sed -i '/^\[Daemon\]/a DeviceScale=1' "$conf"
    else
        printf '[Daemon]\nDeviceScale=1\n' | sudo tee -a "$conf" >/dev/null
    fi
fi

info "rebuilding the initramfs (takes a moment)"
sudo update-initramfs -u >/dev/null 2>&1 || { warn "update-initramfs failed"; return 0; }
log "XP boot screen installed - shows on the next boot"
info "undo: sudo update-alternatives --auto default.plymouth && sudo update-initramfs -u"
