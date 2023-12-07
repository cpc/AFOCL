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

#create_project vivado_${input_folder}_xo vivado_${input_folder}_xo -part xcu200-fsgd2104-2-e
create_project vivado_${input_folder}_xo vivado_${input_folder}_xo -part xcvu9p-flgb2104-2-i
set rtl_path "[pwd]/rtl_vecadd"
######## TODO: remove hardcoded path
add_files [list $rtl_path/platform $rtl_path/gcu_ic $rtl_path/vhdl /home/leevi/wb2axip/rtl] 

import_files -force
create_bd_design vec_${input_folder}
update_compile_order -fileset sources_1
set_property  ip_repo_paths  {ip_repo_add_32x32 vitis_add_32x32} [current_project]
update_ip_catalog

######## Add the tta-core
create_bd_cell -type module -reference tta_core_toplevel tta_core_toplevel_0
set_property -dict [list CONFIG.local_mem_addrw_g {12} CONFIG.axi_addr_width_g {16} CONFIG.axi_offset_low_g {1073741824}] [get_bd_cells tta_core_toplevel_0]

####### Make tta-core s-axi external and connect rst and clk signals
make_bd_intf_pins_external  [get_bd_intf_pins tta_core_toplevel_0/s_axi]
set_property name s_axi_control [get_bd_intf_ports s_axi_0]
make_bd_pins_external  [get_bd_pins tta_core_toplevel_0/clk]
set_property name ap_clk [get_bd_ports clk_0]
make_bd_pins_external  [get_bd_pins tta_core_toplevel_0/rstx]
set_property name ap_rst_n [get_bd_ports rstx_0]

######## Add the streaming functional unit
create_bd_cell -type ip -vlnv xilinx.com:hls:${input_folder}_ip:2.0 ${input_folder}_ip_0
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins add_32x32_ip_0/ap_rst_n]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins add_32x32_ip_0/ap_clk]

####### Create DMA units
create_bd_cell -type module -reference axis2mm zipcpu_axis2mm_0
set_property -dict [list CONFIG.C_AXI_ADDR_WIDTH {40} CONFIG.C_AXI_DATA_WIDTH {512} CONFIG.LGFIFO {5} CONFIG.LGLEN {26} CONFIG.OPT_ASYNCMEM {0} CONFIG.OPT_TREADY_WHILE_IDLE {0}] [get_bd_cells zipcpu_axis2mm_0]

create_bd_cell -type module -reference aximm2s zipcpu_aximm2s_0
set_property -dict [list CONFIG.C_AXI_ADDR_WIDTH {40} CONFIG.C_AXI_DATA_WIDTH {512} CONFIG.LGFIFO {5} CONFIG.LGLEN {26}] [get_bd_cells zipcpu_aximm2s_0]

create_bd_cell -type module -reference aximm2s zipcpu_aximm2s_1
set_property -dict [list CONFIG.C_AXI_ADDR_WIDTH {40} CONFIG.C_AXI_DATA_WIDTH {512} CONFIG.LGFIFO {5} CONFIG.LGLEN {26}] [get_bd_cells zipcpu_aximm2s_1]

connect_bd_net [get_bd_ports ap_clk] [get_bd_pins zipcpu_aximm2s_0/S_AXI_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins zipcpu_aximm2s_1/S_AXI_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins zipcpu_axis2mm_0/S_AXI_ACLK]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins zipcpu_aximm2s_0/S_AXI_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins zipcpu_aximm2s_1/S_AXI_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins zipcpu_axis2mm_0/S_AXI_ARESETN]

####### Connect DMAs to functional unit
connect_bd_intf_net [get_bd_intf_pins zipcpu_axis2mm_0/S_AXIS] [get_bd_intf_pins ${input_folder}_ip_0/C]
connect_bd_intf_net [get_bd_intf_pins zipcpu_aximm2s_0/M_AXIS] [get_bd_intf_pins ${input_folder}_ip_0/A]
connect_bd_intf_net [get_bd_intf_pins zipcpu_aximm2s_1/M_AXIS] [get_bd_intf_pins ${input_folder}_ip_0/B]

####### Create axi interconnect for connecting the tta-core to the DMAs
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {3}] [get_bd_cells axi_interconnect_0]
connect_bd_intf_net [get_bd_intf_pins tta_core_toplevel_0/m_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins zipcpu_aximm2s_0/S_AXIL]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins zipcpu_aximm2s_1/S_AXIL]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins zipcpu_axis2mm_0/S_AXIL]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M01_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M02_ARESETN]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M01_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M02_ACLK]

####### Create external axi masters
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi
set_property -dict [list CONFIG.DATA_WIDTH {512}] [get_bd_intf_ports m_axi]
set_property -dict [list CONFIG.NUM_WRITE_OUTSTANDING {16} CONFIG.NUM_READ_OUTSTANDING {16} CONFIG.ADDR_WIDTH {40}] [get_bd_intf_ports m_axi]
set_property -dict [list CONFIG.HAS_BURST {0} CONFIG.HAS_LOCK {0} CONFIG.HAS_QOS {0} CONFIG.HAS_REGION {0} CONFIG.HAS_WSTRB {0}] [get_bd_intf_ports m_axi]
set_property -dict [list CONFIG.HAS_BRESP {0}] [get_bd_intf_ports m_axi]
copy_bd_objs /  [get_bd_intf_ports {m_axi}]
copy_bd_objs /  [get_bd_intf_ports {m_axi}]

