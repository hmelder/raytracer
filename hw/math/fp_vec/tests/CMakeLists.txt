cmake_minimum_required(VERSION 3.30)

pkg_check_modules(gtest_main REQUIRED IMPORTED_TARGET gtest_main)

# Extract include directories from fp_core_sv and fp_vec_sv target
get_target_property(fp_core_includes fp_core_sv INTERFACE_INCLUDE_DIRECTORIES)
get_target_property(fp_core_sources  fp_core_sv INTERFACE_SOURCES)
get_target_property(fp_vec_includes fp_vec_sv INTERFACE_INCLUDE_DIRECTORIES)
get_target_property(fp_vec_sources  fp_vec_sv INTERFACE_SOURCES)

function(add_verilated_test TEST_NAME SV_SRC CC_SRC TOP_MODULE_NAME)
  add_executable(${TEST_NAME} ${CC_SRC})
  target_link_libraries(${TEST_NAME} PRIVATE PkgConfig::gtest_main)

  verilate(${TEST_NAME}
    SOURCES
      ${SV_SRC}
      ${fp_core_sources}
      ${fp_vec_sources}
    INCLUDE_DIRS
      ${fp_core_includes}
      ${fp_vec_includes}
    TOP_MODULE
      ${TOP_MODULE_NAME}
  )

  add_test(
    NAME ${TEST_NAME}
    COMMAND $<TARGET_FILE:${TEST_NAME}>
  )
endfunction()

add_verilated_test(Vsfp_vec_dot
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_vec_dot_wrapper.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_vec_dot_test.cc
  sfp_vec_dot_wrapper
)

add_verilated_test(Vsfp_vec3_cross
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_vec3_cross_wrapper.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_vec3_cross_test.cc
  sfp_vec3_cross_wrapper
)

add_verilated_test(Vsfp_vec_add_s
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_vec_add_s_wrapper.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_vec_add_s_test.cc
  sfp_vec_add_s_wrapper
)