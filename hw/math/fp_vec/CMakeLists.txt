add_library(fp_vec_sv INTERFACE)

target_sources(fp_vec_sv INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/sfp_vec_add.sv
    ${CMAKE_CURRENT_SOURCE_DIR}/sfp_vec_add_s.sv
    ${CMAKE_CURRENT_SOURCE_DIR}/sfp_vec_mul.sv
    ${CMAKE_CURRENT_SOURCE_DIR}/sfp_vec_mul_s.sv
    ${CMAKE_CURRENT_SOURCE_DIR}/sfp_vec_sub.sv
    ${CMAKE_CURRENT_SOURCE_DIR}/sfp_vec_neg.sv
    ${CMAKE_CURRENT_SOURCE_DIR}/sfp_vec_lerp.sv
    ${CMAKE_CURRENT_SOURCE_DIR}/sfp_vec3_dot.sv
    ${CMAKE_CURRENT_SOURCE_DIR}/sfp_vec3_cross.sv
)

target_include_directories(fp_vec_sv INTERFACE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/..
)

option(FP_VEC_TESTS "Enable building of fp_vec tests" OFF)

if(FP_VEC_TESTS)
  add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/tests)
endif()
