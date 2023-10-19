# generate_vec_512_xo.tcl - Vivado script
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

set input_folder [lindex $argv 0]
puts $input_folder

create_project vivado_${input_folder}_xo vivado_${input_folder}_xo -part xcu280-fsvh2892-2L-e
set_property board_part xilinx.com:au280:part0:1.2 [current_project]


set rtl_path "[pwd]/rtl_vecadd"
add_files [list $rtl_path/platform $rtl_path/gcu_ic $rtl_path/vhdl]

import_files -force
create_bd_design vec_${input_folder}
update_compile_order -fileset sources_1
set_property  ip_repo_paths  vitis_${input_folder} [current_project]
update_ip_catalog

create_bd_cell -type ip -vlnv xilinx.com:hls:${input_folder}_ip:2.0 ${input_folder}_ip_0
create_bd_cell -type module -reference tta_core_toplevel tta_core_toplevel_0
set_property -dict [list CONFIG.local_mem_addrw_g {12} CONFIG.axi_addr_width_g {16} CONFIG.axi_offset_low_g {1073741824}] [get_bd_cells tta_core_toplevel_0]


create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0
set_property -dict [list CONFIG.c_addr_width {40} CONFIG.c_include_sg {0} CONFIG.c_sg_length_width {26} CONFIG.c_sg_include_stscntrl_strm {0} CONFIG.c_m_axi_mm2s_data_width {512} CONFIG.c_m_axis_mm2s_tdata_width {512} CONFIG.c_mm2s_burst_size {16} CONFIG.c_m_axi_s2mm_data_width {512} CONFIG.c_s_axis_s2mm_tdata_width {512}] [get_bd_cells axi_dma_0]


copy_bd_objs /  [get_bd_cells {axi_dma_0}]
set_property -dict [list CONFIG.c_include_s2mm {0}] [get_bd_cells axi_dma_1]

connect_bd_intf_net [get_bd_intf_pins axi_dma_1/M_AXIS_MM2S] [get_bd_intf_pins ${input_folder}_ip_0/B]
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S] [get_bd_intf_pins ${input_folder}_ip_0/A]
connect_bd_intf_net [get_bd_intf_pins ${input_folder}_ip_0/C] [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM]

make_bd_pins_external  [get_bd_pins tta_core_toplevel_0/clk]
set_property name ap_clk [get_bd_ports clk_0]
make_bd_pins_external  [get_bd_pins tta_core_toplevel_0/rstx]
set_property name ap_rst_n [get_bd_ports rstx_0]

connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_dma_0/axi_resetn]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_dma_1/axi_resetn]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins ${input_folder}_ip_0/ap_rst_n]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_dma_0/m_axi_mm2s_aclk]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_dma_0/s_axi_lite_aclk]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_dma_0/m_axi_s2mm_aclk]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_dma_1/s_axi_lite_aclk]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_dma_1/m_axi_mm2s_aclk]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins ${input_folder}_ip_0/ap_clk]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ap_clk (100 MHz)} Clk_slave {/ap_clk (100 MHz)} Clk_xbar {/ap_clk (100 MHz)} Master {/tta_core_toplevel_0/m_axi} Slave {/axi_dma_0/S_AXI_LITE} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_dma_0/S_AXI_LITE]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ap_clk (100 MHz)} Clk_slave {/ap_clk (100 MHz)} Clk_xbar {/ap_clk (100 MHz)} Master {/tta_core_toplevel_0/m_axi} Slave {/axi_dma_1/S_AXI_LITE} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_dma_1/S_AXI_LITE]

set_property -dict [list CONFIG.NUM_MI {3}] [get_bd_cells tta_core_toplevel_0_axi_periph]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0

set_property -dict [list CONFIG.NUM_SI {4} CONFIG.NUM_MI {1} CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_0]

connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_MM2S] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_S2MM] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_dma_1/M_AXI_MM2S] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S02_AXI]

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins tta_core_toplevel_0_axi_periph/M02_AXI] [get_bd_intf_pins axi_interconnect_0/S03_AXI]

make_bd_intf_pins_external  [get_bd_intf_pins axi_interconnect_0/M00_AXI]
set_property name m_axi [get_bd_intf_ports M00_AXI_0]

connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/S01_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/S02_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/S03_ACLK]
connect_bd_net [get_bd_pins axi_interconnect_0/S03_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/S03_ARESETN] -boundary_type upper
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/S01_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/S02_ARESETN]
delete_bd_objs [get_bd_cells rst_ap_clk_100M]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins tta_core_toplevel_0_axi_periph/M02_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins tta_core_toplevel_0_axi_periph/M01_ARESETN]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins tta_core_toplevel_0_axi_periph/M02_ACLK]

make_bd_intf_pins_external  [get_bd_intf_pins tta_core_toplevel_0/s_axi]
set_property name s_axi_control [get_bd_intf_ports s_axi_0]


#ALTERNATIVELY REDO THE RESET ONLY BY ADDING THE PROCESSOR SYSTEM RESET IP
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0

disconnect_bd_net /rstx_0_1 [get_bd_ports ap_rst_n]

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins tta_core_toplevel_0/rstx]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
#PROCESSOR SYSTEM RESET REDO DONE

