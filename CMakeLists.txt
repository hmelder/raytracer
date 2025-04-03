cmake_minimum_required(VERSION 3.30)
project(raytracer)

# Set global C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(verilator HINTS $ENV{VERILATOR_ROOT} REQUIRED)
find_package(PkgConfig REQUIRED)

# Enable testing
enable_testing()

# Add the hw/tests subdirectory
add_subdirectory(hw/tests)