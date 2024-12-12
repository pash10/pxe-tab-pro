#!/bin/bash

LOG_FILE="/var/log/syslog"
TRACKER_FILE="/var/log/tftp_requests.txt"
ISO_FOLDER="/var/lib/tftpboot/iso_files"
TFTP_DIR="/var/lib/tftpboot"
ISO_FILE=""
DEPLOYMENT_SCRIPT="./deployment.sh"
FILE_NAME_THAT_CH=''
SAMBA_IMAGE_FOLDER="/mnt/samba/images"
CHECK_EMPTRY='true'
MOUNT_POINT="/mnt/samba/images"
MOUNT_WORK='false'

sync_iso_from_samba() {
    echo "Syncing ISO files from Samba server..."
    rsync -av --delete "$SAMBA_IMAGE_FOLDER/" "$ISO_FOLDER/"
    if [[ $? -eq 0 ]]; then
        echo "Sync completed successfully."
    else
        echo "Error: Failed to sync with Samba server."
    fi
}

select_iso() {
    iso_files=("$ISO_FOLDER"/*)
    ISO_COUNT=${#iso_files[@]}

    if[[$ISO_COUNT -eq 1]];then
        $ISO_FILE="$iso_files[0]"
        $FILE_NAME_THAT_CH=$ISO_FILE
        echo "Only one ISO file found. Automatically selected: $(basename "$ISO_FILE")" 
    fi 
     
}

monitor_pxe() {
    echo "Monitoring TFTP requests in: $TRACKER_FILE"
    while read -r request; do
        if [[ -f "$request" ]]; then
            echo "Processing request for: $request"
            bash "$DEPLOYMENT_SCRIPT" "$request"
            sed -i \"/^$request$/d\" "$TRACKER_FILE"
            echo "Request completed and removed: $request"
        fi
    done < "$TRACKER_FILE"
}

check_and_remount_samba() {
    if ! mountpoint -q "$SAMBA_IMAGE_FOLDER"; then
        echo "Problem: The Samba server lost connection for some reason."
        read -p "Do you want to attempt remounting? (yes/no): " choice
        if [[ "$choice" == "yes" ]]; then
            echo "Attempting to remount Samba server..."
            mount -t cifs -o username="$SAMBA_USER",password="$SAMBA_PASSWORD" "$SAMBA_SERVER" "$SAMBA_IMAGE_FOLDER"
            if mountpoint -q "$SAMBA_IMAGE_FOLDER"; then
                echo "Samba server successfully remounted."
                MOUNT_WORK='true'
            else
                echo "Failed to remount Samba server."
                $MOUNT_WORK='false'
            fi
        else
            echo "Remounting skipped by user."
        fi
    fi
}

# Start monitoring process
while true; do
    check_and_remount_samba
    if [[ $CHECK_EMPTRY == 'true' ]]; then
        if [[ $MOUNT_WORK == 'true' ]]; then
            sync_iso_from_samba
            select_iso
            if [[ -f "$ISO_FILE" && "$ISO_FILE" != "" ]]; then
                CHECK_EMPTRY='false'
            fi
        else
            echo "Problem: Unable to sync files because the Samba mount is not active."
        fi
    else
        for ((i = 0; i < 30; i++)); do
            monitor_pxe
            if ((i == 29)); then
                CHECK_EMPTRY='true'
            fi
            sleep 1
        done
    fi
done



