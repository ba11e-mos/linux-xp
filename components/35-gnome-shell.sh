# GNOME Shell: XP shell theme, a taskbar (Dash to Panel) and a Start menu (ArcMenu)
#
# Both extensions come from extensions.gnome.org, in the build made for the
# GNOME version that is running. They load at the next login.

is_gnome || { skip "needs GNOME - skipped on this desktop"; return 0; }

ver="$(gnome-shell --version 2>/dev/null | grep -oE '[0-9]+' | head -1)"
extdir="$HOME/.local/share/gnome-shell/extensions"

# install_ext <uuid> - unpack the build for this shell version, print its schema dir
install_ext() {
    local uuid="$1" url z d
    url="$(curl -fsS "https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=$ver" |
           python3 -c 'import json,sys; print("https://extensions.gnome.org" + json.load(sys.stdin)["download_url"])')" ||
        { warn "$uuid has no build for GNOME $ver"; return 1; }
    z="$(fetch "$url" "$uuid-gnome$ver.zip")" || return 1
    d="$extdir/$uuid"
    rm -rf "$d"; mkdir -p "$d"
    unzip -qq -o "$z" -d "$d"
    [ -d "$d/schemas" ] && glib-compile-schemas "$d/schemas"
    printf '%s\n' "$d/schemas"
}

# enable_ext <uuid> - add to enabled-extensions and drop from disabled-extensions
enable_ext() {
    python3 - "$1" <<'PY'
import ast, subprocess, sys
uuid = sys.argv[1]
def get(k):
    v = subprocess.run(["gsettings", "get", "org.gnome.shell", k], capture_output=True, text=True).stdout.strip()
    return ast.literal_eval(v.replace("@as ", "")) if v else []
on, off = get("enabled-extensions"), get("disabled-extensions")
if uuid not in on: on.append(uuid)
off = [u for u in off if u != uuid]
subprocess.run(["gsettings", "set", "org.gnome.shell", "enabled-extensions", str(on)], check=True)
subprocess.run(["gsettings", "set", "org.gnome.shell", "disabled-extensions", str(off)], check=True)
PY
}

disable_ext() {
    python3 - "$1" <<'PY'
import ast, subprocess, sys
uuid = sys.argv[1]
v = subprocess.run(["gsettings", "get", "org.gnome.shell", "disabled-extensions"], capture_output=True, text=True).stdout.strip()
off = ast.literal_eval(v.replace("@as ", "")) if v else []
if uuid not in off: off.append(uuid)
subprocess.run(["gsettings", "set", "org.gnome.shell", "disabled-extensions", str(off)], check=True)
PY
}

# --- shell theme ---
theme_ext=user-theme@gnome-shell-extensions.gcampax.github.com
if [ -d "/usr/share/gnome-shell/extensions/$theme_ext" ]; then
    enable_ext "$theme_ext"
    gsettings set org.gnome.shell.extensions.user-theme name "$THEME_NAME" 2>/dev/null || warn "could not set the shell theme"
    log "XP shell theme set"
else
    warn "User Themes extension missing (sudo apt install gnome-shell-extensions)"
fi

# libadwaita apps follow color-scheme, not the GTK theme: keep them light
gsettings set org.gnome.desktop.interface color-scheme default

# --- taskbar ---
if s="$(install_ext dash-to-panel@jderose9.github.com)"; then
    dtp() { gsettings --schemadir "$s" set org.gnome.shell.extensions.dash-to-panel "$@"; }
    dtp panel-positions '{"0":"BOTTOM"}'
    dtp panel-sizes '{"0":30}'
    dtp show-activities-button false
    # XP's task buttons: one per window, icon and title, no dots or previews;
    # the colours come from the shell theme (xp-extras.css)
    dtp trans-use-custom-bg false
    dtp group-apps false
    dtp show-favorites false
    dtp show-window-previews false
    dtp highlight-appicon-hover false
    dtp focus-highlight false
    dtp dot-size 0
    dtp appicon-padding 7
    dtp appicon-margin 0
    dtp group-apps-use-fixed-width true
    dtp group-apps-label-max-width 150
    dtp group-apps-label-font-size 12
    dtp group-apps-label-font-color '#FFFFFF'
    # Start | running apps ... | tray, clock
    dtp panel-element-positions '{"0":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}'
    enable_ext dash-to-panel@jderose9.github.com
    # Ubuntu Dock would sit on top of the taskbar
    disable_ext ubuntu-dock@ubuntu.com
    log "XP taskbar installed (Dash to Panel)"
