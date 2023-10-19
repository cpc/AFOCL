

# Here's how to reproduce the proposed method from the AFOCL-paper for Alveo U280

# To generate the firmware for the command processor (used for both simulation and on the FPGA):
make firmware

# Alveo u280 flow:
# First make sure to source from vivado installation and the XRT installation

source VIVADO_INSTALLATION_PATH/Vivado/2022.1/settings64.sh
source /opt/xilinx/xrt/setup.sh


#To generate the bistream for Vivado's RTL simulation:
make vec_add_32x32_sim.xclbin

# To launch the simulation with vivado, source the tests/vecadd/setup_sim.sh-file
# If not running installed PoCL, also source the devel_env.sh from pocl/tools/scripts
# Then, launching the example/accel/accel_example from pocl-examples should work.

# Alternatively, you can run the ctest from this repo:
mkdir build && cd build && cmake -DPOCL_BUILD_DIR=<...> -DPOCL_INCLUDE_DIR=<...> .. && make
ctest -R hw_emu/add.i32


# To generate the bitstream:
# (Note: the generation takes a very long time (many hours)

make vec_add_32x32.xclbin

# After sourcing the setup_hw.sh, the same exact application should work on FPGA
ctest -R fpga/add.i32


# Other notes:
# The 32x32 vectors actually consist of 16 elements of 32-bit unsigned integers. Similarly the 16x64 vectors are actually
# vectors of 32 16-bit short unsigned integers. This is just an erroneous naming convention that hasn't been fixed.
