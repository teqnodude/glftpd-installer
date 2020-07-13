#!/bin/bash
VER=1.0
#---------------------------------------------------------------#
# Syscheck by Teqno                                             #
#                                                               #
# Lists the relevant S.M.A.R.T status on installed hdds         #
# and the CPU temp in a clear way.                              #
#                                                               #
#--[ Script Start ]---------------------------------------------#

echo "----------------------------- Regular Controller ------------------------------"
for disk in `lsblk | grep "0 disk" | tr -s ' ' '-' | awk -F '-' '{print $1}'`
do
        echo
        echo "`smartctl -i /dev/$disk | grep "Device Model:"` - `smartctl -i /dev/$disk | grep "User Capacity:"`"
        echo "`smartctl -i /dev/$disk | grep "Serial Number:"`"
        echo "HDD: /dev/$disk - Health:`smartctl -H /dev/$disk | grep "test result:" | awk -F ':' '{print $2}'` - TEMP: "`smartctl -A /dev/$disk | grep "Temperature" | awk '{print $10}' | uniq`"ºc"
        smartctl -A /dev/$disk | grep "Reallocated_Sector_Ct"
        smartctl -A /dev/$disk | grep "Current_Pending_Sector"
done
echo
echo "----------------------------------- CPU Temp -----------------------------------"
echo
sensors

exit 0
