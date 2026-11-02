# XP screen saver after 10 minutes idle, then lock to the XP greeter

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
OnlyShowIn=X-Cinnamon;
X-GNOME-Autostart-enabled=true
NoDisplay=false
DESKTOP

# Two lockers must never both be armed, or the XP greeter and the Cinnamon
# lock screen stack on top of each other - which is what lock-on-suspend did.
gsettings set org.cinnamon.settings-daemon.plugins.power lock-on-suspend false 2>/dev/null || true
gsettings set org.cinnamon.desktop.screensaver idle-activation-enabled false 2>/dev/null || true
gsettings set org.cinnamon.desktop.screensaver lock-enabled false 2>/dev/null || true

log "Cinnamon's own locker switched off, xss-lock takes idle and suspend"
info "the greeter itself is set up separately - see docs/login-screen.md"
info "takes effect at next login, or run ~/.local/bin/xp-idle-lock.sh now"
