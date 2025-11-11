#!/usr/bin/env bash
# Disable suspend on lid close
# Writes: /etc/systemd/logind.conf.d/10-laptop-server.conf

set -euo pipefail

CONF_DIR="/etc/systemd/logind.conf.d"
CONF_FILE="$CONF_DIR/10-laptop-server.conf"

sudo mkdir -p "$CONF_DIR"
sudo install -d -m 0755 "$CONF_DIR"

sudo tee "$CONF_FILE" >/dev/null <<'EOF'
[Login]
# Action when the lid closes in general
HandleLidSwitch=ignore
# Action when the lid closes while on AC power (overrides the general one)
HandleLidSwitchExternalPower=ignore
# Action when the lid closes while “docked” (external monitor/DOCK present)
# This overrides both above when applicable.
HandleLidSwitchDocked=ignore
EOF

sudo chmod 0644 "$CONF_FILE"

sudo systemctl reload-or-restart systemd-logind
