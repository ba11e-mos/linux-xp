#!/usr/bin/env bash
# Tags the network and printer applet menus so the theme can style them
# as Windows XP dialogs without touching every other panel menu.
#
#   sudo bash ~/xp-uac/xp-menus.sh           apply
#   sudo bash ~/xp-uac/xp-menus.sh --revert  undo
set -euo pipefail

A=/usr/share/cinnamon/applets
[ "$(id -u)" -eq 0 ] || { echo "Must run as root (use sudo)." >&2; exit 1; }

for name in network printers; do
    F="$A/$name@cinnamon.org/applet.js"

    if [ "${1:-}" = "--revert" ]; then
        if [ -f "$F.orig-xp" ]; then
            cp -p "$F.orig-xp" "$F"
            echo "restored $name"
        fi
        continue
    fi

    if [ ! -f "$F.orig-xp" ]; then
        cp -p "$F" "$F.orig-xp"
        echo "backed up $name"
    else
        cp -p "$F.orig-xp" "$F"
    fi

    python3 - "$F" <<'PY'
import io, sys
path = sys.argv[1]
s = io.open(path, encoding="utf-8").read()
# The calendar passes this.orientation, the others a bare orientation.
tag = '            this.menu.actor.add_style_class_name("xp-dialog-menu");'
for arg in ("orientation", "this.orientation"):
    old = "this.menu = new Applet.AppletPopupMenu(this, %s);" % arg
    if old in s:
        s = s.replace(old, old + "\n" + tag, 1)
        break
else:
    raise SystemExit("PATTERN NOT FOUND in " + path)
io.open(path, "w", encoding="utf-8").write(s)
print("patched", path)
PY

    if node --check "$F" 2>/dev/null; then
        echo "syntax OK: $name"
    else
        echo "SYNTAX ERROR in $name - rolling back" >&2
        cp -p "$F.orig-xp" "$F"
        exit 1
    fi
done

echo
echo "Done. Press Ctrl+Alt+Esc to restart Cinnamon."
