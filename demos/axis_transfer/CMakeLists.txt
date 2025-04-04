cmake_minimum_required(VERSION 3.30)

project(axis_transfer)

# Set global C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(verilator HINTS $ENV{VERILATOR_ROOT} REQUIRED)
find_package(PkgConfig REQUIRED)

pkg_check_modules(gtest_main REQUIRED IMPORTED_TARGET gtest_main)

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

add_executable(Vtb_axis_transfer axis_transfer_test.cc)
target_link_libraries(Vtb_axis_transfer PRIVATE PkgConfig::gtest_main)

set(Vaxis_transfer_sources
  ${CMAKE_CURRENT_SOURCE_DIR}/axis_transfer.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/gradient.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/../../hw/ufp_if.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/../../hw/ufp_from_real.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/../../hw/ufp_mul.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/../../hw/ufp_resize.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/../../hw/clip_unsigned.sv
)
verilate(Vtb_axis_transfer
  VERILATOR_ARGS --timing --trace
  SOURCES ${Vaxis_transfer_sources}
  TOP_MODULE axis_transfer
)
