#!/bin/bash
 
#lvs -o +raid_mismatch_count,raid_sync_action --all

json_report=$(lvs --reportformat json_std --all)

# Iterate through each logical volume in the JSON report
echo "$json_report" | jq -r '.report[0].lv[] | .lv_name' | while read -r lv_name; do
    # Extract the lv_attr and copy_percent for the current lv_name
    lv_attr=$(echo "$json_report" | jq -r --arg lv "$lv_name" '.report[0].lv[] | select(.lv_name == $lv) | .lv_attr')
    copy_percent=$(echo "$json_report" | jq -r --arg lv "$lv_name" '.report[0].lv[] | select(.lv_name == $lv) | .copy_percent')
    lv_size=$(echo "$json_report" | jq -r --arg lv "$lv_name" '.report[0].lv[] | select(.lv_name == $lv) | .lv_size')
    
    # Check for RAID inconsistencies based on the lv_attr
    if [[ "$lv_attr" =~ "p" ]]; then
        echo "ERROR: Logical volume $lv_name has a 'p' attribute indicating potential RAID issues (e.g., partial)."
    fi

    # Check for inconsistencies with 'Iwi' vs 'iwi'
    if [[ "$lv_attr" =~ "I" ]]; then
        echo "ERROR: Logical volume $lv_name has 'I' in its lv_attr, which might indicate an inconsistency or failure in the mirror."
    fi

    # Check for copy_percent issues, allow null for rmeta images
    if [[ "$lv_name" != *"rmeta"* && "$lv_name" != *"rimage"* && ("$copy_percent" != "100.00")]]; then
        echo "WARNING: Logical volume $lv_name has an unusual copy_percent value: $copy_percent"
    fi

done
