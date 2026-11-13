#!/usr/bin/python3
# Cinnamon's custom-screensaver-command (component 55 sets it to this).
#
# Cinnamon runs it in three cases, all decided by its own settings:
#   - idle for "Delay before starting the screensaver" (idle-delay):
#     csd-power sets LOCKED_BY_SESSION_IDLE=true. Show the XP screen saver
#     until there is input; if "Lock the computer after the screensaver
#     starts" is on, lock to the XP greeter after "Delay before locking".
#   - before suspend, when "Lock the computer when put to sleep" is on:
#     LOCKED_BY_SESSION_IDLE=false and XSS_SLEEP_LOCK_FD holds back the
#     suspend until it is closed. Lock now, then let the suspend go.
#   - Super+L / Lock Screen in the menu (cinnamon-screensaver-command
#     --lock): no variable set. Lock now.
#
# With a custom command set, cinnamon-screensaver itself refuses to start,
# so Mint's screen saver never shows up next to this one.
import ctypes, ctypes.util, os, signal, subprocess, sys, time
from gi.repository import Gio

HERE = os.path.dirname(os.path.abspath(__file__))
LOCKER = [os.path.join(HERE, "xp-idle-lock.sh"), "--locker"]
SAVER = [os.path.join(HERE, "xp-screensaver.py")]
SESSION = os.environ.get("XDG_SESSION_ID", "")


def session_active():
    if not SESSION:
        return True
    out = subprocess.run(["loginctl", "show-session", SESSION, "-p", "Active", "--value"],
                         capture_output=True, text=True).stdout.strip()
    return out != "no"


def lock():
    """Hand the screen to the greeter; returns once it has taken it."""
    locker = subprocess.Popen(LOCKER)  # waits for unlock on its own
    for _ in range(50):
        if not session_active():
            break
        time.sleep(0.2)
    return locker


class XIdle:
    """Milliseconds since the last keyboard or mouse input."""
    class Info(ctypes.Structure):
        _fields_ = [("window", ctypes.c_ulong), ("state", ctypes.c_int), ("kind", ctypes.c_int),
                    ("til_or_since", ctypes.c_ulong), ("idle", ctypes.c_ulong),
                    ("event_mask", ctypes.c_ulong)]

    def __init__(self):
        x11 = ctypes.cdll.LoadLibrary(ctypes.util.find_library("X11"))
        self.xss = ctypes.cdll.LoadLibrary(ctypes.util.find_library("Xss"))
        x11.XOpenDisplay.restype = ctypes.c_void_p
        x11.XDefaultRootWindow.restype = ctypes.c_ulong
        x11.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
        self.xss.XScreenSaverAllocInfo.restype = ctypes.POINTER(self.Info)
        self.xss.XScreenSaverQueryInfo.argtypes = [ctypes.c_void_p, ctypes.c_ulong,
                                                   ctypes.POINTER(self.Info)]
        self.dpy = x11.XOpenDisplay(None)
        if not self.dpy:
            sys.exit("xp-saver-lock: cannot open the X display")
        self.root = x11.XDefaultRootWindow(self.dpy)
        self.info = self.xss.XScreenSaverAllocInfo()

    def ms(self):
        self.xss.XScreenSaverQueryInfo(self.dpy, self.root, self.info)
        return self.info.contents.idle


def idle_saver():
    settings = Gio.Settings.new("org.cinnamon.desktop.screensaver")
    lock_after = settings.get_uint("lock-delay") if settings.get_boolean("lock-enabled") else None

    idle = XIdle()
    saver = subprocess.Popen(SAVER)
    start = time.monotonic()
    last = idle.ms()
    try:
        while saver.poll() is None:
            time.sleep(0.25)
            now = idle.ms()
            if now < last:  # input since the last look
                return
            last = now
            if lock_after is not None and time.monotonic() - start >= lock_after:
                lock().wait()
                return
    finally:
        if saver.poll() is None:
            saver.terminate()


def main():
    reason = os.environ.get("LOCKED_BY_SESSION_IDLE")
    if reason == "true":
        idle_saver()
        return
    locker = lock()
    fd = os.environ.get("XSS_SLEEP_LOCK_FD")
    if fd and fd.isdigit():
        try:
            os.close(int(fd))  # the greeter is up: let the suspend go
        except OSError:
            pass
    locker.wait()


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, lambda *a: sys.exit(0))
    main()
