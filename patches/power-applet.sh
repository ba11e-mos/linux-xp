#!/usr/bin/env bash
# Battery icon from the six XP cells (the same-size xp-charge-*-symbolic
# icons 95-symbolic-icons.sh makes): while charging it steps through them,
# empty to full, like a phone filling up; otherwise it shows the cell
# nearest the charge. upower's own names are too coarse for that -
# battery-good covers roughly 40-80%, so 43% looked almost full.
#
#   sudo bash power-applet.sh           apply
#   sudo bash power-applet.sh --revert  undo
#
# Both places the applet sets its panel icon go through _xpSetIcon, which
# animates for any upower icon name containing "-charging" and picks a cell
# by percentage for the other battery-* names.
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
'''                this._xpSetIcon(icon, percentage);''')
s = s.replace('''                                let gicon = Gio.icon_new_for_string(icon);
                                this._applet_icon.gicon = gicon;''',
'''                                this._xpSetIcon(icon, this._proxy.Percentage);''')

reps.append(('''    on_applet_removed_from_panel() {
''',
'''    _xpSetIcon(icon, percentage) {
        // The callers only come here when the icon name changes, and the
        // name stays the same across a whole upower band. Leave a name that
        // never matches, so every update comes back for the percentage.
        this.panel_icon_name = null;
        if (icon.indexOf("-charging") >= 0) {
            if (!this._xpChargeId) {
                this._xpFrame = 0;
                this._xpChargeId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 600, () => {
                    this._xpFrame = (this._xpFrame + 1) % XP_CHARGE_FRAMES.length;
                    this._applet_icon.gicon = Gio.icon_new_for_string(XP_CHARGE_FRAMES[this._xpFrame]);
                    return GLib.SOURCE_CONTINUE;
                });
            }
            this._applet_icon.gicon = Gio.icon_new_for_string(XP_CHARGE_FRAMES[this._xpFrame]);
            return;
        }
        if (this._xpChargeId) {
            GLib.source_remove(this._xpChargeId);
            this._xpChargeId = 0;
        }
        // upower hands over a serialized GThemedIcon (". GThemedIcon
        // battery-level-30-symbolic battery-good-symbolic ..."), not one name;
        // its battery-level-NN also gives the charge when the caller has none.
        if (typeof percentage != "number") {
            let m = /battery-level-(\\d+)/.exec(icon);
            if (m)
                percentage = parseInt(m[1]);
        }
        if (/battery-/.test(icon) && !/missing/.test(icon) && typeof percentage == "number") {
            let i = Math.max(0, Math.min(XP_CHARGE_FRAMES.length - 1, Math.round(percentage / 20)));
            icon = XP_CHARGE_FRAMES[i];
        }
        this._applet_icon.gicon = Gio.icon_new_for_string(icon);
    }

    on_applet_removed_from_panel() {
        if (this._xpChargeId) {
            GLib.source_remove(this._xpChargeId);
            this._xpChargeId = 0;
        }
'''))

if s.count("this._xpSetIcon(icon, ") != 2:
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
