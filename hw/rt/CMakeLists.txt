add_library(rt_sv INTERFACE)

target_sources(rt_sv INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/rt_rgu_5_stage.sv
    ${CMAKE_CURRENT_SOURCE_DIR}/rt_controller.sv
    ${CMAKE_CURRENT_SOURCE_DIR}/rt_core.sv
    ${CMAKE_CURRENT_SOURCE_DIR}/coprocessor.v
)

target_include_directories(rt_sv INTERFACE
  ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(rt_sv INTERFACE fp_vec_sv)

if(TESTS)
  add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/tests)
endif()