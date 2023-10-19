export POCL_DEVICES=almaif
export POCL_ALMAIF0_PARAMETERS=0xA,vec_add_32x32,1
export POCL_ALMAIF_EXTERNALREGION=0x00000,0x20000

# XRT crashes if this is set (not even 'hw' allowed)
unset XCL_EMULATION_MODE
