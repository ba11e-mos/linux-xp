#!/usr/bin/env bash
# Reworks the sound applet: Windows trackbars for the volume sliders,
# and a Media Player 8 layout for the player section.
#
#   sudo bash ~/xp-uac/sound-slider.sh           apply
#   sudo bash ~/xp-uac/sound-slider.sh --revert  undo
#
# Only the sound applet is touched. PopupSliderMenuItem binds its repaint
# handler with Lang.bind(this, this._sliderRepaint), which resolves the
# method on the instance, so overriding it in VolumeSlider is enough and
# popupMenu.js stays untouched.
set -euo pipefail

A=/usr/share/cinnamon/applets/sound@cinnamon.org
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

# --- Volume sliders drawn as Windows trackbars -----------------------
reps.append(('''    connectWithStream(stream) {
        if (!stream) {
            this.actor.hide();
            this.stream = null;''',
'''    // Windows trackbar: an etched track, a green fill up to the value
    // and a rectangular thumb. The wedge is only drawn when the row is
    // tall enough, so a short menu row still looks right.
    _sliderRepaint(area) {
        const cr = area.get_context();
        const [width, height] = area.get_surface_size();
        const ratio = Math.max(0, Math.min(1, this._value));

        const thumbW = 7;
        const thumbH = Math.min(14, Math.max(10, height - 2));
        const trackY = Math.round(height - thumbH / 2 - 2) + 0.5;
        const usable = Math.max(1, width - thumbW);
        const thumbCx = thumbW / 2 + usable * ratio;

        const wedgeBottom = Math.round(trackY - thumbH / 2 - 3) + 0.5;
        const wedgeTop = 1.5;
        const hasWedge = wedgeBottom - wedgeTop >= 6;

        cr.setLineWidth(1);

        if (hasWedge) {
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

            cr.setSourceRGBA(0.173, 0.247, 0.478, 1.0);
            cr.moveTo(3.5, wedgeBottom);
            cr.lineTo(width - 3.5, wedgeBottom);
            cr.curveTo(width - 0.5, wedgeBottom, width - 0.5, wedgeBottom,
                       width - 0.5, wedgeBottom - 3);
            cr.lineTo(width - 0.5, wedgeTop + 2);
            cr.curveTo(width - 0.5, wedgeTop, width - 0.5, wedgeTop, width - 3, wedgeTop + 1);
            cr.closePath();
            cr.stroke();
        } else {
            cr.setSourceRGBA(0.235, 0.749, 0.0, 1.0);
            cr.rectangle(0.5, trackY - 2, Math.max(0, thumbCx - 0.5), 4);
            cr.fill();
        }

        cr.setSourceRGBA(0.36, 0.44, 0.62, 1.0);
        cr.moveTo(0.5, trackY);
        cr.lineTo(width - 0.5, trackY);
        cr.stroke();
        cr.setSourceRGBA(1.0, 1.0, 1.0, 1.0);
        cr.moveTo(0.5, trackY + 1);
        cr.lineTo(width - 0.5, trackY + 1);
        cr.stroke();

        const tx = Math.round(thumbCx - thumbW / 2) + 0.5;
        const ty = Math.round(trackY - thumbH / 2) + 0.5;
        const r = 2.5;
        const HALF = Math.PI / 2;
        cr.newPath();
        cr.arc(tx + r, ty + r, r, Math.PI, 3 * HALF);
        cr.arc(tx + thumbW - r, ty + r, r, 3 * HALF, 4 * HALF);
        cr.arc(tx + thumbW - r, ty + thumbH - r, r, 0, HALF);
        cr.arc(tx + r, ty + thumbH - r, r, HALF, Math.PI);
        cr.closePath();
        cr.setSourceRGBA(0.847, 0.886, 0.941, 1.0);
        cr.fillPreserve();
        cr.setSourceRGBA(0.173, 0.247, 0.478, 1.0);
        cr.stroke();

        cr.$dispose();
    }

    connectWithStream(stream) {
        if (!stream) {
            this.actor.hide();
            this.stream = null;'''))

# --- Player layout: text above the art, controls in their own bar ----
reps.append(('''        this.trackInfo.add_actor(artistInfo);
        this.trackInfo.add_actor(titleInfo);
        this.coverBox.add_actor(this.trackInfo);''',
'''        this.trackInfo.add_actor(artistInfo);
        this.trackInfo.add_actor(titleInfo);
        // Media Player prints the artist and title above the art,
        // rather than floating them on top of it.
        this.vertBox.add_actor(this.trackInfo);'''))

reps.append(('''        this.trackInfo.add_actor(trackControls);''',
'''        // Added to a bar of its own below the art instead.'''))

