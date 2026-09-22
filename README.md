# linux-xp

Turn Linux Mint Cinnamon into Windows XP.

Built and tested on Linux Mint 22, Cinnamon 6.4, Firefox 152.

## What it does

| Part | Result |
|---|---|
| Desktop | Luna theme, XP icons, XP cursors, Tahoma |
| Title bars | The real Luna buttons, with their full white outline |
| Admin password | The polkit dialog redrawn as the Windows 7 UAC prompt |
| Volume | XP's wedge-and-track OSD |
| Sound applet | Windows Media Player 8 |
| Panel menus | XP dialogs with a blue caption bar and a red X |
| Start menu | The XP header with your name and account picture |
| Notifications | XP balloon tips |
| Firefox | Internet Explorer 6 |
| VS Code | Native title bar, and a bundled Luna theme with readable colours |
| Lock screen | Idle and suspend both go to the XP greeter |
| Terminal | cmd.exe |
| Teams | The MSN icon |

## Install

```bash
git clone git@github.com:ba11e-mos/linux-xp.git
cd linux-xp
./install.sh
```

Components can be run on their own:

```bash
./install.sh --list      # see what there is
./install.sh 60          # just Firefox
./install.sh 30 40       # the Cinnamon shell and the title bar buttons
```

Log out and back in when it finishes.

### Artwork that is not in here

The theme, the icons, the cursors, the wallpaper and the MSN icon are other
people's work, so they are not bundled. Download them and point at them:

```bash
# Theme and icon pack - drop the zip in ~/Downloads, or:
XP_PACK=~/Downloads/Windows-XP-3.1.zip ./install.sh 10

XP_WALLPAPER=~/Pictures/bliss.jpg ./install.sh 20
XP_MSN_ICON=~/Pictures/msn.png    ./install.sh 90
```

| What | Where |
|---|---|
| Luna GTK/Cinnamon/metacity theme | [B00merang-Project/Windows-XP](https://github.com/B00merang-Project/Windows-XP) |
| XP icon pack | [B00merang-Artwork/Windows-XP](https://github.com/B00merang-Artwork/Windows-XP) |
| XP cursors | [na0miluv/modernXP-cursor-theme](https://github.com/na0miluv/modernXP-cursor-theme) |
| Bliss wallpaper | [en.wikipedia.org/wiki/Bliss_(image)](https://en.wikipedia.org/wiki/Bliss_(image)) |
| MSN butterfly icon | [icon-icons.com](https://images.icon-icons.com/5/PNG/256/msn_146.png) - needs a browser User-Agent, `curl` alone gets a Cloudflare page |
| VGA raster fonts (`Bm437`) | [The Ultimate Oldschool PC Font Pack](https://int10h.org/oldschool-pc-fonts/) |
| Tahoma | `sudo apt install fonts-wine` |
| Login screen greeter | [JezerM/nody-greeter](https://github.com/JezerM/nody-greeter) |
| Login screen theme | [mshernandez5/WelcomeXP](https://github.com/mshernandez5/WelcomeXP) |

### Optional

```bash
XP_TERMINAL_FONT=1 ./install.sh 80     # the real VGA raster font
XP_SKIP_SUDO=1     ./install.sh        # skip everything that edits system files
```

The login screen is a separate setup - see [docs/login-screen.md](docs/login-screen.md).

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

## Uninstall

```bash
./uninstall.sh --dry     # see what would be put back
./uninstall.sh
```

Everything that gets changed is copied to `~/.local/share/linux-xp/backups`
first, and the scripts that edit Cinnamon's source files leave an `.orig-xp`
next to every file they touch. `uninstall.sh` uses both.

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

**Two lockers stack.** `lock-on-suspend` makes cinnamon-screensaver lock on
resume while `xss-lock` is already showing the greeter, so you get both
screens. Component 55 turns Cinnamon's side off.

**cinnamon-settings-daemon zeroes `xset s`** whenever it decides it is
managing idle itself, which kills the idle path without any error. Setting
the timer once at login is not enough; the script re-asserts it.
