# XP screen saver when idle, then lock to the XP greeter
#
# Cinnamon: its own settings decide (Screensaver: delay, lock after, lock on
# sleep); xp-saver-lock.py is set as its custom screen saver command, which
# also keeps Mint's screen saver from starting. XFCE: xss-lock, with the
# times fixed in xp-idle-lock.sh.

is_gnome && { skip "GNOME locks with GDM and runs on Wayland, where xss-lock cannot"; return 0; }

have dm-tool  || { warn "dm-tool missing - this needs lightdm"; return 0; }
is_xfce && ! have xss-lock && { warn "xss-lock missing (sudo apt install xss-lock)"; return 0; }

install -Dm755 "$ASSETS/idle-lock/xp-idle-lock.sh" "$HOME/.local/bin/xp-idle-lock.sh"
install -Dm755 "$ASSETS/idle-lock/xp-screensaver.py" "$HOME/.local/bin/xp-screensaver.py"
install -Dm755 "$ASSETS/idle-lock/xp-saver-lock.py" "$HOME/.local/bin/xp-saver-lock.py"
[ -x /usr/libexec/xscreensaver/pipes ] || warn "3D Pipes missing (sudo apt install xscreensaver-gl) - the screen saver stays black"

auto="$HOME/.config/autostart/xp-idle-lock.desktop"
backup_file "$auto"
mkdir -p "$(dirname "$auto")"
cat > "$auto" <<DESKTOP
[Desktop Entry]
Type=Application
Name=XP idle lock
Comment=Lock to the lightdm greeter on idle instead of xfce4-screensaver
Exec=$HOME/.local/bin/xp-idle-lock.sh
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
NoDisplay=false
DESKTOP

# Two lockers must never both be armed, or the XP greeter and the desktop's
# own lock screen stack on top of each other.
if is_cinnamon; then
    gsettings set org.cinnamon.desktop.screensaver custom-screensaver-command "$HOME/.local/bin/xp-saver-lock.py"
    # Earlier versions set the delay to 0 (never) to keep Mint's saver away.
    [ "$(gsettings get org.cinnamon.desktop.session idle-delay)" = "uint32 0" ] &&
        gsettings set org.cinnamon.desktop.session idle-delay 600
    gsettings set org.cinnamon.desktop.screensaver lock-enabled true
    gsettings set org.cinnamon.settings-daemon.plugins.power lock-on-suspend true
    # xss-lock from earlier versions would lock a second time
    pkill -u "$USER" -x xss-lock 2>/dev/null || true
elif is_xfce; then
    xfset xfce4-screensaver /saver/enabled bool false
    xfset xfce4-screensaver /lock/enabled bool false
    xfset xfce4-power-manager /xfce4-power-manager/lock-screen-suspend-hibernate bool false
fi

# Locked = inactive session, so background flatpak refreshes would ask for
# a password behind the lock (see the rules file).
if have flatpak; then
    sudo install -Dm644 "$ASSETS/idle-lock/50-linux-xp-flatpak.rules" /etc/polkit-1/rules.d/50-linux-xp-flatpak.rules
fi

if is_cinnamon; then
    log "Cinnamon runs the XP screen saver and lock - times in Settings > Screensaver"
else
    log "the desktop's own locker switched off, xss-lock takes idle and suspend"
    info "takes effect at next login, or run ~/.local/bin/xp-idle-lock.sh now"
fi
