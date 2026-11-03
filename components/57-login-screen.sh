# XP login screen: WelcomeXP on nody-greeter, with fingerprint prompts
#
# nody-greeter comes from its release .deb, WelcomeXP is cloned at a fixed
# commit and gets assets/login/welcomexp.patch (fingerprint hints, auto-select
# a lone account). Needs sudo and lightdm. The switch only happens once the
# greeter and the theme are both in place, and it takes effect at the next
# login screen - lightdm is not restarted under you.
#
# If the login screen ever breaks: Ctrl+Alt+F2, log in, then
#   sudo rm /etc/lightdm/lightdm.conf.d/99-nody.conf && sudo systemctl restart lightdm

have lightdm || { warn "lightdm not installed - the login screen needs it"; return 0; }
if [ "${XP_SKIP_SUDO:-0}" = "1" ]; then
    skip "skipped (XP_SKIP_SUDO=1)"
    return 0
fi

if ! have nody-greeter; then
    deb="$(fetch https://github.com/JezerM/nody-greeter/releases/download/1.6.2/nody-greeter-1.6.2-ubuntu.deb nody-greeter.deb)" || return 0
    sudo apt-get install -y "$deb" >/dev/null || { warn "nody-greeter install failed"; return 0; }
fi
# Electron needs its setuid sandbox helper where unprivileged user namespaces
# are restricted (Ubuntu 24.04); the release .deb ships it without the bit.
[ -f /opt/nody-greeter/chrome-sandbox ] && sudo chmod 4755 /opt/nody-greeter/chrome-sandbox
nody-greeter --version >/dev/null 2>&1 || { warn "nody-greeter does not run - login screen left as it is"; return 0; }

src="$CACHE/WelcomeXP"
if [ ! -d "$src/.git" ]; then
    have git || { warn "git missing"; return 0; }
    git clone -q https://github.com/mshernandez5/WelcomeXP "$src" || { warn "clone failed"; return 0; }
fi
git -C "$src" checkout -q -f 9f5177496b0112085754cc5a020e6a45b3878c05
git -C "$src" clean -qfd
git -C "$src" apply "$ASSETS/login/welcomexp.patch" || { warn "WelcomeXP patch did not apply"; return 0; }
cp "$ASSETS/login/"*.svg "$src/img/"

dst=/usr/share/web-greeter/themes/WelcomeXP
sudo rm -rf "$dst"
sudo mkdir -p "$dst"
sudo cp -r "$src/." "$dst/"
sudo rm -rf "$dst/.git"
sudo chmod -R 755 "$dst"
[ -f "$dst/index.html" ] || { warn "theme copy failed - login screen left as it is"; return 0; }

sudo sed -i 's/^\( *theme:\).*/\1 WelcomeXP/' /etc/lightdm/web-greeter.yml
sudo mkdir -p /etc/lightdm/lightdm.conf.d
# WelcomeXP logs in to lightdm's default session, which is "ubuntu" on Ubuntu
# even without GNOME installed - so name the desktop this runs on.
sess=""
for s in $(is_cinnamon && echo cinnamon) $(is_xfce && echo xfce); do
    [ -f "/usr/share/xsessions/$s.desktop" ] && { sess="$s"; break; }
done
{ printf '[Seat:*]\ngreeter-session=nody-greeter\n'; [ -n "$sess" ] && printf 'user-session=%s\n' "$sess"; } |
    sudo tee /etc/lightdm/lightdm.conf.d/99-nody.conf >/dev/null
log "XP login screen set - it shows the next time you log out or boot"
