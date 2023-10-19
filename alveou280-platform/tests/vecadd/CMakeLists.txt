
include_directories("${POCL_INCLUDE_DIR}/hpp/")
add_executable(vecadd accel_example.cpp)
target_link_libraries(vecadd "-Wl,-rpath=${POCL_BUILD_DIR}/lib/CL/ -L${POCL_BUILD_DIR}/lib/CL/ -lm -lOpenCL")



add_test("hw_emu/add.i32" vecadd pocl.add.i32)
add_test("hw_emu/add.i32/twice" vecadd pocl.add.i32 2) #2 iterations to test the stability
add_test("hw_emu/add.i16" vecadd pocl.add.i16)
add_test("hw_emu/mul.i32" vecadd pocl.mul.i32)

set_tests_properties("hw_emu/add.i32" "hw_emu/add.i16" "hw_emu/mul.i32" "hw_emu/add.i32/twice"
    PROPERTIES
        ENVIRONMENT "POCL_DEVICES=almaif;POCL_ALMAIF_EXTERNALREGION=0x00000,0x20000;XCL_EMULATION_MODE=hw_emu;EMCONFIG_PATH=${CMAKE_SOURCE_DIR}")


set_property(TEST "hw_emu/add.i32"
    APPEND PROPERTY ENVIRONMENT "POCL_ALMAIF0_PARAMETERS=0xA,${CMAKE_SOURCE_DIR}/vec_add_32x32_sim,1")
set_property(TEST "hw_emu/add.i32/twice"
    APPEND PROPERTY ENVIRONMENT "POCL_ALMAIF0_PARAMETERS=0xA,${CMAKE_SOURCE_DIR}/vec_add_32x32_sim,1")
set_property(TEST "hw_emu/mul.i32"
    APPEND PROPERTY ENVIRONMENT "POCL_ALMAIF0_PARAMETERS=0xA,${CMAKE_SOURCE_DIR}/vec_mul_32x32_sim,2")
set_property(TEST "hw_emu/add.i16"
    APPEND PROPERTY ENVIRONMENT "POCL_ALMAIF0_PARAMETERS=0xA,${CMAKE_SOURCE_DIR}/vec_add_16x64_sim,14")