fi

# --- Start menu ---
if s="$(install_ext arcmenu@arcmenu.com)"; then
    arc() { gsettings --schemadir "$s" set org.gnome.shell.extensions.arcmenu "$@"; }
    icons="$(icon_dir)"
    arc menu-layout 'redmond'
    arc position-in-panel 'Left'
    arc menu-button-appearance 'Icon_Text'
    arc menu-button-text 'start'
    # the PNG: the pack's SVG wraps a bitmap without the xlink namespace and St draws nothing
    [ -f "$icons/128x128/apps/start-here.png" ] && arc menu-button-icon "$icons/128x128/apps/start-here.png"
    arc menu-button-icon-size 20
    # the frame picture is drawn for this size (xp-extras.css)
    arc menu-height 600
    arc right-panel-width 205
    arc menu-width-adjustment 0
    # the shell theme draws the button and the menu frame
    arc override-menu-theme false
    enable_ext arcmenu@arcmenu.com
    log "XP Start menu installed (ArcMenu)"
fi

# --- XP pictures for the taskbar and Start menu, in the shell theme ---
shell="$(theme_dir gnome-shell)" || { warn "no gnome-shell in $THEME_NAME"; shell=""; }
if [ -n "$shell" ]; then
    # Cinnamon's Start menu frame, mirrored so the blue places column is on
    # the right, and stretched to ArcMenu's 640x720 with the edges kept 1:1
    convert "$shell/menu-bg.png" -flop \
        \( -clone 0 -crop 20x478+0+0 \) \( -clone 0 -crop 213x478+20+0 -resize 405x478\! \) \
        \( -clone 0 -crop 144x478+233+0 -resize 212x478\! \) \( -clone 0 -crop 3x478+377+0 \) \
        -delete 0 +append +repage \
        \( -clone 0 -crop 640x68+0+0 \) \( -clone 0 -crop 640x367+0+68 -resize 640x609\! \) \( -clone 0 -crop 640x43+0+435 \) \
        -delete 0 -append +repage "$shell/xp-start-menu.png"
    css="$shell/gnome-shell.css" marker="/* --- linux-xp extras --- */"
    backup_file "$css"
    if marker_present "$css" "$marker"; then
        sed -i "/^\/\* --- linux-xp extras --- \*\//,\$d" "$css"
    fi
    { printf '%s\n' "$marker"; cat "$ASSETS/gnome-shell/xp-extras.css"; } >> "$css"
    # load it now
    gsettings set org.gnome.shell.extensions.user-theme name "" 2>/dev/null
    gsettings set org.gnome.shell.extensions.user-theme name "$THEME_NAME" 2>/dev/null
    log "XP taskbar and Start menu pictures added to the shell theme"
fi

# --- Luna title bars for GTK4/libadwaita apps, GNOME Terminal and Wine ---
# GNOME draws the frames of X11 apps with GTK4, and GTK4 has no theme
# support, but every GTK app reads the user's gtk.css last.
if gtk_assets="$(theme_dir gtk-3.20)/assets" && [ -d "$gtk_assets" ]; then
    # snap Firefox may read only its own folder, not ~/.themes or any hidden dir;
    # other apps read that folder too, so the pictures go there when it exists
    # shortcut: covers snap Firefox only, other snaps and flatpaks get no caption pictures
    pics="$gtk_assets"
    if [ -d "$HOME/snap/firefox/common" ]; then
        pics="$HOME/snap/firefox/common/linux-xp"
        mkdir -p "$pics"
        cp "$gtk_assets"/{titlebar-focused-middle,titlebar-unfocused-middle}.png "$pics/"
        cp "$gtk_assets"/{close,minimize,maximize}-{normal,hover,active,backdrop}.png "$gtk_assets"/restore-{normal,hover}.png "$pics/"
    fi
    for v in gtk-3.0 gtk-4.0; do
        f="$HOME/.config/$v/gtk.css"
        mkdir -p "$(dirname "$f")"
        backup_file "$f"
        [ -f "$f" ] && sed -i '/^\/\* linux-xp: Luna title bars/,/^\/\* linux-xp end \*\//d' "$f"
        sed "s|@ASSETS@|$pics|g" "$ASSETS/gnome-shell/gtk4-luna.css" >> "$f"
    done
    gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
    log "Luna title bars for GTK4 apps and X11 windows"
fi

info "log out and back in to load the taskbar and Start menu"
