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
    model=`smartctl -i /dev/$disk | grep "Device Model:" | tr -s '[:space:]' '-' | cut -d'-' -f3`
    [ -z "$model" ] && model="N/A"
    capacity=`smartctl -i /dev/$disk | grep "User Capacity:" | tr -s '[:space:]' '-' | cut -d'-' -f3- | tr -s '-' ' '`
    [ -z "$capacity" ] && capacity="N/A"
    serial=`smartctl -i /dev/$disk | grep "Serial Number:" | tr -s '[:space:]' '-' | cut -d'-' -f3`
    [ -z "$serial" ] && serial="N/A"
    health=`smartctl -H /dev/$disk | grep "test result:" | awk -F ':' '{print $2}' | tr -d '[:space:]'`
    [ -z "$health" ] && health="N/A"
    temp=`smartctl -A /dev/$disk | grep "Temperature" | awk '{print $10}' | uniq | head -1`
    [ -z "$temp" ] && temp="N/A"
    reallocated=`smartctl -A /dev/$disk | grep "Reallocated_Sector_Ct" | tr -s '[:space:]' '#' | cut -d'#' -f11`
    [ -z "$reallocated" ] && reallocated="N/A"
    pending=`smartctl -A /dev/$disk | grep "Pending_Sector" | tr -s '[:space:]' '#' | cut -d'#' -f10`
    [ -z "$pending" ] && pending="N/A"
    echo
    echo "Device Model: $model - User Capacity: $capacity"
    echo "Serial Number: $serial"
    echo "HDD: /dev/$disk - Health: $health - TEMP: $tempºc"
    echo "Reallocated_Sector_Ct: $reallocated"
    echo "Current_Pending_Sector: $pending"
    echo "-"
done
echo
echo "----------------------------------- CPU Temp -----------------------------------"
echo
sensors

exit 0
