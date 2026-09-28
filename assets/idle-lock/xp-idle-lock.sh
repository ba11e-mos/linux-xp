#!/bin/sh
# Hands idle locking and suspend locking to lightdm, so both show the
# WelcomeXP greeter instead of cinnamon-screensaver.
#
# Two lockers must never both be armed, or you get the XP greeter and the
# Cinnamon lock screen stacked on top of each other. Cinnamon's side is
# switched off in gsettings:
#   org.cinnamon.settings-daemon.plugins.power lock-on-suspend  false
#   org.cinnamon.desktop.screensaver           idle-activation-enabled false
#   org.cinnamon.desktop.screensaver           lock-enabled    false

IDLE_SECONDS=900
SESSION_ID="${XDG_SESSION_ID:-$(loginctl list-sessions --no-legend 2>/dev/null | awk -v u="$USER" '$3==u {print $1; exit}')}"

session_locked() {
    [ -n "$SESSION_ID" ] || return 1
    [ "$(loginctl show-session "$SESSION_ID" -p LockedHint --value 2>/dev/null || printf no)" = yes ]
}

locker() {
    # If another lock request lands while the greeter is already up, do
    # nothing and wait for the session to unlock instead of stacking another
    # greeter on top.
    if session_locked; then
        while session_locked; do
            sleep 1
        done
        exit 0
    fi

    dm-tool lock

    # dm-tool returns immediately, so wait for the lock hint to flip on and
    # then stay alive until the session actually unlocks.
    while ! session_locked; do
        sleep 0.2
    done

    while session_locked; do
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
        case "$(xset q | awk '/timeout:/ {print $2}')" in
            "$IDLE_SECONDS") ;;
            *) xset s "$IDLE_SECONDS" "$IDLE_SECONDS" ;;
        esac
        sleep 60
    done
) &

exec xss-lock -- "$0" --locker
