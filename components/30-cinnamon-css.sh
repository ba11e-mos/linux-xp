# Cinnamon-skallet: UAC-dialog, volum-OSD, WMP8-lydapplet, XP-menyer, varsler

css_dir="$(theme_dir cinnamon)" || die "fant ikke $THEME_NAME/cinnamon - kjør komponent 10 først"
css="$css_dir/cinnamon.css"
marker="/* --- linux-xp extras --- */"

for f in "$ASSETS"/cinnamon/*.svg "$ASSETS"/cinnamon/*.png; do
    [ -e "$f" ] || continue
    cp "$f" "$css_dir/"
done
info "kopierte $(ls "$ASSETS"/cinnamon/*.svg "$ASSETS"/cinnamon/*.png 2>/dev/null | wc -l) bilder"

if marker_present "$css" "$marker"; then
    # skriv seksjonen på nytt i stedet for å legge til enda en kopi
    backup_file "$css"
    tmp="$(mktemp)"
    sed "/$(printf '%s' "$marker" | sed 's/[][\.*^$/]/\\&/g')/,\$d" "$css" > "$tmp"
    # dropp etterfølgende tomme linjer, ellers vokser filen med én per kjøring
    printf '%s\n' "$(cat "$tmp")" > "$css"
    rm -f "$tmp"
    info "erstatter tidligere linux-xp-seksjon"
else
    backup_file "$css"
fi

{ printf '\n%s\n' "$marker"; cat "$ASSETS/cinnamon/xp-extras.css"; } >> "$css"
log "la til $(wc -l < "$ASSETS/cinnamon/xp-extras.css") linjer i cinnamon.css"
