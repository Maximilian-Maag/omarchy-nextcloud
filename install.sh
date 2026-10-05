#!/usr/bin/env bash
# install.sh — install the omarchy-nextcloud plugin on this machine.
#
# Usage:
#   bash install.sh           # interactive (asks about bar placement)
#   bash install.sh --yes     # non-interactive, place in right section

set -euo pipefail

PLUGIN_ID="maximilian-maag.nextcloud"
PLUGINS_DIR="$HOME/.config/omarchy/plugins"
DEST="$PLUGINS_DIR/$PLUGIN_ID"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_JSON="$HOME/.config/omarchy/shell.json"

ASSUME_YES=0
[[ "${1:-}" == "--yes" ]] && ASSUME_YES=1

# ── helpers ────────────────────────────────────────────────────────────────────
info()    { echo "  [nextcloud] $*"; }
success() { echo "  [nextcloud] ✓ $*"; }
fail()    { echo "  [nextcloud] ✗ $*" >&2; exit 1; }

command -v omarchy >/dev/null 2>&1 || fail "omarchy not found — is this an Omarchy system?"
command -v python3 >/dev/null 2>&1 || fail "python3 not found"

# ── copy plugin files ──────────────────────────────────────────────────────────
info "Installing plugin to $DEST"
mkdir -p "$DEST"
cp "$SCRIPT_DIR/manifest.json"      "$DEST/"
cp "$SCRIPT_DIR/Panel.qml"         "$DEST/"
cp "$SCRIPT_DIR/Service.qml"       "$DEST/"
cp "$SCRIPT_DIR/NextcloudIcon.qml" "$DEST/"
success "Files copied."

# ── validate ──────────────────────────────────────────────────────────────────
info "Validating manifest…"
omarchy plugin validate "$DEST" && success "Manifest valid." || fail "Manifest validation failed."

# ── rescan so the shell knows about the new plugin ─────────────────────────────
omarchy-shell shell rescanPlugins 2>/dev/null || true

# ── enable in bar ─────────────────────────────────────────────────────────────
if (( ASSUME_YES )); then
  omarchy plugin enable "$PLUGIN_ID" right
  success "Plugin enabled in right bar section."
else
  echo ""
  echo "  Where would you like to place the Nextcloud widget in the bar?"
  echo "  [1] right (recommended, default)"
  echo "  [2] center"
  echo "  [3] left"
  echo "  [q] skip (enable manually later with: omarchy plugin enable $PLUGIN_ID)"
  echo ""
  read -rp "  Choice [1]: " choice
  case "${choice:-1}" in
    1|"") omarchy plugin enable "$PLUGIN_ID" right   && success "Enabled in right section." ;;
    2)    omarchy plugin enable "$PLUGIN_ID" center  && success "Enabled in center section." ;;
    3)    omarchy plugin enable "$PLUGIN_ID" left    && success "Enabled in left section." ;;
    q|Q)  info "Skipped. Run: omarchy plugin enable $PLUGIN_ID" ;;
    *)    omarchy plugin enable "$PLUGIN_ID" right   && success "Enabled in right section." ;;
  esac
fi

# ── suppress duplicate SNI tray icon ─────────────────────────────────────────
# The Nextcloud client registers a system-tray SNI entry. Our bar widget makes
# that redundant. We hide "Nextcloud" from the tray drawer so it doesn't appear
# twice. This adds "hidden": ["Nextcloud"] to the omarchy.tray entry in shell.json.
info "Suppressing duplicate Nextcloud tray icon…"
python3 - "$SHELL_JSON" << 'PYEOF'
import json, sys
path = sys.argv[1]
with open(path) as f:
    d = json.load(f)
right = d.get('bar', {}).get('layout', {}).get('right', [])
changed = False
for entry in right:
    if entry.get('id') == 'omarchy.tray':
        hidden = entry.get('hidden', [])
        if 'Nextcloud' not in hidden:
            hidden.append('Nextcloud')
            entry['hidden'] = hidden
            changed = True
        break
if changed:
    with open(path, 'w') as f:
        json.dump(d, f, indent=2)
        f.write('\n')
    print('Updated tray hidden list.')
else:
    print('Tray hidden list already configured.')
PYEOF
success "Tray SNI entry suppressed."

# ── autostart tweak ────────────────────────────────────────────────────────────
# Ensure Nextcloud starts silently at login with --background.
AUTOSTART_DIR="$HOME/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/Nextcloud.desktop"

if [[ ! -f "$AUTOSTART_FILE" ]]; then
  info "Creating Nextcloud autostart entry…"
  mkdir -p "$AUTOSTART_DIR"
  cat > "$AUTOSTART_FILE" << 'DESKTOPEOF'
[Desktop Entry]
Name=Nextcloud
GenericName=File Synchronizer
Exec=/usr/bin/nextcloud --background
Terminal=false
Icon=Nextcloud
Categories=Network
Type=Application
StartupNotify=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=10
DESKTOPEOF
  success "Autostart entry created."
else
  if ! grep -q "\-\-background" "$AUTOSTART_FILE"; then
    sed -i 's|^Exec=.*nextcloud.*|Exec=/usr/bin/nextcloud --background|' "$AUTOSTART_FILE"
    success "Autostart entry updated (added --background)."
  else
    info "Autostart entry already present and correct."
  fi
fi

echo ""
success "Done! The Nextcloud widget is now in your bar."
info "Start the client now with: nextcloud --background &"
info "Or set up a server: nextcloud (opens the wizard)"
