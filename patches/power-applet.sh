#!/usr/bin/env bash
# Animates the battery icon while charging: the panel icon steps through the
# six charge levels (the same-size xp-charge-*-symbolic icons
# 95-symbolic-icons.sh makes), empty to full, like a phone filling up.
#
#   sudo bash power-applet.sh           apply
#   sudo bash power-applet.sh --revert  undo
#
# Both places the applet sets its panel icon go through _xpSetIcon, which
# starts the cycle for any upower icon name containing "-charging" and stops
# it for everything else (discharging, "-charged", no battery).
set -euo pipefail

A=/usr/share/cinnamon/applets/power@cinnamon.org
F=applet.js
[ "$(id -u)" -eq 0 ] || { echo "Must run as root (use sudo)." >&2; exit 1; }

if [ "${1:-}" = "--revert" ]; then
    [ -f "$A/$F.orig-xp" ] || { echo "No backup at $A/$F.orig-xp" >&2; exit 1; }
    cp -p "$A/$F.orig-xp" "$A/$F"
    echo "restored $F"
    exit 0
fi

if [ ! -f "$A/$F.orig-xp" ]; then
    cp -p "$A/$F" "$A/$F.orig-xp"
    echo "backed up $F -> $F.orig-xp"
else
    cp -p "$A/$F.orig-xp" "$A/$F"
fi

python3 - "$A/$F" <<'PY'
import io, sys
path = sys.argv[1]
s = io.open(path, encoding="utf-8").read()

reps = []

reps.append(('const Gio = imports.gi.Gio;\n',
'''const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const XP_CHARGE_FRAMES = ["000", "020", "040", "060", "080", "100"].map(n => "xp-charge-" + n + "-symbolic");
'''))

# Both icon setters (single device and display device) share this line.
s = s.replace('''                let gicon = Gio.icon_new_for_string(icon);
                this._applet_icon.gicon = gicon;''',
'''                this._xpSetIcon(icon);''')
s = s.replace('''                                let gicon = Gio.icon_new_for_string(icon);
                                this._applet_icon.gicon = gicon;''',
'''                                this._xpSetIcon(icon);''')

reps.append(('''    on_applet_removed_from_panel() {
''',
'''    _xpSetIcon(icon) {
        if (this._xpChargeId) {
            GLib.source_remove(this._xpChargeId);
            this._xpChargeId = 0;
        }
        this._applet_icon.gicon = Gio.icon_new_for_string(icon);
        if (icon.indexOf("-charging") < 0)
            return;
        let frame = 0;
        this._xpChargeId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 600, () => {
            frame = (frame + 1) % XP_CHARGE_FRAMES.length;
            this._applet_icon.gicon = Gio.icon_new_for_string(XP_CHARGE_FRAMES[frame]);
            return GLib.SOURCE_CONTINUE;
        });
    }

    on_applet_removed_from_panel() {
        if (this._xpChargeId) {
            GLib.source_remove(this._xpChargeId);
            this._xpChargeId = 0;
        }
'''))

if s.count("this._xpSetIcon(icon);") != 2:
    raise SystemExit("PATTERN NOT FOUND: icon setters (expected 2)")

for old, new in reps:
    if old not in s:
        raise SystemExit("PATTERN NOT FOUND:\n" + old[:160])
    s = s.replace(old, new, 1)

io.open(path, "w", encoding="utf-8").write(s)
print("patched %s (%d edits)" % (path, len(reps) + 2))
PY

if node --check "$A/$F" 2>/dev/null; then
    echo "syntax OK"
else
    echo "SYNTAX ERROR - rolling back" >&2
    cp -p "$A/$F.orig-xp" "$A/$F"
    exit 1
fi

echo
echo "Done. Press Ctrl+Alt+Esc to restart Cinnamon, then plug in the charger."
