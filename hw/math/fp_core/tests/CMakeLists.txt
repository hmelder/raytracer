cmake_minimum_required(VERSION 3.30)

pkg_check_modules(gtest_main REQUIRED IMPORTED_TARGET gtest_main)

# Extract include directories from fp_core_sv target
get_target_property(fp_core_includes fp_core_sv INTERFACE_INCLUDE_DIRECTORIES)
get_target_property(fp_core_sources  fp_core_sv INTERFACE_SOURCES)

function(add_verilated_test TEST_NAME SV_SRC CC_SRC TOP_MODULE_NAME)
  add_executable(${TEST_NAME} ${CC_SRC})
  target_link_libraries(${TEST_NAME} PRIVATE PkgConfig::gtest_main)

  verilate(${TEST_NAME}
    SOURCES
      ${SV_SRC}
      ${fp_core_sources}
    INCLUDE_DIRS
      ${fp_core_includes}
    TOP_MODULE
      ${TOP_MODULE_NAME}
  )

  add_test(
    NAME ${TEST_NAME}
    COMMAND $<TARGET_FILE:${TEST_NAME}>
  )
endfunction()

add_verilated_test(Vclip_unsigned_test
  ${CMAKE_CURRENT_SOURCE_DIR}/clip_unsigned_wrapper.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/clip_unsigned_test.cc
  clip_unsigned_wrapper
)

add_verilated_test(Vresize_down_test
  ${CMAKE_CURRENT_SOURCE_DIR}/resize_down_test.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/resize_down_test.cc
  resize_down_test
)

add_verilated_test(Vufp_mul_test
  ${CMAKE_CURRENT_SOURCE_DIR}/ufp_mul_wrapper.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/ufp_mul_test.cc
  ufp_mul_wrapper
)

add_verilated_test(Vsfp_add_test
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_add_wrapper.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_add_test.cc
  sfp_add_wrapper
)

add_verilated_test(Vsfp_sub_test
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_sub_wrapper.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_sub_test.cc
  sfp_sub_wrapper
)
