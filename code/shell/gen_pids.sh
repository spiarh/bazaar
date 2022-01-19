#!/bin/bash

PROC_LIMIT="${PROC_LIMIT:-4096}"

echo "Processes to create: $PROC_LIMIT"

while true; do
    for i in $(seq 1 "$PROC_LIMIT"); do
        sleep 1d &
        echo "  [+] proc count: $i"
    done

    echo "Created processes: $PROC_LIMIT"
    sleep 1d
done
