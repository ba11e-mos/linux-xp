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

if [ "${XP_SKIP_SUDO:-0}" = "1" ]; then
    skip "skipped (XP_SKIP_SUDO=1)"
    return 0
fi

sudo install -d "$ff_dir/defaults/pref"
sudo tee "$ff_dir/defaults/pref/autoconfig.js" >/dev/null <<'EOF'
// linux-xp
pref("general.config.filename", "linux-xp.cfg");
pref("general.config.obscure_value", 0);
pref("general.config.sandbox_enabled", false);
EOF

sudo tee "$ff_dir/linux-xp.cfg" >/dev/null <<'EOF'
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
