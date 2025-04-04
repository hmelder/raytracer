cmake_minimum_required(VERSION 3.30)

pkg_check_modules(gtest_main REQUIRED IMPORTED_TARGET gtest_main)

# Vclipping_test
add_executable(Vclipping_test clipping_test.cc)
target_link_libraries(Vclipping_test PRIVATE PkgConfig::gtest_main)

set(Vclipping_sources ${CMAKE_CURRENT_SOURCE_DIR}/clipping_test.sv ${CMAKE_CURRENT_SOURCE_DIR}/../clip_unsigned.sv)

verilate(Vclipping_test SOURCES ${Vclipping_sources} TOP_MODULE clipping_test)

# Vresize_down_test
add_executable(Vresize_down_test resize_down_test.cc)
target_link_libraries(Vresize_down_test PRIVATE PkgConfig::gtest_main)

set(Vresize_down_test ${CMAKE_CURRENT_SOURCE_DIR}/resize_down_test.sv ${CMAKE_CURRENT_SOURCE_DIR}/resize_test.sv ${CMAKE_CURRENT_SOURCE_DIR}/../clip_unsigned.sv ${CMAKE_CURRENT_SOURCE_DIR}/../ufp_resize.sv ${CMAKE_CURRENT_SOURCE_DIR}/../ufp_if.sv)

verilate(Vresize_down_test SOURCES ${Vresize_down_test} TOP_MODULE resize_down_test)

# Vufp_mul_test
add_executable(Vufp_mul_test ufp_mul_test.cc)
target_link_libraries(Vufp_mul_test PRIVATE PkgConfig::gtest_main)
set(Vufp_mul_sources
  ${CMAKE_CURRENT_SOURCE_DIR}/ufp_mul_test.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/../clip_unsigned.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/../ufp_resize.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/../ufp_if.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/../ufp_mul.sv
)
verilate(Vufp_mul_test SOURCES ${Vufp_mul_sources} TOP_MODULE ufp_mul_test)

# Register test
add_test(
  NAME Vclipping_test
  COMMAND $<TARGET_FILE:Vclipping_test>
)

add_test(
  NAME Vresize_down_test
  COMMAND $<TARGET_FILE:Vresize_down_test>
)

add_test(
  NAME Vufp_mul_test
  COMMAND $<TARGET_FILE:Vufp_mul_test>
)