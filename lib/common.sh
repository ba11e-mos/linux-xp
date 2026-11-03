# Shared helpers. Sourced by install.sh and every component.

set -o pipefail

BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; OFF=$'\033[0m'

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS="$REPO/assets"
PATCHES="$REPO/patches"
BACKUP="${XP_BACKUP:-$HOME/.local/share/linux-xp/backups}"

THEME_NAME="${XP_THEME:-Windows XP Luna}"
ICON_NAME="${XP_ICONS:-Windows-XP}"
CURSOR_NAME="${XP_CURSORS:-Windows-XP-Cursors}"

log()  { printf '%s==>%s %s\n' "$GRN" "$OFF" "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '%s !!%s %s\n' "$YEL" "$OFF" "$*" >&2; }
die()  { printf '%s !!%s %s\n' "$RED" "$OFF" "$*" >&2; exit 1; }
skip() { printf '%s -- %s%s\n' "$DIM" "$*" "$OFF"; }

have() { command -v "$1" >/dev/null 2>&1; }

# fetch <url> <file> - download once into the cache, print the local path.
# A browser User-Agent because some hosts (icon-icons.com) refuse curl's.
CACHE="${XP_CACHE:-$HOME/.cache/linux-xp}"
fetch() {
    local out="$CACHE/$2"
    if [ ! -s "$out" ]; then
        mkdir -p "$CACHE"
        info "downloading $2" >&2
        curl -fsSL -A "Mozilla/5.0 (X11; Linux x86_64; rv:152.0) Gecko/20100101 Firefox/152.0" \
            -o "$out.part" "$1" || { rm -f "$out.part"; warn "download failed: $1"; return 1; }
        mv "$out.part" "$out"
    fi
    printf '%s\n' "$out"
}

# theme_dir <subpath> -> first existing location of the installed theme
theme_dir() {
    local sub="$1" d
    for d in "$HOME/.themes/$THEME_NAME" "/usr/share/themes/$THEME_NAME"; do
        [ -d "$d/$sub" ] && { printf '%s\n' "$d/$sub"; return 0; }
    done
    return 1
}

icon_dir() {
    local d
    for d in "$HOME/.icons/$ICON_NAME" "$HOME/.local/share/icons/$ICON_NAME" "/usr/share/icons/$ICON_NAME"; do
        [ -d "$d" ] && { printf '%s\n' "$d"; return 0; }
    done
    return 1
}

# backup_file <path> - keep one pristine copy, never overwrite it on re-runs
backup_file() {
    local f="$1" rel dest
    [ -e "$f" ] || return 0
    rel="${f#/}"; dest="$BACKUP/$rel"
    [ -e "$dest" ] && return 0
    mkdir -p "$(dirname "$dest")"
    cp -a "$f" "$dest"
    info "backup: $dest"
}

# marker_present <file> <marker>  - lets components stay idempotent
marker_present() { [ -e "$1" ] && grep -qF "$2" "$1"; }

# Desktop detection. Only some components are Cinnamon-specific; the rest
# (Firefox, VS Code, icons, terminal) work on any desktop.
is_cinnamon() {
    have cinnamon && [ -d /usr/share/cinnamon ]
}

# GNOME Shell (Ubuntu's default desktop). Cinnamon is a fork, so rule it out.
is_gnome() { have gnome-shell && ! is_cinnamon; }

# XFCE keeps its settings in Xfconf, not gsettings.
is_xfce() { have xfconf-query && have xfce4-session; }

# xfset <channel> <property> <type> <value> - set an Xfconf property, creating it if missing
xfset() { xfconf-query -c "$1" -p "$2" -n -t "$3" -s "$4" 2>/dev/null || warn "could not set $1 $2"; }

require_cinnamon() {
    is_cinnamon && return 0
    skip "needs Cinnamon - skipped on this desktop"
    return 1
}

# Schema prefix for the desktop settings that exist under both org.cinnamon
# and org.gnome with the same keys.
desktop_schema() {
    if is_cinnamon; then printf 'org.cinnamon.desktop'; else printf 'org.gnome.desktop'; fi
}

restart_cinnamon() {
    if have dbus-send; then
        dbus-send --session --dest=org.Cinnamon --type=method_call \
            /org/Cinnamon org.Cinnamon.Eval string:'global.reexec_self()' >/dev/null 2>&1 \
            && { info "Cinnamon restarted"; return 0; }
    fi
    warn "Could not restart Cinnamon automatically - press Ctrl+Alt+Esc."
}
