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
else
    info "on GNOME the shell theme needs the User Themes extension"
    set_if org.gnome.shell.extensions.user-theme name "$THEME_NAME"
fi

# Deliberately no font here. Wine ships a Tahoma, but it carries embedded
# bitmaps and renders as a pixel font in title bars at small sizes, so the
# desktop keeps whatever face the distribution set.


if [ -n "${XP_WALLPAPER:-}" ] && [ -f "$XP_WALLPAPER" ]; then
    set_if "$D.background" picture-uri "file://$XP_WALLPAPER"
    set_if "$D.background" picture-options 'zoom'
else
    info "set the wallpaper yourself, or pass XP_WALLPAPER=/path/to/bliss.jpg"
fi
