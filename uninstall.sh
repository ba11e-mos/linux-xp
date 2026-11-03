#!/usr/bin/env bash
#
# Put back what install.sh changed, and remove what it added.
#
#   ./uninstall.sh          restore everything
#   ./uninstall.sh --dry    only show what would happen

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"

dry=0
[ "${1:-}" = "--dry" ] && dry=1

# A failed step (a setting this desktop does not have) must not stop the rest.
run() { if [ "$dry" = 1 ]; then printf '    would run: %s\n' "$*"; else "$@" 2>/dev/null || info "skipped: $*"; fi; }

# --- user files from the backup tree ---
# xfconfd holds the XFCE panel layout in memory and would write it back over
# the restored file, so stop it and the panel first (component 36)
panel=0
if [ -f "$BACKUP$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" ] && pgrep -x xfce4-panel >/dev/null; then
    panel=1
    run xfce4-panel --quit
    run pkill -x xfconfd
    [ "$dry" = 1 ] || sleep 1
fi
if [ -d "$BACKUP" ]; then
    log "restoring files from $BACKUP"
    while IFS= read -r b; do
        orig="/${b#$BACKUP/}"
        info "$orig"
        run cp -a "$b" "$orig"
    done < <(find "$BACKUP" -type f)
else
    warn "no backup in $BACKUP"
fi

# --- Cinnamon source files: each patch script left an .orig-xp behind ---
log "restoring Cinnamon source files"
while IFS= read -r o; do
    info "${o%.orig-xp}"
    run sudo mv "$o" "${o%.orig-xp}"
done < <(find /usr/share/cinnamon -name "*.orig-xp" 2>/dev/null)

# --- Firefox ---
for prof in "$HOME"/.mozilla/firefox/*.default*/; do
    [ -d "$prof" ] || continue
    log "Firefox: $(basename "$prof")"
    run rm -rf "$prof/chrome"
    run rm -f  "$prof/user.js"
    [ -f "$prof/prefs.js.bak-xp" ] && run cp -a "$prof/prefs.js.bak-xp" "$prof/prefs.js"
done

# --- VS Code theme (a folder extension, not a backed-up file) ---
ext="$HOME/.vscode/extensions/linux-xp.linux-xp-theme-1.0.0"
if [ -d "$ext" ]; then
    log "removing the bundled VS Code theme"
    run rm -rf "$ext"
fi

# --- Firefox new tab autoconfig (component 65) ---
for d in /usr/lib/firefox /usr/lib64/firefox /opt/firefox; do
    if grep -qs linux-xp "$d/defaults/pref/autoconfig.js"; then
        log "Firefox new tab autoconfig in $d"
        run sudo rm -f "$d/defaults/pref/autoconfig.js" "$d/linux-xp.cfg"
    fi
done

# --- desktop settings (component 20): back to the distribution defaults ---
D="$(desktop_schema)"
log "theme, icons, cursor and wallpaper back to the defaults"
for k in gtk-theme icon-theme cursor-theme; do run gsettings reset "$D.interface" "$k"; done
run gsettings reset "$D.wm.preferences" theme
run gsettings reset org.cinnamon.theme name 2>/dev/null || true
run gsettings reset "$D.background" picture-uri
run gsettings reset "$D.background" picture-options

if is_xfce; then
    log "XFCE appearance, sounds and lockers back to the defaults"
    for p in /Net/ThemeName /Net/IconThemeName /Gtk/CursorThemeName /Net/SoundThemeName; do
        run xfconf-query -c xsettings -p "$p" -r 2>/dev/null || true
    done
    run xfconf-query -c xfwm4 -p /general/theme -r 2>/dev/null || true
    run xfconf-query -c xfwm4 -p /general/button_layout -r 2>/dev/null || true
    run xfconf-query -c xfce4-screensaver -p /saver/enabled -r 2>/dev/null || true
    run xfconf-query -c xfce4-screensaver -p /lock/enabled -r 2>/dev/null || true
    run xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-screen-suspend-hibernate -r 2>/dev/null || true
    for p in /theme /notify-location /do-fadeout /initial-opacity; do
        run xfconf-query -c xfce4-notifyd -p "$p" -r 2>/dev/null || true
    done
    run pkill -x xfce4-notifyd
    [ "$panel" = 1 ] && [ "$dry" = 0 ] && { setsid xfce4-panel >/dev/null 2>&1 < /dev/null & }
    for p in /color-use-theme /color-foreground /color-background /color-palette /misc-cursor-shape /font-use-system /font-name; do
        run xfconf-query -c xfce4-terminal -p "$p" -r 2>/dev/null || true
    done
