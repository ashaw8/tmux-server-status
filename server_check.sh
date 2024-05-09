#!/bin/bash

# Define the associative array for servers
declare -A servers=(
    ["Server1"]="192.168.10.1"
    ["Server2"]="192.168.10.2"
    ["Server3"]="192.168.10.3
    # Add more servers as needed
)

status_file="/tmp/server_status"
timestamp_file="/tmp/server_status_timestamp"

# Read existing down times if the file exists
declare -A downtimes
if [[ -f "$timestamp_file" ]]; then
    while IFS= read -r line; do
        server=$(echo "$line" | cut -d':' -f1)
        time=$(echo "$line" | cut -d':' -f2)
        downtimes[$server]=$time
    done < "$timestamp_file"
fi

# Ping each server and update status
down_servers=()
for server_name in "${!servers[@]}"; do
    server_ip="${servers[$server_name]}"
    if ! ping -c 1 "$server_ip" &> /dev/null; then
        down_servers+=("$server_name")
        # If not already recorded, record the downtime
        [[ -z "${downtimes[$server_name]}" ]] && downtimes[$server_name]=$(date +%s)
    else
        # If the server is up, clear its downtime record
        unset downtimes[$server_name]
    fi
done

# Update the down server list file and timestamps
echo "${down_servers[*]}" > "$status_file"
> "$timestamp_file"  # Clear and rewrite the timestamp file
for server in "${!downtimes[@]}"; do
    echo "$server:${downtimes[$server]}" >> "$timestamp_file"
done
