#!/usr/bin/env bash
# Puts the fingerprint reader ahead of the custom PIN file in the
# lightdm auth stack, without losing the PIN as a fallback.
#
#   sudo bash ~/xp-uac/pam-fingerprint-first.sh          apply
#   sudo bash ~/xp-uac/pam-fingerprint-first.sh --revert  undo
#
# Before:
#   auth sufficient pam_pwdfile.so ...      <- prompts for a password first
#   @include common-auth                    <- fprintd lives in here
#
# After:
#   auth sufficient pam_fprintd.so ...      <- reader gets first turn
#   auth sufficient pam_pwdfile.so ...      <- PIN, if the reader fails
#   <common-auth inlined, minus fprintd>    <- so the reader is not asked twice
set -euo pipefail

F=/etc/pam.d/lightdm
B=$F.bak-xp
[ "$(id -u)" -eq 0 ] || { echo "Must run as root (use sudo)." >&2; exit 1; }

if [ "${1:-}" = "--revert" ]; then
    [ -f "$B" ] || { echo "No backup at $B" >&2; exit 1; }
    cp -p "$B" "$F"
    echo "restored $F"
    exit 0
fi

[ -f "$B" ] || { cp -p "$F" "$B"; echo "backed up $F -> $B"; }
cp -p "$B" "$F"

python3 - "$F" <<'PY'
import io, sys
path = sys.argv[1]
s = io.open(path, encoding="utf-8").read()

pin = "auth    sufficient  pam_pwdfile.so pwdfile=/etc/custompinfile\n"
if pin not in s:
    raise SystemExit("PIN line not found; nothing changed.")
s = s.replace(pin, "", 1)

inc = "@include common-auth\n"
if inc not in s:
    raise SystemExit("@include common-auth not found; nothing changed.")

block = (
    "# Fingerprint first, then the PIN file, then the usual password stack.\n"
    "# common-auth is inlined below without pam_fprintd so the reader is\n"
    "# not asked for a second time. See ~/xp-uac/pam-fingerprint-first.sh\n"
    "auth    sufficient  pam_fprintd.so max-tries=1 timeout=10\n"
    "auth    sufficient  pam_pwdfile.so pwdfile=/etc/custompinfile\n"
    "auth    [success=1 default=ignore]   pam_unix.so nullok try_first_pass\n"
    "auth    requisite                    pam_deny.so\n"
    "auth    required                     pam_permit.so\n"
    "auth    required    pam_ecryptfs.so unwrap\n"
    "auth    optional    pam_cap.so\n"
)
s = s.replace(inc, block, 1)
io.open(path, "w", encoding="utf-8").write(s)
print("rewrote", path)
PY

echo
echo "--- new auth stack ---"
grep -E '^\s*(auth|@include)' "$F"
echo
echo "Keep a root shell or a TTY open until you have confirmed login works."
echo "Undo: sudo bash ~/xp-uac/pam-fingerprint-first.sh --revert"
