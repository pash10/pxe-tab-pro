# Base image
FROM ubuntu:latest

# Copy offline packages into the image
COPY offline-packages /tmp/offline-packages

# Install dependencies from the copied packages
RUN dpkg -i /tmp/offline-packages/*.deb || apt-get -f install -y

# Remove any existing file or symlink at /var/lib/tftpboot
RUN rm -rf /var/lib/tftpboot

# Create the TFTP boot directory
RUN mkdir -p /var/lib/tftpboot/pxelinux.cfg

# Copy ldlinux.c32 to the TFTP directory
RUN cp /tmp/offline-packages/ldlinux.c32 /var/lib/tftpboot

# Set up TFTP server directory
RUN mkdir -p /var/lib/tftpboot/pxelinux.cfg

# Copy required PXE bootloader files into TFTP directory
RUN cp /usr/lib/PXELINUX/pxelinux.0 /var/lib/tftpboot
RUN cp /tmp/offline-packages/ldlinux.c32 /var/lib/tftpboot

# Add kernel and initrd files (these must be included in the build context)
COPY ./linux_staff/noble-server-cloudimg-amd64-vmlinuz-generic /var/lib/tftpboot
COPY ./linux_staff/noble-server-cloudimg-amd64-initrd-generic /var/lib/tftpboot

# Copy PXE configuration file
#COPY pxelinux.cfg/default /var/lib/tftpboot/pxelinux.cfg/default

# Copy DHCP configuration file
COPY ./conf_files/dhcpd.conf /etc/dhcp/dhcpd.conf

# Copy TFTP server configuration
COPY ./conf_files/tftpd-hpa /etc/default/tftpd-hpa

# Copy the monitoring script
COPY tftp_monitor.sh /tftp_monitor.sh
RUN chmod +x /tftp_monitor.sh

# Start DHCP and TFTP services with the monitoring script
COPY start.sh /start.sh
RUN chmod +x /start.sh

COPY deployment.sh /deployment.sh
RUN chmod +x /deployment.sh

# Expose DHCP and TFTP ports
EXPOSE 67/udp 69/udp

ENTRYPOINT ["/start.sh"]
