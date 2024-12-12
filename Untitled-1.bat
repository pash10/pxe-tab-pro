#!/bin/bash

# Path to DHCP log file
DHCP_LOG="/var/log/dhcpd.log"

# File to track unique MAC addresses
MAC_TRACKER="tracked_macs.txt"

# Minimum number of devices required to trigger PXE deployment
MIN_DEVICES=50

# PXE deployment script
DEPLOYMENT_SCRIPT="/path/to/deployment_script.sh"

# Function to extract MAC addresses from DHCP logs
extract_mac_addresses() {
    grep -E "DHCPDISCOVER|DHCPREQUEST" "$DHCP_LOG" | \
    grep -oE "([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}" | sort -u
}

# Function to monitor DHCP requests
monitor_dhcp_requests() {
    # Initialize the MAC tracker file if it doesn't exist
    if [[ ! -f $MAC_TRACKER ]]; then
        > "$MAC_TRACKER"
    fi

    # Load tracked MAC addresses into an array
    tracked_macs=($(cat "$MAC_TRACKER"))
    tracked_count=${#tracked_macs[@]}

    echo "Currently tracked devices: $tracked_count"

    while true; do
        # Extract new MAC addresses from the logs
        current_macs=$(extract_mac_addresses)
        new_macs=()

        # Find MACs that are not already tracked
        for mac in $current_macs; do
            if ! grep -q "$mac" "$MAC_TRACKER"; then
                new_macs+=("$mac")
            fi
        done

        # Add new MAC addresses to the tracker file
        if [[ ${#new_macs[@]} -gt 0 ]]; then
            echo "New devices detected: ${new_macs[*]}"
            for mac in "${new_macs[@]}"; do
                echo "$mac" >> "$MAC_TRACKER"
            done
            tracked_count=$((tracked_count + ${#new_macs[@]}))
        fi

        echo "Total unique devices tracked: $tracked_count"

        # Check if the threshold is met
        if [[ $tracked_count -ge $MIN_DEVICES ]]; then
            echo "Threshold met! Starting PXE deployment..."
            start_pxe_deployment
            break
        fi

        # Sleep for 10 seconds before checking again
        sleep 10
    done
}

# Function to start PXE deployment
start_pxe_deployment() {
    if [[ -x "$DEPLOYMENT_SCRIPT" ]]; then
        "$DEPLOYMENT_SCRIPT"
        echo "PXE deployment triggered successfully."
        # Clear the MAC tracker for re-deployment
        > "$MAC_TRACKER"
    else
        echo "Error: Deployment script $DEPLOYMENT_SCRIPT not found or not executable."
        exit 1
    fi
}

# Main function
main() {
    echo "Monitoring DHCP requests..."
    monitor_dhcp_requests
}

# Run the main function
main
