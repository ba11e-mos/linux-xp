#!/usr/bin/env bash
# Gives Cinnamon's keyring prompt the same XP caption bar as the UAC dialog.
#
#   sudo bash ~/xp-uac/keyring-dialog.sh
#
# The keyring prompt is a Cinnamon dialog, not gcr-prompter - it already
# carries the .prompt-dialog style class, so the body is themed. What it
# lacks is the caption strip, which is added here the same way
# apply.sh adds it to the polkit dialog.
set -euo pipefail

UI=/usr/share/cinnamon/js/ui
F=keyringPrompt.js
[ "$(id -u)" -eq 0 ] || { echo "Must run as root (use sudo)." >&2; exit 1; }

if [ ! -f "$UI/$F.orig-xp" ]; then
    cp -p "$UI/$F" "$UI/$F.orig-xp"
    echo "backed up $F -> $F.orig-xp"
else
    cp -p "$UI/$F.orig-xp" "$UI/$F"
    echo "restored $F from backup before patching"
fi

python3 - "$UI/$F" <<'PY'
import io, sys
path = sys.argv[1]
s = io.open(path, encoding="utf-8").read()

reps = []

# The caption strip goes in before the message content, so it sits at the
# top of the dialog the way a window title bar does.
reps.append(('''        let content = new Dialog.MessageDialogContent();''',
'''        let titleBar = new St.BoxLayout({
            style_class: 'uac-title-bar',
            vertical: false,
        });

        let titleIcon = new St.Icon({
            style_class: 'uac-title-icon',
            icon_name: 'linuxmint-logo-ring-symbolic',
            icon_size: 16,
        });
        titleBar.add(titleIcon, { x_fill: false, y_fill: false, y_align: St.Align.MIDDLE });

        let titleLabel = new St.Label({
            style_class: 'uac-title-label',
            text: _("Windows Security"),
        });
        titleBar.add(titleLabel, { expand: true, x_fill: true, y_align: St.Align.MIDDLE });

        let closeButton = new St.Button({
            style_class: 'uac-close-button',
            can_focus: true,
        });
        closeButton.connect('clicked', () => this._onCancelButton());
        titleBar.add(closeButton, { x_fill: false, y_fill: false, y_align: St.Align.MIDDLE });

        // Drag the dialog by its caption, like a real window. Negative
        // margins would crash St, so the actor is translated instead.
        titleBar.reactive = true;
        titleBar.connect('button-press-event', (actor, event) => {
            let [x, y] = event.get_coords();
            this._dragOrigin = [x, y,
                this.actor.translation_x, this.actor.translation_y];
            this._dragMotionId = global.stage.connect('motion-event', (stage, ev) => {
                if (!this._dragOrigin)
                    return Clutter.EVENT_PROPAGATE;
                let [mx, my] = ev.get_coords();
                let [ox, oy, tx, ty] = this._dragOrigin;
                this.actor.translation_x = tx + (mx - ox);
                this.actor.translation_y = ty + (my - oy);
                return Clutter.EVENT_STOP;
            });
            this._dragReleaseId = global.stage.connect('button-release-event', () => {
                this._dragOrigin = null;
                if (this._dragMotionId) {
                    global.stage.disconnect(this._dragMotionId);
                    this._dragMotionId = 0;
                }
                if (this._dragReleaseId) {
                    global.stage.disconnect(this._dragReleaseId);
                    this._dragReleaseId = 0;
                }
                return Clutter.EVENT_STOP;
            });
            return Clutter.EVENT_STOP;
        });

        this.contentLayout.add_child(titleBar);

        let content = new Dialog.MessageDialogContent();'''))

for old, new in reps:
    if old not in s:
        raise SystemExit("PATTERN NOT FOUND:\n" + old[:160])
    s = s.replace(old, new, 1)

io.open(path, "w", encoding="utf-8").write(s)
print("patched %s (%d edits)" % (path, len(reps)))
PY

if node --check "$UI/$F" 2>/dev/null; then
    echo "syntax OK"
else
    echo "SYNTAX ERROR - rolling back" >&2
    cp -p "$UI/$F.orig-xp" "$UI/$F"
    exit 1
fi

echo
echo "Done. Ctrl+Alt+Esc to restart Cinnamon."
