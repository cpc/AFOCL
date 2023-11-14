

include_directories("home/topi/pocl_wd/os/include/")
add_executable(canny canny_opencl.c opencl_util.c util.c)
add_executable(canny_pipe canny_pipe.c opencl_util.c util.c)
target_link_libraries(canny "-Wl,-rpath=/home/topi/pocl_wd/os/build/lib/CL/ -L/home/topi/pocl_wd/os/build/lib/CL/ -lm -lOpenCL")
target_link_libraries(canny_pipe "-Wl,-rpath=/home/topi/pocl_wd/os/build/lib/CL/ -L/home/topi/pocl_wd/os/build/lib/CL/ -lm -lOpenCL")


# canny1 tests have 1 device implementing the 4 BiKs
add_test("hw_emu/canny1/sobel3x3/x_64x4" canny "${CMAKE_SOURCE_DIR}/data/img/x_64x4.pgm")
add_test("hw_emu/canny1/sobel3x3-phase-magnitude/x_64x4" canny "${CMAKE_SOURCE_DIR}/data/img/x_64x4.pgm")
add_test("hw_emu/canny1/all/x_64x4" canny -b 2 "${CMAKE_SOURCE_DIR}/data/img/x_64x4.pgm")
add_test("hw_emu/canny1/all/incr1216x3" canny "${CMAKE_SOURCE_DIR}/data/img/incr1216x3.pgm")

set_tests_properties("hw_emu/canny1/all/x_64x4" "hw_emu/canny1/all/incr1216x3"
    "hw_emu/canny1/sobel3x3-phase-magnitude/x_64x4" "hw_emu/canny1/sobel3x3/x_64x4"
    PROPERTIES
    ENVIRONMENT "POCL_DEVICES=almaif;POCL_ALMAIF_EXTERNALREGION=0x00000,0x20000;XCL_EMULATION_MODE=hw_emu;EMCONFIG_PATH=${CMAKE_SOURCE_DIR}")

set_property(TEST "hw_emu/canny1/sobel3x3/x_64x4"
    APPEND PROPERTY ENVIRONMENT "POCL_ALMAIF0_PARAMETERS=0xA,${CMAKE_SOURCE_DIR}/vec_canny1_sim,25")
set_property(TEST "hw_emu/canny1/sobel3x3-phase-magnitude/x_64x4"
    APPEND PROPERTY ENVIRONMENT "POCL_ALMAIF0_PARAMETERS=0xA,${CMAKE_SOURCE_DIR}/vec_canny1_sim,25,26,27")
set_property(TEST "hw_emu/canny1/all/x_64x4"
    APPEND PROPERTY ENVIRONMENT "POCL_ALMAIF0_PARAMETERS=0xA,${CMAKE_SOURCE_DIR}/vec_canny1_sim,25,26,27,28")
set_property(TEST "hw_emu/canny1/all/incr1216x3"
    APPEND PROPERTY ENVIRONMENT "POCL_ALMAIF0_PARAMETERS=0xA,${CMAKE_SOURCE_DIR}/vec_canny1_sim,25,26,27,28")


# canny2 tests have 4 different devices each implementing one BiK each
add_test("hw_emu/canny2/sobel3x3/x_64x4" canny "${CMAKE_SOURCE_DIR}/data/img/x_64x4.pgm")
add_test("hw_emu/canny2/sobel3x3-phase-magnitude/x_64x4" canny "${CMAKE_SOURCE_DIR}/data/img/x_64x4.pgm")
#add_test("hw_emu/canny2/all/x_64x4" canny -b 2 "${CMAKE_SOURCE_DIR}/data/img/x_64x4.pgm")
#add_test("hw_emu/canny2/all/incr1216x3" canny "${CMAKE_SOURCE_DIR}/data/img/incr1216x3.pgm")

#set_tests_properties("hw_emu/canny2/all/x_64x4" "hw_emu/canny2/all/incr1216x3"
set_tests_properties("hw_emu/canny2/sobel3x3-phase-magnitude/x_64x4" "hw_emu/canny2/sobel3x3/x_64x4"
    PROPERTIES
    ENVIRONMENT "POCL_ALMAIF_EXTERNALREGION=0x00000,0x20000;\
XCL_EMULATION_MODE=hw_emu;\
EMCONFIG_PATH=${CMAKE_SOURCE_DIR};\
POCL_ALMAIF0_PARAMETERS=0xA,${CMAKE_SOURCE_DIR}/vec_sobel3x3_sim,25;\
POCL_ALMAIF1_PARAMETERS=0xA,${CMAKE_SOURCE_DIR}/vec_phase_sim,26;\
POCL_ALMAIF2_PARAMETERS=0xA,${CMAKE_SOURCE_DIR}/vec_magnitude_sim,27;\
POCL_ALMAIF3_PARAMETERS=0xA,${CMAKE_SOURCE_DIR}/vec_nonmax_sim,28")

#set_property(TEST "hw_emu/canny2/all/x_64x4"
#    APPEND PROPERTY ENVIRONMENT "POCL_DEVICES=almaif almaif almaif almaif")
#set_property(TEST "hw_emu/canny2/all/incr1216x3"
#    APPEND PROPERTY ENVIRONMENT "POCL_DEVICES=almaif almaif almaif almaif")
set_property(TEST "hw_emu/canny2/sobel3x3/x_64x4"
    APPEND PROPERTY ENVIRONMENT "POCL_DEVICES=almaif")
set_property(TEST "hw_emu/canny2/sobel3x3-phase-magnitude/x_64x4"
    APPEND PROPERTY ENVIRONMENT "POCL_DEVICES=almaif almaif almaif")


# canny3 tests. A single mega-kernel in 1 device
add_test("hw_emu/canny3/all/x_64x4" canny -b 2 "${CMAKE_SOURCE_DIR}/data/img/x_64x4.pgm")
add_test("hw_emu/canny3/all/incr1216x3" canny "${CMAKE_SOURCE_DIR}/data/img/incr1216x3.pgm")

set_tests_properties("hw_emu/canny3/all/x_64x4" "hw_emu/canny3/all/incr1216x3"
    PROPERTIES
    ENVIRONMENT "POCL_DEVICES=almaif;POCL_ALMAIF_EXTERNALREGION=0x00000,0x20000;XCL_EMULATION_MODE=hw_emu;EMCONFIG_PATH=${CMAKE_SOURCE_DIR}")

set_property(TEST "hw_emu/canny3/all/x_64x4"
    APPEND PROPERTY ENVIRONMENT "POCL_ALMAIF0_PARAMETERS=0xA,${CMAKE_SOURCE_DIR}/vec_canny3_sim,29")
set_property(TEST "hw_emu/canny3/all/incr1216x3"
    APPEND PROPERTY ENVIRONMENT "POCL_ALMAIF0_PARAMETERS=0xA,${CMAKE_SOURCE_DIR}/vec_canny3_sim,29")
