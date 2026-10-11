# New tabs open the XP start page.
#
# Firefox dropped browser.newtab.url in 41 and never replaced it with a pref:
# the only handle left is AboutNewTab.newTabURL, which is privileged JS. An
# autoconfig file is the supported way to run that, so this writes one into the
# Firefox installation - which is why it needs root, and why a Firefox package
# update wipes it (after-update.sh puts it back).

ff_dir=""
for d in /usr/lib/firefox /usr/lib64/firefox /opt/firefox; do
    [ -x "$d/firefox" ] && { ff_dir="$d"; break; }
done
[ -n "$ff_dir" ] || { warn "no system Firefox installation found - skipping new tab page"; return 0; }

if [ "$(id -u)" != 0 ]; then
    warn "component 65 writes into $ff_dir and needs root:"
    warn "    sudo $REPO/install.sh 65"
    return 0
fi

install -d "$ff_dir/defaults/pref"
cat > "$ff_dir/defaults/pref/autoconfig.js" <<'EOF'
// linux-xp
pref("general.config.filename", "linux-xp.cfg");
pref("general.config.obscure_value", 0);
pref("general.config.sandbox_enabled", false);
EOF

cat > "$ff_dir/linux-xp.cfg" <<'EOF'
// linux-xp - the first line of an autoconfig file is always ignored.
try {
  // AboutNewTab is a browser module and is not loadable this early, so the
  // work waits for the first window. The URL comes from a pref so it stays a
  // per-profile setting.
  var linuxXpObserver = {
    observe: function () {
      Services.obs.removeObserver(linuxXpObserver, "browser-delayed-startup-finished");
      var url = Services.prefs.getStringPref("linuxxp.newtab.url", "");
      if (!url) {
        return;
      }
      var { AboutNewTab } = ChromeUtils.importESModule(
        "resource:///modules/AboutNewTab.sys.mjs");
      AboutNewTab.newTabURL = url;
    },
  };
  Services.obs.addObserver(linuxXpObserver, "browser-delayed-startup-finished");
} catch (e) {
  Components.utils.reportError("linux-xp newtab: " + e);
}
EOF

log "new tab page wired up in $ff_dir"
info "each profile's user.js sets linuxxp.newtab.url (component 60)"
