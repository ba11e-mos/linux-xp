# Firefox som Internet Explorer 6

prof_root="$HOME/.mozilla/firefox"
[ -d "$prof_root" ] || { warn "fant ingen Firefox-profil"; return 0; }

profiles=()
while IFS= read -r d; do profiles+=("$d"); done < <(
    find "$prof_root" -maxdepth 1 -type d -name "*.default*" 2>/dev/null)
[ ${#profiles[@]} -gt 0 ] || { warn "fant ingen standardprofil under $prof_root"; return 0; }

for prof in "${profiles[@]}"; do
    info "profil: $(basename "$prof")"
    mkdir -p "$prof/chrome/xp"
    backup_file "$prof/chrome/userChrome.css"
    backup_file "$prof/user.js"
    cp "$ASSETS/firefox/userChrome.css" "$prof/chrome/"
    cp "$ASSETS/firefox/xp/"*.svg       "$prof/chrome/xp/"
    cp "$ASSETS/firefox/user.js"        "$prof/"
done

# Menylinja og Links-linja ligger i xulstore.json, og Home/Favorites i prefs.js.
# Firefox skriver begge når det avslutter, så dette må skje mens det er lukket.
if pgrep -x firefox >/dev/null; then
    warn "Firefox kjører - lukk det og kjør: $REPO/install.sh 60"
    return 0
fi

for prof in "${profiles[@]}"; do
python3 - "$prof" <<'PY'
import json, os, shutil, sys
prof = sys.argv[1]

xs = os.path.join(prof, "xulstore.json")
store = json.load(open(xs)) if os.path.exists(xs) else {}
win = store.setdefault("chrome://browser/content/browser.xhtml", {})
win.setdefault("toolbar-menubar", {})["autohide"] = "false"
win.setdefault("PersonalToolbar", {})["collapsed"] = "false"
json.dump(store, open(xs, "w"))

prefs = os.path.join(prof, "prefs.js")
if not os.path.exists(prefs):
    print("  ingen prefs.js enda - start Firefox en gang og kjør komponent 60 på nytt")
    raise SystemExit(0)
if not os.path.exists(prefs + ".bak-xp"):
    shutil.copy2(prefs, prefs + ".bak-xp")

key = 'user_pref("browser.uiCustomization.state", '
lines = open(prefs).read().splitlines(True)
for i, line in enumerate(lines):
    if not line.startswith(key):
        continue
    state = json.loads(json.loads(line[len(key):].rstrip()[:-2]))
    nav = state["placements"]["nav-bar"]
    changed = False
    for btn, after in (("home-button", "stop-reload-button"),
                       ("bookmarks-menu-button", "home-button")):
        if btn not in nav:
            nav.insert(nav.index(after) + 1 if after in nav else 0, btn)
            changed = True
    if changed:
        lines[i] = key + json.dumps(json.dumps(state)) + ");\n"
        open(prefs, "w").writelines(lines)
        print("  Home- og Favorites-knapper lagt til")
    break
print("  menylinje og Links-linje på")
PY
done
