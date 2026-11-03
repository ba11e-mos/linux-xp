# Discord as MSN Messenger, through Vesktop's theme support
#
# Needs Vesktop (Discord with Vencord built in), flatpak or native.

cfg=""
for d in "$HOME/.var/app/dev.vencord.Vesktop/config/vesktop" "$HOME/.config/vesktop"; do
    [ -d "$d" ] && { cfg="$d"; break; }
done
[ -n "$cfg" ] || { skip "Vesktop not found (flatpak install flathub dev.vencord.Vesktop, start it once)"; return 0; }

mkdir -p "$cfg/themes"
cp "$ASSETS/discord/xp.theme.css" "$cfg/themes/xp.theme.css"

s="$cfg/settings/settings.json"
backup_file "$s"
mkdir -p "$(dirname "$s")"
python3 - "$s" <<'PY'
import json, os, sys
p = sys.argv[1]
d = json.load(open(p)) if os.path.exists(p) else {}
themes = d.setdefault("enabledThemes", [])
if "xp.theme.css" not in themes:
    themes.append("xp.theme.css")
json.dump(d, open(p, "w"), indent=4)
PY
log "MSN theme installed and enabled - restart Vesktop if it is open"
