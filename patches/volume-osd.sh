#!/usr/bin/env bash
# Draws the volume OSD level as a Windows-style trackbar: a wedge that
# fills with the level, a sunken track and a slider thumb.
#
#   sudo bash ~/xp-uac/osd-volume.sh           apply
#   sudo bash ~/xp-uac/osd-volume.sh --revert  undo
#
# Only osdWindow.js is touched. The drawing subclasses BarLevel and
# overrides vfunc_repaint, so barLevel.js itself is untouched and every
# other level bar in Cinnamon keeps its normal capsule.
set -euo pipefail

UI=/usr/share/cinnamon/js/ui
F=osdWindow.js
[ "$(id -u)" -eq 0 ] || { echo "Must run as root (use sudo)." >&2; exit 1; }

if [ "${1:-}" = "--revert" ]; then
    [ -f "$UI/$F.orig-xp" ] || { echo "No backup at $UI/$F.orig-xp" >&2; exit 1; }
    cp -p "$UI/$F.orig-xp" "$UI/$F"
    echo "restored $F"
    exit 0
fi

if [ ! -f "$UI/$F.orig-xp" ]; then
    cp -p "$UI/$F" "$UI/$F.orig-xp"
    echo "backed up $F -> $F.orig-xp"
else
    cp -p "$UI/$F.orig-xp" "$UI/$F"
fi

python3 - "$UI/$F" <<'PY'
import io, sys
path = sys.argv[1]
s = io.open(path, encoding="utf-8").read()

reps = []

reps.append(("""var OsdWindow = GObject.registerClass(""",
"""// A Windows-style trackbar in place of the capsule bar. Subclassing
// BarLevel keeps its value/maximum-value properties, so setLevel() can
// still animate, and leaves barLevel.js alone for everything else.
var XpLevel = GObject.registerClass(
class XpLevel extends BarLevel.BarLevel {
    vfunc_repaint() {
        const cr = this.get_context();
        const [width, height] = this.get_surface_size();

        const max = this._maxValue > 0 ? this._maxValue : 1;
        const ratio = Math.max(0, Math.min(1, this._value / max));

        // Anchor the layout to the bottom edge: the thumb is the tallest
        // thing here, so placing the track by a fraction of the height
        // pushes its lower half outside the drawing area.
        const thumbW = 7;
        const thumbH = 14;
        const trackY = Math.round(height - thumbH / 2 - 2) + 0.5;
        const wedgeBottom = Math.round(trackY - thumbH / 2 - 4) + 0.5;
        const wedgeTop = 1.5;
        const usable = Math.max(1, width - thumbW);
        const thumbCx = thumbW / 2 + usable * ratio;

        // Wedge, filled up to the current level.
        cr.save();
        cr.rectangle(0, 0, thumbCx, height);
        cr.clip();
        cr.moveTo(0, wedgeBottom);
        cr.lineTo(width, wedgeBottom);
        cr.lineTo(width, wedgeTop);
        cr.closePath();
        cr.setSourceRGBA(0.235, 0.749, 0.0, 1.0);
        cr.fill();
        cr.restore();

        // Wedge outline.
        cr.setLineWidth(1);
        cr.setSourceRGBA(0.25, 0.25, 0.25, 1.0);
        cr.moveTo(0.5, wedgeBottom);
        cr.lineTo(width - 0.5, wedgeBottom);
        cr.lineTo(width - 0.5, wedgeTop);
        cr.closePath();
        cr.stroke();

        // Etched track: a grey line with a white line under it.
        cr.setSourceRGBA(0.50, 0.50, 0.47, 1.0);
        cr.moveTo(0.5, trackY);
        cr.lineTo(width - 0.5, trackY);
        cr.stroke();
        cr.setSourceRGBA(1.0, 1.0, 1.0, 1.0);
        cr.moveTo(0.5, trackY + 1);
        cr.lineTo(width - 0.5, trackY + 1);
        cr.stroke();

        // Slider thumb.
        const tx = Math.round(thumbCx - thumbW / 2) + 0.5;
        const ty = Math.round(trackY - thumbH / 2) + 0.5;
        cr.rectangle(tx, ty, thumbW, thumbH);
        cr.setSourceRGBA(0.925, 0.914, 0.847, 1.0);
        cr.fillPreserve();
        cr.setSourceRGBA(0.25, 0.25, 0.25, 1.0);
        cr.stroke();

        cr.$dispose();
    }
});

var OsdWindow = GObject.registerClass("""))

reps.append(("""        this._level = new BarLevel.BarLevel({
            style_class: 'level',
            value: 0,
        });""",
"""        this._level = new XpLevel({
            style_class: 'level',
            value: 0,
        });"""))

for old, new in reps:
    if old not in s:
        raise SystemExit("PATTERN NOT FOUND:\\n" + old[:140])
    s = s.replace(old, new, 1)

io.open(path, "w", encoding="utf-8").write(s)
print("patched", path)
PY

if node --check "$UI/$F" 2>/dev/null; then
    echo "syntax OK"
else
    echo "SYNTAX ERROR - rolling back" >&2
    cp -p "$UI/$F.orig-xp" "$UI/$F"
    exit 1
fi

echo
echo "Done. Press Ctrl+Alt+Esc to restart Cinnamon, then press a volume key."
