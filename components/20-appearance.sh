# Slår på temaene, XP-fonten og musepekeren

set_if() { gsettings set "$1" "$2" "$3" 2>/dev/null || warn "kunne ikke sette $1 $2"; }

set_if org.cinnamon.desktop.interface           gtk-theme      "$THEME_NAME"
set_if org.cinnamon.desktop.wm.preferences      theme          "$THEME_NAME"
set_if org.cinnamon.theme                       name           "$THEME_NAME"
set_if org.cinnamon.desktop.interface           icon-theme     "$ICON_NAME"
set_if org.cinnamon.desktop.interface           cursor-theme   "$CURSOR_NAME"
set_if org.cinnamon.desktop.interface           font-name      'Tahoma 9'
set_if org.cinnamon.desktop.wm.preferences      titlebar-font  'Tahoma Bold 9'

# Tahoma finnes ikke i Mint. Uten den faller alt tilbake til Noto Sans, som er
# nært nok, men ekte Tahoma ligger i wine-pakken.
if ! fc-list 2>/dev/null | grep -qi tahoma; then
    info "Tahoma mangler - 'sudo apt install fonts-wine' gir den ekte fonten"
fi

if [ -n "${XP_WALLPAPER:-}" ] && [ -f "$XP_WALLPAPER" ]; then
    set_if org.cinnamon.desktop.background picture-uri "file://$XP_WALLPAPER"
    set_if org.cinnamon.desktop.background picture-options 'zoom'
else
    info "sett bakgrunnen selv, eller kjør med XP_WALLPAPER=/sti/til/bliss.jpg"
fi
