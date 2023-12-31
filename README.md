Scripts to generate the bistream database AFOCL.
Meant to be used with PoCL's AlmaIF driver.

Tested with Vivado tool versions 2022.1 and Alveo U280

Build Instructions
------------------
To build the database for both Alveo U280.

First you should initialize the FPGA tools so that they are
found from the path:
```
source {XILINX INSTALL DIR}/Vivado/2022.1/settings.sh
```

If OpenASIP is not installed in ${HOME}/local, you need
to set it with variable OPENASIP\_INSTALL\_DIR. This is
needed to override the LD\_LIBRARY\_PATH and PATH set by
sourcing the toolset script.
This is done when calling OpenASIP's oacc to compile the firmware.

Then you can run:

```
make
```

Usage
-----
The make command generates the 'db' folder, which contains the bitstreams.
PoCL's AlmaIF driver needs to be pointed to this folder with the
environment variable.
```
export POCL_DEVICES=almaif
export POCL_ALMAIF0_PARAMETERS=0xF,<path/db>
```
The magic number 0xF enables the DBDevice backend
of the AlmaIF driver.

Now you can execute the example application from {PoCL}/examples/accel/accel\_example.
Since there are two different built-in kernel implementations in the database, you
can choose the built-in kernel you want like this:

```
{PoCL}/examples/accel/accel_example pocl.add.i32
{PoCL}/examples/accel/accel_example pocl.add.i16

```
The PoCL will reconfigure the FPGA in between these different kernels.
