cmake_minimum_required(VERSION 3.30)

pkg_check_modules(gtest_main REQUIRED IMPORTED_TARGET gtest_main)

# Extract include directories from fp_core_sv target
get_target_property(fp_core_includes fp_core_sv INTERFACE_INCLUDE_DIRECTORIES)
get_target_property(fp_core_sources  fp_core_sv INTERFACE_SOURCES)

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