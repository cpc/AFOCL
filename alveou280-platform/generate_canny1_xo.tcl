

set input_folder [lindex $argv 0]
puts $input_folder

create_project vivado_${input_folder}_xo vivado_${input_folder}_xo -part xcu280-fsvh2892-2L-e
set_property board_part xilinx.com:au280:part0:1.2 [current_project]


set rtl_path "[pwd]/rtl_vecadd"
set zipcpu_path "[pwd]/wb2axip"
add_files [list $rtl_path/platform $rtl_path/gcu_ic $rtl_path/vhdl $zipcpu_path/rtl]

import_files -force
create_bd_design vec_${input_folder}
update_compile_order -fileset sources_1
set_property  ip_repo_paths  {vitis_magnitude vitis_phase vitis_sobel3x3 vitis_nonmax} [current_project]
update_ip_catalog

create_bd_cell -type ip -vlnv xilinx.com:hls:sobel3x3_ip:2.0 sobel3x3_ip_0
create_bd_cell -type ip -vlnv xilinx.com:hls:nonmax_ip:2.0 nonmax_ip_0
create_bd_cell -type ip -vlnv xilinx.com:hls:phase_ip:2.0 phase_ip_0
create_bd_cell -type ip -vlnv xilinx.com:hls:magnitude_ip:2.0 magnitude_ip_0

create_bd_cell -type module -reference tta_core_toplevel tta_core_toplevel_0
set_property -dict [list CONFIG.local_mem_addrw_g {12} CONFIG.axi_offset_low_g {1073741824}] [get_bd_cells tta_core_toplevel_0]

create_bd_cell -type module -reference axis2mm zipcpu_axis2mm_0
set_property -dict [list CONFIG.C_AXI_ADDR_WIDTH {40} CONFIG.C_AXI_DATA_WIDTH {512} CONFIG.LGFIFO {5} CONFIG.LGLEN {26} CONFIG.OPT_ASYNCMEM {0} CONFIG.OPT_TREADY_WHILE_IDLE {0}] [get_bd_cells zipcpu_axis2mm_0]
copy_bd_objs /  [get_bd_cells {zipcpu_axis2mm_0}]
copy_bd_objs /  [get_bd_cells {zipcpu_axis2mm_0}]
copy_bd_objs /  [get_bd_cells {zipcpu_axis2mm_0}]
copy_bd_objs /  [get_bd_cells {zipcpu_axis2mm_0}]

create_bd_cell -type module -reference aximm2s zipcpu_aximm2s_0
set_property -dict [list CONFIG.C_AXI_ADDR_WIDTH {40} CONFIG.C_AXI_DATA_WIDTH {512} CONFIG.LGFIFO {5} CONFIG.LGLEN {26}] [get_bd_cells zipcpu_aximm2s_0]
copy_bd_objs /  [get_bd_cells {zipcpu_aximm2s_0}]
copy_bd_objs /  [get_bd_cells {zipcpu_aximm2s_0}]
copy_bd_objs /  [get_bd_cells {zipcpu_aximm2s_0}]
copy_bd_objs /  [get_bd_cells {zipcpu_aximm2s_0}]
copy_bd_objs /  [get_bd_cells {zipcpu_aximm2s_0}]
copy_bd_objs /  [get_bd_cells {zipcpu_aximm2s_0}]

make_bd_pins_external  [get_bd_pins tta_core_toplevel_0/clk]
set_property name ap_clk [get_bd_ports clk_0]

make_bd_pins_external  [get_bd_pins tta_core_toplevel_0/rstx]
set_property name ap_rst_n [get_bd_ports rstx_0]

for {set i 0} {$i < 13} {incr i} {
    create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_$i
    set_property -dict [list CONFIG.NUM_WRITE_OUTSTANDING {2} CONFIG.NUM_READ_OUTSTANDING {2} CONFIG.ADDR_WIDTH {40} CONFIG.DATA_WIDTH {512}] [get_bd_intf_ports m_axi_$i]
}
set_property -dict [list CONFIG.DATA_WIDTH {32}] [get_bd_intf_ports m_axi_12]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
#set_property -dict [list CONFIG.NUM_SI {4} CONFIG.NUM_MI {4} CONFIG.STRATEGY {2} CONFIG.M00_HAS_REGSLICE {4} CONFIG.M01_HAS_REGSLICE {4} CONFIG.M02_HAS_REGSLICE {4} CONFIG.M03_HAS_REGSLICE {4} CONFIG.S00_HAS_REGSLICE {4} CONFIG.S01_HAS_REGSLICE {4} CONFIG.S02_HAS_REGSLICE {4} CONFIG.S03_HAS_REGSLICE {4} CONFIG.NUM_MI {4} CONFIG.S00_HAS_DATA_FIFO {2} CONFIG.S01_HAS_DATA_FIFO {2} CONFIG.S02_HAS_DATA_FIFO {2} CONFIG.S03_HAS_DATA_FIFO {2}] [get_bd_cells axi_interconnect_0]

