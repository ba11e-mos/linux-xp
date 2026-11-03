# The terminal as cmd.exe

have gsettings || return 0
prof="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")"
[ -n "$prof" ] || { skip "no GNOME Terminal profile found"; return 0; }
B="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$prof/"

gsettings set "$B" use-theme-colors false
gsettings set "$B" background-color '#000000'
gsettings set "$B" foreground-color '#C0C0C0'
gsettings set "$B" cursor-shape 'block'
gsettings set "$B" palette "['#000000','#800000','#008000','#808000','#000080','#800080','#008080','#C0C0C0','#808080','#FF0000','#00FF00','#FFFF00','#0000FF','#FF00FF','#00FFFF','#FFFFFF']"
log "cmd.exe colours set"

# The real VGA raster font, from int10h.org's Oldschool PC Font Pack. The .otb
# versions go in the user font folder, which fontconfig's bitmap filter allows.
if [ "${XP_TERMINAL_FONT:-0}" = "1" ]; then
    if ! fc-list 2>/dev/null | grep -qi "Bm437" &&
       z="$(fetch https://int10h.org/oldschool-pc-fonts/download/oldschool_pc_font_pack_v2.2_linux.zip oldschool-pc-fonts.zip)"; then
        mkdir -p "$HOME/.local/share/fonts"
        unzip -qq -o -j "$z" '*/Bm437_IBM_VGA_*.otb' -d "$HOME/.local/share/fonts"
        fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1
    fi
    if fc-list 2>/dev/null | grep -qi "Bm437"; then
        gsettings set "$B" use-system-font false
        gsettings set "$B" font 'Bm437 IBM VGA 8x16 12'
        log "VGA raster font set"
    else
        warn "Bm437 fonts missing after download"
    fi
else
    info "set XP_TERMINAL_FONT=1 for the real VGA raster font"
fi
