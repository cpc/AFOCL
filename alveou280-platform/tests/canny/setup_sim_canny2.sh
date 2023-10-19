export POCL_DEVICES="almaif almaif almaif almaif"
export POCL_ALMAIF0_PARAMETERS=0xA,vec_sobel3x3_sim,25
export POCL_ALMAIF1_PARAMETERS=0xA,vec_phase_sim,26
export POCL_ALMAIF2_PARAMETERS=0xA,vec_magnitude_sim,27
export POCL_ALMAIF3_PARAMETERS=0xA,vec_nonmax_sim,28
export POCL_ALMAIF_EXTERNALREGION=0x00000,0x20000

#Enable vivado emulator
export XCL_EMULATION_MODE=hw_emu
export EMCONFIG_PATH=$PWD
