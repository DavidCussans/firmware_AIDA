#!/bin/sh
mkdir work
cd work
git clone git@github.com:ipbus/ipbb.git 
# ( ... or curl -L https://github.com/ipbus/ipbb/archive/v0.2.5.tar.gz | tar xvz )
source ipbb/env.sh
ipbb init build
cd build
ipbb add git https://github.com/ipbus/ipbus-firmware.git -b enhancement/28
ipbb add git git@github.com:DavidCussans/firmware_AIDA.git


# In order to generate the VHDL to decode the addresses follow the instructions at https://ipbus.web.cern.ch/ipbus/doc/user/html/firmware/hwDevInstructions.html
echo "Generating address table VHDL from XML file"
pushd src/firmware_AIDA/projects/TLU_v1e/addr_table
pwd
/opt/cactus/bin/uhal/tools/gen_ipbus_addr_decode -v TLUaddrmap.xml
#copy resulting file ( ipbus_decode_TLUaddrmap.vhd ) to work/build/src/firmware_AIDA/projects/TLU_v1e/firmware/hdl/
cp ipbus_decode_TLUaddrmap.vhd ../firmware/hdl/
popd

# Edit the files in the IPBus repostitory to expose the 200MHz clock
echo "BUILD: Editing enclustra_ax3_pm3_infra.vhd to add 200MHz clock port"
sed -i 's/onehz);/onehz); clk_200_o<=clk200;/' src/ipbus-firmware/boards/enclustra_ax3_pm3/base_fw/synth/firmware/hdl/enclustra_ax3_pm3_infra.vhd

echo "BUILD: Editing enclustra_ax3_pm3_infra.vhd to add signals"
sed -i 's/clk125_o: out std_logic/clk125_o, clk_200_o: out std_logic/' src/ipbus-firmware/boards/enclustra_ax3_pm3/base_fw/synth/firmware/hdl/enclustra_ax3_pm3_infra.vhd

# Comment out the cfg signals in the IPBus constraints file enclustra_ax3_pm3.tcl
echo "BUILD: patching /enclustra_ax3_pm3.patch"
pushd src/ipbus-firmware/boards/enclustra_ax3_pm3/base_fw/synth/firmware/ucf
patch  <  ../../../../../../../firmware_AIDA/boards/enclustra_ax3_pm3/base_fw/synth/firmware/ucf/enclustra_ax3_pm3.patch
popd

echo "BUILD: ipbb proj create"
ipbb proj create vivado TLU_1e firmware_AIDA:projects/TLU_v1e -t top_tlu_1e_a35.dep
cd proj/TLU_1e

ipbb vivado project
# Set correct file as design "top"
#echo "BUILD: Setting the correct design as top"
#vivado -mode tcl -nojournal -nolog -notrace -source ../../src/firmware_AIDA/projects/TLU_v1e/firmware/cfg/set_top.tcl top/top.xpr


echo "BUILD: ipbb impl"
ipbb vivado impl
echo "BUILD: ipbb bitfile"
ipbb vivado bitfile
echo "BUILD: ipbb package"
ipbb vivado package
deactivate
