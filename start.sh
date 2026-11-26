#!/bin/bash
set -euo pipefail
if [[ "${PXE_LAB_APPROVED:-}" != "yes" ]]; then
    echo "PXE services disabled. Authorize an isolated provisioning lab first." >&2
    exit 1
fi
# Do not start with a previously generated unattended restore config.
config=/var/lib/tftpboot/pxelinux.cfg
mkdir -p "$config"
if [[ -n "$(find "$config" -mindepth 1 -maxdepth 1 ! -name default -print -quit)" ]]; then
    echo "Unexpected client-specific boot configuration; review manually." >&2
    exit 1
fi
cat > "$config/default" <<'EOF'
DEFAULT local
LABEL local
    LOCALBOOT 0
PROMPT 1
TIMEOUT 50
EOF
service isc-dhcp-server start
service tftpd-hpa start
exec bash /tftp_monitor.sh
