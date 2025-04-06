cmake_minimum_required(VERSION 3.30)
project(raytracer)

# Set global C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(verilator HINTS $ENV{VERILATOR_ROOT} REQUIRED)
find_package(PkgConfig REQUIRED)

option(TESTS "Enable building of tests" ON)
option(DEMOS "Enable building of demos" OFF)

# Enable testing
enable_testing()

# Add component
add_subdirectory(hw/math/fp_core) # Exposes fp_core_sv
add_subdirectory(hw/math/fp_vec) # Exposes fp_vec_sv
add_subdirectory(hw/rt) # Exposes rt_sv
add_subdirectory(hw/coprocessor) # Exposes coprocessor_sv

if (DEMOS)
add_subdirectory(hw/demos/axis_transfer)
endif()