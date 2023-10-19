# generate_vitis_vec.tcl - Vitis HLS script
#
#   Copyright (c) 2023 Topi Leppänen / Tampere University
#
#   Permission is hereby granted, free of charge, to any person obtaining a copy
#   of this software and associated documentation files (the "Software"), to
#   deal in the Software without restriction, including without limitation the
#   rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
#   sell copies of the Software, and to permit persons to whom the Software is
#   furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in
#   all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
#   IN THE SOFTWARE.



set input_folder [lindex $argv 2]
set device_count [lindex $argv 3]

open_project vitis_${input_folder}
set_top ${input_folder}_ip
add_files kernels/${input_folder}/src/${input_folder}_ip.cpp
open_solution "solution1" -flow_target vitis
set_part {xcu280-fsvh2892-2L-e}
create_clock -period 4 -name default
config_export -format ip_catalog -output vec_hls_${input_folder} -rtl verilog
config_export -ipname ${input_folder}_ip -version 2.0.1

set_directive_top -name ${input_folder}_ip "${input_folder}_ip"
#csim_design
csynth_design
#cosim_design

export_design -rtl verilog -format ip_catalog -output vec_hls_${input_folder} -version 2.0.1

exit
