# XP games under Wine: Minesweeper, Solitaire, Spider, FreeCell, Hearts, Pinball
#
# The games are Microsoft's and not bundled: they are downloaded from
# archive.org/details/windows-xp-games on first run. XP_GAMES=/path uses a
# local zip or folder.
# The MSN Internet games in that zip are left out: their servers are gone.

have wine || { warn "wine missing (sudo apt install wine)"; return 0; }

src="${XP_GAMES:-}"
[ -n "$src" ] || src="$(fetch "https://archive.org/download/windows-xp-games/windows%20xp%20games.zip" xp-games.zip)" || return 0

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

# Hearts is linked against MFC42u.DLL, which neither the zip nor Wine has.
# winetricks installs it from Microsoft's Visual C++ 6 redistributable.
pfx="${WINEPREFIX:-$HOME/.wine}"
if [ -f "$dir/mshearts.exe" ] && ! compgen -G "$pfx/drive_c/windows/*/mfc42u.dll" >/dev/null; then
    if have winetricks; then
        info "installing MFC42 for Hearts (winetricks)"
        winetricks -q mfc42 >/dev/null 2>&1 || warn "winetricks mfc42 failed - Hearts will not start"
    else
        warn "winetricks missing - Hearts will not start"
    fi
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
