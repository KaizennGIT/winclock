#!/usr/bin/env bash
# winclock installer. Installs or upgrades the widget for the current user.
#   ./install.sh              install or upgrade
#   ./install.sh --restart    install or upgrade, then restart the panel
#   ./install.sh --uninstall  remove the widget
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "kpackagetool6 not found. This widget needs KDE Plasma 6." >&2
    exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 not found (only used to read metadata.json)." >&2
    exit 1
fi
if [ ! -f metadata.json ]; then
    echo "metadata.json not found. Run this script from the winclock folder." >&2
    exit 1
fi

ID=$(python3 -c "import json; print(json.load(open('metadata.json'))['KPlugin']['Id'])")
NAME=$(python3 -c "import json; print(json.load(open('metadata.json'))['KPlugin']['Name'])")

if [ "${1:-}" = "--uninstall" ]; then
    kpackagetool6 -t Plasma/Applet -r "$ID"
    echo "Removed $NAME. Restart the panel (or log out and back in) to finish."
    exit 0
fi

if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -q "$ID"; then
    kpackagetool6 -t Plasma/Applet -u "$PWD"
    echo "Upgraded $NAME."
else
    kpackagetool6 -t Plasma/Applet -i "$PWD"
    echo "Installed $NAME."
fi

if [ "${1:-}" = "--restart" ]; then
    kquitapp6 plasmashell || true
    kstart plasmashell
    echo "Panel restarted."
else
    echo "Restart the panel to load it:  kquitapp6 plasmashell; kstart plasmashell"
fi

echo "To use it: right-click the panel > Add or Manage Widgets > search for \"$NAME\"."
