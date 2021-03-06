#!/bin/bash


ATMEL_BOARDS="circuitplayground_express circuitplayground_express_crickit circuitplayground_express_displayio feather_m0_express feather_m0_express_crickit feather_m4_express grandcentral_m4_express hallowing_m0_express hallowing_m4_express itsybitsy_m0_express itsybitsy_m4_express metro_m0_express metro_m4_express trellis_m4_express trinket_m0 monster_m4sk pybadge pybadge_airlift pygamer pygamer_advance pyportal pyportal_titano pyruler"
#ATMEL_BOARDS="circuitplayground_express"


NRF_BOARDS="circuitplayground_bluefruit feather_nrf52840_express itsybitsy_nrf52840_express metro_nrf52840_express"
#NRF_BOARDS="circuitplayground_bluefruit"

ALL_BOARDS="${ATMEL_BOARDS} ${NRF_BOARDS}"

#start where the script lives
SCRIPT_LOC=`dirname "$0"`
cd ${SCRIPT_LOC}
SCRIPT_LOC=`pwd`

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
git checkout -f $LATEST_TAG
git submodule sync
git submodule update --init --recursive

#append the XAC stuff to the py/circuitpy_mpconfig.mk file
echo '#enable XAC Support (and no other HID)' >> py/circuitpy_mpconfig.mk
echo 'USB_HID_DEVICES="XAC_COMPATIBLE_GAMEPAD"' >> py/circuitpy_mpconfig.mk

#Copy the alternative gamepad file to be frozen
cp -v ${SCRIPT_LOC}/lib/adafruit_hid/gamepad.py frozen/Adafruit_CircuitPython_HID/adafruit_hid/gamepad.py


#mpy-cross is not board specific
export BUILD_VERBOSE=3
make -C mpy-cross

NUM_BOARDS_BUILT=0

#do the atmel boards first
cd ports/atmel-samd/

# Adafruit's sample format for the UF2 file is
# adafruit-circuitpython-${BOARD}-${LANG}-${VERSION}.uf2
# adafruit-circuitpython-circuitplayground_express-en_US-5.0.0-beta.0.uf2
# Ours is similar
# atmakers-cp4xac-${BOARD}-${LANG}-${VERSION}.uf2
# Latest will be copied to atmakers-cp4xac-${BOARD}-${LANG}-LATEST.uf2
for curboard in $ATMEL_BOARDS
do
    VERUF2="${SCRIPT_LOC}/cp4xac-${LATEST_TAG}-${curboard}-en_US.uf2"
    LATESTUF2="${SCRIPT_LOC}/cp4xac-LATEST-${curboard}-en_US.uf2"
    if test -f ${VERUF2}; then
	echo "Skipping ${VERUF2}"
	continue
    fi
    echo 'FROZEN_MPY_DIRS += $(TOP)/frozen/Adafruit_CircuitPython_HID' >> boards/${curboard}/mpconfigboard.mk

    echo "Building $curboard----------------------------------------------------------------"
    make BOARD="$curboard" clean all
    cp -v "./build-${curboard}/firmware.uf2" ${VERUF2}
    cp -v ${VERUF2} ${LATESTUF2}
    NUM_BOARDS_BUILT=$((NUM_BOARDS_BUILT+1))
#    make BOARD="$curboard" clean
done

#do the NRF boards next

cd ${CP_ROOT}/ports/nrf/

for curboard in $NRF_BOARDS
do
    VERUF2="${SCRIPT_LOC}/cp4xac-${LATEST_TAG}-${curboard}-en_US.uf2"
    LATESTUF2="${SCRIPT_LOC}/cp4xac-LATEST-${curboard}-en_US.uf2"
    if test -f ${VERUF2}; then
	echo "Skipping ${VERUF2}"
	continue
    fi
    echo 'FROZEN_MPY_DIRS += $(TOP)/frozen/Adafruit_CircuitPython_HID' >> boards/${curboard}/mpconfigboard.mk
    
    echo "Building $curboard----------------------------------------------------------------"
    make BOARD="$curboard" clean all
    cp -v "./build-${curboard}/firmware.uf2" ${VERUF2}
    cp -v ${VERUF2} ${LATESTUF2}
    NUM_BOARDS_BUILT=$((NUM_BOARDS_BUILT+1))
#    make BOARD="$curboard" clean
done

cd ${SCRIPT_LOC}
echo "BUILT ${NUM_BOARDS_BUILT} Images"
if [ "$NUM_BOARDS_BUILT" -gt "1000000" ]; then
    git add -v *uf2
    git tag -v "TESTING-${LATEST_TAG}"
    git commit -v -m "Adding ${NUM_BOARDS_BUILT} Images with version ${LATEST_TAG}"
    git push -v
fi
