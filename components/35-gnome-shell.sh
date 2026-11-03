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
    dtp trans-use-custom-bg true
    dtp trans-bg-color '#245EDC'
    dtp trans-use-custom-opacity true
    dtp trans-panel-opacity 1.0
    dtp dot-style-focused 'SOLID'
    dtp dot-style-unfocused 'DOTS'
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
    [ -f "$icons/scalable/apps/start-here.svg" ] && arc menu-button-icon "$icons/scalable/apps/start-here.svg"
    arc menu-button-icon-size 20
    arc menu-button-bg-color "(true, '#3C9A3C')"
    arc menu-button-hover-bg-color "(true, '#4FB34F')"
    arc menu-button-active-bg-color "(true, '#2E7D2E')"
    arc menu-button-fg-color "(true, '#FFFFFF')"
    arc menu-button-hover-fg-color "(true, '#FFFFFF')"
    arc menu-button-active-fg-color "(true, '#FFFFFF')"
    arc menu-button-border-radius "(true, 0)"
    # the menu itself: XP's white pane with Luna blue highlights
    arc override-menu-theme true
    arc menu-background-color '#FFFFFF'
    arc menu-foreground-color '#000000'
    arc menu-border-color '#0A246A'
    arc menu-border-width 2
    arc menu-border-radius 6
    arc menu-item-hover-bg-color '#316AC5'
    arc menu-item-hover-fg-color '#FFFFFF'
    arc menu-item-active-bg-color '#316AC5'
    arc menu-item-active-fg-color '#FFFFFF'
    arc menu-separator-color '#D3D3D3'
    arc search-entry-border-radius "(true, 0)"
    enable_ext arcmenu@arcmenu.com
    log "XP Start menu installed (ArcMenu)"
fi

info "log out and back in to load the taskbar and Start menu"
