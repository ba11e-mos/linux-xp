# Cinnamon-kildefiler: UAC-dialog, lydapplet, volum-OSD, menyer med tittellinje
#
# Disse redigerer /usr/share/cinnamon/js/... og trenger sudo. Hvert skript tar
# sin egen .orig-xp-kopi og hopper over hvis det allerede er kjørt.

[ -d /usr/share/cinnamon/js ] || { warn "fant ikke /usr/share/cinnamon/js"; return 0; }

if [ "${XP_SKIP_SUDO:-0}" = "1" ]; then
    skip "hoppet over (XP_SKIP_SUDO=1)"
    return 0
fi

for p in uac-dialog sound-applet volume-osd applet-menus menu-titlebars; do
    f="$PATCHES/$p.sh"
    [ -f "$f" ] || continue
    info "kjører $p.sh"
    sudo bash "$f" || warn "$p.sh feilet"
done

info "fingeravtrykk før passord i innloggingen: sudo bash $PATCHES/pam-fingerprint-first.sh"
restart_cinnamon
