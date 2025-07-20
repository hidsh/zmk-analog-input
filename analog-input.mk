# Makefile for zmk
#
# Install:
#   1. cd PATH/TO/zmk/app
#   2. ln -s PATH/TO/analog-input.mk ./Makefile
#
# Usage:
#   1. cd PATH/TO/zmk/app
#   2. make

SHIELD = analog-input
BOARD = seeeduino_xiao_ble
DRV_NAME = XIAO
KBD_PID = 615e					# product id

# abs path to this makefile
mkpath = $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# for usb-debugging, or comment out if you don't need it
OPT_USB_LOGGING = --snippet zmk-usb-logging

# for un-official drivers
OPT_DRV = -DZMK_EXTRA_MODULES='${mkpath}/zmk-modules/zmk-analog-input-driver'

.PHONY: build flash info

flash: build info
	@echo '::'
	@echo -n ':: Flashing: '
	@find $$(pwd) -name *.uf2 | xargs ls -l | cut -d ' ' -f 6-
	@echo -n '::           '
	@find $$(pwd) -name *.uf2 | xargs file -b | cut -d ',' -f 1,2
	@echo ':: DOUBLE CLICK RESET BUTTON ON XIAO!!'
	@until mount | grep --quiet ${DRV_NAME}; do echo -n '.'; sleep 1; done; echo
	@-west flash 2> /dev/null
	@sleep 1
	@echo -n ':: '
	@timeout 5s sh -c "until grep --ignore-case --fixed-strings '${SHIELD}' /proc/bus/input/devices | cut -d ' ' -f 2-; do sleep 1; done"
	@cyme | grep ${KBD_PID}
	@echo ':: done flashing.'

build: info
	[ ! -d ${mkpath}/zmk-modules/zmk-analog-input-driver ] && git clone https://github.com/badjeff/zmk-analog-input-driver.git ${mkpath}/zmk-modules/zmk-analog-input-driver || true
	west build  --pristine \
	            --board ${BOARD} \
	            ${OPT_USB_LOGGING} \
	            --  -DSHIELD=${SHIELD} \
	                -DZMK_CONFIG='${mkpath}/config' \
	                ${OPT_DRV}
	@echo -n ':: '
	@find $$(pwd) -name *.uf2 | xargs ls -l | cut -d ' ' -f 6-

info:
	@echo -n ':: Reading: '
	@find $$(pwd) -maxdepth 1 -name $(firstword $(MAKEFILE_LIST)) | xargs ls -l | cut -d ' ' -f 8-
	@echo '::   Board:   '${BOARD}
	@echo '::   Shield:  '${SHIELD}
	@echo '::   KBD_PID: '${KBD_PID}
	@echo ' '$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
