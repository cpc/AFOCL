

set input_folder [lindex $argv 0]
puts $input_folder

create_project vivado_${input_folder}_xo vivado_${input_folder}_xo -part xcu280-fsvh2892-2L-e
set_property board_part xilinx.com:au280:part0:1.2 [current_project]


set rtl_path "[pwd]/rtl_vecadd"
add_files [list $rtl_path/platform $rtl_path/gcu_ic $rtl_path/vhdl axi_constant_vhdl /home/topi/wb2axip/rtl]

import_files -force
create_bd_design vec_${input_folder}
update_compile_order -fileset sources_1
set_property  ip_repo_paths  {vitis_magnitude_ctrl vitis_phase_ctrl vitis_sobel3x3_ctrl vitis_nonmax_ctrl} [current_project]
update_ip_catalog

create_bd_cell -type ip -vlnv xilinx.com:hls:sobel3x3_ctrl_ip:2.0 sobel3x3_ip_0
create_bd_cell -type ip -vlnv xilinx.com:hls:nonmax_ctrl_ip:2.0 nonmax_ip_0
create_bd_cell -type ip -vlnv xilinx.com:hls:phase_ctrl_ip:2.0 phase_ip_0
create_bd_cell -type ip -vlnv xilinx.com:hls:magnitude_ctrl_ip:2.0 magnitude_ip_0

create_bd_cell -type module -reference axis2mm zipcpu_axis2mm_0
set_property -dict [list CONFIG.C_AXI_ADDR_WIDTH {40} CONFIG.C_AXI_DATA_WIDTH {512} CONFIG.LGFIFO {5} CONFIG.LGLEN {26} CONFIG.OPT_ASYNCMEM {0} CONFIG.OPT_TREADY_WHILE_IDLE {0}] [get_bd_cells zipcpu_axis2mm_0]

create_bd_cell -type module -reference aximm2s zipcpu_aximm2s_0
set_property -dict [list CONFIG.C_AXI_ADDR_WIDTH {40} CONFIG.C_AXI_DATA_WIDTH {512} CONFIG.LGFIFO {5} CONFIG.LGLEN {26}] [get_bd_cells zipcpu_aximm2s_0]

for {set i 0} {$i < 1} {incr i} {
    create_bd_cell -type module -reference tta_core_toplevel tta_core_toplevel_$i
    set device_offset [expr $i * 65536 + 1073741824]
    set_property -dict [list CONFIG.local_mem_addrw_g {12} CONFIG.axi_offset_low_g ${device_offset}] [get_bd_cells tta_core_toplevel_$i]
}

make_bd_pins_external  [get_bd_pins tta_core_toplevel_0/clk]
set_property name ap_clk [get_bd_ports clk_0]

make_bd_pins_external  [get_bd_pins tta_core_toplevel_0/rstx]
set_property name ap_rst_n [get_bd_ports rstx_0]

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi
set_property -dict [list CONFIG.NUM_WRITE_OUTSTANDING {2} CONFIG.NUM_READ_OUTSTANDING {2} CONFIG.ADDR_WIDTH {40} CONFIG.DATA_WIDTH {512}] [get_bd_intf_ports m_axi]


create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_dma
connect_bd_intf_net [get_bd_intf_ports m_axi] [get_bd_intf_pins axi_interconnect_dma/M00_AXI]
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_dma]

connect_bd_intf_net [get_bd_intf_pins zipcpu_aximm2s_0/M_AXI] [get_bd_intf_pins axi_interconnect_dma/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins zipcpu_axis2mm_0/M_AXI] [get_bd_intf_pins axi_interconnect_dma/S01_AXI]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins zipcpu_axis2mm_0/S_AXI_ACLK]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins zipcpu_axis2mm_0/S_AXI_ARESETN]

connect_bd_net [get_bd_ports ap_clk] [get_bd_pins zipcpu_aximm2s_0/S_AXI_ACLK]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins zipcpu_aximm2s_0/S_AXI_ARESETN]