set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {15}] [get_bd_cells axi_interconnect_0]


connect_bd_intf_net [get_bd_intf_pins zipcpu_aximm2s_0/M_AXI] -boundary_type upper [get_bd_intf_ports m_axi_0]
connect_bd_intf_net [get_bd_intf_pins zipcpu_aximm2s_1/M_AXI] -boundary_type upper [get_bd_intf_ports m_axi_1]
connect_bd_intf_net [get_bd_intf_pins zipcpu_aximm2s_2/M_AXI] -boundary_type upper [get_bd_intf_ports m_axi_2]
connect_bd_intf_net [get_bd_intf_pins zipcpu_aximm2s_3/M_AXI] -boundary_type upper [get_bd_intf_ports m_axi_3]
connect_bd_intf_net [get_bd_intf_pins zipcpu_aximm2s_4/M_AXI] -boundary_type upper [get_bd_intf_ports m_axi_4]
connect_bd_intf_net [get_bd_intf_pins zipcpu_aximm2s_5/M_AXI] -boundary_type upper [get_bd_intf_ports m_axi_5]
connect_bd_intf_net [get_bd_intf_pins zipcpu_aximm2s_6/M_AXI] -boundary_type upper [get_bd_intf_ports m_axi_6]
connect_bd_intf_net [get_bd_intf_pins zipcpu_axis2mm_0/M_AXI] -boundary_type upper [get_bd_intf_ports m_axi_7]
connect_bd_intf_net [get_bd_intf_pins zipcpu_axis2mm_1/M_AXI] -boundary_type upper [get_bd_intf_ports m_axi_8]
connect_bd_intf_net [get_bd_intf_pins zipcpu_axis2mm_2/M_AXI] -boundary_type upper [get_bd_intf_ports m_axi_9]
connect_bd_intf_net [get_bd_intf_pins zipcpu_axis2mm_3/M_AXI] -boundary_type upper [get_bd_intf_ports m_axi_10]
connect_bd_intf_net [get_bd_intf_pins zipcpu_axis2mm_4/M_AXI] -boundary_type upper [get_bd_intf_ports m_axi_11]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] -boundary_type upper [get_bd_intf_ports m_axi_12]
connect_bd_intf_net [get_bd_intf_pins tta_core_toplevel_0/m_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI]

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins sobel3x3_ip_0/s_axi_control]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins nonmax_ip_0/s_axi_control]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M03_AXI] [get_bd_intf_pins zipcpu_aximm2s_0/S_AXIL]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M04_AXI] [get_bd_intf_pins zipcpu_aximm2s_1/S_AXIL]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M05_AXI] [get_bd_intf_pins zipcpu_aximm2s_2/S_AXIL]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M06_AXI] [get_bd_intf_pins zipcpu_aximm2s_3/S_AXIL]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M07_AXI] [get_bd_intf_pins zipcpu_aximm2s_4/S_AXIL]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M08_AXI] [get_bd_intf_pins zipcpu_aximm2s_5/S_AXIL]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M09_AXI] [get_bd_intf_pins zipcpu_aximm2s_6/S_AXIL]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M10_AXI] [get_bd_intf_pins zipcpu_axis2mm_0/S_AXIL]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M11_AXI] [get_bd_intf_pins zipcpu_axis2mm_1/S_AXIL]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M12_AXI] [get_bd_intf_pins zipcpu_axis2mm_2/S_AXIL]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M13_AXI] [get_bd_intf_pins zipcpu_axis2mm_3/S_AXIL]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M14_AXI] [get_bd_intf_pins zipcpu_axis2mm_4/S_AXIL]
#connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M10_AXI] [get_bd_intf_pins phase_ip_0/s_axi_control]
#connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M11_AXI] [get_bd_intf_pins magnitude_ip_0/s_axi_control]

