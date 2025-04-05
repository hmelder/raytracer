add_library(rt_sv INTERFACE)

target_sources(rt_sv INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/rt_rgu.sv
)

target_include_directories(rt_sv INTERFACE
  ${CMAKE_CURRENT_SOURCE_DIR}
)

if(TESTS)
  add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/tests)
endif()