cmake_minimum_required(VERSION 3.30)

project(axis_transfer)

find_package(verilator HINTS $ENV{VERILATOR_ROOT} REQUIRED)
find_package(PkgConfig REQUIRED)

pkg_check_modules(gtest_main REQUIRED IMPORTED_TARGET gtest_main)


add_executable(Vadder hw/adder_test.cc)
target_link_libraries(Vadder PRIVATE PkgConfig::gtest_main)
set_property(TARGET Vadder PROPERTY CXX_STANDARD 17)

verilate(Vadder SOURCES hw/adder.sv)


# enable testing functionality
enable_testing()

add_test(
  NAME Vadder_test
  COMMAND $<TARGET_FILE:Vadder>
  )