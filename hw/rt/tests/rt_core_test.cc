// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

#include <verilated.h>
#include <verilated_vcd_c.h>

#include <gtest/gtest.h>

#include <memory>

#include "scene.h"
#include "test_helpers.h"
#include "vec3.h"

#include "Vrt_core.h"

static const int CLOCK_PERIOD = 10;
static const int CLOCK_HALF_PERIOD = 5;

static void tick(std::shared_ptr<Vrt_core> dut,
                 std::shared_ptr<VerilatedVcdC> m_trace) {
  // Cycle the clock
  dut->clk ^= 1;
  dut->eval();
  m_trace->dump(dut->contextp()->time());
  Verilated::timeInc(CLOCK_HALF_PERIOD);

  dut->clk ^= 1;
  dut->eval();
  m_trace->dump(dut->contextp()->time());
  dut->contextp()->timeInc(CLOCK_HALF_PERIOD);
}

namespace {

class RtCoreTest : public testing::Test {};

TEST_F(RtCoreTest, NoStall) {
  auto context = std::make_unique<VerilatedContext>();
  std::shared_ptr<Vrt_core> dut = std::make_shared<Vrt_core>(context.get());
  std::shared_ptr<VerilatedVcdC> trace = std::make_shared<VerilatedVcdC>();

  Verilated::traceEverOn(true);
  // Register trace object
  dut->trace(trace.get(), 10);
  trace->open("RtCoreTest_NoStall.vcd");

  // Get Scene
  Scene scene(10.0f, 16.0f / 9.0f, 1.0f);
  struct Scene::camera cam = scene.raw_camera();

  dut->resetn = 0; // Assert reset (active low)
  tick(dut, trace);
  dut->resetn = 1; // Deassert reset
  tick(dut, trace);

  dut->image_width = cam.image_width >> FP_QW;
  dut->image_height = cam.image_height >> FP_QW;

  ASSIGN_RAW_VEC(dut->pixel_00_loc, cam.pixel_00_loc)
  ASSIGN_RAW_VEC(dut->pixel_delta_u, cam.pixel_delta_u)
  ASSIGN_RAW_VEC(dut->pixel_delta_v, cam.pixel_delta_v)
  ASSIGN_RAW_VEC(dut->camera_center, cam.camera_center)

  // Control
  dut->start = 0;
  dut->stall = 0;

  tick(dut, trace);

  // rt_controller state : IDLE
  EXPECT_EQ(dut->valid, 0);
  EXPECT_EQ(dut->last, 0);

  dut->start = 1;
  // rt_controller state : READY
  for (int i = 0; i < 5; i++) {
    tick(dut, trace);
    EXPECT_EQ(dut->valid, 0);
    EXPECT_EQ(dut->last, 0);
  }

  int image_width = dut->image_width;
  int image_height = dut->image_height;
  for (int h = 0; h < dut->image_height; h++) {
    for (int w = 0; w < dut->image_width; w++) {
      tick(dut, trace);
      EXPECT_EQ(dut->valid, 1);

      if (w == (image_width - 1) && (h == (image_height - 1))) {
        EXPECT_EQ(dut->last, 1);
      } else {
        EXPECT_EQ(dut->last, 0);
      }
    }
  }
}

TEST_F(RtCoreTest, Stall) {
  auto context = std::make_unique<VerilatedContext>();
  std::shared_ptr<Vrt_core> dut = std::make_shared<Vrt_core>(context.get());
  std::shared_ptr<VerilatedVcdC> trace = std::make_shared<VerilatedVcdC>();

  Verilated::traceEverOn(true);
  // Register trace object
  dut->trace(trace.get(), 10);
  trace->open("RtCoreTest_Stall.vcd");

  // Get Scene
  Scene scene(10.0f, 16.0f / 9.0f, 1.0f);
  struct Scene::camera cam = scene.raw_camera();

  dut->resetn = 0; // Assert reset (active low)
  tick(dut, trace);
  dut->resetn = 1; // Deassert reset
  tick(dut, trace);

  dut->image_width = cam.image_width >> FP_QW;
  dut->image_height = cam.image_height >> FP_QW;

  ASSIGN_RAW_VEC(dut->pixel_00_loc, cam.pixel_00_loc)
  ASSIGN_RAW_VEC(dut->pixel_delta_u, cam.pixel_delta_u)
  ASSIGN_RAW_VEC(dut->pixel_delta_v, cam.pixel_delta_v)
  ASSIGN_RAW_VEC(dut->camera_center, cam.camera_center)

  // Control
  dut->start = 0;
  dut->stall = 0;

  tick(dut, trace);

  // rt_controller state : IDLE
  EXPECT_EQ(dut->valid, 0);
  EXPECT_EQ(dut->last, 0);

  dut->start = 1;
  // rt_controller state : READY
  for (int i = 0; i < 5; i++) {
    tick(dut, trace);
    dut->start = 0;
    EXPECT_EQ(dut->valid, 0);
    EXPECT_EQ(dut->last, 0);
  }

  int image_width = dut->image_width;
  int image_height = dut->image_height;
  for (int h = 0; h < dut->image_height;) {
    for (int w = 0; w < dut->image_width;) {
      tick(dut, trace);
      EXPECT_EQ(dut->valid, 1);
      // Validation
      vec3 pixel_center = scene.pixel_center(w, h);
      vec3 ray_direction = pixel_center - scene.camera_center;

      EXPECT_NEAR(FIX_2_FLOAT(dut->pixel), ray_direction[0], 0.0005);

      if (w == (image_width - 1) && (h == (image_height - 1))) {
        dut->stall = 1;
        tick(dut, trace);
        tick(dut, trace);
        dut->stall = 0;
        EXPECT_EQ(dut->last, 1);
      } else {
        EXPECT_EQ(dut->last, 0);
      }

      if (w == image_width / 2) {
        dut->stall = 1;
        tick(dut, trace);
        tick(dut, trace);
        dut->stall = 0;
      }

      w++;
    }
    h++;
  }
}

} // namespace