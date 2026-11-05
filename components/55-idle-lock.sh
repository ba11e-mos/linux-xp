# XP screen saver after 10 minutes idle, then lock to the XP greeter

is_gnome && { skip "GNOME locks with GDM and runs on Wayland, where xss-lock cannot"; return 0; }

have xss-lock || { warn "xss-lock missing (sudo apt install xss-lock)"; return 0; }
have dm-tool  || { warn "dm-tool missing - this needs lightdm"; return 0; }

install -Dm755 "$ASSETS/idle-lock/xp-idle-lock.sh" "$HOME/.local/bin/xp-idle-lock.sh"
install -Dm755 "$ASSETS/idle-lock/xp-screensaver.py" "$HOME/.local/bin/xp-screensaver.py"
[ -x /usr/libexec/xscreensaver/pipes ] || warn "3D Pipes missing (sudo apt install xscreensaver-gl) - the screen saver stays black"

auto="$HOME/.config/autostart/xp-idle-lock.desktop"
backup_file "$auto"
mkdir -p "$(dirname "$auto")"
cat > "$auto" <<DESKTOP
[Desktop Entry]
Type=Application
Name=XP idle lock
Comment=Lock to the lightdm greeter on idle instead of cinnamon-screensaver
Exec=$HOME/.local/bin/xp-idle-lock.sh
OnlyShowIn=X-Cinnamon;XFCE;
X-GNOME-Autostart-enabled=true
NoDisplay=false
DESKTOP

# Two lockers must never both be armed, or the XP greeter and the desktop's
# own lock screen stack on top of each other.
if is_cinnamon; then
    gsettings set org.cinnamon.settings-daemon.plugins.power lock-on-suspend false 2>/dev/null || true
    gsettings set org.cinnamon.desktop.screensaver idle-activation-enabled false 2>/dev/null || true
    gsettings set org.cinnamon.desktop.screensaver lock-enabled false 2>/dev/null || true
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

log "the desktop's own locker switched off, xss-lock takes idle and suspend"
info "takes effect at next login, or run ~/.local/bin/xp-idle-lock.sh now"
