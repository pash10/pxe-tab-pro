#!/bin/bash

LOG_FILE="/var/log/syslog"
TRACKER_FILE="/var/log/tftp_requests.txt"
ISO_FILE="pxelinux.0"

if  [[ -z $1 ]]; then
     echo "Usage : $0 <MIN_DOWNLOADS>"
     exit 1
fi 


MIN_DOWNLOADS=$1

read -p "Do you want to start monitoring PXE downloads? (yes/no): " START_RESPONSE
if [[ "$START_RESPONSE" != "yes" ]]; then
    echo "Exiting PXE monitoring."
    exit 0
fi


echo "Monitoring TFTP downloads for file: $ISO_FILE"
echo "Minimum downloads required: $MIN_DOWNLOADS"

if [[ ! -f $LOG_FILE ]]; then
    > "$LOG_FILE"
fi

if [[ ! -f $TRACKER_FILE ]]; then
    > "$TRACKER_FILE"
fi

while true; do
    grep "RRQ" "$LOG_FILE" | grep "$ISO_FILE" | awk '{print $5}' | sort -u > "$TRACKER_FILE"

    DOWNLOAD_COUNT=$(wc -l < "$TRACKER_FILE")
    echo "Current unique downloads: $DOWNLOAD_COUNT"

    if [[ $DOWNLOAD_COUNT -eq $MIN_DOWNLOADS ]]; then
        echo "Threshold met! Starting PXE deployment..."
        > "$TRACKER_FILE" 

        # Start deployment logic
        echo "Deploying PXE boot..."
        # Replace the following with actual deployment commands
        # Example: Initiate deployment script
        bash "/deployment-script.sh"

       else
       echo "Threshold did not meet the req qu..."
    fi

    sleep 10
done




