

Reproducing results for AFOCL-paper (NorCAS 2023)
-------------------------------------------------

Here's how to reproduce the proposed method from the AFOCL-paper for Alveo U280.
For full reproducibility, checkout the NorCAS2023 tag.


To generate the firmware for the command processor (used for both simulation and on the FPGA):
```
make firmware
```

Alveo u280 flow:
First make sure to source from vivado installation and the XRT installation

```
source VIVADO_INSTALLATION_PATH/Vivado/2022.1/settings64.sh
source /opt/xilinx/xrt/setup.sh
```


To generate the bitstreams for Vivado's RTL simulation:
```
make sim_bitstreams
```

To launch the simulation with vivado, source the tests/vecadd/setup\_sim.sh-file
If not running installed PoCL, also source the devel\_env.sh from pocl/tools/scripts
Then, launching the example/accel/accel\_example from pocl-examples should work.

 Alternatively, you can run the ctest from this repo:
```
mkdir build && cd build && cmake -DPOCL_BUILD_DIR=<...> -DPOCL_INCLUDE_DIR=<...> .. && make
ctest
```


To generate the bitstream:
(Note: the generation takes a very long time (many hours)

```
make vec_add_32x32.xclbin
```

After sourcing the setup\_hw.sh, the same exact application should work on FPGA

Other notes:
The 32x32 vectors actually consist of 16 elements of 32-bit unsigned integers.
Similarly the 16x64 vectors are actually vectors of 32 16-bit short unsigned integers.
This is just an erroneous naming convention that hasn't been fixed.
(because it would be easier to mixup 32x16 and 16x32 designs).


Reproducing results for AFOCL Pipe paper (IWOCL 2024)
-----------------------------------------------------
This is a slightly more complex design than the above NorCAS 2023 design.
Therefore, it makes sense to first familiarize yourself with the simpler case above.

For full reproducibility, checkout the IWOCL2024 tag.

To generate the configuration #1 as described in the paper, run

```
make vec_canny1.xclbin
```

For configuration #2, run

```
make vec_canny3.xclbin
```

For configuration #3, run

```
make vec_canny4.xclbin
```

The configurations also need the firmwares for the OpenASIP cores,
for that, first set OPENASIP\_INSTALL\_DIR as described in the main README,
and POCL\_SOURCE\_DIR environment variable to point to a PoCL source directory.
This is needed to compile printing functions for debugging. Then, run:

```
make firmware
```

To run the design, you'll need to use the PoCL's AlmaIF-driver with the 0xA-option,
managing the bitstream and the firmware file manually as described in PoCL documentation.
This is because the OpenCL pipe support is not yet fully integrated to the more convenient database usage
(introduced in the NorCAS 2023 paper).