connect_bd_net [get_bd_ports ap_clk] [get_bd_pins zipcpu_aximm2s_0/S_AXI_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins zipcpu_aximm2s_1/S_AXI_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins zipcpu_aximm2s_2/S_AXI_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins zipcpu_aximm2s_3/S_AXI_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins zipcpu_aximm2s_4/S_AXI_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins zipcpu_aximm2s_5/S_AXI_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins zipcpu_aximm2s_6/S_AXI_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins zipcpu_axis2mm_0/S_AXI_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins zipcpu_axis2mm_1/S_AXI_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins zipcpu_axis2mm_2/S_AXI_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins zipcpu_axis2mm_3/S_AXI_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins zipcpu_axis2mm_4/S_AXI_ACLK]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins zipcpu_aximm2s_0/S_AXI_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins zipcpu_aximm2s_1/S_AXI_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins zipcpu_aximm2s_2/S_AXI_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins zipcpu_aximm2s_3/S_AXI_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins zipcpu_aximm2s_4/S_AXI_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins zipcpu_aximm2s_5/S_AXI_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins zipcpu_aximm2s_6/S_AXI_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins zipcpu_axis2mm_0/S_AXI_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins zipcpu_axis2mm_1/S_AXI_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins zipcpu_axis2mm_2/S_AXI_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins zipcpu_axis2mm_3/S_AXI_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins zipcpu_axis2mm_4/S_AXI_ARESETN]

connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins sobel3x3_ip_0/ap_clk]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins nonmax_ip_0/ap_clk]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins phase_ip_0/ap_clk]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins magnitude_ip_0/ap_clk]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M01_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M02_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M03_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M04_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M05_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M06_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M07_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M08_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M09_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M10_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M11_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M12_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M13_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_0/M14_ACLK]

connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M01_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M02_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M03_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M04_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M05_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M06_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M07_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M08_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M09_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M10_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M11_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M12_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M13_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/M14_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_0/S00_ARESETN]

connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins sobel3x3_ip_0/ap_rst_n]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins nonmax_ip_0/ap_rst_n]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins phase_ip_0/ap_rst_n]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins magnitude_ip_0/ap_rst_n]

connect_bd_intf_net [get_bd_intf_pins sobel3x3_ip_0/in0] [get_bd_intf_pins zipcpu_aximm2s_0/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins sobel3x3_ip_0/out0] [get_bd_intf_pins zipcpu_axis2mm_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins sobel3x3_ip_0/out1] [get_bd_intf_pins zipcpu_axis2mm_1/S_AXIS]

connect_bd_intf_net [get_bd_intf_pins phase_ip_0/in0] [get_bd_intf_pins zipcpu_aximm2s_1/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins phase_ip_0/in1] [get_bd_intf_pins zipcpu_aximm2s_2/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins phase_ip_0/out0] [get_bd_intf_pins zipcpu_axis2mm_2/S_AXIS]

connect_bd_intf_net [get_bd_intf_pins magnitude_ip_0/in0] [get_bd_intf_pins zipcpu_aximm2s_3/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins magnitude_ip_0/in1] [get_bd_intf_pins zipcpu_aximm2s_4/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins magnitude_ip_0/out0] [get_bd_intf_pins zipcpu_axis2mm_3/S_AXIS]

connect_bd_intf_net [get_bd_intf_pins nonmax_ip_0/in0] [get_bd_intf_pins zipcpu_aximm2s_5/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins nonmax_ip_0/in1] [get_bd_intf_pins zipcpu_aximm2s_6/M_AXIS]
connect_bd_intf_net [get_bd_intf_pins nonmax_ip_0/out0] [get_bd_intf_pins zipcpu_axis2mm_4/S_AXIS]


make_bd_intf_pins_external  [get_bd_intf_pins tta_core_toplevel_0/s_axi]
set_property name s_axi_control [get_bd_intf_ports s_axi_0]

regenerate_bd_layout
assign_bd_address

set_property offset 0x81EC0000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_sobel3x3_ip_0_Reg}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_sobel3x3_ip_0_Reg}]
#set_property offset 0x81E80000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_phase_ip_0_Reg}]
#set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_phase_ip_0_Reg}]
#set_property offset 0x81E90000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_magnitude_ip_0_Reg}]
#set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_magnitude_ip_0_Reg}]
set_property offset 0x81ED0000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_nonmax_ip_0_Reg}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_nonmax_ip_0_Reg}]


set_property offset 0x81E00000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_0_reg0}]
set_property offset 0x81E10000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_1_reg0}]
set_property offset 0x81E20000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_2_reg0}]
set_property offset 0x81E30000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_3_reg0}]
set_property offset 0x81E40000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_4_reg0}]
set_property offset 0x81E50000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_5_reg0}]
set_property offset 0x81E60000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_6_reg0}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_0_reg0}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_1_reg0}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_2_reg0}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_3_reg0}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_4_reg0}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_5_reg0}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_6_reg0}]
set_property offset 0x81E70000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_axis2mm_0_reg0}]
set_property offset 0x81E80000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_axis2mm_1_reg0}]
set_property offset 0x81E90000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_axis2mm_2_reg0}]
set_property offset 0x81EA0000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_axis2mm_3_reg0}]
set_property offset 0x81EB0000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_axis2mm_4_reg0}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_axis2mm_0_reg0}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_axis2mm_1_reg0}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_axis2mm_2_reg0}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_axis2mm_3_reg0}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_axis2mm_4_reg0}]
set_property offset 0x00000000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_m_axi_12_Reg}]
set_property range 2G [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_m_axi_12_Reg}]

