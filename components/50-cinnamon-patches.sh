# Cinnamon source files: UAC dialog, sound applet, volume OSD, captioned menus
#
# These edit /usr/share/cinnamon/js/... and need sudo. Each script keeps its
# own .orig-xp copy and skips if it has already run.

require_cinnamon || return 0

[ -d /usr/share/cinnamon/js ] || { warn "/usr/share/cinnamon/js not found"; return 0; }

if [ "${XP_SKIP_SUDO:-0}" = "1" ]; then
    skip "skipped (XP_SKIP_SUDO=1)"
    return 0
fi

for p in uac-dialog keyring-dialog sound-applet volume-osd applet-menus menu-titlebars; do
    f="$PATCHES/$p.sh"
    [ -f "$f" ] || continue
    info "running $p.sh"
    sudo bash "$f" || warn "$p.sh failed"
done

info "fingerprint before password at login: sudo bash $PATCHES/pam-fingerprint-first.sh"
restart_cinnamon
