#!/bin/bash

# Configuration
CLONEZILLA_IMAGES_DIR="/var/lib/tftpboot/clonezilla_images"
PXE_CONFIG_DIR="/var/lib/tftpboot/pxelinux.cfg"
DEFAULT_PXE_CONFIG="$PXE_CONFIG_DIR/default"
TFTP_DIR="/var/lib/tftpboot"
IMAGE_NAME="$1"


# Create PXE configuration for the selected image
echo "Creating PXE configuration for Clonezilla image: $IMAGE_NAME..."
cat <<EOF > "$DEFAULT_PXE_CONFIG"
DEFAULT clonezilla
LABEL clonezilla
    KERNEL vmlinuz
    APPEND initrd=initrd.img boot=live union=overlay components noswap edd=on nomodeset noprompt locales=en_US.UTF-8 keyboard-layouts=NONE ocs_prerun1="mount -t nfs \$server_ip:/clonezilla_images /home/partimag" ocs_live_run="ocs-sr -g auto -e1 auto -e2 -r -j2 -scr -p poweroff restoredisk $IMAGE_NAME sda" fetch=tftp://\$server_ip/live/filesystem.squashfs
PROMPT 0
TIMEOUT 30
EOF

echo "PXE configuration created successfully for $IMAGE_NAME."

# Restart services
echo "Restarting TFTP and DHCP services..."
service isc-dhcp-server restart
service tftpd-hpa restart

echo "Deployment setup completed for Clonezilla image: $IMAGE_NAME."