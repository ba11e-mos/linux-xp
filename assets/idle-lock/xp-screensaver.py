#!/usr/bin/python3
# The XP screen saver: an xscreensaver hack (3D Pipes by default) full screen.
#
# xss-lock starts this when the X screen saver activates and kills it as soon
# as there is input, so it needs no input handling of its own. The window is
# override-redirect so it lands above the X server's own saver window.
#
#   xp-screensaver.py [hack]     e.g. pipes, flyingtoasters, starwars
import os, signal, subprocess, sys
import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GdkX11", "3.0")
from gi.repository import Gdk, GdkX11, GLib, Gtk

HACK = sys.argv[1] if len(sys.argv) > 1 else "pipes"
path = next((d + "/" + HACK for d in ("/usr/libexec/xscreensaver", "/usr/lib/xscreensaver")
             if os.access(d + "/" + HACK, os.X_OK)), None)

win = Gtk.Window(type=Gtk.WindowType.POPUP)
screen = win.get_screen()
win.move(0, 0)
win.resize(screen.get_width(), screen.get_height())
win.override_background_color(Gtk.StateFlags.NORMAL, Gdk.RGBA(0, 0, 0, 1))
win.show_all()
gdkwin = win.get_window()
gdkwin.set_cursor(Gdk.Cursor.new_for_display(gdkwin.get_display(), Gdk.CursorType.BLANK_CURSOR))

hack = None
if path:
    hack = subprocess.Popen([path, "-window-id", str(gdkwin.get_xid())])
else:
    print("xp-screensaver: %s not installed (sudo apt install xscreensaver-gl), showing black" % HACK,
          file=sys.stderr)

def stop():
    if hack:
        hack.terminate()
    Gtk.main_quit()

for sig in (signal.SIGTERM, signal.SIGINT):
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, sig, stop)
Gtk.main()
