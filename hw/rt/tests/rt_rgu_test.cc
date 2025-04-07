// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

#include <verilated.h>
#include <verilated_vcd_c.h>

#include <gtest/gtest.h>

#include <memory>

#include "scene.h"
#include "test_helpers.h"
#include "vec3.h"

#include "Vrt_rgu_wrapper.h"

static const int CLOCK_PERIOD = 10;
static const int CLOCK_HALF_PERIOD = 5;

static void tick(std::shared_ptr<Vrt_rgu_wrapper> dut,
                 std::shared_ptr<VerilatedVcdC> m_trace) {
  // Cycle the clock
  dut->clk ^= 1;
  dut->eval();
  m_trace->dump(Verilated::time());
  Verilated::timeInc(CLOCK_HALF_PERIOD);

  dut->clk ^= 1;
  dut->eval();
  m_trace->dump(Verilated::time());
  Verilated::timeInc(CLOCK_HALF_PERIOD);
}

namespace {

class RtRGUTest : public testing::Test {};

TEST_F(RtRGUTest, SinglePipelineIteration) {
  std::shared_ptr<Vrt_rgu_wrapper> dut = std::make_shared<Vrt_rgu_wrapper>();
  std::shared_ptr<VerilatedVcdC> trace = std::make_shared<VerilatedVcdC>();

  Verilated::traceEverOn(true);

  // Register trace object
  dut->trace(trace.get(), 10);
  trace->open("rgu_waveform.vcd");

  dut->resetn = 0; // Assert reset (active low)
  tick(dut, trace);
  dut->resetn = 1; // Deassert reset
  tick(dut, trace);

  // Get Scene
  Scene scene(10.0f, 16.0f / 9.0f, 1.0f);
  struct Scene::camera cam = scene.raw_camera();
  for (int i = 0; i < 3; i++) {
    printf("%08x\n", cam.pixel_00_loc[i]);
  }
  for (int i = 0; i < 3; i++) {
    printf("%08x\n", cam.pixel_delta_u[i]);
  }
  for (int i = 0; i < 3; i++) {
    printf("%08x\n", cam.pixel_delta_v[i]);
  }
  for (int i = 0; i < 3; i++) {
    printf("%08x\n", cam.camera_center[i]);
  }

  ASSIGN_RAW_VEC(dut->pixel_00_loc, cam.pixel_00_loc)
  ASSIGN_RAW_VEC(dut->pixel_delta_u, cam.pixel_delta_u)
  ASSIGN_RAW_VEC(dut->pixel_delta_v, cam.pixel_delta_v)
  ASSIGN_RAW_VEC(dut->camera_center, cam.camera_center)

  int x = 0;
  int y = 1;

  dut->y = y << FP_QW;
  dut->start = 1;
  //  Saturate pipeline
  for (int i = 0; i < 4; i++) {
    dut->x = i << FP_QW;
    EXPECT_EQ(dut->valid, 0);
    tick(dut, trace);
  }
  dut->start = 0;

  // Validation
  for (int i = 0; i < 4; i++) {
    tick(dut, trace);
    EXPECT_EQ(dut->valid, 1);
    // Validation
    vec3 pixel_center = scene.pixel_center(x + i, y);
    vec3 ray_direction = pixel_center - scene.camera_center;

    EXPECT_VEC_NEAR(dut->ray_direction, ray_direction, 0.0005);
    for (int j = 0; j < 3; j++) {
      printf("%d: %08x\n", i, dut->ray_direction[j]);
    }
  }
}

} // namespace