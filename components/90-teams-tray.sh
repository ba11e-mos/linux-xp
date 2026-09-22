# Teams: MSN-ikon i oppgavelinja og i systemkurven
#
# Selve MSN-bildet følger ikke med (se README). Pek på det med XP_MSN_ICON.

icons="$(icon_dir)" || { warn "fant ikke ikontemaet"; return 0; }
src="${XP_MSN_ICON:-}"
[ -n "$src" ] && [ -f "$src" ] || { skip "XP_MSN_ICON er ikke satt - hoppet over"; return 0; }
have convert || { warn "ImageMagick mangler (sudo apt install imagemagick)"; return 0; }

name="com.github.IsmaelMartinez.teams_for_linux"
for sz in 16 22 24 32 48 128; do
    d="$icons/${sz}x${sz}/apps"; [ -d "$d" ] || continue
    convert "$src" -filter Lanczos -resize ${sz}x${sz} -strip "$d/$name.png"
    cp "$d/$name.png" "$d/teams-for-linux.png"
    cp "$d/$name.png" "$d/teams.png"
done
gtk-update-icon-cache -f -t "$icons" >/dev/null 2>&1 || true
log "ikontemaet oppdatert"

# Systemkurv-ikonet tegnes av appen selv, ikke via ikontemaet. teams-for-linux
# leser en egen innstilling, og den leses bare ved oppstart.
cfg="$HOME/.var/app/$name/config/teams-for-linux"
if [ -d "$cfg" ]; then
    cp "$src" "$cfg/msn.png"
    backup_file "$cfg/config.json"
    python3 - "$cfg" <<'PY'
import json, os, sys
cfg = sys.argv[1]
p = os.path.join(cfg, "config.json")
d = {}
if os.path.exists(p):
    try: d = json.load(open(p))
    except Exception: d = {}
d["appIcon"] = os.path.join(cfg, "msn.png")
json.dump(d, open(p, "w"), indent=2)
print("  appIcon satt - start Teams på nytt")
PY
else
    skip "teams-for-linux (flatpak) er ikke installert"
fi
