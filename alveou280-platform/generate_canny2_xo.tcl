

set accel_ip [lindex $argv 0]
puts $accel_ip
set tta_offset [lindex $argv 1]
set input_count [lindex $argv 2]
set output_count [lindex $argv 3]
set control_port [lindex $argv 4]

create_project vivado_canny2_${accel_ip}_xo vivado_canny2_${accel_ip}_xo -part xcu280-fsvh2892-2L-e
set_property board_part xilinx.com:au280:part0:1.2 [current_project]

set rtl_path "[pwd]/rtl_vecadd"
add_files [list $rtl_path/platform $rtl_path/gcu_ic $rtl_path/vhdl]

import_files -force
create_bd_design vec_${accel_ip}
update_compile_order -fileset sources_1
set_property  ip_repo_paths  vitis_${accel_ip} [current_project]
update_ip_catalog

create_bd_cell -type ip -vlnv xilinx.com:hls:${accel_ip}_ip:1.0 ${accel_ip}_ip_0

create_bd_cell -type module -reference tta_core_toplevel tta_core_toplevel_0
set_property -dict [list CONFIG.local_mem_addrw_g {12} CONFIG.axi_offset_low_g ${tta_offset}] [get_bd_cells tta_core_toplevel_0]

make_bd_pins_external  [get_bd_pins tta_core_toplevel_0/clk]
set_property name ap_clk [get_bd_ports clk_0]

make_bd_pins_external  [get_bd_pins tta_core_toplevel_0/rstx]
set_property name ap_rst_n [get_bd_ports rstx_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0
set_property -dict [list CONFIG.c_addr_width {40} CONFIG.c_include_sg {0} CONFIG.c_sg_length_width {26} CONFIG.c_sg_include_stscntrl_strm {0} CONFIG.c_m_axi_mm2s_data_width {512} CONFIG.c_m_axis_mm2s_tdata_width {512} CONFIG.c_mm2s_burst_size {16} CONFIG.c_m_axi_s2mm_data_width {512} CONFIG.c_s_axis_s2mm_tdata_width {512}] [get_bd_cells axi_dma_0]


make_bd_intf_pins_external  [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
set_property name m_axi [get_bd_intf_ports M_AXI_S2MM_0]
set_property CONFIG.READ_WRITE_MODE READ_WRITE [get_bd_intf_ports /m_axi]
delete_bd_objs [get_bd_intf_nets axi_dma_0_M_AXI_S2MM]


create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
connect_bd_intf_net [get_bd_intf_ports m_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI]
#set_property -dict [list CONFIG.NUM_SI {4} CONFIG.NUM_MI {4} CONFIG.STRATEGY {2} CONFIG.M00_HAS_REGSLICE {4} CONFIG.M01_HAS_REGSLICE {4} CONFIG.M02_HAS_REGSLICE {4} CONFIG.M03_HAS_REGSLICE {4} CONFIG.S00_HAS_REGSLICE {4} CONFIG.S01_HAS_REGSLICE {4} CONFIG.S02_HAS_REGSLICE {4} CONFIG.S03_HAS_REGSLICE {4} CONFIG.NUM_MI {4} CONFIG.S00_HAS_DATA_FIFO {2} CONFIG.S01_HAS_DATA_FIFO {2} CONFIG.S02_HAS_DATA_FIFO {2} CONFIG.S03_HAS_DATA_FIFO {2}] [get_bd_cells axi_interconnect_0]

if { $control_port == 1 } {
    set_property -dict [list CONFIG.NUM_SI {4} CONFIG.NUM_MI {4}] [get_bd_cells axi_interconnect_0]
    connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M03_AXI] [get_bd_intf_pins ${accel_ip}_ip_0/s_axi_control]
} else {
    set_property -dict [list CONFIG.NUM_SI {4} CONFIG.NUM_MI {4}] [get_bd_cells axi_interconnect_0]
}

connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_MM2S] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_S2MM] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S01_AXI]

connect_bd_intf_net [get_bd_intf_pins tta_core_toplevel_0/m_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S03_AXI]

copy_bd_objs /  [get_bd_cells {axi_dma_0}]
if { $input_count < 2 } {
    set_property -dict [list CONFIG.c_include_mm2s {0} CONFIG.c_m_axi_mm2s_data_width {32}] [get_bd_cells axi_dma_1]
    connect_bd_intf_net [get_bd_intf_pins axi_dma_1/M_AXI_S2MM] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S02_AXI]
    connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_dma_1/m_axi_s2mm_aclk]
    connect_bd_intf_net [get_bd_intf_pins ${accel_ip}_ip_0/out1] [get_bd_intf_pins axi_dma_1/S_AXIS_S2MM]
} 
if { $output_count < 2 } {
    set_property -dict [list CONFIG.c_include_s2mm {0} CONFIG.c_m_axi_s2mm_data_width {32}] [get_bd_cells axi_dma_1]
    connect_bd_intf_net [get_bd_intf_pins axi_dma_1/M_AXI_MM2S] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S02_AXI]
    connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_dma_1/m_axi_mm2s_aclk]
    connect_bd_intf_net [get_bd_intf_pins ${accel_ip}_ip_0/in1] [get_bd_intf_pins axi_dma_1/M_AXIS_MM2S]
}

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins axi_dma_0/S_AXI_LITE]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins axi_dma_1/S_AXI_LITE]

connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_dma_0/s_axi_lite_aclk]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_dma_0/m_axi_mm2s_aclk]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_dma_0/m_axi_s2mm_aclk]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_dma_1/s_axi_lite_aclk]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins ${accel_ip}_ip_0/ap_clk]

connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/S01_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/S02_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/S03_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M01_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M02_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M03_ACLK]

connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M01_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M02_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M03_ARESETN]

connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/S01_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/S02_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/S03_ARESETN]

connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins ${accel_ip}_ip_0/ap_rst_n]


connect_bd_intf_net [get_bd_intf_pins ${accel_ip}_ip_0/in0] [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S]
connect_bd_intf_net [get_bd_intf_pins ${accel_ip}_ip_0/out0] [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM]

connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_dma_0/axi_resetn]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_dma_1/axi_resetn]

make_bd_intf_pins_external  [get_bd_intf_pins tta_core_toplevel_0/s_axi]
set_property name s_axi_control [get_bd_intf_ports s_axi_0]

regenerate_bd_layout
assign_bd_address

set_property offset 0x0000000000 [get_bd_addr_segs {axi_dma_0/Data_MM2S/SEG_m_axi_Reg}]
set_property range 256M [get_bd_addr_segs {axi_dma_0/Data_MM2S/SEG_m_axi_Reg}]
set_property offset 0x0000000000 [get_bd_addr_segs {axi_dma_0/Data_S2MM/SEG_m_axi_Reg}]
set_property range 256M [get_bd_addr_segs {axi_dma_0/Data_S2MM/SEG_m_axi_Reg}]

if { $input_count < 2 } {
    set_property offset 0x0000000000 [get_bd_addr_segs {axi_dma_1/Data_S2MM/SEG_m_axi_Reg}]
    set_property range 256M [get_bd_addr_segs {axi_dma_1/Data_S2MM/SEG_m_axi_Reg}]
} 
if { $output_count < 2 } {
    set_property offset 0x0000000000 [get_bd_addr_segs {axi_dma_1/Data_MM2S/SEG_m_axi_Reg}]
    set_property range 256M [get_bd_addr_segs {axi_dma_1/Data_MM2S/SEG_m_axi_Reg}]
}

if { $control_port == 1 } {
    set_property offset 0x41E20000 [get_bd_addr_segs tta_core_toplevel_0/m_axi/SEG_${accel_ip}_ip_0_Reg]
    set_property range 4K [get_bd_addr_segs tta_core_toplevel_0/m_axi/SEG_${accel_ip}_ip_0_Reg]
}

set_property offset 0x00000000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_m_axi_Reg}]
set_property range 256M [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_m_axi_Reg}]

set_property offset 0x41E00000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_axi_dma_0_Reg}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_axi_dma_0_Reg}]
set_property offset 0x41E10000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_axi_dma_1_Reg}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_axi_dma_1_Reg}]
save_bd_design

ipx::package_project -root_dir ip_repo_canny2 -vendor user.org -library user -taxonomy /UserIP -module vec_${accel_ip} -import_files
set_property ipi_drc {ignore_freq_hz false} [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]
set_property sdx_kernel true [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]
set_property sdx_kernel_type rtl [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]
set_property vitis_drc {ctrl_protocol ap_ctrl_hs} [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]
set_property vitis_drc {ctrl_protocol user_managed} [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]
set_property ipi_drc {ignore_freq_hz true} [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]
ipx::merge_project_changes ports [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]
ipx::infer_bus_interface ap_rst_n xilinx.com:signal:reset_rtl:1.0 [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]
ipx::associate_bus_interfaces -clock CLK.AP_CLK -reset ap_rst_n [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]

ipx::add_register CTRL [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]]]
ipx::add_register dummy [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]]]
set_property address_offset 0x10 [ipx::get_registers dummy -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]]]]
set_property size 64 [ipx::get_registers dummy -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]]]]
ipx::add_register_parameter ASSOCIATED_BUSIF [ipx::get_registers dummy -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]]]]
set_property value m_axi [ipx::get_register_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_registers dummy -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]]]]]

ipx::remove_bus_parameter FREQ_HZ [ipx::get_bus_interfaces CLK.AP_CLK -of_objects [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]]

#??
ipx::update_checksums [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]
ipx::save_core [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]
set_property core_revision 2 [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]
ipx::create_xgui_files [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]
ipx::update_checksums [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]
ipx::check_integrity -kernel [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]
ipx::save_core [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]
package_xo  -xo_path vec_canny2_${accel_ip}.xo -kernel_name vec_${accel_ip} -ip_directory ip_repo_canny2 -ctrl_protocol user_managed
package_xo  -xo_path vec_canny2_${accel_ip}_sim.xo -kernel_name vec_${accel_ip}_sim -ip_directory ip_repo_canny2 -ctrl_protocol user_managed
set_property  ip_repo_paths  {ip_repo_canny2} [current_project]
update_ip_catalog
ipx::check_integrity -quiet -kernel [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]
ipx::archive_core ip_repo_canny2/user.org_user_vec_${accel_ip}_1.0.zip [ipx::find_open_core user.org:user:vec_${accel_ip}:1.0]

