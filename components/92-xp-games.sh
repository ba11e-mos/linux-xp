# Minesweeper and Solitaire: XP's own winmine.exe and sol.exe under Wine
#
# The games are not bundled - they are Microsoft's. Download "windows xp
# games.zip" from https://archive.org/details/windows-xp-games into
# ~/Downloads, or point at the zip or an unpacked folder with XP_GAMES=/path.

have wine || { warn "wine missing (sudo apt install wine)"; return 0; }

src="${XP_GAMES:-}"
[ -n "$src" ] || src="$(find "$HOME/Downloads" -maxdepth 2 \( -iname '*xp*games*.zip' -o -iname 'winmine.exe' \) 2>/dev/null | sort | head -1)"
[ -n "$src" ] || { warn "no XP games found. Download them (see README) and run this component again."; return 0; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN
case "$src" in
    *.zip) unzip -qq -o "$src" -d "$tmp"; src="$tmp" ;;
    *.exe) src="$(dirname "$src")" ;;
esac

dir="$HOME/.local/share/xp-games"
mkdir -p "$dir"
for f in winmine.exe sol.exe cards.dll; do
    p="$(find "$src" -iname "$f" -print -quit)"
    [ -n "$p" ] || { warn "$f not in $src"; return 0; }
    cp "$p" "$dir/$f"
done

apps="$HOME/.local/share/applications"
mkdir -p "$apps"
# name <TAB> exe <TAB> icon <TAB> category <TAB> comment
while IFS=$'\t' read -r name exe icon cat comment; do
    cat > "$apps/xp-${exe%.exe}.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=$name
Comment=$comment
Exec=wine "$dir/$exe"
Path=$dir
Icon=$icon
Categories=Game;$cat;
StartupWMClass=$exe
DESKTOP
done <<'EOF'
Minesweeper	winmine.exe	gnome-mines	LogicGame	Find the mines without setting any of them off
Solitaire	sol.exe	sol	CardGame	Klondike, the way XP dealt it
EOF

update-desktop-database "$apps" >/dev/null 2>&1 || true
log "Minesweeper and Solitaire in the start menu under Games"
