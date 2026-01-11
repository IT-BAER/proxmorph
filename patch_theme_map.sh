#!/bin/bash
# Patch proxmoxlib.js to add UniFi theme
FILE="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"

# Check if already patched
if grep -q "unifi" "$FILE"; then
    echo "Already patched!"
else
    # Use awk for multi-line insert
    awk '/theme_map: \{/ { print; print "            '\''unifi'\'': '\''UniFi'\'',"; next }1' "$FILE" > /tmp/proxmoxlib.js.new
    mv /tmp/proxmoxlib.js.new "$FILE"
    echo "Patched!"
fi

# Restart pveproxy
systemctl restart pveproxy
echo "pveproxy restarted"

echo "Current theme_map:"
grep -A6 "theme_map:" "$FILE"
