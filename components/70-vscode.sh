# VS Code: native title bar, and readable colours in the dark XP theme

sett="$HOME/.config/Code/User/settings.json"
[ -d "$(dirname "$sett")" ] || { skip "VS Code is not installed"; return 0; }
backup_file "$sett"

python3 - "$sett" "$ASSETS/vscode/settings-fragment.json" <<'PY'
import json, os, re, sys
path, frag = sys.argv[1], sys.argv[2]

cur = {}
if os.path.exists(path):
    raw = open(path).read()
    try:
        cur = json.loads(raw)
    except json.JSONDecodeError:
        # settings.json allows // comments; strip them and retry
        cur = json.loads(re.sub(r'(?m)^\s*//.*$', '', raw))

add = json.load(open(frag))
for k, v in add.items():
    if k == "workbench.colorCustomizations":
        tgt = cur.setdefault(k, {})
        for theme, colours in v.items():
            tgt.setdefault(theme, {}).update(colours)
    else:
        cur[k] = v

json.dump(cur, open(path, "w"), indent=2)
print("  wrote", sum(len(v) for v in add.get("workbench.colorCustomizations", {}).values()),
      "colour overrides")
PY

info "the theme itself comes from the 'vscode-windows-xp-theme' extension"