create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_interconnect_0
set_property -dict [list CONFIG.NUM_SI {10} CONFIG.NUM_MI {10}] [get_bd_cells axis_interconnect_0]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axis_interconnect_0/ACLK]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axis_interconnect_0/ARESETN]
for {set i 0} {$i < 10} {incr i} {
    set_property -dict [list CONFIG.M0${i}_HAS_REGSLICE {1} CONFIG.M0${i}_FIFO_DEPTH {128} CONFIG.S0${i}_HAS_REGSLICE {1}] [get_bd_cells axis_interconnect_0]
    connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axis_interconnect_0/M0${i}_AXIS_ACLK]
    connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axis_interconnect_0/S0${i}_AXIS_ACLK]
    connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axis_interconnect_0/M0${i}_AXIS_ARESETN]
    connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axis_interconnect_0/S0${i}_AXIS_ARESETN]
}
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_interconnect_out
set_property -dict [list CONFIG.NUM_SI {10} CONFIG.NUM_MI {10}] [get_bd_cells axis_interconnect_out]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axis_interconnect_out/ACLK]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axis_interconnect_out/ARESETN]
for {set i 0} {$i < 10} {incr i} {
    set_property -dict [list CONFIG.M0${i}_HAS_REGSLICE {1} CONFIG.S0${i}_HAS_REGSLICE {1}] [get_bd_cells axis_interconnect_out]
    connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axis_interconnect_out/M0${i}_AXIS_ACLK]
    connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axis_interconnect_out/S0${i}_AXIS_ACLK]
    connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axis_interconnect_out/M0${i}_AXIS_ARESETN]
    connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axis_interconnect_out/S0${i}_AXIS_ARESETN]
    connect_bd_intf_net [get_bd_intf_pins axis_interconnect_0/M0${i}_AXIS] [get_bd_intf_pins axis_interconnect_out/S0${i}_AXIS]
}

create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1 axis_broadcaster_0
set_property -dict [list CONFIG.M_TDATA_NUM_BYTES {64} CONFIG.S_TDATA_NUM_BYTES {64} CONFIG.M00_TDATA_REMAP {tdata[511:0]} CONFIG.M01_TDATA_REMAP {tdata[511:0]}] [get_bd_cells axis_broadcaster_0]
copy_bd_objs /  [get_bd_cells {axis_broadcaster_0}]

connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axis_broadcaster_0/aclk]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axis_broadcaster_1/aclk]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axis_broadcaster_0/aresetn]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axis_broadcaster_1/aresetn]

create_bd_cell -type module -reference axi_constant axi_constant_0
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_constant_0/clk]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_constant_0/rstx]


create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_tta
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {7}] [get_bd_cells axi_interconnect_tta]
connect_bd_intf_net [get_bd_intf_pins tta_core_toplevel_0/m_axi] [get_bd_intf_pins axi_interconnect_tta/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_tta/M00_AXI] [get_bd_intf_pins zipcpu_aximm2s_0/S_AXIL]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_tta/M01_AXI] [get_bd_intf_pins sobel3x3_ip_0/s_axi_control]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_tta/M02_AXI] [get_bd_intf_pins phase_ip_0/s_axi_control]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_tta/M03_AXI] [get_bd_intf_pins magnitude_ip_0/s_axi_control]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_tta/M04_AXI] [get_bd_intf_pins nonmax_ip_0/s_axi_control]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_tta/M05_AXI] [get_bd_intf_pins axi_constant_0/s_axi]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_tta/M06_AXI] [get_bd_intf_pins zipcpu_axis2mm_0/S_AXIL]

connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_dma/ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_dma/S00_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_dma/S01_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_dma/M00_ACLK]

connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_dma/ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_dma/S00_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_dma/S01_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_dma/M00_ARESETN]

connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_tta/ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_tta/S00_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_tta/M00_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_tta/M01_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_tta/M02_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_tta/M03_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_tta/M04_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_tta/M05_ACLK]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axi_interconnect_tta/M06_ACLK]

connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_tta/ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_tta/S00_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_tta/M00_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_tta/M01_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_tta/M02_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_tta/M03_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_tta/M04_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_tta/M05_ARESETN]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axi_interconnect_tta/M06_ARESETN]

connect_bd_net [get_bd_ports ap_clk] [get_bd_pins sobel3x3_ip_0/ap_clk]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins nonmax_ip_0/ap_clk]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins phase_ip_0/ap_clk]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins magnitude_ip_0/ap_clk]

connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins sobel3x3_ip_0/ap_rst_n]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins nonmax_ip_0/ap_rst_n]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins phase_ip_0/ap_rst_n]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins magnitude_ip_0/ap_rst_n]

