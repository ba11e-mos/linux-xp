# Firefox as Internet Explorer 6

# Deb, snap and flatpak Firefox keep their profiles in different places.
roots=(
    "$HOME/.mozilla/firefox"
    "$HOME/snap/firefox/common/.mozilla/firefox"
    "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"
)

profiles=()
for r in "${roots[@]}"; do
    [ -d "$r" ] || continue
    while IFS= read -r d; do profiles+=("$d"); done < <(
        find "$r" -maxdepth 1 -type d -name "*.default*" 2>/dev/null)
done
[ ${#profiles[@]} -gt 0 ] || { warn "no Firefox profile found"; return 0; }

for prof in "${profiles[@]}"; do
    info "profile: $(basename "$prof")"
    mkdir -p "$prof/chrome/xp"
    backup_file "$prof/chrome/userChrome.css"
    backup_file "$prof/user.js"
    cp "$ASSETS/firefox/userChrome.css" "$prof/chrome/"
    cp "$ASSETS/firefox/xp/"*.svg       "$prof/chrome/xp/"
    cp "$ASSETS/firefox/user.js"        "$prof/"
done

# The menu bar and Links bar live in xulstore.json, Home/Favorites in prefs.js.
# Firefox rewrites both when it exits, so this has to run while it is closed.
if pgrep -x firefox >/dev/null; then
    warn "Firefox is running - close it and run: $REPO/install.sh 60"
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
    print("  no prefs.js yet - start Firefox once and run component 60 again")
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
        print("  Home and Favorites buttons added")
    break
print("  menu bar and Links bar on")
PY
done
