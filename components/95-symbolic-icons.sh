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

gtk-update-icon-cache -f -t "$icons" >/dev/null 2>&1 || true
log "$made aliases created, $miss sources missing"
