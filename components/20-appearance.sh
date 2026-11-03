# Apply the themes and the cursor
#
# Cinnamon and GNOME keep these under different schema prefixes but the same
# key names, so the only difference is which prefix we write to.

D="$(desktop_schema)"
set_if() { gsettings set "$1" "$2" "$3" 2>/dev/null || warn "could not set $1 $2"; }

set_if "$D.interface"      gtk-theme    "$THEME_NAME"
set_if "$D.interface"      icon-theme   "$ICON_NAME"
set_if "$D.interface"      cursor-theme "$CURSOR_NAME"
set_if "$D.wm.preferences" theme         "$THEME_NAME"

if is_cinnamon; then
    set_if org.cinnamon.theme name "$THEME_NAME"
elif is_xfce; then
    xfset xsettings /Net/ThemeName       string "$THEME_NAME"
    xfset xsettings /Net/IconThemeName   string "$ICON_NAME"
    xfset xsettings /Gtk/CursorThemeName string "$CURSOR_NAME"
    xfset xfwm4     /general/theme       string "$THEME_NAME"
else
    info "on GNOME the shell theme needs the User Themes extension"
    set_if org.gnome.shell.extensions.user-theme name "$THEME_NAME"
fi

# Deliberately no font here. Wine ships a Tahoma, but it carries embedded
# bitmaps and renders as a pixel font in title bars at small sizes, so the
# desktop keeps whatever face the distribution set.


# XP_WALLPAPER=bliss: the 600 dpi scan of Bliss from archive.org
if [ "${XP_WALLPAPER:-}" = bliss ]; then
    XP_WALLPAPER="$(fetch https://archive.org/download/bliss-600dpi/bliss-600dpi.png bliss.png)" || XP_WALLPAPER=
fi
if [ -n "${XP_WALLPAPER:-}" ] && [ -f "$XP_WALLPAPER" ]; then
    set_if "$D.background" picture-uri "file://$XP_WALLPAPER"
    set_if "$D.background" picture-options 'zoom'
    if is_xfce; then
        # one backdrop per monitor and workspace; set every one that exists
        for p in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep 'last-image$'); do
            xfset xfce4-desktop "$p" string "$XP_WALLPAPER"
        done
    fi
else
    info "wallpaper left alone (XP_WALLPAPER=bliss or =/path/to/image sets one)"
fi
