#!/usr/bin/env bash
# Reshapes Cinnamon's polkit dialog into the Windows 7 UAC Credential UI,
# in the colours of the Windows XP Luna theme.
#
#   sudo bash ~/xp-uac/apply.sh     apply
#   sudo bash ~/xp-uac/revert.sh    undo
#
# Only polkitAuthenticationAgent.js is touched. Button placement is applied
# to this dialog's own button row at runtime, so every other Cinnamon dialog
# keeps its default layout.
set -euo pipefail

UI=/usr/share/cinnamon/js/ui
F=polkitAuthenticationAgent.js
[ "$(id -u)" -eq 0 ] || { echo "Must run as root (use sudo)." >&2; exit 1; }

# An earlier version of this script patched dialog.js. Undo that.
if [ -f "$UI/dialog.js.orig-xp" ]; then
    cp -p "$UI/dialog.js.orig-xp" "$UI/dialog.js"
    rm -f "$UI/dialog.js.orig-xp"
    echo "reverted the old dialog.js patch (no longer needed)"
fi

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

# The picture is sized to match the two stacked fields beside it.
reps.append(("const DIALOG_ICON_SIZE = 64;", "const DIALOG_ICON_SIZE = 72;"))

# Windows asks the question itself, then lists the program in three
# fields. polkit gives one sentence, so the program path is pulled out
# of it; the publisher is genuinely unknown to polkit.
reps.append(('''        let title = _("Authentication Required");

        let headerContent = new Dialog.MessageDialogContent({ title, description });
        this.contentLayout.add_child(headerContent);''',
'''        // Built by hand so the title bar can carry a close button.
        // Dialog.MessageDialogContent only offers a plain label, and it
        // hides that label entirely when no title is passed.
        let titleBar = new St.BoxLayout({
            style_class: 'uac-title-bar',
            vertical: false,
        });

        // St.Icon pulls from the active icon theme, so this follows the
        // Windows XP icon pack like every other icon on the desktop.
        let titleIcon = new St.Icon({
            style_class: 'uac-title-icon',
            icon_name: 'linuxmint-logo-ring-symbolic',
            icon_size: 16,
        });
        titleBar.add(titleIcon, { x_fill: false, y_fill: false, y_align: St.Align.MIDDLE });

        let titleLabel = new St.Label({
            style_class: 'uac-title-label',
            text: _("User Account Control"),
        });
        titleBar.add(titleLabel, { expand: true, x_fill: true,
            y_fill: false, y_align: St.Align.MIDDLE });

        let closeButton = new St.Button({
            style_class: 'uac-close-button',
            can_focus: true,
        });
        closeButton.connect('clicked', () => this.cancel());
        titleBar.add(closeButton, { x_fill: false, y_fill: false, y_align: St.Align.MIDDLE });

        this.contentLayout.add_child(titleBar);

        let headerContent = new Dialog.MessageDialogContent({
            description: _("Do you want to allow the following program to make changes to this computer?"),
        });

        let programPath = null;
        let pathMatch = /`([^']+)'/.exec(description);
        if (pathMatch)
            programPath = pathMatch[1];

        let programBox = new St.BoxLayout({
            style_class: 'uac-program-box',
            vertical: false,
            x_align: Clutter.ActorAlign.CENTER,
        });

        let programIcon = new St.Icon({
            style_class: 'uac-program-icon',
            icon_name: (iconName && iconName.length > 0)
                ? iconName : 'application-x-executable',
            icon_size: 32,
        });
        programBox.add(programIcon, { x_fill: false, y_fill: false, y_align: St.Align.START });

        let detailBox = new St.BoxLayout({
            style_class: 'uac-detail-box',
            vertical: true,
        });

        let details = [
            [_("Program name:"),
             programPath ? GLib.path_get_basename(programPath) : description],
            [_("Verified publisher:"), _("Unknown")],
            [_("File origin:"), programPath ? programPath : _("This computer")],
        ];

        details.forEach(([name, value]) => {
            let row = new St.Label({ style_class: 'message-dialog-caption' });
            row.clutter_text.line_wrap = true;
            row.clutter_text.set_markup(
                '<b>' + GLib.markup_escape_text(name, -1) + '</b>  ' +
                GLib.markup_escape_text(String(value), -1));
            detailBox.add_child(row);
        });

        programBox.add(detailBox, { x_fill: false, y_align: St.Align.MIDDLE });
        headerContent.add_child(programBox);

        this.contentLayout.add_child(headerContent);'''))

reps.append(('''    _init(actionId, description, cookie, userNames) {''',
'''    _init(actionId, description, cookie, userNames, iconName) {'''))

