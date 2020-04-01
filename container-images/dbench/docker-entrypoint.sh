#!/usr/bin/env sh
# SOURCE: https://github.com/leeliu/dbench
set -e

log() {
  (>&2 echo ">>> [dbench] ($(date '+%Y-%m-%d %H:%M:%S')) $*");
}

if [ -z "$DBENCH_MOUNTPOINT" ]; then
    DBENCH_MOUNTPOINT=/tmp
fi

if [ -z "$FIO_SIZE" ]; then
    FIO_SIZE=2G
fi

if [ -z "$FIO_OFFSET_INCREMENT" ]; then
    FIO_OFFSET_INCREMENT=500M
fi

if [ -z "$FIO_RAMP_TIME" ]; then
    FIO_RAMP_TIME=2s
fi

if [ -z "$FIO_RUNTIME" ]; then
    FIO_RUNTIME=20s
fi

if [ -z "$FIO_DIRECT" ]; then
    FIO_DIRECT=1
fi

if [ -z "$WORKLOAD_TYPE" ]; then
    WORKLOAD_TYPE=job
fi

if [ -z "$IOPING_COUNT" ]; then
    IOPING_COUNT=20
fi

echo Working dir: $DBENCH_MOUNTPOINT
echo

if [ "$1" = "fio" ]; then
    log "Testing Read IOPS"
    READ_IOPS=$(fio --randrepeat=1 --ioengine=libaio --direct="$FIO_DIRECT" --gtod_reduce=1 --name=read_iops --filename="$DBENCH_MOUNTPOINT/fiotest" --bs=4K --iodepth=64 --size="$FIO_SIZE" --readwrite=randread --time_based --ramp_time="$FIO_RAMP_TIME" --runtime="$FIO_RUNTIME")
    echo "$READ_IOPS"
    READ_IOPS_VAL=$(echo "$READ_IOPS"|grep -E 'read ?:'|grep -Eoi 'IOPS=[0-9k.]+'|cut -d'=' -f2)
    echo
    echo

    log "Testing Write IOPS"
    WRITE_IOPS=$(fio --randrepeat=1 --ioengine=libaio --direct="$FIO_DIRECT" --gtod_reduce=1 --name=write_iops --filename="$DBENCH_MOUNTPOINT/fiotest" --bs=4K --iodepth=64 --size="$FIO_SIZE" --readwrite=randwrite --time_based --ramp_time="$FIO_RAMP_TIME" --runtime="$FIO_RUNTIME")
    echo "$WRITE_IOPS"
    WRITE_IOPS_VAL=$(echo "$WRITE_IOPS"|grep -E 'write:'|grep -Eoi 'IOPS=[0-9k.]+'|cut -d'=' -f2)
    echo
    echo

    log "Testing Read Bandwidth"
    READ_BW=$(fio --randrepeat=1 --ioengine=libaio --direct="$FIO_DIRECT" --gtod_reduce=1 --name=read_bw --filename="$DBENCH_MOUNTPOINT/fiotest" --bs=128K --iodepth=64 --size="$FIO_SIZE" --readwrite=randread --time_based --ramp_time="$FIO_RAMP_TIME" --runtime="$FIO_RUNTIME")
    echo "$READ_BW"
    READ_BW_VAL=$(echo "$READ_BW"|grep -E 'read ?:'|grep -Eoi 'BW=[0-9GMKiBs/.]+'|cut -d'=' -f2)
    echo
    echo

    log "Testing Write Bandwidth"
    WRITE_BW=$(fio --randrepeat=1 --ioengine=libaio --direct="$FIO_DIRECT" --gtod_reduce=1 --name=write_bw --filename="$DBENCH_MOUNTPOINT/fiotest" --bs=128K --iodepth=64 --size="$FIO_SIZE" --readwrite=randwrite --time_based --ramp_time="$FIO_RAMP_TIME" --runtime="$FIO_RUNTIME")
    echo "$WRITE_BW"
    WRITE_BW_VAL=$(echo "$WRITE_BW"|grep -E 'write:'|grep -Eoi 'BW=[0-9GMKiBs/.]+'|cut -d'=' -f2)
    echo
    echo

    log "Testing Disk I/O Latency"
    LATENCY=$(ioping -c "$IOPING_COUNT" "$DBENCH_MOUNTPOINT")
    echo "$LATENCY"
    LATENCY_VALS=$(echo "$LATENCY" | grep -Eoi '^min/avg/max/mdev.*$' | awk -F' = ' '{ print $2 }')
    echo
    echo

    if  [ -z "$DBENCH_QUICK" ] || [ "$DBENCH_QUICK" = "no" ]; then
        log "Testing Read Latency"
        READ_LATENCY=$(fio --randrepeat=1 --ioengine=libaio --direct="$FIO_DIRECT" --name=read_latency --filename="$DBENCH_MOUNTPOINT/fiotest" --bs=4K --iodepth=4 --size="$FIO_SIZE" --readwrite=randread --time_based --ramp_time="$FIO_RAMP_TIME" --runtime="$FIO_RUNTIME")
        echo "$READ_LATENCY"
        READ_LATENCY_VAL=$(echo "$READ_LATENCY"|grep ' lat.*avg'|grep -Eoi 'avg=[0-9.]+'|cut -d'=' -f2)
        echo
        echo

        log "Testing Write Latency"
        WRITE_LATENCY=$(fio --randrepeat=1 --ioengine=libaio --direct="$FIO_DIRECT" --name=write_latency --filename="$DBENCH_MOUNTPOINT/fiotest" --bs=4K --iodepth=4 --size="$FIO_SIZE" --readwrite=randwrite --time_based --ramp_time="$FIO_RAMP_TIME" --runtime="$FIO_RUNTIME")
        echo "$WRITE_LATENCY"
        WRITE_LATENCY_VAL=$(echo "$WRITE_LATENCY"|grep ' lat.*avg'|grep -Eoi 'avg=[0-9.]+'|cut -d'=' -f2)
        echo
        echo

        log "Testing Read Sequential Speed"
        READ_SEQ=$(fio --randrepeat=1 --ioengine=libaio --direct="$FIO_DIRECT" --gtod_reduce=1 --name=read_seq --filename="$DBENCH_MOUNTPOINT/fiotest" --bs=1M --iodepth=16 --size="$FIO_SIZE" --readwrite=read --time_based --ramp_time="$FIO_RAMP_TIME" --runtime="$FIO_RUNTIME" --thread --numjobs=4 --offset_increment=$FIO_OFFSET_INCREMENT)
        echo "$READ_SEQ"
        READ_SEQ_VAL=$(echo "$READ_SEQ"|grep -E 'READ:'|grep -Eoi '(aggrb|bw)=[0-9GMKiBs/.]+'|cut -d'=' -f2)
        echo
        echo

        log "Testing Write Sequential Speed"
        WRITE_SEQ=$(fio --randrepeat=1 --ioengine=libaio --direct="$FIO_DIRECT" --gtod_reduce=1 --name=write_seq --filename="$DBENCH_MOUNTPOINT/fiotest" --bs=1M --iodepth=16 --size="$FIO_SIZE" --readwrite=write --time_based --ramp_time="$FIO_RAMP_TIME" --runtime="$FIO_RUNTIME" --thread --numjobs=4 --offset_increment=$FIO_OFFSET_INCREMENT)
        echo "$WRITE_SEQ"
        WRITE_SEQ_VAL=$(echo "$WRITE_SEQ"|grep -E 'WRITE:'|grep -Eoi '(aggrb|bw)=[0-9GMKiBs/.]+'|cut -d'=' -f2)
        echo
        echo

        log "Testing Read/Write Mixed"
        RW_MIX=$(fio --randrepeat=1 --ioengine=libaio --direct="$FIO_DIRECT" --gtod_reduce=1 --name=rw_mix --filename="$DBENCH_MOUNTPOINT/fiotest" --bs=4k --iodepth=64 --size="$FIO_SIZE" --readwrite=randrw --rwmixread=75 --time_based --ramp_time="$FIO_RAMP_TIME" --runtime="$FIO_RUNTIME")
        echo "$RW_MIX"
        RW_MIX_R_IOPS=$(echo "$RW_MIX"|grep -E 'read ?:'|grep -Eoi 'IOPS=[0-9k.]+'|cut -d'=' -f2)
        RW_MIX_W_IOPS=$(echo "$RW_MIX"|grep -E 'write:'|grep -Eoi 'IOPS=[0-9k.]+'|cut -d'=' -f2)
        echo
        echo
    fi

    log "All tests complete."
    echo
    echo "=================="
    echo "= Dbench Summary ="
    echo "=================="
    echo "Random Read/Write IOPS: $READ_IOPS_VAL/$WRITE_IOPS_VAL"
    echo "Random Read/Write BW: $READ_BW_VAL/$WRITE_BW_VAL"
    echo "Disk I/O Latency min/avg/max/mdev: $LATENCY_VALS"

    if [ -z "$DBENCH_QUICK" ] || [ "$DBENCH_QUICK" = "no" ]; then
        echo "Average Latency (usec) Read/Write: $READ_LATENCY_VAL/$WRITE_LATENCY_VAL"
        echo "Sequential Read/Write: $READ_SEQ_VAL/$WRITE_SEQ_VAL"
        echo "Mixed Random Read/Write IOPS: $RW_MIX_R_IOPS/$RW_MIX_W_IOPS"
    fi

    rm "$DBENCH_MOUNTPOINT/fiotest"

	# Do not exit if using a daemonset
	if [ "$WORKLOAD_TYPE" != "job" ]; then
		tail -f /dev/null
	fi

    exit 0
fi

exec "$@"
