# Theme and icon packs (GTK, Cinnamon, window frame, cursor)
#
# The XP packs are not bundled here - they are someone else's artwork. Put the
# zips in ~/Downloads, or point at one with XP_PACK=/path/to/pack.zip.

packs=()
if [ -n "${XP_PACK:-}" ]; then
    packs+=("$XP_PACK")
else
    while IFS= read -r p; do packs+=("$p"); done < <(
        find "$HOME/Downloads" -maxdepth 1 -iname "Windows-XP-*.zip" 2>/dev/null | sort)
fi

if theme_dir "" >/dev/null && icon_dir >/dev/null; then
    skip "theme and icons already in place"
elif [ ${#packs[@]} -eq 0 ]; then
    warn "no XP pack found. Download one (see README) and run this component again."
    return 0
else
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN
    for p in "${packs[@]}"; do
        info "extracting $(basename "$p")"
        unzip -qq -o "$p" -d "$tmp"
    done
    mkdir -p "$HOME/.themes" "$HOME/.icons"
    # the packs are laid out differently; find the dirs that really are themes/icons
    while IFS= read -r d; do cp -rn "$d" "$HOME/.themes/" 2>/dev/null || true; done < <(
        find "$tmp" -maxdepth 3 -type d \( -name "gtk-3.0" -o -name "metacity-1" \) -printf '%h\n' | sort -u)
    while IFS= read -r d; do cp -rn "$d" "$HOME/.icons/" 2>/dev/null || true; done < <(
        find "$tmp" -maxdepth 3 -name "index.theme" -path "*icon*" -printf '%h\n' | sort -u)
    while IFS= read -r d; do cp -rn "$d" "$HOME/.icons/" 2>/dev/null || true; done < <(
        find "$tmp" -maxdepth 4 -type d -name "cursors" -printf '%h\n' | sort -u)
    log "extracted"
fi

theme_dir "" >/dev/null || warn "theme '$THEME_NAME' not found after extraction"
icon_dir      >/dev/null || warn "icon theme '$ICON_NAME' not found after extraction"
