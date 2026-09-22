# VS Code: native title bar, and a bundled XP theme with readable colours

sett="$HOME/.config/Code/User/settings.json"
[ -d "$(dirname "$sett")" ] || { skip "VS Code is not installed"; return 0; }

# Ship the theme as a folder extension rather than depending on a marketplace
# one. It is the upstream Luna dark theme with the low-contrast surfaces fixed;
# see assets/vscode/theme/LICENSE.txt.
ext="$HOME/.vscode/extensions/linux-xp.linux-xp-theme-1.0.0"
mkdir -p "$ext"
cp -r "$ASSETS/vscode/theme/." "$ext/"
info "theme installed to $ext"

backup_file "$sett"

python3 - "$sett" <<'PY'
import json, os, re, sys
path = sys.argv[1]

cur = {}
if os.path.exists(path):
    raw = open(path).read()
    try:
        cur = json.loads(raw)
    except json.JSONDecodeError:
        # settings.json allows // comments; strip them and retry
        cur = json.loads(re.sub(r'(?m)^\s*//.*$', '', raw))

cur["window.titleBarStyle"] = "native"
cur["window.dialogStyle"] = "native"
cur["workbench.colorTheme"] = "Windows XP Luna (linux-xp)"

# The colour fixes are baked into the theme now, so the per-theme overrides
# that used to carry them are no longer needed.
cc = cur.get("workbench.colorCustomizations")
if isinstance(cc, dict):
    cc.pop("[Windows Xp Dark Luna]", None)
    if not cc:
        cur.pop("workbench.colorCustomizations")

json.dump(cur, open(path, "w"), indent=2)
print("  theme selected, native title bar on")
PY

info "restart VS Code for the theme to appear"
