cmake_minimum_required(VERSION 3.30)

pkg_check_modules(gtest_main REQUIRED IMPORTED_TARGET gtest_main)

# Extract include directories from fp_core_sv target
get_target_property(fp_core_includes fp_core_sv INTERFACE_INCLUDE_DIRECTORIES)
get_target_property(fp_core_sources  fp_core_sv INTERFACE_SOURCES)

# Gradient Test

# add_executable(Vgradient_test gradient_test.cc)
# target_link_libraries(Vgradient_test PRIVATE PkgConfig::gtest_main)

# set(Vgradient_test_sources
#   ${CMAKE_CURRENT_SOURCE_DIR}/gradient.sv
#   ${CMAKE_CURRENT_SOURCE_DIR}/../../hw/ufp_if.sv
#   ${CMAKE_CURRENT_SOURCE_DIR}/../../hw/ufp_from_real.sv
#   ${CMAKE_CURRENT_SOURCE_DIR}/../../hw/ufp_mul.sv
#   ${CMAKE_CURRENT_SOURCE_DIR}/../../hw/ufp_resize.sv
#   ${CMAKE_CURRENT_SOURCE_DIR}/../../hw/clip_unsigned.sv
# )
# verilate(Vgradient_test
#   SOURCES ${Vgradient_test_sources}
#   TOP_MODULE gradient
# )

# AXIS Test
add_executable(Vtb_axis_transfer ${CMAKE_CURRENT_SOURCE_DIR}/axis_transfer_test.cc)
target_link_libraries(Vtb_axis_transfer PRIVATE PkgConfig::gtest_main)

  verilate(Vtb_axis_transfer
    VERILATOR_ARGS --timing --trace
    SOURCES
      ${CMAKE_CURRENT_SOURCE_DIR}/axis_transfer.sv
      ${CMAKE_CURRENT_SOURCE_DIR}/gradient.sv
      ${fp_core_sources}
    INCLUDE_DIRS
      ${fp_core_includes}
    TOP_MODULE
      axis_transfer
  )

  add_test(
    NAME Vtb_axis_transfer
    COMMAND $<TARGET_FILE:Vtb_axis_transfer>
  )