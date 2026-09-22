# The symbolic icon names the panel applets ask for and the pack lacks

icons="$(icon_dir)" || { warn "icon theme not found"; return 0; }
man="$ASSETS/icons/symbolic-aliases.tsv"
[ -f "$man" ] || return 0

made=0 miss=0
while IFS=$'\t' read -r alias src; do
    case "$alias" in ''|'#'*) continue ;; esac
    [ -f "$icons/$src" ] || { miss=$((miss+1)); continue; }
    [ -f "$icons/$alias" ] && continue
    mkdir -p "$(dirname "$icons/$alias")"
    cp "$icons/$src" "$icons/$alias"
    made=$((made+1))
done < "$man"

# Icons that were redrawn (the media buttons, VS Code) ship as files.
( cd "$ASSETS/icons" && find . -name "*.png" -printf '%P\n' ) | while read -r rel; do
    mkdir -p "$icons/$(dirname "$rel")"
    cp "$ASSETS/icons/$rel" "$icons/$rel"
done

# The XP pack draws Windows Update, but only at 128px, so the tray falls back
# to hicolor's shield at 16-24px. Scale the pack's own art down to the status
# names the Update Manager asks for.
mu="$icons/128x128/apps/mintupdate.png"
if [ -f "$mu" ] && have convert; then
    n=0
    for sz in 16 22 24 32 48; do
        d="$icons/${sz}x${sz}/apps"; [ -d "$d" ] || continue
        convert "$mu" -filter Lanczos -resize ${sz}x${sz} -strip "$d/mintupdate.png"
        for st in updates-available up-to-date error checking installing; do
            cp "$d/mintupdate.png" "$d/mintupdate-$st.png"
            cp "$d/mintupdate.png" "$d/mintupdate-$st-symbolic.png"
            n=$((n+2))
        done
    done
    log "$n Update Manager status icons generated"
fi

gtk-update-icon-cache -f -t "$icons" >/dev/null 2>&1 || true
log "$made aliases created, $miss sources missing"
