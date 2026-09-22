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

exec xss-lock -- dm-tool lock
