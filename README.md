# linux-xp

Gjør Linux Mint Cinnamon om til Windows XP.

Testet på Linux Mint 22 med Cinnamon 6.4 og Firefox 152.

## Hva det gjør

| Del | Resultat |
|---|---|
| Skrivebord | Luna-tema, XP-ikoner, XP-musepeker, Tahoma |
| Tittellinjer | Ekte Luna-knapper med hel hvit kant |
| Admin-passord | Polkit-dialogen tegnet om som Windows 7 UAC |
| Volum | XP sin trekant-og-skinne-OSD |
| Lydapplet | Windows Media Player 8 |
| Panelmenyer | XP-dialoger med blå tittellinje og rødt kryss |
| Startmeny | XP-hodet med brukernavn og kontobilde |
| Varsler | XP-ballongtips |
| Firefox | Internet Explorer 6 |
| VS Code | Innebygd tittellinje, lesbare farger i mørkt XP-tema |
| Terminal | cmd.exe |
| Teams | MSN-ikon |

## Installering

```bash
git clone git@github.com:ba11e-mos/linux-xp.git
cd linux-xp
./install.sh
```

Komponentene kan kjøres hver for seg:

```bash
./install.sh --list      # se hva som finnes
./install.sh 60          # bare Firefox
./install.sh 30 40       # Cinnamon-skallet og tittellinjeknappene
```

Logg ut og inn når det er ferdig.

### Kunst som ikke ligger her

Temaet, ikonene, bakgrunnen og MSN-ikonet er andres arbeid, så de følger ikke
med i repoet. Last dem ned og pek på dem:

```bash
# Tema- og ikonpakke: søk opp "Windows XP" av B00merang på gnome-look.org,
# legg zip-en i ~/Downloads, eller:
XP_PACK=~/Downloads/Windows-XP-3.1.zip ./install.sh 10

XP_WALLPAPER=~/Pictures/bliss.jpg ./install.sh 20
XP_MSN_ICON=~/Pictures/msn.png    ./install.sh 90
```

### Valgfritt

```bash
XP_TERMINAL_FONT=1 ./install.sh 80     # ekte VGA-rasterfont i terminalen
XP_SKIP_SUDO=1     ./install.sh        # hopp over alt som redigerer systemfiler
```

VS Code-temaet kommer fra utvidelsen `vscode-windows-xp-theme`.
Innloggingsskjermen er et eget oppsett, se [docs/login-screen.md](docs/login-screen.md).

## Avinstallering

```bash
./uninstall.sh --dry     # se hva som ville blitt lagt tilbake
./uninstall.sh
```

Alt som endres sikkerhetskopieres først til `~/.local/share/linux-xp/backups`,
og skriptene som redigerer Cinnamons kildefiler legger igjen en `.orig-xp` ved
siden av hver fil de rører. `uninstall.sh` bruker begge deler.

## Hvordan det henger sammen

```
install.sh              kjører components/ i rekkefølge
lib/common.sh           logging, sikkerhetskopier, temaoppslag
components/NN-*.sh      ett steg hver, kan kjøres alene, idempotente
patches/*.sh            redigerer /usr/share/cinnamon/js/... (krever sudo)
assets/cinnamon/        tilleggene til cinnamon.css og bildene de bruker
assets/firefox/         userChrome.css, user.js og IE-ikonene
assets/icons/           ikoner tegnet om, og en liste over symbolske aliaser
```

Ingenting i `components/` skriver til systemet uten `sudo`, og `patches/` er
det eneste som gjør det i det hele tatt.

## Kjente fallgruver

Dette er notater fra da oppsettet ble laget, samlet her fordi hver av dem tok
tid å finne.

**`@namespace` i userChrome.css dreper adressefeltet.** Standardoppskriften
starter med `@namespace url(...there.is.only.xul)`. I Firefox 152 er adresse-
feltet HTML, ikke XUL, så hver regel mot `#urlbar` treffer ingenting — uten
feilmelding. Filen her har ingen `@namespace`.

**Negative marginer krasjer Cinnamon.** St regner størrelser som unsigned, så
`margin-top: -6px` blir et gigantisk tall og hele skallet dør med
`GLib-ERROR: failed to allocate ... bytes`. Bruk `translation_y` på skuespilleren
i stedet.

**`background-gradient-*` slår av `background-image`.** Har et St-element en
gradient satt, også `transparent`, males bildet aldri.

**St har sine egne barne-egenskaper.** `St.BoxLayout` bryr seg om `y-fill`, ikke
`Clutter.ActorAlign`, og `St.Bin` vil ha `St.Align`, ikke `Clutter.ActorAlign` —
feil enum gir `Error: 3 is not a valid value for enumeration StAlign`.

**Tittellinjene er GTK, ikke metacity.** Cinnamon tegner rammene med
`gtk-3.20/gtk.css` (seksjonen merket `/* CSD */`). Å endre `metacity-1/` gjør
ingenting.

**GTK leser `gtk-3.20/`, ikke `gtk-3.0/`**, når begge finnes.
