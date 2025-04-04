cmake_minimum_required(VERSION 3.30)
project(raytracer)

# Set global C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(verilator HINTS $ENV{VERILATOR_ROOT} REQUIRED)
find_package(PkgConfig REQUIRED)

option(TESTS "Enable building of tests" ON)
option(DEMOS "Enable building of demos" ON)

# Enable testing
enable_testing()


function(add_verilated_test TEST_NAME SV_SRC CC_SRC TOP_MODULE_NAME)
  # Extract include directories from fp_core_sv target
  get_target_property(fp_core_includes fp_core_sv INTERFACE_INCLUDE_DIRECTORIES)
  get_target_property(fp_core_sources  fp_core_sv INTERFACE_SOURCES)

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

# Add component
add_subdirectory(hw/math/fp_core) # Exposes fp_core_sv

if (DEMOS)
add_subdirectory(hw/demos/axis_transfer)
endif()