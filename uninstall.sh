#!/usr/bin/env bash
#
# Put back what install.sh changed.
#
#   ./uninstall.sh          restore everything
#   ./uninstall.sh --dry    only show what would happen

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"

dry=0
[ "${1:-}" = "--dry" ] && dry=1

run() { if [ "$dry" = 1 ]; then printf '    would run: %s\n' "$*"; else "$@"; fi; }

# --- user files from the backup tree ---
if [ -d "$BACKUP" ]; then
    log "restoring files from $BACKUP"
    while IFS= read -r b; do
        orig="/${b#$BACKUP/}"
        info "$orig"
        run cp -a "$b" "$orig"
    done < <(find "$BACKUP" -type f)
else
    warn "no backup in $BACKUP"
fi

# --- Cinnamon source files: each patch script left an .orig-xp behind ---
log "restoring Cinnamon source files"
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

log "Done. Pick your theme again in Settings > Themes, then log out and in."
