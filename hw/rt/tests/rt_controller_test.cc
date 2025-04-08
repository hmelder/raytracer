// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

#include <verilated.h>
#include <verilated_vcd_c.h>

#include <gtest/gtest.h>

#include <memory>

#include "scene.h"
#include "test_helpers.h"
#include "vec3.h"

#include "Vrt_controller.h"

static const int CLOCK_PERIOD = 10;
static const int CLOCK_HALF_PERIOD = 5;

static void tick(std::shared_ptr<Vrt_controller> dut,
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

class RtControllerTest : public testing::Test {};

TEST_F(RtControllerTest, OnebyOneImage) {
  auto context = std::make_unique<VerilatedContext>();
  std::shared_ptr<Vrt_controller> dut =
      std::make_shared<Vrt_controller>(context.get());
  std::shared_ptr<VerilatedVcdC> trace = std::make_shared<VerilatedVcdC>();

  Verilated::traceEverOn(true);

  // Register trace object
  dut->trace(trace.get(), 10);
  trace->open("RtControllerTest_OneByOneImage.vcd");

  dut->resetn = 0; // Assert reset (active low)
  tick(dut, trace);
  dut->resetn = 1; // Deassert reset
  tick(dut, trace);

  // state: IDLE
  EXPECT_EQ(dut->rgu_start, 0);
  EXPECT_EQ(dut->x, 0);
  EXPECT_EQ(dut->y, 0);

  dut->image_width = 1;
  dut->image_height = 1;
  dut->stall = 0;
  dut->start = 1;
  tick(dut, trace);

  // state: READY
  EXPECT_EQ(dut->last, 0);
  EXPECT_EQ(dut->rgu_start, 1);
  EXPECT_EQ(dut->x, 0);
  EXPECT_EQ(dut->y, 0);

  // state: DRAIN
  for (int i = 0; i < 3; i++) {
    tick(dut, trace);
    EXPECT_EQ(dut->last, 0);
    EXPECT_EQ(dut->rgu_start, 0);
  }

  tick(dut, trace);
  EXPECT_EQ(dut->last, 1);
  EXPECT_EQ(dut->rgu_start, 0);

  tick(dut, trace);
  EXPECT_EQ(dut->last, 0);
  EXPECT_EQ(dut->rgu_start, 0);
}

TEST_F(RtControllerTest, LargeImage) {
  auto context = std::make_unique<VerilatedContext>();
  auto dut = std::make_shared<Vrt_controller>(context.get());
  auto trace = std::make_shared<VerilatedVcdC>();

  Verilated::traceEverOn(true);

  // Register trace object
  dut->trace(trace.get(), 10);
  trace->open("RtControllerTest_LargeImage.vcd");

  dut->resetn = 0; // Assert reset (active low)
  tick(dut, trace);
  dut->resetn = 1; // Deassert reset
  tick(dut, trace);

  // state: IDLE
  EXPECT_EQ(dut->rgu_start, 0);
  EXPECT_EQ(dut->x, 0);
  EXPECT_EQ(dut->y, 0);

  dut->image_width = 5;
  dut->image_height = 2;
  dut->stall = 0;
  dut->start = 1;

  for (int h = 0; h < dut->image_height; h++) {
    for (int w = 0; w < dut->image_width; w++) {
      tick(dut, trace);
      EXPECT_EQ(dut->rgu_start, 1);
      EXPECT_EQ(dut->x, w);
      EXPECT_EQ(dut->y, h);
      EXPECT_EQ(dut->last, 0);
    }
  }

  // state: DRAIN
  for (int i = 0; i < 3; i++) {
    tick(dut, trace);
    EXPECT_EQ(dut->last, 0);
    EXPECT_EQ(dut->rgu_start, 0);
  }

  tick(dut, trace);
  EXPECT_EQ(dut->last, 1);
  EXPECT_EQ(dut->rgu_start, 0);

  tick(dut, trace);
  EXPECT_EQ(dut->last, 0);
  EXPECT_EQ(dut->rgu_start, 0);
}

} // namespace