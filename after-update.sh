#!/usr/bin/env bash
#
# Run this after a system update. It puts back what an update can undo:
#
#   Cinnamon   a cinnamon update replaces the patched files in /usr/share/cinnamon
#   GNOME      a new GNOME version turns off Dash to Panel and ArcMenu until
#              they are swapped for builds made for it
#   Firefox    a deb or tarball update replaces the installation directory,
#              taking the new-tab autoconfig with it (the snap reads it from
#              /etc/firefox, which no update touches)
#
# XFCE keeps everything in your home directory, so it has nothing to put back.
#
#   ./after-update.sh          check and repair
#   ./after-update.sh --dry    only show what it would do

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"

dry=0
[ "${1:-}" = "--dry" ] && dry=1
fixed=0

# fix <why> <component> - re-run one component, or say it would
fix() {
    log "$1"
    fixed=1
    if [ "$dry" = 1 ]; then info "--dry: would run install.sh $2"; else "$REPO/install.sh" "$2"; fi
}

# --- Cinnamon ---
# Every patch script keeps a .orig-xp copy and restores it before patching, so
# re-running one after an update would put the pre-update file back. The stale
# copies have to go first.
if [ -d /usr/share/cinnamon/js ]; then
    # A patched file shows up in dpkg --verify as changed; one the update put
    # back does not. Only those lose their .orig-xp - deleting the copy of a
    # still-patched file would make the patch back up and patch it twice.
    # Without dpkg every copy counts as stale.
    changed=""
    if have dpkg; then
        pkgs="$(dpkg -S /usr/share/cinnamon 2>/dev/null | cut -d: -f1 | tr -d ',')"
        changed="$(dpkg --verify $pkgs 2>/dev/null || true)"
    fi
    stale=()
    while IFS= read -r f; do
        [ -n "$changed" ] && grep -qF " ${f%.orig-xp}" <<<"$changed" && continue
        stale+=("$f")
    done < <(find /usr/share/cinnamon -name "*.orig-xp" 2>/dev/null | sort)
    if [ ${#stale[@]} -gt 0 ]; then
        log "a Cinnamon update replaced ${#stale[@]} patched files"
        printf '    %s\n' "${stale[@]%.orig-xp}"
        [ "$dry" = 0 ] && sudo rm -f "${stale[@]}"
        fix "re-patching Cinnamon" 50
        info "Ctrl+Alt+Esc to restart Cinnamon"
        info "PAM: an update may also have replaced /etc/pam.d/lightdm. If the login"
        info "screen asks for a password before the fingerprint, run:"
        info "  sudo bash $PATCHES/pam-fingerprint-first.sh"
    fi
fi

# --- GNOME ---
if have gnome-shell; then
    ver="$(gnome-shell --version 2>/dev/null | grep -oE '[0-9]+' | head -1)"
    for uuid in dash-to-panel@jderose9.github.com arcmenu@arcmenu.com; do
        meta="$HOME/.local/share/gnome-shell/extensions/$uuid/metadata.json"
        [ -f "$meta" ] || continue
        if ! python3 -c 'import json,sys; sys.exit(sys.argv[2] not in json.load(open(sys.argv[1]))["shell-version"])' "$meta" "$ver"; then
            fix "GNOME $ver is newer than the taskbar and Start menu builds" 35
            break
        fi
    done
fi

# --- Firefox (deb or tarball) ---
for d in /usr/lib/firefox /usr/lib64/firefox /opt/firefox; do
    if [ -x "$d/firefox" ] && [ ! -f "$d/linux-xp.cfg" ]; then
        fix "a Firefox update removed the new-tab setup in $d" 65
        break
    fi
done

[ "$fixed" = 1 ] && log "Done." || log "Nothing to put back."
