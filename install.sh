#!/usr/bin/env bash
#
# linux-xp - turn Linux Mint Cinnamon into Windows XP.
#
#   ./install.sh             ask about each part, then install what you chose
#   ./install.sh --yes       install everything without asking
#   ./install.sh 30 60       run only those components, no questions
#   ./install.sh --list      list the components
#
# Everything the parts need is downloaded on the way (sources in README).
# Each component is idempotent, and originals are copied to
# ~/.local/share/linux-xp/backups before any file is touched.

set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/lib/common.sh"

# components | what must be installed (command or path:apt package) | env | question
PARTS=(
"10 20 40 95|convert:imagemagick unzip:unzip curl:curl||Luna theme, XP icons and cursors (the base for everything else)"
"20||XP_WALLPAPER=bliss|Bliss as the wallpaper"
"30 50|||Start menu, XP dialogs, volume OSD, Media Player sound applet, charging battery (sudo)"
"15|ffmpeg:ffmpeg unzip:unzip||XP sounds: startup, shutdown, balloons, USB in/out"
"57|lightdm:lightdm git:git||XP login screen (sudo)"
"55|xss-lock:xss-lock /usr/libexec/xscreensaver/pipes:xscreensaver-gl||3D Pipes screen saver, then lock to the login screen"
"85|git:git plymouth:plymouth||XP boot screen (sudo)"
"60 65|||Firefox as Internet Explorer 6 (sudo)"
"70|||VS Code with a Luna theme"
"80|unzip:unzip|XP_TERMINAL_FONT=1|Terminal as cmd.exe, with the VGA raster font"
"90|convert:imagemagick||Teams with the MSN icon"
"92|wine:wine 7z:p7zip-full convert:imagemagick unzip:unzip||XP games: Minesweeper, Solitaire, Spider, FreeCell, Hearts, Pinball"
)

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

# ask <question> - yes unless the answer starts with n
ask() {
    local a
    [ "$all" = 1 ] && return 0
    read -r -p "  $1? [Y/n] " a </dev/tty || a=""
    case "$a" in n*|N*) return 1 ;; esac
}

wanted=() all=0 picked=0
for a in "$@"; do
    case "$a" in
        -h|--help) usage ;;
        -l|--list) list_components; exit 0 ;;
        -y|--yes) all=1 ;;
        -*) die "unknown flag: $a" ;;
        *) wanted+=("$a"); picked=1 ;;
    esac
done

is_cinnamon || warn "Cinnamon not found - the shell components will skip themselves"
mkdir -p "$BACKUP"

if [ "$picked" = 0 ]; then
    log "Choose what to install"
    pkgs=()
    for p in "${PARTS[@]}"; do
        IFS='|' read -r comps needs env text <<<"$p"
        ask "$text" || continue
        read -ra c <<<"$comps"; wanted+=("${c[@]}")
        [ -n "$env" ] && export "${env?}"
        for n in $needs; do
            case "${n%%:*}" in
                /*) [ -e "${n%%:*}" ] ;;
                *)  have "${n%%:*}" ;;
            esac || pkgs+=("${n#*:}")
        done
    done
    [ ${#wanted[@]} -gt 0 ] || die "nothing chosen"

    # One password prompt up front, then the rest runs unattended.
    sudo -v || die "sudo is needed for the packages and the system parts"
    if [ ${#pkgs[@]} -gt 0 ]; then
        mapfile -t pkgs < <(printf '%s\n' "${pkgs[@]}" | sort -u)
        log "Installing packages: ${pkgs[*]}"
        sudo apt-get install -y "${pkgs[@]}" || warn "some packages failed - the parts that need them will say so"
    fi
fi

ran=0
for f in "$REPO"/components/*.sh; do
    num="$(basename "$f" .sh | cut -d- -f1)"
    printf '%s\n' "${wanted[@]}" | grep -qx "$num" || continue
    log "$(sed -n '1s/^# \{0,1\}//p' "$f")"
    # shellcheck disable=SC1090
    ( source "$f" ) || warn "component $num failed - continuing"
    ran=$((ran+1))
done

[ "$ran" -gt 0 ] || die "no components ran (check the numbers with --list)"

log "Done. Log out and back in for everything to take effect."
