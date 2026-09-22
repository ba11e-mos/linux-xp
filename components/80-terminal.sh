# Terminalen som cmd.exe

have gsettings || return 0
prof="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")"
[ -n "$prof" ] || { skip "fant ingen GNOME Terminal-profil"; return 0; }
B="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$prof/"

gsettings set "$B" use-theme-colors false
gsettings set "$B" background-color '#000000'
gsettings set "$B" foreground-color '#C0C0C0'
gsettings set "$B" cursor-shape 'block'
gsettings set "$B" palette "['#000000','#800000','#008000','#808000','#000080','#800080','#008080','#C0C0C0','#808080','#FF0000','#00FF00','#FFFF00','#0000FF','#FF00FF','#00FFFF','#FFFFFF']"
log "cmd.exe-fargene satt"

# Ekte VGA-rasterfont. Krever at Bm437-fontene er installert og at fontconfig
# ikke filtrerer bort punktfonter (70-no-bitmaps.conf).
if [ "${XP_TERMINAL_FONT:-0}" = "1" ]; then
    if fc-list 2>/dev/null | grep -qi "Bm437"; then
        gsettings set "$B" use-system-font false
        gsettings set "$B" font 'Bm437 IBM VGA 8x16 12'
        log "VGA-rasterfonten satt"
    else
        warn "Bm437-fontene mangler - se README"
    fi
else
    info "sett XP_TERMINAL_FONT=1 for den ekte VGA-rasterfonten"
fi
