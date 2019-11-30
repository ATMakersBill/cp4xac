#!/bin/bash


ATMEL_BOARDS="circuitplayground_express circuitplayground_express_crickit circuitplayground_express_displayio feather_m0_express feather_m0_express_crickit feather_m4_express grandcentral_m4_express hallowing_m0_express hallowing_m4_express itsybitsy_m0_express itsybitsy_m4_express metro_m0_express metro_m4_express trellis_m4_express trinket_mo monster_m4sk pybadge pybadge_airlift pygamer pygamer_advance pyportal pyportal_titano pyruler"

NRF_BOARDS="circuitplayground_bluefruit feather_nrf52840_express itsybitsy_nrf52840_express metro_nrf52840_express"

ALL_BOARDS="${ATMEL_BOARDS} ${NRF_BOARDS}"

#start where the script lives
SCRIPT_LOC=`dirname "$0"`
CP_ROOT="${SCRIPT_LOC}/../circuitpython"

#Change CP_ROOT to your CircuitPython github clone

cd ${CP_ROOT}
pwd

#reset the CP source directory
git checkout -f master
git pull

#we need the latest named release
LATEST_TAG=`git tag --list | grep -v v | tail -1`

#Now we set that as the current view and then update
git checkout -q -f $LATEST_TAG


echo '#enable XAC Support (and no other HID)'
echo 'USB_HID_DEVICES="XAC_COMPATIBLE_GAMEPAD"'


#for curboard in $ALL_BOARDS
#do
#    echo $curboard
#done

echo $SCRIPT_LOC
echo $CP_ROOT
