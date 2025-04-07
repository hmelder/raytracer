cmake_minimum_required(VERSION 3.30)

pkg_check_modules(gtest_main REQUIRED IMPORTED_TARGET gtest_main)

# Extract include directories from fp_core_sv, fp_vec_sv, and rt_sv targets
get_target_property(fp_core_includes fp_core_sv INTERFACE_INCLUDE_DIRECTORIES)
get_target_property(fp_core_sources  fp_core_sv INTERFACE_SOURCES)
get_target_property(fp_vec_includes fp_vec_sv INTERFACE_INCLUDE_DIRECTORIES)
get_target_property(fp_vec_sources  fp_vec_sv INTERFACE_SOURCES)
get_target_property(rt_includes rt_sv INTERFACE_INCLUDE_DIRECTORIES)
get_target_property(rt_sources  rt_sv INTERFACE_SOURCES)


function(add_verilated_test TEST_NAME SV_SRC CC_SRC TOP_MODULE_NAME)
  add_executable(${TEST_NAME} ${CC_SRC})
  target_link_libraries(${TEST_NAME} PRIVATE PkgConfig::gtest_main)

  verilate(${TEST_NAME}
    VERILATOR_ARGS --timing --trace
    SOURCES
      ${SV_SRC}
      ${fp_core_sources}
      ${fp_vec_sources}
      ${rt_sources}
    INCLUDE_DIRS
      ${fp_core_includes}
      ${fp_vec_includes}
      ${rt_includes}
    TOP_MODULE
      ${TOP_MODULE_NAME}
  )

  add_test(
    NAME ${TEST_NAME}
    COMMAND $<TARGET_FILE:${TEST_NAME}>
  )
endfunction()

add_verilated_test(Vrt_rgu
  ${CMAKE_CURRENT_SOURCE_DIR}/rt_rgu_wrapper.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/rt_rgu_test.cc
  rt_rgu_wrapper
)