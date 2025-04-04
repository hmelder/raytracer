# fp_core/CMakeLists.txt
add_library(fp_core_sv INTERFACE)

target_sources(fp_core_sv INTERFACE
  ${CMAKE_CURRENT_SOURCE_DIR}/clip_signed.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/clip_unsigned.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_add.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_add_full.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_if.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_mul.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_mul_full.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_resize.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_sub.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/sfp_sub_full.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/ufp_from_real.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/ufp_if.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/ufp_mul.sv
  ${CMAKE_CURRENT_SOURCE_DIR}/ufp_resize.sv
)

target_include_directories(fp_core_sv INTERFACE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/..
)

if(TESTS)
  add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/tests)
endif()
