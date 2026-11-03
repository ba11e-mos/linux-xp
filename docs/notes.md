# Notes

Background for people changing the code. The README covers using it.

## Will it work on GNOME? On other distros?

Partly on GNOME, mostly yes on other distros that run Cinnamon.

Nothing hard-fails on the wrong desktop. Components that need Cinnamon check
for it and skip themselves, so on GNOME you still get Firefox, VS Code, the
icons and the terminal.

| # | Component | Cinnamon | GNOME | KDE / XFCE |
|---|---|---|---|---|
| 10 | Theme and icon packs | yes | GTK apps yes, shell no | GTK apps only |
| 20 | Themes, font, cursor | yes | yes¹ | no² |
| 30 | Cinnamon shell CSS | yes | no³ | no |
| 40 | Title bar buttons | yes | likely⁴ | no⁵ |
| 50 | Cinnamon source patches | yes⁶ | no | no |
| 55 | Idle and suspend lock | yes⁸ | no | no |
| 60 | Firefox | yes | yes | yes |
| 70 | VS Code | yes | yes | yes |
| 80 | Terminal | yes⁷ | yes⁷ | no⁷ |
| 90 | Teams icon | yes | yes | yes |
| 95 | Symbolic icon names | yes | yes | yes |

1. Writes `org.gnome.desktop.*` instead of `org.cinnamon.desktop.*`. GNOME
   also needs the User Themes extension before a shell theme applies at all.
2. KDE and XFCE keep appearance settings outside gsettings entirely.
3. This is ~1800 lines of Cinnamon-specific St CSS. GNOME Shell uses different
   widget class names throughout, so it would have to be rewritten, not ported.
4. It patches `gtk-3.20/gtk.css`, which any GTK3 desktop reads. GNOME draws
   headerbar buttons from the same rules, so it should apply - untested.
5. KWin and xfwm4 use their own decoration themes, not GTK CSS.
6. Version-sensitive. The patches anchor on exact strings in
   `/usr/share/cinnamon/js/ui/*.js` as they are in Cinnamon 6.4. On a different
   version they will not find their anchors and will refuse rather than
   corrupt the file.
7. Only `gnome-terminal`, whichever desktop it runs on.
8. Needs lightdm and `xss-lock`. It also switches off Cinnamon's own locker,
   which is Cinnamon-specific.

**Other distros.** Anything shipping Cinnamon should work: Fedora's Cinnamon
spin, Debian, Arch, Ubuntu Cinnamon. Two caveats. The Cinnamon version has to
be close to 6.4 for component 50, per note 6 above. And a few messages suggest
`apt` packages by name - the packages exist elsewhere under other names.

Snap and flatpak Firefox are handled; component 60 looks in all three profile
locations.

## Layout

```
install.sh              runs components/ in order
lib/common.sh           logging, backups, theme lookup, desktop detection
components/NN-*.sh      one step each, runnable alone, idempotent
patches/*.sh            edit /usr/share/cinnamon/js/... (the only sudo)
assets/cinnamon/        the cinnamon.css additions and the images they use
assets/firefox/         userChrome.css, user.js and the IE icons
assets/icons/           redrawn icons, plus a list of symbolic aliases
assets/vscode/theme/    the VS Code theme, installed as a folder extension
assets/idle-lock/       the script that hands idle and suspend to lightdm
```

The VS Code theme is bundled rather than pulled from the marketplace. It is
[Mssjim's Windows XP Dark](https://github.com/Mssjim) (MIT) with twenty-eight
colour values changed - surfaces the original left light while the text on
them stayed white, which made hover cards, the suggestion list, the command
palette and the peek view unreadable.

## Traps worth knowing

Notes from building this. Each one cost time to find.

**`@namespace` in userChrome.css kills the address bar.** Every guide starts
with `@namespace url(...there.is.only.xul)`. In Firefox 152 the address bar is
HTML, not XUL, so every rule targeting `#urlbar` matches nothing - silently.
The file here has no `@namespace`.

**Negative margins crash Cinnamon.** St computes sizes unsigned, so
`margin-top: -6px` becomes an enormous number and the shell dies with
`GLib-ERROR: failed to allocate ... bytes`. Use `translation_y` on the actor.

**`background-gradient-*` suppresses `background-image`.** If a St element has
a gradient set, even `transparent`, the image is never painted.

**St has its own child properties.** `St.BoxLayout` honours `y-fill`, not
`Clutter.ActorAlign`, and `St.Bin` wants `St.Align`, not
`Clutter.ActorAlign` - the wrong enum throws
`Error: 3 is not a valid value for enumeration StAlign`.

**Title bars are GTK, not metacity.** Cinnamon draws window frames from
`gtk-3.20/gtk.css`, in the section marked `/* CSD */`. Editing `metacity-1/`
does nothing.

**GTK reads `gtk-3.20/`, not `gtk-3.0/`**, when a theme ships both.

**The keyring prompt is Cinnamon's, not gcr-prompter's.** `gcr` ships a GTK
prompter, but Cinnamon registers its own `KeyringDialog` on the same DBus
name, and that one is a St dialog carrying `.prompt-dialog` - so it can be
patched exactly like the polkit prompt.

**Two lockers stack.** `lock-on-suspend` makes cinnamon-screensaver lock on
resume while `xss-lock` is already showing the greeter, so you get both
screens. Component 55 turns Cinnamon's side off.

**cinnamon-settings-daemon zeroes `xset s`** whenever it decides it is
managing idle itself, which kills the idle path without any error. Setting
the timer once at login is not enough; the script re-asserts it.
