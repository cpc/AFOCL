export POCL_DEVICES=almaif
export POCL_ALMAIF0_PARAMETERS=0xA,vec_canny3_sim,29
export POCL_ALMAIF_EXTERNALREGION=0x00000,0x20000

#Enable vivado emulator
export XCL_EMULATION_MODE=hw_emu
export EMCONFIG_PATH=$PWD
