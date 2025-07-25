#!/bin/bash

# Run vmstat command and store its output
vmstat_output=$(vmstat)

# Split the second line of vmstat output into an array
read -ra line <<< "$(echo "$vmstat_output" | sed -n '3p')"

# Find the index of "us" in the array
for ((i = 0; i < ${#line[@]}; i++)); do
    if [[ "${line[i]}" == "us" ]]; then
        j=$i
        break
    fi
done

# If "us" is found, extract the corresponding value from the third line
if [[ -n $j ]]; then
    read -ra stat <<< "$(echo "$vmstat_output" | sed -n '4p')"
    echo "Message: CPU user time in percentage: ${stat[j]}"
    echo "Statistic: ${stat[j]}"
    exit 0
else
    echo "Message: ERROR: Can't find CPU user time (us) in output of vmstat command."
    exit 1
fi
