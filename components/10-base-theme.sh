# Theme, icons and cursors: B00merang's Windows XP 3.1 and ModernXP
#
# Downloaded from GitHub on first run (see README for the sources).

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN

if theme_dir "" >/dev/null; then
    skip "theme already in place"
elif z="$(fetch https://github.com/B00merang-Project/Windows-XP/archive/refs/tags/3.1.zip xp-theme.zip)"; then
    unzip -qq -o "$z" -d "$tmp/theme"
    mkdir -p "$HOME/.themes"
    cp -r "$tmp"/theme/*/"Windows XP "* "$HOME/.themes/"
    log "Luna and the other XP themes installed"
fi

if icon_dir >/dev/null; then
    skip "icons already in place"
elif z="$(fetch https://github.com/B00merang-Artwork/Windows-XP/archive/refs/tags/3.1.zip xp-icons.zip)"; then
    unzip -qq -o "$z" -d "$tmp/icons"
    mkdir -p "$HOME/.icons"
    cp -r "$tmp"/icons/*/ "$HOME/.icons/$ICON_NAME"
    log "XP icons installed"
fi

if [ -d "$HOME/.icons/$CURSOR_NAME/cursors" ]; then
    skip "cursors already in place"
elif z="$(fetch https://github.com/na0miluv/modernXP-cursor-theme/releases/download/final/ModernXP.tar.gz xp-cursors.tar.gz)"; then
    mkdir -p "$tmp/cursors" "$HOME/.icons"
    tar xzf "$z" -C "$tmp/cursors"
    cp -r "$(dirname "$(find "$tmp/cursors" -type d -name cursors -print -quit)")" "$HOME/.icons/$CURSOR_NAME"
    log "XP cursors installed"
fi

theme_dir "" >/dev/null || warn "theme '$THEME_NAME' not found after extraction"
icon_dir      >/dev/null || warn "icon theme '$ICON_NAME' not found after extraction"
