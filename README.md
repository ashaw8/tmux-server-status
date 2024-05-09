### Steps

1. **Create the Directory for Scripts**
    - Create the `.tmux` directory in your home folder:

    ```bash
    mkdir -p ~/.tmux
    ```

2. **Create the Server Check Script**
    - Create the `server_check.sh` file inside the `.tmux` directory:

    ```bash
    vi ~/.tmux/server_check.sh
    ```

    - Copy and paste the following script into `server_check.sh` to define which servers to monitor:

    ```bash
    #!/bin/bash

    # Define the associative array for servers
    declare -A servers=(
        ["Server1"]="192.168.10.1"
        ["Server2"]="192.168.10.21"
        ["Server3"]="192.168.10.22"
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
    for server in "${!downtimes[@]}"]; do
        echo "$server:${downtimes[$server]}" >> "$timestamp_file"
    done
    ```

3. **Create the Display Status Script**
    - Create the `display_status.sh` file inside the `.tmux` directory:

    ```bash
    vi ~/.tmux/display_status.sh
    ```

    - Copy and paste the following script into `display_status.sh` to show the server status in the tmux status bar:

    ```bash
    #!/bin/bash

    status_file="/tmp/server_status"
    index_file="/tmp/server_index"
    timestamp_file="/tmp/server_status_timestamp"

    servers=($(cat "$status_file"))  # Read server list into an array
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
    ```

4. **Make Both Scripts Executable**
    - Ensure that both scripts are executable:

    ```bash
    chmod +x ~/.tmux/server_check.sh ~/.tmux/display_status.sh
    ```

5. **Set Up the Cron Job**
    - Schedule the `server_check.sh` script to run every minute by adding this line to the cron job list:

    ```bash
    crontab -e
    ```

    - Add the following line to run the script every minute:

    ```bash
    * * * * * ~/.tmux/server_check.sh
    ```

6. **Update Tmux Configuration**
    - Update your `~/.tmux.conf` file to include the status bar updates:

    ```bash
    set -g status-right "#(~/.tmux/display_status.sh)"
    set -g status-interval 5  # This makes tmux update the status bar every 5 seconds
    ```