reps.append(('''        this._currentDialog = new AuthenticationDialog(actionId, message, cookie, userNames);''',
'''        this._currentDialog = new AuthenticationDialog(actionId, message, cookie, userNames, iconName);'''))

# The picture sits to the left of the fields, not above them.
reps.append(('''        let userBox = new St.BoxLayout({
            style_class: 'polkit-dialog-user-layout',
            important: true,
            vertical: true,
        });''',
'''        let userBox = new St.BoxLayout({
            style_class: 'polkit-dialog-user-layout',
            important: true,
            vertical: false,
        });'''))

# y_fill defaults to true, which stretched the picture to the height of
# the field column and overrode its fixed size.
reps.append(('''            userBox.add(adminUser.avatar, { x_fill: false });''',
'''            userBox.add(adminUser.avatar, {
                x_fill: false,
                y_fill: false,
                y_align: St.Align.START,
            });'''))

reps.append(('''        bodyContent.add_child(userBox);''',
'''        let continueLabel = new St.Label({
            style_class: 'uac-continue-label',
            text: _("To continue, type an administrator password, and then click Yes."),
        });
        continueLabel.clutter_text.line_wrap = true;
        bodyContent.add_child(continueLabel);

        bodyContent.add_child(userBox);'''))

# Windows shows the account in a read-only box. The combo is kept only
# for picking between several administrators.
reps.append(('''        userBox.add(this._userCombo, { x_fill: false });''',
'''        this._userFields = new St.BoxLayout({
            style_class: 'uac-user-fields',
            vertical: true,
        });
        userBox.add(this._userFields, { expand: true, x_fill: true });

        this._userNameEntry = new St.Entry({
            style_class: 'uac-user-entry',
            can_focus: false,
            reactive: false,
        });
        this._userNameEntry.clutter_text.editable = false;
        this._userNameEntry.clutter_text.selectable = false;
        if (this._user)
            this._userNameEntry.set_text(this._user.realName || this._user.userName);
        this._userFields.add(this._userNameEntry, {
            x_fill: false,
            x_align: St.Align.START,
        });

        this._userFields.add(this._userCombo, {
            x_fill: false,
            x_align: St.Align.START,
        });
        this._userCombo.visible = userNames.length > 1;'''))

# _updateUser runs before the entry exists during construction.
reps.append(('''                this._userCombo.set_label(this._user.realName);''',
'''                this._userCombo.set_label(this._user.realName);
                if (this._userNameEntry)
                    this._userNameEntry.set_text(this._user.realName || user.userName);'''))

# Windows shows both fields from the start. Cinnamon hides the password
# box until PAM asks for it, which is only after the reader gives up.
reps.append(('''        this._passwordEntry = new St.PasswordEntry({
            style_class: 'prompt-dialog-password-entry',
            text: "",
            can_focus: true,
            visible: false,
            x_align: Clutter.ActorAlign.CENTER,
        });''',
'''        this._passwordEntry = new St.PasswordEntry({
            style_class: 'prompt-dialog-password-entry',
            text: "",
            can_focus: true,
            visible: true,
            reactive: false,
            x_align: Clutter.ActorAlign.START,
        });'''))

reps.append(('''        bodyContent.add_child(passwordBox);''',
'''        this._userFields.add_child(passwordBox);'''))

# Keep the fingerprint hint in the box when PAM then asks for a password.
reps.append(('''        // Cheap localization trick
        if (request === 'Password:' || request === 'Password: ')
            this._passwordEntry.hint_text = _("Password");
        else
            this._passwordEntry.hint_text = request;''',
'''        // Cheap localization trick
        if (request === 'Password:' || request === 'Password: ')
            this._passwordEntry.hint_text = _("Password");
        else
            this._passwordEntry.hint_text = request;

        if (this._fingerprintHint)
            this._passwordEntry.hint_text = this._fingerprintHint;'''))

# Fingerprint prompts belong inside the password box, as hint text.
reps.append(('''    _onSessionShowInfo(session, text) {
        this._passwordEntry.set_text('');
        this._infoMessageLabel.set_text(text);
        this._infoMessageLabel.show();
        this._errorMessageLabel.hide();
        this._nullMessageLabel.hide();
        this._ensureOpen();
    }''',
'''    _onSessionShowInfo(session, text) {
        this._passwordEntry.set_text('');
        if (/finger|fprint/i.test(text)) {
            this._fingerprintHint = text;
            this._passwordEntry.hint_text = text;
            this._infoMessageLabel.hide();
            this._nullMessageLabel.show();
        } else {
            this._infoMessageLabel.set_text(text);
            this._infoMessageLabel.show();
            this._nullMessageLabel.hide();
        }
        this._errorMessageLabel.hide();
        this._ensureOpen();
    }'''))

