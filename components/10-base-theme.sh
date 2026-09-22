# Tema- og ikonpakker (GTK, Cinnamon, vindusramme, musepeker)
#
# Selve XP-pakkene følger ikke med her - de er tredjeparts kunst. Legg zip-ene
# i ~/Downloads, eller pek på dem med XP_PACK=/sti/til/pakke.zip. Se README.

packs=()
if [ -n "${XP_PACK:-}" ]; then
    packs+=("$XP_PACK")
else
    while IFS= read -r p; do packs+=("$p"); done < <(
        find "$HOME/Downloads" -maxdepth 1 -iname "Windows-XP-*.zip" 2>/dev/null | sort)
fi

if theme_dir "" >/dev/null && icon_dir >/dev/null; then
    skip "tema og ikoner er allerede på plass"
elif [ ${#packs[@]} -eq 0 ]; then
    warn "fant ingen XP-pakke. Last den ned (se README) og kjør denne komponenten igjen."
    return 0
else
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN
    for p in "${packs[@]}"; do
        info "pakker ut $(basename "$p")"
        unzip -qq -o "$p" -d "$tmp"
    done
    mkdir -p "$HOME/.themes" "$HOME/.icons"
    # pakkene har ulik mappestruktur; finn mappene som faktisk er temaer/ikoner
    while IFS= read -r d; do cp -rn "$d" "$HOME/.themes/" 2>/dev/null || true; done < <(
        find "$tmp" -maxdepth 3 -type d \( -name "gtk-3.0" -o -name "metacity-1" \) -printf '%h\n' | sort -u)
    while IFS= read -r d; do cp -rn "$d" "$HOME/.icons/" 2>/dev/null || true; done < <(
        find "$tmp" -maxdepth 3 -name "index.theme" -path "*icon*" -printf '%h\n' | sort -u)
    while IFS= read -r d; do cp -rn "$d" "$HOME/.icons/" 2>/dev/null || true; done < <(
        find "$tmp" -maxdepth 4 -type d -name "cursors" -printf '%h\n' | sort -u)
    log "pakket ut"
fi

theme_dir "" >/dev/null || warn "temaet '$THEME_NAME' ble ikke funnet etter utpakking"
icon_dir      >/dev/null || warn "ikontemaet '$ICON_NAME' ble ikke funnet etter utpakking"
