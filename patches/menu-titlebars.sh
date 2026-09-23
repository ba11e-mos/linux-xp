#!/usr/bin/env bash
# Gives every applet popup menu a Windows-style caption bar.
#
#   sudo bash ~/xp-uac/menu-titlebars.sh           apply
#   sudo bash ~/xp-uac/menu-titlebars.sh --revert  undo
#
# One edit in AppletPopupMenu covers every applet at once. The bar is a
# plain actor inserted at the top of the menu box; PopupMenuBase filters
# its children by _delegate when it collects menu items, so a bare actor
# is skipped by keyboard navigation rather than treated as a row.
set -euo pipefail

UI=/usr/share/cinnamon/js/ui
F=applet.js
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

old = """        Main.uiGroup.add_actor(this.actor);
        this.actor.hide();
        this.launcher = launcher;"""

new = """        Main.uiGroup.add_actor(this.actor);
        this.actor.hide();
        this.launcher = launcher;

        // A caption bar across the top of the menu, named after the
        // applet. Applets set their own title through setCaption().
        this._captionLabel = new St.Label({
            style_class: 'xp-menu-caption-label',
            text: this._defaultCaption(launcher),
        });
        this._captionClose = new St.Button({
            style_class: 'xp-menu-close',
            can_focus: true,
        });
        this._captionClose.connect('clicked', Lang.bind(this, function () {
            this.close(true);
        }));

        this._captionBar = new St.BoxLayout({ style_class: 'xp-menu-caption' });
        this._captionBar.add(this._captionLabel, {
            expand: true, x_fill: true, y_fill: false, y_align: St.Align.MIDDLE,
        });
        this._captionBar.add(this._captionClose, {
            expand: false, x_fill: false, y_fill: false, y_align: St.Align.MIDDLE,
        });
        this.box.insert_child_at_index(this._captionBar, 0);

        // The menu box pads its contents, which would leave the caption
        // floating as a stripe. Cleared inline so only applet menus are
        // affected; items carry their own padding already.
        // Style classes rather than inline style: Cinnamon writes
        // actor.style itself to cap a tall menu's size (max-height /
        // max-width), which wipes anything set here. The power menu is
        // tall enough to hit that, which is why only it lost its frame.
        this.box.add_style_class_name('xp-captioned-box');
        this.actor.add_style_class_name('xp-captioned-menu');

        // The frame belongs around the items, not around the caption: in XP
        // the title bar is the top edge of the window. The caption cannot
        // reach that edge while it sits inside the bordered box, so it is
        // lifted out and made a sibling. The BoxPointer's bin takes one
        // child, so a vertical wrapper holds both.
        //
        // this.box stays the menu's item container, which matters: applets
        // call addMenuItem() long after this runs, and those items have to
        // keep landing inside the frame.
        let bp = this._boxPointer;
        if (bp && bp.bin) {
            this.box.remove_child(this._captionBar);
            bp.bin.remove_actor(this.box);
            let wrapper = new St.BoxLayout({ vertical: true });
            wrapper.add_child(this._captionBar);
            wrapper.add_child(this.box);
            bp.bin.set_child(wrapper);
        }

        // The start menu gets the XP header instead of a title bar:
        // account picture, the user's real name, and no close button,
        // since the original has none.
        if (launcher && launcher._uuid === 'menu@cinnamon.org') {
            let GLib = imports.gi.GLib;
            this._captionBar.add_style_class_name('xp-start-header');
            this._captionLabel.set_text(GLib.get_real_name() || GLib.get_user_name());
            this._captionClose.hide();

            let face = GLib.get_home_dir() + '/.face';
            if (GLib.file_test(face, GLib.FileTest.EXISTS)) {
                let picture = new St.Bin({ style_class: 'xp-start-avatar' });
                picture.style = 'background-image: url("' + face + '");';
                this._captionBar.insert_child_at_index(picture, 0);
                // The box stretches the picture to the full height of the
                // header otherwise. Clutter's y_expand/y_align are not
                // enough: St.BoxLayout keeps its own y-fill child property
                // and that is what actually decides.
                picture.y_expand = false;
                picture.y_align = imports.gi.Clutter.ActorAlign.CENTER;
                try {
                    this._captionBar.child_set_property(picture, 'y-fill', false);
                    this._captionBar.child_set_property(picture, 'y-align', 1);
                } catch (e) {
                    picture.set_height(52);
                }
            }
        }"""

if old not in s:
    raise SystemExit("PATTERN NOT FOUND (constructor)")
s = s.replace(old, new, 1)

old2 = """    _onOrientationChanged(a, orientation) {
        this.setArrowSide(orientation);
    }"""

new2 = """    _defaultCaption(launcher) {
        let uuid = launcher && launcher._uuid;
        if (!uuid)
            return "";

        // appletManager.appletMeta only carries the path at runtime, so
        // the readable name comes from the applet's own metadata.json.
        try {
            let meta = imports.ui.appletManager.appletMeta[uuid];
            if (meta && meta.path) {
                let [ok, data] = imports.gi.GLib.file_get_contents(meta.path + "/metadata.json");
                if (ok) {
                    let text = (typeof TextDecoder !== "undefined")
                        ? new TextDecoder().decode(data)
                        : String(data);
                    let json = JSON.parse(text);
                    if (json && json.name)
                        return json.name;
                }
            }
        } catch (e) {
            // fall through to the uuid
        }

        return uuid.split("@")[0]
                   .replace(/-/g, " ")
                   .replace(/^./, function (ch) { return ch.toUpperCase(); });
    }

    /**
     * setCaption:
     * @text (string): Caption to show in the menu's title bar
     */
    setCaption(text) {
        if (this._captionLabel)
            this._captionLabel.set_text(text || "");
    }

    _onOrientationChanged(a, orientation) {
        this.setArrowSide(orientation);
    }"""

if old2 not in s:
    raise SystemExit("PATTERN NOT FOUND (methods)")
s = s.replace(old2, new2, 1)

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
echo "Done. Press Ctrl+Alt+Esc to restart Cinnamon."