connect_bd_intf_net [get_bd_intf_pins axis_broadcaster_0/M00_AXIS] [get_bd_intf_pins axis_interconnect_0/S00_AXIS]
connect_bd_net [get_bd_pins axi_constant_0/tready_10_tdest_out] [get_bd_pins axis_interconnect_0/S00_AXIS_tdest]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 broadcaster0_tready_concat
connect_bd_net [get_bd_pins axis_broadcaster_0/m_axis_tready] [get_bd_pins broadcaster0_tready_concat/dout]
connect_bd_net [get_bd_pins axi_constant_0/tready_10_tready_in] [get_bd_pins axis_interconnect_0/S00_AXIS_tready]
connect_bd_net [get_bd_pins axi_constant_0/tready_10_tready_out] [get_bd_pins broadcaster0_tready_concat/In0]
#SLICE the broadcasters tvalid signal:
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 tvalid_10_slice
set_property -dict [list CONFIG.DIN_WIDTH {2} CONFIG.DIN_TO {0} CONFIG.DIN_FROM {0} CONFIG.DOUT_WIDTH {1}] [get_bd_cells tvalid_10_slice]
connect_bd_net [get_bd_pins axis_broadcaster_0/m_axis_tvalid] [get_bd_pins tvalid_10_slice/Din]
connect_bd_net [get_bd_pins axi_constant_0/tready_10_tvalid_in] [get_bd_pins tvalid_10_slice/Dout]
connect_bd_net [get_bd_pins axi_constant_0/tready_10_tvalid_out] [get_bd_pins axis_interconnect_0/S00_AXIS_tvalid]

connect_bd_intf_net [get_bd_intf_pins axis_broadcaster_0/M01_AXIS] [get_bd_intf_pins axis_interconnect_0/S01_AXIS]
connect_bd_net [get_bd_pins axi_constant_0/tready_11_tdest_out] [get_bd_pins axis_interconnect_0/S01_AXIS_tdest]
connect_bd_net [get_bd_pins axi_constant_0/tready_11_tready_in] [get_bd_pins axis_interconnect_0/S01_AXIS_tready]
connect_bd_net [get_bd_pins axi_constant_0/tready_11_tready_out] [get_bd_pins broadcaster0_tready_concat/In1]
#SLICE the broadcasters tvalid signal:
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 tvalid_11_slice
set_property -dict [list CONFIG.DIN_WIDTH {2} CONFIG.DIN_TO {1} CONFIG.DIN_FROM {1} CONFIG.DOUT_WIDTH {1}] [get_bd_cells tvalid_11_slice]
connect_bd_net [get_bd_pins axis_broadcaster_0/m_axis_tvalid] [get_bd_pins tvalid_11_slice/Din]
connect_bd_net [get_bd_pins axi_constant_0/tready_11_tvalid_in] [get_bd_pins tvalid_11_slice/Dout]
connect_bd_net [get_bd_pins axi_constant_0/tready_11_tvalid_out] [get_bd_pins axis_interconnect_0/S01_AXIS_tvalid]

connect_bd_intf_net [get_bd_intf_pins axis_broadcaster_1/M00_AXIS] [get_bd_intf_pins axis_interconnect_0/S02_AXIS]
connect_bd_net [get_bd_pins axi_constant_0/tready_12_tdest_out] [get_bd_pins axis_interconnect_0/S02_AXIS_tdest]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 broadcaster1_tready_concat
connect_bd_net [get_bd_pins axis_broadcaster_1/m_axis_tready] [get_bd_pins broadcaster1_tready_concat/dout]
connect_bd_net [get_bd_pins axi_constant_0/tready_12_tready_in] [get_bd_pins axis_interconnect_0/S02_AXIS_tready]
connect_bd_net [get_bd_pins axi_constant_0/tready_12_tready_out] [get_bd_pins broadcaster1_tready_concat/In0]
#SLICE the broadcasters tvalid signal:
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 tvalid_12_slice
set_property -dict [list CONFIG.DIN_WIDTH {2} CONFIG.DIN_TO {0} CONFIG.DIN_FROM {0} CONFIG.DOUT_WIDTH {1}] [get_bd_cells tvalid_12_slice]
connect_bd_net [get_bd_pins axis_broadcaster_1/m_axis_tvalid] [get_bd_pins tvalid_12_slice/Din]
connect_bd_net [get_bd_pins axi_constant_0/tready_12_tvalid_in] [get_bd_pins tvalid_12_slice/Dout]
connect_bd_net [get_bd_pins axi_constant_0/tready_12_tvalid_out] [get_bd_pins axis_interconnect_0/S02_AXIS_tvalid]