####### Connect axi masters to DMA units
connect_bd_intf_net [get_bd_intf_ports m_axi] [get_bd_intf_pins zipcpu_aximm2s_0/M_AXI]
connect_bd_intf_net [get_bd_intf_ports m_axi1] [get_bd_intf_pins zipcpu_aximm2s_1/M_AXI]
connect_bd_intf_net [get_bd_intf_ports m_axi2] [get_bd_intf_pins zipcpu_axis2mm_0/M_AXI]

####### Set address ranges for internal DMA control signals
assign_bd_address
set_property offset 0x41E00000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_0_reg0}]
set_property offset 0x41E10000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_1_reg0}]
set_property offset 0x41E20000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_axis2mm_0_reg0}]

####### Set address ranges for external axi masters
set_property offset 0x0800000000 [get_bd_addr_segs {zipcpu_aximm2s_0/M_AXI/SEG_m_axi_Reg}]
set_property range 256M [get_bd_addr_segs {zipcpu_aximm2s_0/M_AXI/SEG_m_axi_Reg}]
set_property offset 0x0800000000 [get_bd_addr_segs {zipcpu_aximm2s_1/M_AXI/SEG_m_axi1_Reg}]
set_property range 256M [get_bd_addr_segs {zipcpu_aximm2s_1/M_AXI/SEG_m_axi1_Reg}]
set_property offset 0x0800000000 [get_bd_addr_segs {zipcpu_axis2mm_0/M_AXI/SEG_m_axi2_Reg}]
set_property range 256M [get_bd_addr_segs {zipcpu_axis2mm_0/M_AXI/SEG_m_axi2_Reg}]

####### Set associated clock for the external interfaces
set_property CONFIG.ASSOCIATED_BUSIF {s_axi_control:m_axi:m_axi1:m_axi2} [get_bd_ports /ap_clk]

####### Package project
#apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/ap_clk (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins add_32x32_ip_0/ap_clk]
regenerate_bd_layout
save_bd_design
ipx::package_project -root_dir ip_repo_${input_folder} -vendor user.org -library user -taxonomy /UserIP -module vec_${input_folder} -import_files

####### Set secret registers according to the vitis doc
ipx::add_register CTRL [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]

ipx::add_register dummy [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]
set_property address_offset 0x10 [ipx::get_registers dummy -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]
set_property size 64 [ipx::get_registers dummy -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]
ipx::add_register_parameter ASSOCIATED_BUSIF [ipx::get_registers dummy -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]
set_property value m_axi [ipx::get_register_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_registers dummy -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]]

ipx::add_register dummy1 [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]    
set_property address_offset 0x18 [ipx::get_registers dummy1 -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]    
set_property size 64 [ipx::get_registers dummy1 -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]    
ipx::add_register_parameter ASSOCIATED_BUSIF [ipx::get_registers dummy1 -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]
set_property value m_axi1 [ipx::get_register_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_registers dummy1 -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_add_32x32:1.0]]]]]

ipx::add_register dummy2 [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]    
set_property address_offset 0x20 [ipx::get_registers dummy2 -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]    
set_property size 64 [ipx::get_registers dummy2 -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]    
ipx::add_register_parameter ASSOCIATED_BUSIF [ipx::get_registers dummy2 -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]
set_property value m_axi2 [ipx::get_register_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_registers dummy2 -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_add_32x32:1.0]]]]]

####### The vitis doc recommends this
ipx::remove_bus_parameter FREQ_HZ [ipx::get_bus_interfaces CLK.AP_CLK -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]

####### Set some parameters
set_property ipi_drc {ignore_freq_hz true} [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
set_property sdx_kernel true [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
set_property sdx_kernel_type rtl [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
set_property vitis_drc {ctrl_protocol ap_ctrl_hs} [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
set_property vitis_drc {ctrl_protocol user_managed} [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
set_property ipi_drc {ignore_freq_hz true} [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]

####### ?
ipx::infer_bus_interface ap_rst_n xilinx.com:signal:reset_rtl:1.0 [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::associate_bus_interfaces -clock CLK.AP_CLK -reset ap_rst_n [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]

#######??
ipx::update_checksums [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::save_core [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
set_property core_revision 2 [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::create_xgui_files [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::update_checksums [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::check_integrity -kernel [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::save_core [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
package_xo  -xo_path vec_${input_folder}.xo -kernel_name vec_${input_folder} -ip_directory ip_repo_${input_folder} -ctrl_protocol user_managed
package_xo  -xo_path vec_${input_folder}_sim.xo -kernel_name vec_${input_folder}_sim -ip_directory ip_repo_${input_folder} -ctrl_protocol user_managed

ipx::check_integrity -quiet -kernel [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::archive_core ip_repo_${input_folder}/user.org_user_vec_${input_folder}_1.0.zip [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
