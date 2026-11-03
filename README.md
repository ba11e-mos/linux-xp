# linux-xp

Turns a Linux desktop into Windows XP: Cinnamon, XFCE or GNOME.

## Install

```bash
curl -L https://github.com/ba11e-mos/linux-xp/archive/refs/heads/main.tar.gz | tar xz
cd linux-xp-main
./install.sh
```

It asks yes or no for each part, installs the packages they need, downloads
the rest, and runs. Log out and back in afterwards.

```bash
./install.sh --yes      # everything, no questions
./install.sh --list     # the components
./install.sh 15 92      # only those components
```

## What works where

| Feature | Cinnamon | XFCE | GNOME |
|---|:-:|:-:|:-:|
| Luna theme, XP icons and cursors | ✓ | ✓ | ✓ |
| Luna window frames | ✓ | ✓ | partly¹ |
| Bliss wallpaper | ✓ | ✓ | ✓ |
| XP taskbar | ✓ | – | ✓ |
| XP start menu | ✓ | – | ✓ |
| UAC-style password prompts | ✓ | – | – |
| XP volume OSD, Media Player sound applet | ✓ | – | – |
| Captioned panel menus | ✓ | – | – |
| Balloon tips | ✓ | – | ✓ |
| Animated charging battery | ✓ | – | – |
| XP sounds | ✓ | ✓ | ✓ |
| 3D Pipes screen saver, then lock | ✓ | ✓ | – |
| XP login screen (fingerprint prompts) | ✓ | ✓ | – |
| XP boot screen | ✓ | ✓ | ✓ |
| Firefox as Internet Explorer 6 | ✓ | ✓ | ✓² |
| Terminal as cmd.exe | ✓ | ✓ | ✓ |
| Games: Minesweeper, Solitaire, Spider, FreeCell, Hearts, Pinball | ✓ | ✓ | ✓ |
| VS Code Luna theme, Teams MSN icon | ✓ | untested | untested |

¹ GNOME draws its own frames for GTK4/libadwaita apps, which ignore the theme.  
² Snap Firefox gets the skin but not the new-tab page.

Tested in clean virtual machines (install, reboot, log in, uninstall):
Cinnamon on Linux Mint 22.1, XFCE and GNOME on Ubuntu 24.04, Firefox 159.
Other distros with these desktops should work; the installer names packages
the Debian/Ubuntu way. The Firefox skin drifts on old versions (on 134 two
menu labels overlap). Your own start page links go in
`~/.config/linux-xp/home.html`.

## Where things come from

Nothing below is bundled in this repo. The installer downloads it when you
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
| XP games | [archive.org/details/windows-xp-games](https://archive.org/details/windows-xp-games), run with Wine |
| MSN icon | [icon-icons.com](https://images.icon-icons.com/5/PNG/256/msn_146.png) |
| VGA font | [The Ultimate Oldschool PC Font Pack](https://int10h.org/oldschool-pc-fonts/) |
| Login screen | [JezerM/nody-greeter](https://github.com/JezerM/nody-greeter) 1.6.2 + [mshernandez5/WelcomeXP](https://github.com/mshernandez5/WelcomeXP), patched for fingerprints |

The sounds, games, Bliss and boot-screen artwork are Microsoft's.

The Firefox skin, the Cinnamon patches, the WelcomeXP fingerprint patch and
the VS Code theme are written here.

## After a Mint update

A `cinnamon` update overwrites the patched Cinnamon files, and a Firefox
update removes the new-tab setup. Put them back with:

```bash
./after-update.sh
```

## If the login screen breaks

Press Ctrl+Alt+F2, log in, and go back to Mint's login screen:

```bash
sudo rm /etc/lightdm/lightdm.conf.d/99-nody.conf && sudo systemctl restart lightdm
```

## Uninstall

```bash
./uninstall.sh --dry    # see what would be put back
./uninstall.sh
```

Every file is backed up to `~/.local/share/linux-xp/backups` before it is
changed.

[docs/notes.md](docs/notes.md) covers other desktops, the repo layout and the
traps found while building this.