connect_bd_intf_net [get_bd_intf_pins axis_broadcaster_1/M01_AXIS] [get_bd_intf_pins axis_interconnect_0/S03_AXIS]
connect_bd_net [get_bd_pins axi_constant_0/tready_13_tdest_out] [get_bd_pins axis_interconnect_0/S03_AXIS_tdest]
connect_bd_net [get_bd_pins axi_constant_0/tready_13_tready_in] [get_bd_pins axis_interconnect_0/S03_AXIS_tready]
connect_bd_net [get_bd_pins axi_constant_0/tready_13_tready_out] [get_bd_pins broadcaster1_tready_concat/In1]
#SLICE the broadcasters tvalid signal:
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 tvalid_13_slice
set_property -dict [list CONFIG.DIN_WIDTH {2} CONFIG.DIN_TO {1} CONFIG.DIN_FROM {1} CONFIG.DOUT_WIDTH {1}] [get_bd_cells tvalid_13_slice]
connect_bd_net [get_bd_pins axis_broadcaster_1/m_axis_tvalid] [get_bd_pins tvalid_13_slice/Din]
connect_bd_net [get_bd_pins axi_constant_0/tready_13_tvalid_in] [get_bd_pins tvalid_13_slice/Dout]
connect_bd_net [get_bd_pins axi_constant_0/tready_13_tvalid_out] [get_bd_pins axis_interconnect_0/S03_AXIS_tvalid]

connect_bd_intf_net [get_bd_intf_pins axis_interconnect_out/M00_AXIS] [get_bd_intf_pins axis_broadcaster_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins axis_interconnect_out/M01_AXIS] [get_bd_intf_pins axis_broadcaster_1/S_AXIS]

connect_bd_intf_net [get_bd_intf_pins sobel3x3_ip_0/in0] [get_bd_intf_pins axis_interconnect_out/M02_AXIS]
connect_bd_intf_net [get_bd_intf_pins sobel3x3_ip_0/out0] [get_bd_intf_pins axis_interconnect_0/S04_AXIS]
connect_bd_intf_net [get_bd_intf_pins sobel3x3_ip_0/out1] [get_bd_intf_pins axis_interconnect_0/S05_AXIS]

connect_bd_intf_net [get_bd_intf_pins phase_ip_0/in0] [get_bd_intf_pins axis_interconnect_out/M03_AXIS]
connect_bd_intf_net [get_bd_intf_pins phase_ip_0/in1] [get_bd_intf_pins axis_interconnect_out/M04_AXIS]
connect_bd_intf_net [get_bd_intf_pins phase_ip_0/out0] [get_bd_intf_pins axis_interconnect_0/S06_AXIS]

connect_bd_intf_net [get_bd_intf_pins magnitude_ip_0/in0] [get_bd_intf_pins axis_interconnect_out/M05_AXIS]
connect_bd_intf_net [get_bd_intf_pins magnitude_ip_0/in1] [get_bd_intf_pins axis_interconnect_out/M06_AXIS]
connect_bd_intf_net [get_bd_intf_pins magnitude_ip_0/out0] [get_bd_intf_pins axis_interconnect_0/S07_AXIS]

connect_bd_intf_net [get_bd_intf_pins nonmax_ip_0/in0] [get_bd_intf_pins axis_interconnect_out/M07_AXIS]
connect_bd_intf_net [get_bd_intf_pins nonmax_ip_0/in1] [get_bd_intf_pins axis_interconnect_out/M08_AXIS]
connect_bd_intf_net [get_bd_intf_pins nonmax_ip_0/out0] [get_bd_intf_pins axis_interconnect_0/S08_AXIS]

