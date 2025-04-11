# Raytracer

It all started, when I stumbled upon [Ray Tracing in One Weekend](https://raytracing.github.io/books/RayTracingInOneWeekend.html), which is an excellent introduction to path tracing from the ground up.

After a couple of hours, I had a parallelized software implementation mostly based on the algorithms provided in the book.

During that time, I was studying at the National University of Singapore and taking EE4218 - Embedded Hardware System Design. The course syllabus included a term project, and we had the choice between a standard project, implementing a multi-level perceptron neural network (with one hidden layer), or a custom project on an FPGA.

So, I had the Xilinx KV260 Kit lying around, just waiting to be programmed.

## Current Status

The coprocessor generates rays, and sends out the ray direction (y coordinate) via AXIS. Software running on the KV260s CPU, located in `sw/mpsoc`, computes a basic gradient, applies gamma correction, and outputs the final image via UART.

Here as an overview of the repository contents:

- Supporting Libraries: `hw/math`
    - [fp_core](hw/math/fp_core): Unsigned and Signed Fixed-point arithmetic including clipping, and resizing
    - [fp_vec](hw/math/fp_vec): Modules operating on arrays of `sfp_if` or `ufp_if` instances of length `N`.
    - [goldschmidt.sv](hw/rt/goldschmidt.sv): Sqrt and reciprocal sqrt approximation using Goldschmidt's Algorithm and `fp_core`. 
- The Coprocessor (RTL): `hw/rt`
    - [coprocessor.sv](hw/rt/coprocessor.v): Top-level module. AXIS interface.
    - [rt_core.sv](hw/rt/rt_core.sv): Container for `rt_controller.sv` and `rt_rgu_5_stage.sv`.
    - [rt_controller.sv](hw/rt/rt_controller.sv): Generates coordinates, and controls *ray generation unit* (RGU)
    - [rt_rgu_5_stage.sv](hw/rt/rt_rgu_5_stage.sv`): Pipelined ray generation unit
    - [rt_alu.sv](hw/rt/rt_alu.sv): A fixed-point SIMD ALU
- The Coprocessor (HLS): `hw/hls`
    - Replica of the RTL coprocessor
        - [main_v1.cpp](hw/hls/main_v1.cpp): Initial implementation
        - [main.cpp](hw/hls/main.cpp): Optimised implementation

All modules have a `tests` subdirectory with Verilator tests, and SystemVerilog test benches. 

### Next Steps

- Reduce pipeline depth, by offloading more work onto the DSP
- Implement a ray-object intersection unit
    - BVH tree traversal
- Implement a shading unit
    - Shader attached to object in BVH tree?
- Output to HDMI

### Demo

This is a 64x32 "path-traced" gradient with rays generated on the FPGA:

<img src="resources/64x32_gradient.png" alt="drawing" width="100%"/>

- 8-bit RGB
- Gamma Correction
- Lerp from  #7FB2FF to #FFFFFF

#### Hardware Utilisation on the KV260

Vivado 2024.2 Synthesis Report:
```
Report Cell Usage: 
+------+----------------+------+
|      |Cell            |Count |
+------+----------------+------+
|1     |BUFG            |     1|
|2     |CARRY8          |    24|
|3     |DSP_ALU         |     8|
|4     |DSP_A_B_DATA    |     8|
|6     |DSP_C_DATA      |     8|
|7     |DSP_MULTIPLIER  |     8|
|8     |DSP_M_DATA      |     8|
|9     |DSP_OUTPUT      |     8|
|10    |DSP_PREADD      |     8|
|11    |DSP_PREADD_DATA |     8|
|12    |LUT1            |     1|
|13    |LUT2            |   175|
|14    |LUT3            |    11|
|15    |LUT4            |    19|
|16    |LUT5            |    41|
|17    |LUT6            |    35|
|18    |FDCE            |   227|
|19    |FDRE            |   174|
|20    |FDSE            |     1|
|21    |LD              |    35|
|22    |IBUF            |    36|
|23    |OBUF            |    35|
+------+----------------+------+
```

## Building

### Dependencies

- Clang
- Verilator
- Google Test (Make sure that `pkg-config -cflags gtest` works)

### Build
```
cmake -B build -G Ninja
ninja -C build
```

### Test

```
ninja -C build test
```