# XP's games under Wine: Minesweeper, Solitaire, Spider Solitaire, FreeCell,
# Hearts and 3D Pinball - Space Cadet
#
# The games are not bundled - they are Microsoft's. Download "windows xp
# games.zip" from https://archive.org/details/windows-xp-games into
# ~/Downloads, or point at the zip or an unpacked folder with XP_GAMES=/path.
# The MSN Internet games in that zip are left out: their servers are gone.

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
for f in winmine.exe sol.exe spider.exe freecell.exe mshearts.exe cards.dll; do
    p="$(find "$src" -iname "$f" -print -quit)"
    [ -n "$p" ] && cp "$p" "$dir/$f" || warn "$f not in $src"
done
pin="$(find "$src" -iname 'PINBALL.EXE' -printf '%h\n' -quit)"
if [ -n "$pin" ]; then
    mkdir -p "$dir/Pinball" && cp -r "$pin/." "$dir/Pinball/"
else
    warn "Pinball not in $src"
fi

apps="$HOME/.local/share/applications"
icons="$HOME/.local/share/icons/hicolor/48x48/apps"
mkdir -p "$apps" "$icons"
n=0
# id <TAB> exe (relative to $dir) <TAB> name <TAB> category <TAB> comment
while IFS=$'\t' read -r id exe name cat comment; do
    [ -f "$dir/$exe" ] || continue
    # The game's own 48px icon: of the 48px images in the exe, the largest
    # file is the 32-bit one with the soft edges.
    icon=applications-games
    if have 7z && have convert; then
        x="$tmp/ico-$id"
        7z x -y -o"$x" "$dir/$exe" '.rsrc/ICON/*' >/dev/null 2>&1
        best="$(for f in "$x"/.rsrc/ICON/*.ico; do
                    [ "$(identify -format %w "$f[0]" 2>/dev/null)" = 48 ] && echo "$(stat -c%s "$f") $f"
                done | sort -n | tail -1 | cut -d' ' -f2-)"
        [ -n "$best" ] && convert "$best[0]" "$icons/xp-$id.png" && icon="xp-$id"
    fi
    cat > "$apps/xp-$id.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=$name
Comment=$comment
Exec=wine "$dir/$exe"
Path=$(dirname "$dir/$exe")
Icon=$icon
Categories=Game;$cat;
StartupWMClass=$(basename "$exe")
DESKTOP
    n=$((n+1))
done <<'EOF'
winmine	winmine.exe	Minesweeper	LogicGame	Find the mines without setting any of them off
sol	sol.exe	Solitaire	CardGame	Klondike, the way XP dealt it
spider	spider.exe	Spider Solitaire	CardGame	Build eight runs of King to Ace
freecell	freecell.exe	FreeCell	CardGame	Solitaire with four free cells
mshearts	mshearts.exe	Hearts	CardGame	Avoid the hearts and the Queen of Spades
pinball	Pinball/PINBALL.EXE	3D Pinball - Space Cadet	ArcadeGame	The Space Cadet table
EOF

gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
update-desktop-database "$apps" >/dev/null 2>&1 || true
log "$n XP games in the start menu under Games"
