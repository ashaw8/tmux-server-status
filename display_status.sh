#!/bin/bash

status_file="/tmp/server_status"
index_file="/tmp/server_index"
timestamp_file="/tmp/server_status_timestamp"

servers=($(cat "$status_file"))  # Read server list into array
index=$(cat "$index_file" 2>/dev/null)  # Read the current index
index=${index:-0}  # Default to 0 if not set

declare -A downtimes
if [[ -f "$timestamp_file" ]]; then
    while IFS= read -r line; do
        server=$(echo "$line" | cut -d':' -f1)
        time=$(echo "$line" | cut -d':' -f2)
        downtimes[$server]=$time
    done < "$timestamp_file"
fi

# Display one server from the list with its downtime
if [ ${#servers[@]} -gt 0 ]; then
    server=${servers[$index]}
    downtime=${downtimes[$server]}
    echo_time=$(date -d "@$downtime" +"%Y-%m-%d %H:%M:%S")
    echo "$server DOWN @ $echo_time"
    # Increment the index
    ((index=(index+1)%${#servers[@]}))
else
    echo "All servers are up"
fi

# Save the new index
echo "$index" > "$index_file"
