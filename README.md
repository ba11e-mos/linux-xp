# linux-xp

Gives your Linux desktop (Cinnamon, XFCE or GNOME) a Windows XP look :)

## Install

```bash
curl -L https://github.com/ba11e-mos/linux-xp/archive/refs/heads/main.tar.gz | tar xz
cd linux-xp-main
./install.sh
```

It asks yes or no for each part, installs the packages they need, downloads
the rest, and runs. Log out and back in afterwards.

```bash
./install.sh --yes      # installs everything
./install.sh --list     # lists possible components
./install.sh 15 92      # installs only specific components
```

## What works where

| Feature | Cinnamon | XFCE | GNOME |
|---|:-:|:-:|:-:|
| Luna theme, XP icons and cursors | ✓ | ✓ | ✓ |
| Luna window frames | ✓ | ✓ | ✓¹ |
| Bliss wallpaper | ✓ | ✓ | ✓ |
| XP taskbar | ✓ | ✓ | ✓ |
| XP start menu | ✓ | ✓³ | ✓ |
| UAC-style password prompts | ✓ | – | – |
| XP volume OSD, Media Player sound applet | ✓ | – | – |
| Captioned panel menus | ✓ | – | – |
| Balloon tips | ✓ | ✓ | ✓ |
| Animated charging battery | ✓ | – | – |
| XP sounds | ✓ | ✓ | ✓ |
| 3D Pipes screen saver, then lock | ✓ | ✓ | – |
| XP login screen (fingerprint prompts) | ✓ | ✓ | – |
| XP boot screen | ✓ | ✓ | ✓ |
| Firefox as Internet Explorer 6 | ✓ | ✓ | ✓² |
| Terminal as cmd.exe | ✓ | ✓ | ✓ |
| Games: Minesweeper, Solitaire, Spider, FreeCell, Hearts, Pinball | ✓ | ✓ | ✓ |
| VS Code Luna theme, Teams MSN icon | ✓ | untested | untested |

¹ GTK4/libadwaita apps only get Luna title bars.  
² Snap Firefox reads the new-tab setup from /etc/firefox, which no snap update touches.  
³ Whisker Menu in XP colours; the layout inside is Whisker's.

Tested in clean virtual machines (install, reboot, log in, uninstall):
Cinnamon on Linux Mint 22.1, XFCE and GNOME on Ubuntu 24.04, Firefox 159.
Other distros with these desktops should work; the installer names packages
the Debian/Ubuntu way. Your own start page links go in
`~/.config/linux-xp/home.html`.

## Where do the assets come from?

Nothing listed below is bundled in this repo. The installer downloads it when you
pick the part that needs it, into `~/.cache/linux-xp`.

| What | Source |
|---|---|
| Luna GTK/Cinnamon theme | [B00merang-Project/Windows-XP](https://github.com/B00merang-Project/Windows-XP) 3.1 |
| XP icons | [B00merang-Artwork/Windows-XP](https://github.com/B00merang-Artwork/Windows-XP) 3.1 |
| Cursors | [na0miluv/modernXP-cursor-theme](https://github.com/na0miluv/modernXP-cursor-theme) |
| Bliss | [archive.org/details/bliss-600dpi](https://archive.org/details/bliss-600dpi) |
| XP sounds | [lelegofrog.github.io/winwavxp.html](https://lelegofrog.github.io/winwavxp.html) |
| Boot screen | [BFUR64/WindowsXP-Plymouth](https://github.com/BFUR64/WindowsXP-Plymouth) |
| 3D Pipes | `xscreensaver-gl` from apt |
| GNOME taskbar and Start menu | [Dash to Panel](https://extensions.gnome.org/extension/1160/dash-to-panel/) and [ArcMenu](https://extensions.gnome.org/extension/3628/arcmenu/) from extensions.gnome.org |
| XFCE Start menu | `xfce4-whiskermenu-plugin` from apt |
| XP games | [archive.org/details/windows-xp-games](https://archive.org/details/windows-xp-games), run with Wine |
| MSN icon | [icon-icons.com](https://images.icon-icons.com/5/PNG/256/msn_146.png) |
| VGA font | [The Ultimate Oldschool PC Font Pack](https://int10h.org/oldschool-pc-fonts/) |
| Login screen | [JezerM/nody-greeter](https://github.com/JezerM/nody-greeter) 1.6.2 + [mshernandez5/WelcomeXP](https://github.com/mshernandez5/WelcomeXP), patched for fingerprints |

The sounds, games, Bliss and boot-screen artwork are Microsoft's.

The Firefox skin, the Cinnamon patches, the WelcomeXP fingerprint patch and the VS Code theme are written here.

## After a Linux update

Most of this lives in your home directory, which updates leave alone. Three
things an update can undo:

- a `cinnamon` update replaces the patched Cinnamon files
- a new GNOME version turns off the taskbar and Start menu until they get builds made for it
- a deb Firefox update removes the new-tab setup (snap Firefox keeps it)

`after-update.sh` checks all three and puts back only what is gone

```bash
./after-update.sh --dry    # see what it would put back
./after-update.sh
```

## If the login screen breaks

Cinnamon and XFCE (anything on lightdm): press Ctrl+Alt+F2, log in, and go
back to the distribution's own login screen:

```bash
sudo rm /etc/lightdm/lightdm.conf.d/99-nody.conf && sudo systemctl restart lightdm
```

## Uninstall

```bash
./uninstall.sh --dry    # see what would be put back
./uninstall.sh
```

Every file is backed up to `~/.local/share/linux-xp/backups` before it is changed.

[docs/notes.md](docs/notes.md) covers other desktops, the repo layout and other odd stuff found while building this.