connect_bd_intf_net [get_bd_intf_pins zipcpu_axis2mm_0/S_AXIS] [get_bd_intf_pins axis_interconnect_out/M09_AXIS]
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_0
connect_bd_intf_net [get_bd_intf_pins zipcpu_aximm2s_0/M_AXIS] [get_bd_intf_pins axis_register_slice_0/S_AXIS]
set_property -dict [list CONFIG.TDEST_WIDTH.VALUE_SRC USER] [get_bd_cells axis_register_slice_0]
set_property -dict [list CONFIG.TDEST_WIDTH {5}] [get_bd_cells axis_register_slice_0]
connect_bd_net [get_bd_ports ap_clk] [get_bd_pins axis_register_slice_0/aclk]
connect_bd_net [get_bd_ports ap_rst_n] [get_bd_pins axis_register_slice_0/aresetn]
connect_bd_intf_net [get_bd_intf_pins axis_register_slice_0/M_AXIS] -boundary_type upper [get_bd_intf_pins axis_interconnect_0/S09_AXIS]
connect_bd_net [get_bd_pins axis_register_slice_0/s_axis_tdest] [get_bd_pins axi_constant_0/tready_14_tdest_out]

connect_bd_net [get_bd_pins axi_constant_0/tready_14_tready_in] [get_bd_pins axis_register_slice_0/s_axis_tready]
connect_bd_net [get_bd_pins axi_constant_0/tready_14_tready_out] [get_bd_pins zipcpu_aximm2s_0/m_axis_tready]
connect_bd_net [get_bd_pins axi_constant_0/tready_14_tvalid_in] [get_bd_pins zipcpu_aximm2s_0/m_axis_tvalid]
connect_bd_net [get_bd_pins axi_constant_0/tready_14_tvalid_out] [get_bd_pins axis_register_slice_0/s_axis_tvalid]

for {set i 0} {$i < 10} {incr i} {
    connect_bd_net [get_bd_pins axi_constant_0/tready_0${i}_tdest_out] [get_bd_pins axis_interconnect_out/S0${i}_AXIS_tdest]
    connect_bd_net [get_bd_pins axi_constant_0/tready_0${i}_tready_in] [get_bd_pins axis_interconnect_out/S0${i}_AXIS_tready]
    connect_bd_net [get_bd_pins axi_constant_0/tready_0${i}_tready_out] [get_bd_pins axis_interconnect_0/M0${i}_AXIS_tready]
    connect_bd_net [get_bd_pins axi_constant_0/tready_0${i}_tvalid_in] [get_bd_pins axis_interconnect_0/M0${i}_AXIS_tvalid]
    connect_bd_net [get_bd_pins axi_constant_0/tready_0${i}_tvalid_out] [get_bd_pins axis_interconnect_out/S0${i}_AXIS_tvalid]
}

make_bd_intf_pins_external  [get_bd_intf_pins tta_core_toplevel_0/s_axi]
set_property name s_axi_control [get_bd_intf_ports s_axi_0]

regenerate_bd_layout
assign_bd_address
set_property offset 0x0000000000 [get_bd_addr_segs {zipcpu_aximm2s_0/M_AXI/SEG_m_axi_Reg}]
set_property range 256M [get_bd_addr_segs {zipcpu_aximm2s_0/M_AXI/SEG_m_axi_Reg}]
set_property offset 0x0000000000 [get_bd_addr_segs {zipcpu_axis2mm_0/M_AXI/SEG_m_axi_Reg}]
set_property range 256M [get_bd_addr_segs {zipcpu_axis2mm_0/M_AXI/SEG_m_axi_Reg}]

set_property offset 0x41E30000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_sobel3x3_ip_0_Reg}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_sobel3x3_ip_0_Reg}]
set_property offset 0x41E40000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_phase_ip_0_Reg}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_phase_ip_0_Reg}]
set_property offset 0x41E50000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_magnitude_ip_0_Reg}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_magnitude_ip_0_Reg}]
set_property offset 0x41E60000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_nonmax_ip_0_Reg}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_nonmax_ip_0_Reg}]

set_property offset 0x41E10000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_0_reg0}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_aximm2s_0_reg0}]
set_property offset 0x41E00000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_axi_constant_0_reg0}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_axi_constant_0_reg0}]
set_property offset 0x41E20000 [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_axis2mm_0_reg0}]
set_property range 4K [get_bd_addr_segs {tta_core_toplevel_0/m_axi/SEG_zipcpu_axis2mm_0_reg0}]
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
set_property  ip_repo_paths  {ip_repo_${input_folder}} [current_project]
update_ip_catalog
ipx::check_integrity -quiet -kernel [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
ipx::archive_core ip_repo_${input_folder}/user.org_user_vec_${input_folder}_1.0.zip [ipx::find_open_core user.org:user:vec_${input_folder}:1.0]
