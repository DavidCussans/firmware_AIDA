# firmware_AIDA
Firmware for the AIDA TLU Hardware

This repository contains the VHL used to generate the firmware for the AIDA TLU, both versions V1C (T-shaped pcb) and V1E (rectangular PCB; the one most likely to be used outside the UoB lab).

# Scripts
The repository also contains Python scripts used to test the hardware. These scripts rely on a few libraries not linked here, so they are unlikely to work "out of the box".

# EUDAQ2
The best way to operate on the TLU is by using the EUDAQ2 tools (provide link!).

# Building Firmware

The master firmware uses the [ipbb](https://github.com/ipbus/ipbb) build tool, and requires the ipbus system firmware.

Set up the environment for Xilinx Vivado

	mkdir work
	cd work
	curl -L https://github.com/ipbus/ipbb/archive/v0.2.5.tar.gz | tar xvz
	source ipbb-0.2.5/env.sh
	ipbb init build
	cd build
	ipbb add git https://github.com/ipbus/ipbus-firmware.git -b enhancement/28
	ipbb add git git@github.com:DavidCussans/firmware_AIDA.git
	ipbb proj create vivado TLU_1e firmware_AIDA:projects/TLU_1e -t top_tlu_1e_a35.dep
	cd proj/TLU_1e
	ipbb vivado project
	ipbb vivado impl
	ipbb vivado bitfile
	ipbb vivado package
	deactivate
