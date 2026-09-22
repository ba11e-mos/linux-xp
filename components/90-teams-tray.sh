# Teams: the MSN icon in the task bar and the system tray
#
# The MSN image is not bundled (see README). Point at it with XP_MSN_ICON.

icons="$(icon_dir)" || { warn "icon theme not found"; return 0; }
src="${XP_MSN_ICON:-}"
[ -n "$src" ] && [ -f "$src" ] || { skip "XP_MSN_ICON not set - skipped"; return 0; }
have convert || { warn "ImageMagick missing (sudo apt install imagemagick)"; return 0; }

name="com.github.IsmaelMartinez.teams_for_linux"
for sz in 16 22 24 32 48 128; do
    d="$icons/${sz}x${sz}/apps"; [ -d "$d" ] || continue
    convert "$src" -filter Lanczos -resize ${sz}x${sz} -strip "$d/$name.png"
    cp "$d/$name.png" "$d/teams-for-linux.png"
    cp "$d/$name.png" "$d/teams.png"
done
gtk-update-icon-cache -f -t "$icons" >/dev/null 2>&1 || true
log "icon theme updated"

# The tray icon is drawn by the app itself, not via the icon theme.
# teams-for-linux has its own setting, read only at startup.
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
print("  appIcon set - restart Teams")
PY
else
    skip "teams-for-linux (flatpak) not installed"
fi
