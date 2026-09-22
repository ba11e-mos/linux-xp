# Cinnamon shell: UAC dialog, volume OSD, WMP8 sound applet, XP menus, notifications

require_cinnamon || return 0

css_dir="$(theme_dir cinnamon)" || die "no $THEME_NAME/cinnamon - run component 10 first"
css="$css_dir/cinnamon.css"
marker="/* --- linux-xp extras --- */"

for f in "$ASSETS"/cinnamon/*.svg "$ASSETS"/cinnamon/*.png; do
    [ -e "$f" ] || continue
    cp "$f" "$css_dir/"
done
info "copied $(ls "$ASSETS"/cinnamon/*.svg "$ASSETS"/cinnamon/*.png 2>/dev/null | wc -l) images"

if marker_present "$css" "$marker"; then
    # rewrite the section instead of appending another copy
    backup_file "$css"
    tmp="$(mktemp)"
    sed "/$(printf '%s' "$marker" | sed 's/[][\.*^$/]/\\&/g')/,\$d" "$css" > "$tmp"
    # drop trailing blank lines, or the file grows by one per run
    printf '%s\n' "$(cat "$tmp")" > "$css"
    rm -f "$tmp"
    info "replacing the previous linux-xp section"
else
    backup_file "$css"
fi

{ printf '\n%s\n' "$marker"; cat "$ASSETS/cinnamon/xp-extras.css"; } >> "$css"
log "appended $(wc -l < "$ASSETS/cinnamon/xp-extras.css") lines to cinnamon.css"
