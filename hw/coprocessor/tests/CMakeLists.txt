cmake_minimum_required(VERSION 3.30)

pkg_check_modules(gtest_main REQUIRED IMPORTED_TARGET gtest_main)

# Extract include directories from fp_core_sv target
get_target_property(fp_core_includes fp_core_sv INTERFACE_INCLUDE_DIRECTORIES)
get_target_property(fp_core_sources  fp_core_sv INTERFACE_SOURCES)
get_target_property(fp_vec_includes fp_vec_sv INTERFACE_INCLUDE_DIRECTORIES)
get_target_property(fp_vec_sources  fp_vec_sv INTERFACE_SOURCES)
get_target_property(rt_includes rt_sv INTERFACE_INCLUDE_DIRECTORIES)
get_target_property(rt_sources  rt_sv INTERFACE_SOURCES)
get_target_property(coprocessor_includes coprocessor_sv INTERFACE_INCLUDE_DIRECTORIES)
get_target_property(coprocessor_sources  coprocessor_sv INTERFACE_SOURCES)

# Coprocessor Test
add_executable(Vcoprocessor ${CMAKE_CURRENT_SOURCE_DIR}/coprocessor_test.cc)
target_link_libraries(Vcoprocessor PRIVATE PkgConfig::gtest_main)

verilate(Vcoprocessor
  VERILATOR_ARGS --timing --trace
  SOURCES
    ${coprocessor_sources}
    ${fp_core_sources}
    ${fp_vec_sources}
    ${rt_sources}
  INCLUDE_DIRS
    ${coprocessor_includes}
    ${fp_core_includes}
    ${fp_vec_includes}
    ${rt_includes}
  TOP_MODULE
    coprocessor
)