reps.append(('''        this._seeker = new Seeker(this._mediaServerPlayer, this._prop, this._name.toLowerCase());
        this.vertBox.add_actor(this._seeker.actor);''',
'''        this._seeker = new Seeker(this._mediaServerPlayer, this._prop, this._name.toLowerCase());

        // Media Player keeps the seek rail and the transport inside one
        // blue bar, so both go into a box of their own.
        // One row: the transport sits on the floor of the bar, the seek
        // rail hangs from the ceiling, so its top lines up with the top
        // of the play button.
        // The slider has no natural width, so the expand parameter of
        // add() leaves it at zero. Setting the Clutter properties on the
        // actor works: St.DrawingArea does not shadow x_expand/y_align
        // the way St.Bin shadows y_align.
        this._seeker.actor.x_expand = true;
        this._seeker.actor.y_expand = false;
        this._seeker.actor.y_align = Clutter.ActorAlign.START;

        // Media Player stands the two big buttons on the left, and runs
        // the seek rail above the small ones out to the right edge. So
        // play and stop are kept out of this.controls above and placed
        // here instead.
        let bigButtons = new St.BoxLayout({ style_class: "wmp-big-buttons", vertical: false });
        bigButtons.add_actor(this._playButton.getActor());
        bigButtons.add_actor(this._stopButton.getActor());

        // The rail hides itself when the player cannot seek. Holding it
        // in a slot of fixed height keeps the row from collapsing, so
        // the small buttons stay put instead of jumping up.
        let railSlot = new St.Bin({ x_fill: true, y_fill: true });
        railSlot.height = 24;
        railSlot.set_child(this._seeker.actor);

        let rightSide = new St.BoxLayout({ style_class: "wmp-right-side", vertical: true });
        rightSide.x_expand = true;
        rightSide.add_actor(railSlot);
        rightSide.add_actor(trackControls);

        let controlBar = new St.BoxLayout({ style_class: "wmp-control-bar", vertical: false });
        controlBar.add_actor(bigButtons);
        controlBar.add_actor(rightSide);
        this.vertBox.add_actor(controlBar);'''))

# --- Mark this menu so the theme can style it without touching the
# --- panel menus of every other applet.
reps.append(("""        this.menu = new Applet.AppletPopupMenu(this, orientation);
        this.menuManager.addMenu(this.menu);""",
"""        this.menu = new Applet.AppletPopupMenu(this, orientation);
        this.menu.actor.add_style_class_name("wmp-menu");
        this.menuManager.addMenu(this.menu);"""))

# --- Seek bar drawn as a Media Player slider: a thin green rail with a
# --- tall silver thumb, rather than a filled capsule. Slider.Slider binds
# --- its repaint on the instance too, so overriding it in Seeker is enough.
reps.append(("""class Seeker extends Slider.Slider {""",
"""class Seeker extends Slider.Slider {
    _sliderRepaint(area) {
        const cr = area.get_context();
        const [width, height] = area.get_surface_size();
        const ratio = Math.max(0, Math.min(1, this._value));

        const thumbW = 7;
        const thumbH = Math.max(12, Math.min(18, height - 2));
        const railY = Math.round(height / 2) + 0.5;
        const usable = Math.max(1, width - thumbW);
        const thumbCx = thumbW / 2 + usable * ratio;

        // Rounded rail: a capsule rather than a bare line.
        const HALF = Math.PI / 2;
        const railH = 7;
        const railR = railH / 2;
        const rx0 = 2 + railR;
        const rx1 = width - 2 - railR;
        cr.newPath();
        cr.arc(rx0, railY, railR, HALF, 3 * HALF);
        cr.arc(rx1, railY, railR, 3 * HALF, HALF);
        cr.closePath();
        cr.setSourceRGBA(0.290, 0.835, 0.275, 1.0);
        cr.fill();

        // Rounded thumb: radius is half its width, so the ends are caps.
        const tx = Math.round(thumbCx - thumbW / 2) + 0.5;
        const ty = Math.round(railY - thumbH / 2) + 0.5;
        const r = thumbW / 2;
        cr.setLineWidth(1);
        cr.newPath();
        cr.arc(tx + r, ty + r, r, Math.PI, 3 * HALF);
        cr.arc(tx + thumbW - r, ty + r, r, 3 * HALF, 4 * HALF);
        cr.arc(tx + thumbW - r, ty + thumbH - r, r, 0, HALF);
        cr.arc(tx + r, ty + thumbH - r, r, HALF, Math.PI);
        cr.closePath();
        cr.setSourceRGBA(0.906, 0.937, 0.984, 1.0);
        cr.fillPreserve();
        cr.setSourceRGBA(0.235, 0.306, 0.533, 1.0);
        cr.stroke();

        cr.$dispose();
    }
"""))

