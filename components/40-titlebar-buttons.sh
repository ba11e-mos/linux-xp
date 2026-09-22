# Tittellinjeknappene: hel hvit kant i stedet for avklipt topp og venstre

gtk="$(theme_dir gtk-3.20)" || { warn "fant ingen gtk-3.20 i $THEME_NAME"; return 0; }
css="$gtk/gtk.css"
[ -f "$css" ] || { warn "fant ikke $css"; return 0; }

if marker_present "$css" "min-width: 21px"; then
    skip "knappene er allerede fikset"
    return 0
fi
backup_file "$css"

python3 - "$css" <<'PY'
import re, sys
p = sys.argv[1]; s = open(p).read()
anchor = "  .titlebar .titlebutton.close, .titlebar .titlebutton.maximize, .titlebar .titlebutton.minimize, .titlebar .titlebutton:not(separator) {"
if anchor not in s:
    print("  fant ikke knappereglene - hoppet over"); raise SystemExit(0)
i = s.index(anchor)
j = s.index("\n  .", s.index("maximize-active.png", i))
b = s[i:j]
# The artwork is 21x21 but the box is smaller and the background is pinned to
# 100% 100% (bottom right), so the top row and left column - the white rounded
# outline - get clipped off. Size the box to the art and centre it.
b = b.replace("padding: 2px 2px;", "padding: 0;\n    min-width: 21px;\n    min-height: 21px;")
# `background:` shorthand also resets background-repeat, which makes the art
# tile inside the bigger box; set only the image.
b = re.sub(r'background: (url\("assets/[a-z-]+\.png"\))\s+100% 100%;', r'background-image: \1;', b)
open(p, "w").write(s[:i] + b + s[j:])
print("  knappereglene skrevet om")
PY

info "logg ut og inn, eller bytt tema fram og tilbake, for at GTK skal lese den på nytt"