# The reader gave up; put the password hint back.
reps.append(('''    _onSessionShowError(session, text) {
        this._passwordEntry.set_text('');''',
'''    _onSessionShowError(session, text) {
        this._passwordEntry.set_text('');
        this._fingerprintHint = null;
        this._passwordEntry.hint_text = _("Password");'''))

# Win7 labels the commit buttons Yes and No, which also keeps them narrow.
reps.append(('''            label: _("Cancel"),''', '''            label: _("No"),'''))
reps.append(('''            label:  _("Authenticate"),''', '''            label:  _("Yes"),'''))

# Scoped to this dialog: Dialog centres buttons, makes them equal width
# and sets x_expand on each, which overrides any min-width from CSS.
reps.append(('''        this._okButton.bind_property('reactive',
            this._okButton, 'can-focus',
            GObject.BindingFlags.SYNC_CREATE);''',
'''        this._okButton.bind_property('reactive',
            this._okButton, 'can-focus',
            GObject.BindingFlags.SYNC_CREATE);

        let buttonLayout = this.dialogLayout.buttonLayout;
        buttonLayout.layout_manager.homogeneous = false;
        buttonLayout.layout_manager.spacing = 8;
        buttonLayout.insert_child_at_index(new St.Widget({ x_expand: true }), 0);
        this._cancelButton.x_expand = false;
        this._okButton.x_expand = false;'''))


# The dimming behind a modal is not CSS. Lightbox adds a radial GLSL
# shader when one is available, and falls back to a .lightbox style
# class marked important, which a theme cannot override. Clear both,
# for this dialog only. An inline style outranks any stylesheet in St.
reps.append(("""        super._init({ styleClass: 'prompt-dialog' });""",
"""        super._init({ styleClass: 'prompt-dialog' });

        if (this._lightbox) {
            // show()/hide() branch on the _radialEffect flag and animate
            // '@effects.radial.*'. Dropping the effect without clearing
            // the flag makes both throw, so the dialog never opens.
            this._lightbox._radialEffect = false;
            this._lightbox.actor.remove_effect_by_name('radial');
            this._lightbox.actor.set_style('background-color: transparent;');
        }"""))


# The prompt is a Clutter actor, not a window, so the window manager
# cannot move it. Dragging the title bar shifts the dialog's translation
# instead, which moves it without disturbing the layout.
# The frame has to sit below the caption, not around it, so everything
# except the title bar is reparented into one box that carries it - the
# button row included, which normally lives outside contentLayout.
reps.append(("""        this.contentLayout.add_child(bodyContent);""",
"""        let bodyBox = new St.BoxLayout({
            style_class: 'uac-body',
            vertical: true,
        });
        this.contentLayout.remove_child(headerContent);
        bodyBox.add_child(headerContent);
        bodyBox.add_child(bodyContent);

        let blParent = buttonLayout.get_parent();
        if (blParent)
            blParent.remove_child(buttonLayout);
        bodyBox.add_child(buttonLayout);

        this.contentLayout.add_child(bodyBox);"""))

reps.append(("""        this.contentLayout.add_child(titleBar);""",
"""        titleBar.reactive = true;
        titleBar.connect('button-press-event', (actor, event) => {
            let [pressX, pressY] = event.get_coords();
            let startX = this.dialogLayout.translation_x;
            let startY = this.dialogLayout.translation_y;

            this._endDrag();

            this._dragMotionId = global.stage.connect('motion-event', (stage, ev) => {
                if (!this.dialogLayout)
                    return Clutter.EVENT_PROPAGATE;
                let [mx, my] = ev.get_coords();
                this.dialogLayout.translation_x = startX + (mx - pressX);
                this.dialogLayout.translation_y = startY + (my - pressY);
                return Clutter.EVENT_STOP;
            });

            this._dragReleaseId = global.stage.connect('button-release-event', () => {
                this._endDrag();
                return Clutter.EVENT_STOP;
            });

            return Clutter.EVENT_STOP;
        });

        this.connect('destroy', () => this._endDrag());

        this.contentLayout.add_child(titleBar);"""))

# A single place to drop the stage handlers, so a dialog destroyed
# mid-drag cannot leave them connected.
reps.append(("""    _updateUser() {""",
"""    _endDrag() {
        if (this._dragMotionId) {
            global.stage.disconnect(this._dragMotionId);
            this._dragMotionId = 0;
        }
        if (this._dragReleaseId) {
            global.stage.disconnect(this._dragReleaseId);
            this._dragReleaseId = 0;
        }
    }

    _updateUser() {"""))

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
echo "Done. Press Ctrl+Alt+Esc to restart Cinnamon, then test with: pkexec true"
