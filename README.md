# linux-xp

Turns Linux Mint Cinnamon into Windows XP. Tested on Mint 22, Cinnamon 6.4,
Firefox 152.

## Install

```bash
git clone https://github.com/ba11e-mos/linux-xp.git
cd linux-xp
./install.sh
```

It asks yes or no for each part, installs the packages they need, downloads
the rest, and runs. Log out and back in afterwards.

```bash
./install.sh --yes      # everything, no questions
./install.sh --list     # the components
./install.sh 15 92      # only those components
```

## What you can pick

- **Desktop:** Luna theme, XP icons and cursors, Bliss wallpaper
- **Cinnamon:** XP start menu, UAC-style password prompts, XP volume OSD,
  Media Player sound applet, captioned menus, balloon tips, animated
  charging battery
- **Sounds:** the XP sound scheme
- **Screen saver:** 3D Pipes after 10 minutes, then the lock screen
- **Boot screen:** the XP logo and loading bar
- **Firefox** as Internet Explorer 6, with an IE-era start page
- **VS Code**, **Discord** (as MSN Messenger, via Vesktop), **Teams** (MSN
  icon), **terminal** (as cmd.exe)
- **Games:** Minesweeper, Solitaire, Spider, FreeCell, Hearts, 3D Pinball

The login screen is a separate, manual setup: [docs/login-screen.md](docs/login-screen.md).

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
| Login screen | [JezerM/nody-greeter](https://github.com/JezerM/nody-greeter) + [mshernandez5/WelcomeXP](https://github.com/mshernandez5/WelcomeXP) |

The sounds, games, Bliss and boot-screen artwork are Microsoft's.

The Firefox skin, the Discord theme, the Cinnamon patches and the VS Code
theme are written here.

## After a Mint update

A `cinnamon` update overwrites the patched Cinnamon files, and a Firefox
update removes the new-tab setup. Put them back with:

```bash
./after-update.sh
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
