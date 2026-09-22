#!/usr/bin/env bash
#
# linux-xp - turn Linux Mint Cinnamon into Windows XP.
#
#   ./install.sh                 run every component
#   ./install.sh 30 60           run only those components
#   ./install.sh --list          list the components
#
# Each component is idempotent: running it twice changes nothing the second
# time. Originals are copied to ~/.local/share/linux-xp/backups before any
# file is touched.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"

usage() {
    sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

list_components() {
    local f
    for f in "$REPO"/components/*.sh; do
        printf '  %s%s%s  %s\n' "$BOLD" "$(basename "$f" .sh | cut -d- -f1)" "$OFF" \
            "$(sed -n '1s/^# \{0,1\}//p' "$f")"
    done
}

wanted=()
for a in "$@"; do
    case "$a" in
        -h|--help) usage ;;
        -l|--list) list_components; exit 0 ;;
        -*) die "unknown flag: $a" ;;
        *) wanted+=("$a") ;;
    esac
done

is_cinnamon || warn "Cinnamon not found - the shell components will skip themselves"
mkdir -p "$BACKUP"

ran=0
for f in "$REPO"/components/*.sh; do
    num="$(basename "$f" .sh | cut -d- -f1)"
    if [ ${#wanted[@]} -gt 0 ]; then
        printf '%s\n' "${wanted[@]}" | grep -qx "$num" || continue
    fi
    log "$(sed -n '1s/^# \{0,1\}//p' "$f")"
    # shellcheck disable=SC1090
    ( source "$f" ) || warn "component $num failed - continuing"
    ran=$((ran+1))
done

[ "$ran" -gt 0 ] || die "no components ran (check the numbers with --list)"

log "Done. Log out and back in for everything to take effect."
