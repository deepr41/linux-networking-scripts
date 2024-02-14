#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 T TP X Y"
    exit 1
fi
CPUCOUNT="$(nproc)"

# Assign arguments to variables
T="$1"
TP="$2"
X="$3"
Y="$4"

$(mkdir -p /tmp/ln)

# Output CSV file paths
cpu_log_file="/tmp/ln/cpu_log.csv"
alert_log_file="/tmp/ln/alert_log.csv"

# Function to log CPU load averages
log_cpu_load() {
    echo "timestamp,1min_avg,5min_avg,15min_avg" > "$cpu_log_file"
    echo "timestamp,alert,1min_avg,5min_avg,15min_avg" > "$alert_log_file"
    end_time=$((SECONDS+TP))
    while [ $SECONDS -lt $end_time ]; do
        timestamp=$(date +%s)
	load_avg=$(uptime | awk '{print substr($0, length($0)-15)}' | tr -d ' ')
        echo "$timestamp,$load_avg" >> "$cpu_log_file"
	IFS=',' read -r avg_1min avg_5min avg_15min <<< "$load_avg"

	# high cpu usage
	if (( $(echo "($avg_1min / $CPUCOUNT) > $X" | bc -l) )); then
		alert="HIGH CPU usage"
		echo "$timestamp,$alert,$load_avg" >> "$alert_log_file"
	fi

	# very high cpu usage
	if (( $(echo "($avg_5min / $CPUCOUNT) > $Y" | bc -l) )) && (( $(echo "$avg_1min > $avg_5min" | bc -l) )); then
		alert="VERY HIGH CPU usage"
		echo "$timestamp,$alert,$load_avg" >> "$alert_log_file"
	fi

        sleep "$T"
    done
}


# Run the monitoring and alert generation
log_cpu_load
