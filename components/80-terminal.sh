# The terminal as cmd.exe (GNOME Terminal and the XFCE terminal)

FG='#C0C0C0' BG='#000000'
PALETTE=('#000000' '#800000' '#008000' '#808000' '#000080' '#800080' '#008080' '#C0C0C0'
         '#808080' '#FF0000' '#00FF00' '#FFFF00' '#0000FF' '#FF00FF' '#00FFFF' '#FFFFFF')
FONT='Bm437 IBM VGA 8x16 12'

# The real VGA raster font, from int10h.org's Oldschool PC Font Pack. Ubuntu
# and Mint hide bitmap fonts (70-no-bitmaps-except-emoji.conf); a user rule
# lets the one the terminal uses through again (a <glob> on the file does not
# override that filter, a family pattern does).
vga=0
if [ "${XP_TERMINAL_FONT:-0}" = "1" ]; then
    mkdir -p "$HOME/.config/fontconfig/conf.d"
    cat > "$HOME/.config/fontconfig/conf.d/70-xp-vga-font.conf" <<'XML'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <selectfont><acceptfont><pattern>
    <patelt name="family"><string>Bm437 IBM VGA 8x16</string></patelt>
  </pattern></acceptfont></selectfont>
</fontconfig>
XML
    if ! fc-list 2>/dev/null | grep -i "Bm437" >/dev/null &&
       z="$(fetch https://int10h.org/oldschool-pc-fonts/download/oldschool_pc_font_pack_v2.2_linux.zip oldschool-pc-fonts.zip)"; then
        mkdir -p "$HOME/.local/share/fonts"
        unzip -qq -o -j "$z" '*/Bm437_IBM_VGA_*.otb' -d "$HOME/.local/share/fonts"
    fi
    fc-cache -f >/dev/null 2>&1
    fc-list 2>/dev/null | grep -i "Bm437" >/dev/null && vga=1 || warn "Bm437 fonts missing after download"
fi

done_any=0

prof="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")"
if [ -n "$prof" ]; then
    B="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$prof/"
    gsettings set "$B" use-theme-colors false
    gsettings set "$B" background-color "$BG"
    gsettings set "$B" foreground-color "$FG"
    gsettings set "$B" cursor-shape 'block'
    gsettings set "$B" palette "[$(printf "'%s'," "${PALETTE[@]}" | sed 's/,$//')]"
    if [ "$vga" = 1 ]; then
        gsettings set "$B" use-system-font false
        gsettings set "$B" font "$FONT"
    fi
    log "GNOME Terminal: cmd.exe colours set"
    done_any=1
fi

if have xfce4-terminal && have xfconf-query; then
    xfset xfce4-terminal /color-use-theme  bool   false
    xfset xfce4-terminal /color-foreground string "$FG"
    xfset xfce4-terminal /color-background string "$BG"
    xfset xfce4-terminal /color-palette    string "$(IFS=';'; echo "${PALETTE[*]}")"
    xfset xfce4-terminal /misc-cursor-shape string TERMINAL_CURSOR_SHAPE_BLOCK
    if [ "$vga" = 1 ]; then
        xfset xfce4-terminal /font-use-system bool false
        xfset xfce4-terminal /font-name string "$FONT"
    fi
    log "XFCE terminal: cmd.exe colours set"
    done_any=1
fi

[ "$done_any" = 1 ] || skip "no GNOME Terminal or XFCE terminal found"
