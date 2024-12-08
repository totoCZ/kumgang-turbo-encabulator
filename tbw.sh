#!/bin/bash

# List all disk devices (adjust for your system if needed)
DISKS=$(ls /dev/sd? 2>/dev/null)

# Function to process each disk's SMART data
process_smart_data() {
    local disk="$1"
    echo "Processing disk: $disk"
    
    # Extract necessary SMART data using smartctl
    local lbaw=$(smartctl -A "$disk" | grep "Total_LBAs_Written" | awk '{print $10}')
    local remain=$(smartctl -A "$disk" | grep "Percent_Lifetime_Remain" | awk '{print $10}')
    
    # Skip if no data found
    if [[ -z "$lbaw" || -z "$remain" ]]; then
        echo "  No SMART data found for $disk."
        return
    fi

    # Convert LBAs written to TB (assuming 512 bytes per sector)
    local tbw=$(echo "scale=2; $lbaw * 512 / 1024 / 1024 / 1024 / 1024" | bc)
    
    # Calculate usage percentage
    local usage=$((100 - remain))
    
    # Display results
    echo "  Total Bytes Written (TBW): $tbw TB"
    echo "  Usage: $usage%"
    echo
}

# Loop through all disks
for disk in $DISKS; do
    process_smart_data "$disk"
done
