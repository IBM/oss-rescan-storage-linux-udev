#!/usr/bin/bash
#
# Copyright IBM Corp. 2025
#
# This source code is licensed under the Apache-2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

now="$(date +"%T")"
rasnow="$(date)"
CURRENT_TS_SECONDS=$(date +"%s")
SAFETY_SECONDS_DIFF=600
LAST_SCHEDULED_TS_SECONDS=0

MODEL2145=2145
VENDOR=IBM

RESCAN=/usr/bin/rescan-scsi-bus.sh

rescanpath="/sys$DEVPATH"
modelpath="/sys$DEVPATH/model"
vendorpath="/sys$DEVPATH/vendor"

# Tokenise the incoming devpath
OLDIFS="$IFS"
IFS='/' tokens=( $rescanpath )
IFS="$OLDIFS" # restore IFS

# Iterate over each element in the array and get base hostport
for element in "${tokens[@]}"; do
    first_four="${element:0:4}"
    if [ "$first_four" == "host" ]; then
		ehost=$element
                break
    fi
done

# Get the host# from the host token
HOST=`\echo "$ehost" | sed -e 's~host~~'`

# Check if the HOST contains integers as expected, this may fail if the OS version does not emit devpath format we expect.
if ! [ "$HOST" -eq "$HOST" ] 2> /dev/null
then
    echo "$rasnow Incoming event at $DEVPATH, $SDEV_UA" >> /var/log/ibm_2145/udev/rescan_error.log
    echo "$rasnow Issue in extracting host port identifier. Trigger manual storage rescans. EXITING."  >> /var/log/ibm_2145/udev/rescan_error.log
    exit
fi

# Make sure we trap the evnts from IBM SVC/FlashSystems only.
read -r MODEL_IN < $modelpath
read -r VENDOR_IN < $vendorpath

echo "$rasnow Incoming event at $DEVPATH, $SDEV_UA" >> /var/log/ibm_2145/udev/rescan$HOST.log

schedule_at_jobs(){
    # Schedule storage rescan
    echo "$rasnow Scheduling first step host $HOST " >> /var/log/ibm_2145/udev/rescan$HOST.log
    echo "/bin/ibm_2145_udev_action_rescan.sh $HOST" | at now+5minutes
    # Schedule cleanup rescan
    echo "$rasnow Scheduling cleanup rescan for host $HOST " >> /var/log/ibm_2145/udev/rescan$HOST.log
    echo "/bin/ibm_2145_udev_action_cleanup.sh $HOST" | at now+8minutes
}

# Process only the events from IBM FlashSystems 
if [[ ( "$VENDOR_IN" == "$VENDOR" ) && ( "$MODEL_IN" == "$MODEL2145" ) ]]; then
    if mkdir /tmp/.host$HOST.exclusivelock 2> /dev/null; then
        sync
        READ_SCHEDULED_TS_SECONDS=$(stat -c %Y /tmp/.host$HOST.exclusivelock/)
        echo "$rasnow Lock created for scheduling job. $READ_SCHEDULED_TS_SECONDS secs since epoch " >> /var/log/ibm_2145/udev/rescan$HOST.log
        # Schedule "at" jobs for rescans and cleanups.
        schedule_at_jobs
    else
        # Else would get executed till the time the lock dir is present. The cases could be:
        # - Event occured in the accumulation time of 5minutes from scheduled rescan job. 
        #   No action needed.
        # - Event occured after admin accidentally removed our scheduled rescan jobs.
        #   Read the last time this dir lock was modified and if its more than wait time.
        LAST_SCHEDULED_TS_SECONDS=$(stat -c %Y /tmp/.host$HOST.exclusivelock/)
        # The diff between current and last schedule should not be more 
        # than 10 minutes. Else schedule rescan to cover corner cases.
        diff_ts=$((CURRENT_TS_SECONDS-LAST_SCHEDULED_TS_SECONDS))
        if [ $diff_ts -gt $SAFETY_SECONDS_DIFF ]; then
            if mkdir /tmp/.host$HOST.exclusivelock/racelock 2> /dev/null; then
                echo "$rasnow $CURRENT_TS_SECONDS - $LAST_SCHEDULED_TS_SECONDS = $diff_ts.  Time diff greater than $SAFETY_SECONDS_DIFF seconds" >> /var/log/ibm_2145/udev/rescan$HOST.log
                echo "$rasnow Scheduling rescan to handle accidental job removals host$HOST " >> /var/log/ibm_2145/udev/rescan$HOST.log
                # Schedule "at" jobs for rescans and cleanups
                schedule_at_jobs
            fi
        fi
    fi
else
    echo "$rasnow Unsupported storage model $MODEL, vendor $VENDOR" >> /var/log/ibm_2145/udev/rescan$HOST.log
fi
