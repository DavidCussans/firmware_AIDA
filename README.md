# firmware_AIDA
Firmware for the AIDA TLU Hardware

This repository contains the VHL used to generate the firmware for the AIDA TLU, both versions V1C (T-shaped pcb) and V1E (rectangular PCB; the one most likely to be used outside the UoB lab).

# Scripts
The repository also contains Python scripts used to test the hardware. These scripts rely on a few libraries not linked here, so they are unlikely to work "out of the box".

# EUDAQ2
The best way to operate on the TLU is by using the EUDAQ2 tools (provide link!).

# Building Firmware

The master firmware uses the [ipbb](https://github.com/ipbus/ipbb) build tool, and requires the ipbus system firmware.

Set up the environment for Xilinx Vivado, then:

	mkdir work
	cd work
	git clone git@github.com:ipbus/ipbb.git 	
	( ... or curl -L https://github.com/ipbus/ipbb/archive/v0.2.5.tar.gz | tar xvz )
	source ipbb/env.sh
	ipbb init build
	cd build
	ipbb add git https://github.com/ipbus/ipbus-firmware.git -b enhancement/28
	ipbb add git git@github.com:DavidCussans/firmware_AIDA.git
	ipbb proj create vivado TLU_1e firmware_AIDA:projects/TLU_v1e -t top_tlu_1e_a35.dep
	cd proj/TLU_1e
	ipbb vivado project
	# Set correct file as design "top"
	vivado -mode tcl -nojournal -nolog -notrace -source ../../src/firmware_AIDA/projects/TLU_v1e/firmware/cfg/set_top.tcl top/top.xpr
	# Edit the files in the IPBus repostitory to expose the 200MHz clock
	sed -i 's/onehz);/onehz); clk_200_o<=clk200;/' ../../src/ipbus-firmware/boards/enclustra_ax3_pm3/base_fw/synth/firmware/hdl/enclustra_ax3_pm3_infra.vhd
	sed -i 's/clk125_o: out std_logic/clk125_o, clk_200_o: out std_logic/' ../../src/ipbus-firmware/boards/enclustra_ax3_pm3/base_fw/synth/firmware/hdl/enclustra_ax3_pm3_infra.vhd
	# Comment out the cfg signals in the IPBus constraints file enclustra_ax3_pm3.tcl
	pushd ../../src/ipbus-firmware/boards/enclustra_ax3_pm3/base_fw/synth/firmware/ucf
	patch  <  ../../../../../../../firmware_AIDA/boards/enclustra_ax3_pm3/base_fw/synth/firmware/ucf/enclustra_ax3_pm3.patch

	# In order to generate the VHDL to decode the addresses follow the instructions at https://ipbus.web.cern.ch/ipbus/doc/user/html/firmware/hwDevInstructions.html
	pushd firmware_AIDA/projects/TLU_v1e/addr_table
	/opt/cactus/bin/uhal/tools/gen_ipbus_addr_decode -v TLUaddrmap.xml
	#copy resulting file ( ipbus_decode_TLUaddrmap.vhd ) to work/build/src/firmware_AIDA/projects/TLU_v1e/firmware/hdl/
	cp ipbus_decode_TLUaddrmap.vhd ../firmware/hdl/

	ipbb vivado impl
	ipbb vivado bitfile
	ipbb vivado package
	deactivate
