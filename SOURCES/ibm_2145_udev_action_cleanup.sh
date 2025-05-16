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

echo "$rasnow Processing cleanup step for host $HOST " >> /var/log/ibm_2145/udev/rescan$HOST.log
echo "$rasnow Processing cleanup step for host $HOST " >> /var/log/ibm_2145/udev/rescan_main$HOST.log
sync

. $RESCAN -r --hosts=$HOST 2>&1 | tee /var/log/ibm_2145/udev/rescan_main$HOST.log

rasnow="$(date)"
echo "$rasnow Cleanup processing complete for host $HOST " >> /var/log/ibm_2145/udev/rescan$HOST.log
echo "$rasnow Cleanup processing complete for host $HOST " >> /var/log/ibm_2145/udev/rescan_main$HOST.log
sync
