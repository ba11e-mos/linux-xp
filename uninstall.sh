#!/usr/bin/env bash
#
# Legger tilbake det install.sh endret.
#
#   ./uninstall.sh          gjenopprett alt
#   ./uninstall.sh --dry    bare vis hva som ville skjedd

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"

dry=0
[ "${1:-}" = "--dry" ] && dry=1

run() { if [ "$dry" = 1 ]; then printf '    ville kjørt: %s\n' "$*"; else "$@"; fi; }

# --- brukerfiler fra sikkerhetskopien ---
if [ -d "$BACKUP" ]; then
    log "legger tilbake filer fra $BACKUP"
    while IFS= read -r b; do
        orig="/${b#$BACKUP/}"
        info "$orig"
        run cp -a "$b" "$orig"
    done < <(find "$BACKUP" -type f)
else
    warn "ingen sikkerhetskopi i $BACKUP"
fi

# --- Cinnamons kildefiler: hvert patch-skript la igjen en .orig-xp ---
log "legger tilbake Cinnamon-kildefiler"
while IFS= read -r o; do
    info "${o%.orig-xp}"
    run sudo cp -a "$o" "${o%.orig-xp}"
done < <(sudo find /usr/share/cinnamon -name "*.orig-xp" 2>/dev/null)

# --- Firefox ---
for prof in "$HOME"/.mozilla/firefox/*.default*/; do
    [ -d "$prof" ] || continue
    log "Firefox: $(basename "$prof")"
    run rm -rf "$prof/chrome"
    run rm -f  "$prof/user.js"
    [ -f "$prof/prefs.js.bak-xp" ] && run cp -a "$prof/prefs.js.bak-xp" "$prof/prefs.js"
done

log "Ferdig. Velg temaet ditt på nytt i Innstillinger > Temaer, og logg ut og inn."
