# coprocessor/CMakeLists.txt
add_library(coprocessor_sv INTERFACE)

target_sources(coprocessor_sv INTERFACE
  ${CMAKE_CURRENT_SOURCE_DIR}/coprocessor.v
  ${CMAKE_CURRENT_SOURCE_DIR}/render_core.sv
)

target_include_directories(coprocessor_sv INTERFACE
  ${CMAKE_CURRENT_SOURCE_DIR}
)

# coprocessor depends on modules from rt
target_link_libraries(coprocessor_sv INTERFACE rt_sv)


if(TESTS)
  add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/tests)
endif()
