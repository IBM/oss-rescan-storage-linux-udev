#!/usr/bin/bash
#
# Copyright IBM Corp. 2025
#
# This source code is licensed under the Apache-2.0 license found in the
# LICENSE file in the root directory of this source tree.
#

HOST=$1
RESCAN=/usr/bin/rescan-scsi-bus.sh
rasnow="$(date)"

# Delay of 5 minutes over. Release the lock.
DIR="/tmp/.host$HOST.exclusivelock"
RACEDIR="/tmp/.host$HOST.exclusivelock/racelock"
if [ -d "$DIR" ]; then
    if [ -d "$RACEDIR" ]; then
        echo "$rasnow Removing racelock for $HOST " >> /var/log/ibm_2145/udev/rescan$HOST.log
        rmdir  /tmp/.host$HOST.exclusivelock/racelock
    fi
    echo "$rasnow Removing lock for $HOST " >> /var/log/ibm_2145/udev/rescan$HOST.log
    rmdir  /tmp/.host$HOST.exclusivelock
    sync
fi

rasnow="$(date)"
echo "$rasnow Processing rescan step for host $HOST " >> /var/log/ibm_2145/udev/rescan$HOST.log
echo "$rasnow Processing rescan step for host $HOST " >> /var/log/ibm_2145/udev/rescan_main$HOST.log
sync

. $RESCAN -d -m -r -f -i --hosts=$HOST 2>&1 | tee /var/log/ibm_2145/udev/rescan_main$HOST.log

echo "$rasnow Rescan processing complete for host $HOST" >> /var/log/ibm_2145/udev/rescan$HOST.log
echo "$rasnow Rescan processing complete for host $HOST" >> /var/log/ibm_2145/udev/rescan_main$HOST.log
sync