#SIMPLIFY INTERCONNECT TO JUST ONE
delete_bd_objs [get_bd_intf_nets tta_core_toplevel_0_m_axi] [get_bd_intf_nets tta_core_toplevel_0_axi_periph_M00_AXI] [get_bd_intf_nets tta_core_toplevel_0_axi_periph_M01_AXI] [get_bd_intf_nets tta_core_toplevel_0_axi_periph_M02_AXI] [get_bd_cells tta_core_toplevel_0_axi_periph]

set_property -dict [list CONFIG.NUM_MI {3}] [get_bd_cells axi_interconnect_0]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S03_AXI] [get_bd_intf_pins tta_core_toplevel_0/m_axi]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins axi_dma_0/S_AXI_LITE]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins axi_dma_1/S_AXI_LITE]

connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M01_ACLK]
connect_bd_net [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M02_ACLK]
connect_bd_net [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
#DONE SIMPLIFICATION

#Change 32-bit m_axi to 512-bit
delete_bd_objs [get_bd_intf_nets axi_dma_0_M_AXI_MM2S]
make_bd_intf_pins_external  [get_bd_intf_pins axi_dma_0/M_AXI_MM2S]

delete_bd_objs [get_bd_intf_nets axi_interconnect_0_M00_AXI] [get_bd_intf_ports m_axi]
delete_bd_objs [get_bd_intf_nets axi_dma_0_M_AXI_MM2S]
connect_bd_intf_net [get_bd_intf_ports M_AXI_MM2S_0] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_MM2S] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI]
set_property -dict [list CONFIG.NUM_WRITE_OUTSTANDING {16} CONFIG.READ_WRITE_MODE {READ_WRITE}] [get_bd_intf_ports M_AXI_MM2S_0]
set_property name m_axi [get_bd_intf_ports M_AXI_MM2S_0]
#done 32-bit to 512-bit

assign_bd_address

set_property offset 0x0000000000000000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_m_axi_Reg}]
set_property offset 0x41E10000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_axi_dma_1_Reg}]
set_property offset 0x41E00000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_axi_dma_0_Reg}]

set_property range 256M [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_m_axi_Reg}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_axi_dma_0_Reg}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_axi_dma_1_Reg}]

set_property offset 0x0000000000 [get_bd_addr_segs {axi_dma_1/Data_MM2S/SEG_m_axi_Reg}]
set_property offset 0x0000000000 [get_bd_addr_segs {axi_dma_0/Data_S2MM/SEG_m_axi_Reg}]
set_property offset 0x0000000000 [get_bd_addr_segs {axi_dma_0/Data_MM2S/SEG_m_axi_Reg}]

set_property range 256M [get_bd_addr_segs {axi_dma_0/Data_MM2S/SEG_m_axi_Reg}]
set_property range 256M [get_bd_addr_segs {axi_dma_1/Data_MM2S/SEG_m_axi_Reg}]
set_property range 256M [get_bd_addr_segs {axi_dma_0/Data_S2MM/SEG_m_axi_Reg}]

regenerate_bd_layout
save_bd_design

ipx::package_project -root_dir ip_repo_${input_folder} -vendor user.org -library user -taxonomy /UserIP -module vec_${input_folder} -import_files
set_property ipi_drc {ignore_freq_hz false} [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
set_property sdx_kernel true [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
set_property sdx_kernel_type rtl [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
set_property vitis_drc {ctrl_protocol ap_ctrl_hs} [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
set_property vitis_drc {ctrl_protocol user_managed} [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
set_property ipi_drc {ignore_freq_hz true} [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::merge_project_changes ports [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::infer_bus_interface ap_rst_n xilinx.com:signal:reset_rtl:1.0 [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::associate_bus_interfaces -clock CLK.AP_CLK -reset ap_rst_n [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]

ipx::add_register CTRL [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]
ipx::add_register dummy [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]
set_property address_offset 0x10 [ipx::get_registers dummy -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]
set_property size 64 [ipx::get_registers dummy -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]
ipx::add_register_parameter ASSOCIATED_BUSIF [ipx::get_registers dummy -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]
set_property value m_axi [ipx::get_register_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_registers dummy -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]]


ipx::remove_bus_parameter FREQ_HZ [ipx::get_bus_interfaces CLK.AP_CLK -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]


#??
ipx::update_checksums [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::save_core [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
set_property core_revision 2 [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::create_xgui_files [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::update_checksums [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::check_integrity -kernel [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::save_core [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
package_xo  -xo_path vec_${input_folder}.xo -kernel_name vec_${input_folder} -ip_directory ip_repo_${input_folder} -ctrl_protocol user_managed
package_xo  -xo_path vec_${input_folder}_sim.xo -kernel_name vec_${input_folder}_sim -ip_directory ip_repo_${input_folder} -ctrl_protocol user_managed
set_property  ip_repo_paths  {ip_repo_${input_folder} vitis_vec_add} [current_project]
#set_property  ip_repo_paths  {ip_repo_${input_folder} vitis_${input_folder}} [current_project]
update_ip_catalog
ipx::check_integrity -quiet -kernel [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::archive_core ip_repo_${input_folder}/user.org_user_vec_${input_folder}_1.0.zip [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