fi
if is_gnome; then
    log "GNOME shell theme, taskbar, Start menu and wallpaper back to the defaults"
    run gsettings reset org.gnome.shell.extensions.user-theme name
    run gsettings reset org.gnome.desktop.background picture-uri-dark
    run gsettings reset org.gnome.desktop.interface color-scheme
    run gsettings reset org.gnome.desktop.wm.preferences button-layout
    run rm -rf "$HOME/snap/firefox/common/linux-xp"
    for f in "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"; do
        [ -f "$f" ] && run sed -i '/^\/\* linux-xp: Luna title bars/,/^\/\* linux-xp end \*\//d' "$f"
    done
    for e in dash-to-panel@jderose9.github.com arcmenu@arcmenu.com; do
        run rm -rf "$HOME/.local/share/gnome-shell/extensions/$e"
    done
    run dconf reset -f /org/gnome/shell/extensions/dash-to-panel/
    run dconf reset -f /org/gnome/shell/extensions/arcmenu/
    # Ubuntu Dock back, our extensions off
    run python3 - <<'PY'
import ast, subprocess
def get(k):
    v = subprocess.run(["gsettings", "get", "org.gnome.shell", k], capture_output=True, text=True).stdout.strip()
    return ast.literal_eval(v.replace("@as ", "")) if v else []
ours = {"dash-to-panel@jderose9.github.com", "arcmenu@arcmenu.com"}
on = [u for u in get("enabled-extensions") if u not in ours]
off = [u for u in get("disabled-extensions") if u != "ubuntu-dock@ubuntu.com"]
subprocess.run(["gsettings", "set", "org.gnome.shell", "enabled-extensions", str(on)], check=True)
subprocess.run(["gsettings", "set", "org.gnome.shell", "disabled-extensions", str(off)], check=True)
PY
fi
run rm -f "$HOME/.config/autostart/xp-startup-sound.desktop"

# --- theme, icons and cursors (component 10, everything 30/40/90/95 put in them) ---
log "removing the XP theme, icons and cursors"
for d in "$HOME"/.themes/"Windows XP "* "$HOME/.icons/$ICON_NAME" "$HOME/.icons/$CURSOR_NAME"; do
    [ -e "$d" ] && run rm -rf "$d"
done

# --- sounds (component 15) ---
log "sounds back to the defaults"
run rm -rf "$HOME/.local/share/sounds/WindowsXP"
run gsettings reset org.cinnamon.desktop.sound theme-name
run gsettings reset org.cinnamon.desktop.sound volume-sound-file
for k in login-file logout-file notification-file plug-file unplug-file minimize-file \
         minimize-enabled tile-enabled switch-enabled; do
    run gsettings reset org.cinnamon.sounds "$k"
done

# --- screen saver and idle lock (component 55): Cinnamon's own locker back ---
log "screen saver and idle lock"
run pkill -u "$USER" -x xss-lock || true
run rm -f "$HOME/.config/autostart/xp-idle-lock.desktop" \
          "$HOME/.local/bin/xp-idle-lock.sh" "$HOME/.local/bin/xp-screensaver.py"
run gsettings reset org.cinnamon.settings-daemon.plugins.power lock-on-suspend
run gsettings reset org.cinnamon.desktop.screensaver idle-activation-enabled
run gsettings reset org.cinnamon.desktop.screensaver lock-enabled
run xset s default

# --- login screen (component 57): back to Mint's greeter ---
if [ -f /etc/lightdm/lightdm.conf.d/99-nody.conf ]; then
    log "login screen back to the default (shows at the next login)"
    run sudo rm -f /etc/lightdm/lightdm.conf.d/99-nody.conf
    run sudo rm -rf /usr/share/web-greeter/themes/WelcomeXP
fi

# --- boot screen (component 85) ---
if [ -d /usr/share/plymouth/themes/WindowsXP ]; then
    log "boot screen back to the default"
    run sudo update-alternatives --remove default.plymouth /usr/share/plymouth/themes/WindowsXP/WindowsXP.plymouth
    run sudo rm -rf /usr/share/plymouth/themes/WindowsXP
    run sudo sed -i '/^DeviceScale=1$/d' /etc/plymouth/plymouthd.conf
    run sudo update-initramfs -u
fi

# --- terminal (component 80) ---
prof="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'" || true)"
if [ -n "$prof" ]; then
    log "terminal colours and font back to the defaults"
    B="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$prof/"
    for k in use-theme-colors background-color foreground-color cursor-shape palette use-system-font font; do
        run gsettings reset "$B" "$k"
    done
fi
run rm -f "$HOME"/.local/share/fonts/Bm437_IBM_VGA_*.otb "$HOME/.config/fontconfig/conf.d/70-xp-vga-font.conf"

# --- games (component 92) ---
log "removing the XP games"
run rm -rf "$HOME/.local/share/xp-games"
for id in winmine sol spider freecell mshearts pinball; do
    run rm -f "$HOME/.local/share/applications/xp-$id.desktop" \
              "$HOME/.local/share/icons/hicolor/48x48/apps/xp-$id.png"
done

# --- downloads ---
run rm -rf "$CACHE"

log "Done. Log out and back in."
