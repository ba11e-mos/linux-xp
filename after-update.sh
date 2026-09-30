#!/usr/bin/env bash
#
# Run this after a Mint update that touched cinnamon, lightdm or firefox.
#
# Everything this setup does lives in your home directory except a handful
# of files under /usr/share/cinnamon, which an update replaces. Those are
# what this puts back.
#
# The trap it avoids: every patch script keeps a .orig-xp copy and restores
# it before patching, so re-running one after an update would overwrite the
# newly installed file with the pre-update version. The stale copies have to
# go first.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"

dry=0
[ "${1:-}" = "--dry" ] && dry=1

mapfile -t stale < <(find /usr/share/cinnamon -name "*.orig-xp" 2>/dev/null | sort)

if [ ${#stale[@]} -eq 0 ]; then
    info "no .orig-xp copies under /usr/share/cinnamon - nothing to refresh"
else
    log "stale backups from before the update"
    for f in "${stale[@]}"; do
        printf '    %s\n' "$f"
    done
    if [ "$dry" = 1 ]; then
        info "--dry: would delete those and re-run the patches"
        exit 0
    fi
    for f in "${stale[@]}"; do
        sudo rm -f "$f"
    done
    log "removed ${#stale[@]} stale backups"
fi

[ "$dry" = 1 ] && exit 0

"$REPO/install.sh" 50

log "Done. Ctrl+Alt+Esc to restart Cinnamon."
info "PAM: an update may have replaced /etc/pam.d/lightdm. If the login"
info "screen asks for a password before the fingerprint, run:"
info "  sudo bash $PATCHES/pam-fingerprint-first.sh"