# --- The play/pause button is the large one in Media Player.
reps.append(("""        this._playButton = new ControlButton("media-playback-start",
                                             _("Play"),
                                             () => this._mediaServerPlayer.PlayPauseRemote());""",
"""        this._playButton = new ControlButton("media-playback-start",
                                             _("Play"),
                                             () => this._mediaServerPlayer.PlayPauseRemote());
        this._playButton.button.add_style_class_name("wmp-play");"""))

# --- Media Player order: play, stop, previous, next. Cinnamon puts
# --- previous first and centres the row.
reps.append(("""        this.controls.add_actor(this._prevButton.getActor());
        this.controls.add_actor(this._playButton.getActor());
        this.controls.add_actor(this._stopButton.getActor());
        this.controls.add_actor(this._nextButton.getActor());""",
"""        this.controls.add_actor(this._prevButton.getActor());
        this.controls.add_actor(this._nextButton.getActor());"""))

reps.append(("""        let trackControls = new St.Bin({x_align: St.Align.MIDDLE});""",
"""        let trackControls = new St.Bin({x_align: St.Align.START});"""))

# --- St will not paint background-image on a node that also carries
# --- background-gradient-*, and "transparent" still counts as set. The
# --- ordinary buttons get their own class so the gradient rule can skip
# --- the play button, which is drawn from an image instead.
reps.append(("""        this.button = new St.Button();
        this.button.connect('clicked', callback);""",
"""        // The buttons are different heights, so the row lines them up by
        // their bottom edge rather than centring each one. St.Bin has its
        // own y_align of type StAlign (0-2); Clutter.ActorAlign.END is 3
        // and throws here. y_fill has to be off or the child just
        // stretches and the alignment is ignored.
        this.actor.y_expand = true;
        this.actor.y_fill = false;
        this.actor.y_align = St.Align.END;

        this.button = new St.Button();
        this.button.add_style_class_name("wmp-btn");
        this.button.connect('clicked', callback);"""))

reps.append(("""        this._playButton.button.add_style_class_name("wmp-play");""",
"""        this._playButton.button.remove_style_class_name("wmp-btn");
        this._playButton.button.add_style_class_name("wmp-play");"""))

# --- Media Player tilts the stop button. The tilt is baked into its
# --- background image, so it needs a class of its own. This has to be
# --- anchored on the stop button's own creation: it is built after the
# --- play button, so touching it any earlier is a TypeError.
reps.append(("""        this._stopButton = new ControlButton("media-playback-stop",
                                             _("Stop"),
                                             () => this._mediaServerPlayer.StopRemote());""",
"""        this._stopButton = new ControlButton("media-playback-stop",
                                             _("Stop"),
                                             () => this._mediaServerPlayer.StopRemote());
        this._stopButton.button.add_style_class_name("wmp-stop");"""))

# --- The art gets a black frame, as Media Player draws around its
# --- content area.
reps.append(("""        this._trackCover = new St.Bin({x_align: St.Align.MIDDLE});""",
"""        this._trackCover = new St.Bin({x_align: St.Align.MIDDLE});
        this._trackCover.add_style_class_name("wmp-cover-frame");"""))

# --- trackInfo is no longer a child of coverBox, so ordering the art
# --- below it would warn and leave the art unplaced. Put it at the
# --- bottom of coverBox instead.
reps.append(("""        this.coverBox.set_child_below_sibling(this.cover, this.trackInfo);""",
"""        this.coverBox.set_child_below_sibling(this.cover, null);"""))

# --- The row naming the player, with its open and quit buttons, is
# --- the closest thing here to Media Player's title bar, so it is
# --- styled as one.
reps.append(("""        this._playerBox = new St.BoxLayout();""",
"""        this._playerBox = new St.BoxLayout({ style_class: "wmp-player-head" });"""))

for old, new in reps:
    if old not in s:
        raise SystemExit("PATTERN NOT FOUND:\n" + old[:160])
    s = s.replace(old, new, 1)

io.open(path, "w", encoding="utf-8").write(s)
print("patched %s (%d edits)" % (path, len(reps)))
PY

if node --check "$A/$F" 2>/dev/null; then
    echo "syntax OK"
else
    echo "SYNTAX ERROR - rolling back" >&2
    cp -p "$A/$F.orig-xp" "$A/$F"
    exit 1
fi

echo
echo "Done. Press Ctrl+Alt+Esc to restart Cinnamon, then open the sound applet."
