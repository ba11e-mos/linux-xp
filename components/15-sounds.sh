# Windows XP sound scheme: startup, shutdown, balloon, device in/out, dialogs
#
# The sounds are not bundled - they are Microsoft's. Download xpwav.zip from
# https://lelegofrog.github.io/winwavxp.html into ~/Downloads, or point at the
# zip or an unpacked folder with XP_SOUNDS=/path.

src="${XP_SOUNDS:-}"
[ -n "$src" ] || src="$(find "$HOME/Downloads" -maxdepth 2 \( -iname 'xpwav*.zip' -o -iname 'Windows XP Startup.wav' \) 2>/dev/null | sort | head -1)"
[ -n "$src" ] || { warn "no XP sounds found. Download xpwav.zip (see README) and run this component again."; return 0; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN
case "$src" in
    *.zip) unzip -qq -o "$src" -d "$tmp"; src="$tmp" ;;
    *.wav) src="$(dirname "$src")" ;;
esac
wav() { find "$src" -iname "Windows XP $1.wav" -print -quit; }
[ -n "$(wav Startup)" ] || { warn "Windows XP Startup.wav not in $src"; return 0; }

theme="$HOME/.local/share/sounds/WindowsXP"
mkdir -p "$theme/stereo"
cat > "$theme/index.theme" <<'EOF'
[Sound Theme]
Name=Windows XP
Directories=stereo

[stereo]
OutputProfile=stereo
EOF

# freedesktop sound name <TAB> XP file, the way the XP default scheme assigns them
while IFS=$'\t' read -r name xp; do
    f="$(wav "$xp")"; [ -n "$f" ] || { warn "missing Windows XP $xp.wav"; continue; }
    cp "$f" "$theme/stereo/$name.wav"
done <<'EOF'
desktop-login	Startup
desktop-logout	Shutdown
bell	Default
dialog-error	Critical Stop
dialog-warning	Exclamation
dialog-information	Ding
dialog-question	Ding
device-added	Hardware Insert
device-removed	Hardware Remove
device-added-failure	Hardware Fail
message-new-instant	Notify
message	Balloon
trash-empty	Recycle
battery-low	Battery Low
battery-caution	Battery Critical
window-minimized	Minimize
audio-volume-change	Default
EOF

s="$theme/stereo"
gsettings set org.cinnamon.desktop.sound theme-name 'WindowsXP'
gsettings set org.cinnamon.desktop.sound volume-sound-file "$s/audio-volume-change.wav"
gsettings set org.cinnamon.sounds login-file        "$s/desktop-login.wav"
gsettings set org.cinnamon.sounds logout-file       "$s/desktop-logout.wav"
gsettings set org.cinnamon.sounds notification-file "$s/message.wav"
gsettings set org.cinnamon.sounds plug-file         "$s/device-added.wav"
gsettings set org.cinnamon.sounds unplug-file       "$s/device-removed.wav"
gsettings set org.cinnamon.sounds minimize-file     "$s/window-minimized.wav"
gsettings set org.cinnamon.sounds minimize-enabled  true
# XP has no sound for snapping a window or switching workspace
gsettings set org.cinnamon.sounds tile-enabled      false
gsettings set org.cinnamon.sounds switch-enabled    false

log "XP sound scheme installed ($(ls "$s" | wc -l) sounds)"
