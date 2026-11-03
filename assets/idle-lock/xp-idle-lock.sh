#!/bin/sh
# Hands idle locking and suspend locking to lightdm, so both show the
# WelcomeXP greeter instead of cinnamon-screensaver. Before the lock, XP's
# screen saver (xp-screensaver.py) runs for LOCK_AFTER seconds; input during
# that time just dismisses it.
#
# Two lockers must never both be armed, or you get the XP greeter and the
# Cinnamon lock screen stacked on top of each other. Cinnamon's side is
# switched off in gsettings:
#   org.cinnamon.settings-daemon.plugins.power lock-on-suspend  false
#   org.cinnamon.desktop.screensaver           idle-activation-enabled false
#   org.cinnamon.desktop.screensaver           lock-enabled    false

SAVER_SECONDS=600
LOCK_AFTER=300
SESSION_ID="${XDG_SESSION_ID:-$(loginctl list-sessions --no-legend 2>/dev/null | awk -v u="$USER" '$3==u {print $1; exit}')}"

# Active flips to no while the greeter has the screen and back to yes on
# unlock. LockedHint is no use here: xss-lock sets it itself and clears it
# only once this locker exits, so waiting on it never returns.
session_active() {
    [ -n "$SESSION_ID" ] || return 0
    [ "$(loginctl show-session "$SESSION_ID" -p Active --value 2>/dev/null || printf yes)" = yes ]
}

locker() {
    # If another lock request lands while the greeter is already up, do
    # nothing and wait for the session to come back instead of stacking
    # another greeter on top.
    if ! session_active; then
        while ! session_active; do
            sleep 1
        done
        exit 0
    fi

    dm-tool lock

    # dm-tool returns immediately: wait (up to 10 s) for the greeter to take
    # the screen, then stay alive until the session is active again.
    i=0
    while session_active && [ "$i" -lt 50 ]; do
        sleep 0.2
        i=$((i + 1))
    done

    while ! session_active; do
        sleep 1
    done
}

if [ "${1:-}" = "--locker" ]; then
    locker
    exit 0
fi

if pgrep -xu "$USER" -x xss-lock >/dev/null 2>&1; then
    exit 0
fi

# cinnamon-settings-daemon zeroes the X screensaver timer whenever it decides
# it is managing idle itself, which silently kills the idle path. Setting it
# once at login is not enough - re-assert it.
(
    while true; do
        # noblank: the server's own blanking would hide the screen saver.
        # expose: with neither blanking nor exposures the server never
        # activates at all, so xss-lock never hears of it (XFCE sets noexpose).
        case "$(xset q | awk '/timeout:/ {print $2, $4} /prefer blanking:/ {print $3, $6}' | tr '\n' ' ')" in
            "no yes $SAVER_SECONDS $LOCK_AFTER ") ;;
            *) xset s "$SAVER_SECONDS" "$LOCK_AFTER"; xset s noblank; xset s expose ;;
        esac
        sleep 60
    done
) &

exec xss-lock -n "$(dirname "$0")/xp-screensaver.py" -- "$0" --locker
