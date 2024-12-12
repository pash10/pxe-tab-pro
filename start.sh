#!/bin/bash

# Start DHCP server
service isc-dhcp-server start

# Start TFTP server
service tftpd-hpa start

# Run the TFTP monitor script
bash /tftp_monitor.sh "$@"