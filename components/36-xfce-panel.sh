# XFCE: an XP taskbar (Whisker Menu as Start, task list, tray, clock) and balloon tips
#
# The panel layout is replaced with one bottom panel; the old one is backed up
# and uninstall.sh puts it back. Colours come from CSS added to the Luna theme.

is_xfce || { skip "needs XFCE - skipped on this desktop"; return 0; }
gtk="$(theme_dir gtk-3.20)" || { warn "no gtk-3.20 in $THEME_NAME - install component 10 first"; return 0; }

# --- panel layout ---
backup_file "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
running=0; pgrep -x xfce4-panel >/dev/null && running=1
[ "$running" = 1 ] && xfce4-panel --quit
xfconf-query -c xfce4-panel -p /panels -r -R 2>/dev/null
xfconf-query -c xfce4-panel -p /plugins -r -R 2>/dev/null

pset() { xfconf-query -c xfce4-panel -p "$1" -n "${@:2}" || warn "could not set panel $1"; }
pset /panels -a -t int -s 1
P=/panels/panel-1
pset $P/position -t string -s 'p=8;x=0;y=0'   # bottom edge, full width
pset $P/length -t uint -s 100
pset $P/size -t uint -s 30
pset $P/icon-size -t uint -s 16
pset $P/position-locked -t bool -s true
pset /panels/dark-mode -t bool -s false

# id:type - Start | running windows | gap | tray, volume, clock
plugins=(1:whiskermenu 2:tasklist 6:separator 3:systray 4:pulseaudio 5:clock)
args=()
for p in "${plugins[@]}"; do
    id="${p%%:*}" type="${p#*:}"
    [ "$type" = pulseaudio ] && ! compgen -G "/usr/lib/*/xfce4/panel/plugins/libpulseaudio-plugin.so" >/dev/null && continue
    pset "/plugins/plugin-$id" -t string -s "$type"
    args+=(-t int -s "$id")
done
pset $P/plugin-ids -a "${args[@]}"

W=/plugins/plugin-1
pset $W/button-title -t string -s start
pset $W/show-button-title -t bool -s true
pset $W/show-button-icon -t bool -s true
pset $W/button-icon -t string -s start-here
pset $W/button-single-row -t bool -s true
pset /plugins/plugin-2/grouping -t uint -s 0
pset /plugins/plugin-2/show-labels -t bool -s true
pset /plugins/plugin-2/show-handle -t bool -s false
pset /plugins/plugin-6/expand -t bool -s true    # pushes the tray and clock to the right
pset /plugins/plugin-6/style -t uint -s 0
pset /plugins/plugin-3/square-icons -t bool -s true
pset /plugins/plugin-5/mode -t uint -s 2         # digital
pset /plugins/plugin-5/digital-layout -t uint -s 3
pset /plugins/plugin-5/digital-time-format -t string -s '%H:%M'

[ "$running" = 1 ] && { setsid xfce4-panel >/dev/null 2>&1 < /dev/null & }

# --- colours: blue taskbar, green Start, light-blue tray ---
css="$gtk/gtk.css"
if ! marker_present "$css" "linux-xp: xfce panel"; then
    cat >> "$css" <<'CSS'

/* linux-xp: xfce panel */
.xfce4-panel.background {
    background-color: #245EDC;
    background-image: linear-gradient(to bottom, #3168D5 0%, #4993E6 8%, #2157D7 40%, #2663E0 88%, #1941A5 100%);
    color: #FFFFFF;
}
.xfce4-panel #whiskermenu-button {
    background-color: #3C9A3C;
    background-image: linear-gradient(to bottom, #3D9E3D 0%, #79C579 10%, #3C9A3C 45%, #2E7D2E 100%);
    border-radius: 0 10px 10px 0;
    padding: 0 14px 0 6px;
    color: #FFFFFF;
    font-weight: bold;
    font-style: italic;
    text-shadow: 1px 1px #1A4D1A;
}
.xfce4-panel #whiskermenu-button:hover { background-image: linear-gradient(to bottom, #4FB34F 0%, #8FD68F 10%, #4FB34F 45%, #3A913A 100%); }
.xfce4-panel #whiskermenu-button:checked { background-image: linear-gradient(to bottom, #2E7D2E 0%, #3C9A3C 100%); }
.xfce4-panel #whiskermenu-button label { color: #FFFFFF; }
.xfce4-panel .tasklist button {
    background-color: #3C81F3;
    background-image: none;
    border: 1px solid #1941A5;
    border-radius: 3px;
    margin: 2px 1px;
    color: #FFFFFF;
}
.xfce4-panel .tasklist button:hover { background-color: #5A96F5; }
.xfce4-panel .tasklist button:checked { background-color: #1E52B7; }
.xfce4-panel .tasklist button label { color: #FFFFFF; }
.xfce4-panel #systray, .xfce4-panel #pulseaudio-button, .xfce4-panel #clock-button {
    background-color: #0F8FEB;
    background-image: linear-gradient(to bottom, #0C59B9 0%, #139EE9 8%, #18B5F2 40%, #139BEB 88%, #1290E8 100%);
    border-left: 1px solid #092E51;
    color: #FFFFFF;
}
.xfce4-panel #clock-button label { color: #FFFFFF; }
CSS
fi
log "XP taskbar and Start button set (Whisker Menu)"

# --- balloon tips ---
notify="$(dirname "$gtk")/xfce-notify-4.0"
mkdir -p "$notify"
cat > "$notify/gtk.css" <<'CSS'
#XfceNotifyWindow {
    background-color: #FFFFE1;
    background-image: none;
    border: 1px solid #000000;
    border-radius: 6px;
}
#XfceNotifyWindow label, #XfceNotifyWindow image { color: #000000; }
#XfceNotifyWindow label#summary { font-weight: bold; }
#XfceNotifyWindow button {
    background-color: #FFFFE1;
    background-image: none;
    border: 1px solid #808080;
    border-radius: 0;
    color: #000000;
}
CSS
xfset xfce4-notifyd /theme string "$THEME_NAME"
xfset xfce4-notifyd /notify-location uint 3     # bottom right, above the tray
xfset xfce4-notifyd /do-fadeout bool true
xfset xfce4-notifyd /initial-opacity double 1.0
# it reads the location only at start; D-Bus starts it again on the next balloon
pkill -x xfce4-notifyd 2>/dev/null || true
log "XP balloon tips set (xfce4-notifyd)"