set_property offset 0x0000000000 [get_bd_addr_segs {zipcpu_aximm2s_0/M_AXI/SEG_m_axi_0_Reg}]
set_property range 2G [get_bd_addr_segs {zipcpu_aximm2s_0/M_AXI/SEG_m_axi_0_Reg}]
set_property offset 0x0000000000 [get_bd_addr_segs {zipcpu_aximm2s_1/M_AXI/SEG_m_axi_1_Reg}]
set_property range 2G [get_bd_addr_segs {zipcpu_aximm2s_1/M_AXI/SEG_m_axi_1_Reg}]
set_property offset 0x0000000000 [get_bd_addr_segs {zipcpu_aximm2s_2/M_AXI/SEG_m_axi_2_Reg}]
set_property range 2G [get_bd_addr_segs {zipcpu_aximm2s_2/M_AXI/SEG_m_axi_2_Reg}]
set_property offset 0x0000000000 [get_bd_addr_segs {zipcpu_aximm2s_3/M_AXI/SEG_m_axi_3_Reg}]
set_property range 2G [get_bd_addr_segs {zipcpu_aximm2s_3/M_AXI/SEG_m_axi_3_Reg}]
set_property offset 0x0000000000 [get_bd_addr_segs {zipcpu_aximm2s_4/M_AXI/SEG_m_axi_4_Reg}]
set_property range 2G [get_bd_addr_segs {zipcpu_aximm2s_4/M_AXI/SEG_m_axi_4_Reg}]
set_property offset 0x0000000000 [get_bd_addr_segs {zipcpu_aximm2s_5/M_AXI/SEG_m_axi_5_Reg}]
set_property range 2G [get_bd_addr_segs {zipcpu_aximm2s_5/M_AXI/SEG_m_axi_5_Reg}]
set_property offset 0x0000000000 [get_bd_addr_segs {zipcpu_aximm2s_6/M_AXI/SEG_m_axi_6_Reg}]
set_property range 2G [get_bd_addr_segs {zipcpu_aximm2s_6/M_AXI/SEG_m_axi_6_Reg}]

set_property offset 0x0000000000 [get_bd_addr_segs {zipcpu_axis2mm_0/M_AXI/SEG_m_axi_7_Reg}]
set_property range 2G [get_bd_addr_segs {zipcpu_axis2mm_0/M_AXI/SEG_m_axi_7_Reg}]
set_property offset 0x0000000000 [get_bd_addr_segs {zipcpu_axis2mm_1/M_AXI/SEG_m_axi_8_Reg}]
set_property range 2G [get_bd_addr_segs {zipcpu_axis2mm_1/M_AXI/SEG_m_axi_8_Reg}]
set_property offset 0x0000000000 [get_bd_addr_segs {zipcpu_axis2mm_2/M_AXI/SEG_m_axi_9_Reg}]
set_property range 2G [get_bd_addr_segs {zipcpu_axis2mm_2/M_AXI/SEG_m_axi_9_Reg}]
set_property offset 0x0000000000 [get_bd_addr_segs {zipcpu_axis2mm_3/M_AXI/SEG_m_axi_10_Reg}]
set_property range 2G [get_bd_addr_segs {zipcpu_axis2mm_3/M_AXI/SEG_m_axi_10_Reg}]
set_property offset 0x0000000000 [get_bd_addr_segs {zipcpu_axis2mm_4/M_AXI/SEG_m_axi_11_Reg}]
set_property range 2G [get_bd_addr_segs {zipcpu_axis2mm_4/M_AXI/SEG_m_axi_11_Reg}]

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
for {set i 0} {$i < 13} {incr i} {
    ipx::associate_bus_interfaces -busif m_axi_$i -clock CLK.AP_CLK [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
    set dummy_offset [expr $i * 0x8 + 0x10]
    ipx::add_register dummy_$i [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]
    set_property address_offset $dummy_offset [ipx::get_registers dummy_$i -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]
    set_property size 64 [ipx::get_registers dummy_$i -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]
    ipx::add_register_parameter ASSOCIATED_BUSIF [ipx::get_registers dummy_$i -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]
    set_property value m_axi_$i [ipx::get_register_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_registers dummy_$i -of_objects [ipx::get_address_blocks Reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]]]]]
}

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
set_property  ip_repo_paths  {ip_repo_${input_folder}} [current_project]
update_ip_catalog
ipx::check_integrity -quiet -kernel [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::archive_core ip_repo_${input_folder}/user.org_user_vec_${input_folder}_1.0.zip [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
