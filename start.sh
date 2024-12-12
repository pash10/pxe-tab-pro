#!/bin/bash

# Start DHCP server
service isc-dhcp-server start

# Start TFTP server
service tftpd-hpa start

mkdir -p "$SAMBA_FOLDER"


if [[ $? -ne 0 ]]; then
    echo "Error: Failed to mount Samba share."
    exit 1
fi

echo "Samba share mounted successfully at $SAMBA_FOLDER."
# Run the TFTP monitor script
bash /tftp_monitor.sh 