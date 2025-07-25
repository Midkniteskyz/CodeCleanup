#!/bin/bash
# SolarWinds SAM Component Monitor - TCPDump Statistics Collector
# Script Argument: echo "${PASSWORD}" | sudo -S sh ${SCRIPT} "ens32" "10"
# ------ Arguments Section ------
# First argument: Network interface to monitor (e.g., eth0, ens32)
INTERFACE="$1"
# Second argument: Duration in seconds to run tcpdump
DURATION="$2"
# Third argument (optional): Custom tcpdump filter expression
FILTER="${3:-}"  # The :- syntax provides a default empty value if $3 is not provided
# Generate a unique temporary filename based on current date and time
FILENAME="/tmp/tcpdump_$(date +%Y%m%d_%H%M%S).txt"
# Define log file for persistent logging
LOGFILE="/var/log/tcpdump_sam.log"

# ------ Logging Function ------
# This function writes timestamped messages to both console and log file
log_message() {
    # Format: "YYYY-MM-DD HH:MM:SS - message"
    # tee -a appends to the log file without overwriting it
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

# Log script start with parameters for audit purposes
log_message "SCRIPT STARTED: Interface=$INTERFACE, Duration=$DURATION, Filter='$FILTER'"

# ------ Input Validation ------
# Check if required arguments are provided
if [[ -z "$INTERFACE" || -z "$DURATION" ]]; then
    log_message "ERROR: Missing required arguments."
    # Output in SolarWinds SAM format (Statistic.* and Message.*)
    echo "Statistic.Error: 1"
    echo "Message.Error: Missing required arguments."
    exit 1
fi

# ------ Dependency Check ------
# Verify tcpdump is installed on the system
if ! command -v tcpdump; then
    # Note: Redirecting output to /dev/null to avoid cluttering the output
    log_message "ERROR: tcpdump is not installed."
    echo "Statistic.Error: 1"
    echo "Message.Error: tcpdump is not installed."
    exit 1
fi

# ------ Main tcpdump Execution ------
# Run tcpdump for the specified duration with the given filter
log_message "Running tcpdump on $INTERFACE for $DURATION seconds with filter '$FILTER'..."
# timeout command ensures tcpdump stops after DURATION seconds
# tee captures the output to both the console and the file
if ! timeout "$DURATION" tcpdump -i "$INTERFACE" $FILTER 2>&1 | tee "$FILENAME"; then
    log_message "ERROR: Failed to run tcpdump"
    echo "Statistic.Error: 1"
    echo "Message.Error: Failed to run tcpdump"
    exit 1
fi

# Short delay to ensure all data is flushed to disk
sleep 1

# ------ Parse tcpdump Statistics ------
# Extract the packet statistics from tcpdump's summary output
# These are typically the last few lines of the output
PKTCAP=$(grep -E "packets captured" "$FILENAME")
PKTCAP_NUM=$(echo "$PKTCAP" | awk '{print $1}')  # Extract just the number
PKTRCV=$(grep -E "packets received" "$FILENAME")
PKTRCV_NUM=$(echo "$PKTRCV" | awk '{print $1}')
PKTDRP=$(grep -E "packets dropped" "$FILENAME")
PKTDRP_NUM=$(echo "$PKTDRP" | awk '{print $1}')

# Log the parsed results
log_message "RESULTS: Captured=$PKTCAP_NUM, Received=$PKTRCV_NUM, Dropped=$PKTDRP_NUM"

# ------ Output in SolarWinds SAM Format ------
# Format the output so SolarWinds SAM can parse it correctly
# Each statistic has both a numerical value and a descriptive message
echo "Message.Captured: $PKTCAP on $INTERFACE. Filter: $FILTER"
echo "Statistic.Captured: $PKTCAP_NUM"
echo "Message.Received: $PKTRCV on $INTERFACE. Filter: $FILTER"
echo "Statistic.Received: $PKTRCV_NUM"
echo "Message.Dropped: $PKTDRP on $INTERFACE. Filter: $FILTER"
echo "Statistic.Dropped: $PKTDRP_NUM"

# ------ Cleanup ------
# Remove the temporary file to avoid filling up disk space
rm -f "$FILENAME"
log_message "SCRIPT COMPLETED SUCCESSFULLY."

# Exit with success status code
exit 0