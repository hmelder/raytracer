// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

#include <cstdint>
#include <random>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include <memory>

#include "gtest/gtest.h"

#include "Vcoprocessor.h"
#include "scene.h"
#include "test_helpers.h"
#include "vec3.h"

static const int CLOCK_PERIOD = 10;
static const int CLOCK_HALF_PERIOD = 5;

// Keep tlast from the previous clock cycle
static int m_axis_tlast_prev = 0;

static void tick(std::shared_ptr<Vcoprocessor> dut,
                 std::shared_ptr<VerilatedVcdC> m_trace) {
  // Save tlast
  m_axis_tlast_prev = dut->m_axis_tlast;

  // Cycle the clock
  dut->aclk ^= 1;
  dut->eval();
  m_trace->dump(dut->contextp()->time());
  dut->contextp()->timeInc(CLOCK_HALF_PERIOD);

  dut->aclk ^= 1;
  dut->eval();
  m_trace->dump(dut->contextp()->time());
  dut->contextp()->timeInc(CLOCK_HALF_PERIOD);
}
static void tick(std::shared_ptr<Vcoprocessor> dut,
                 std::shared_ptr<VerilatedVcdC> m_trace, int cycles) {
  for (int i = 0; i < cycles; i++) {
    tick(dut, m_trace);
  }
}

#pragma mark - Unit Test

namespace {

class CoprocessorTest : public testing::Test {};

TEST_F(CoprocessorTest, Basic) {
  auto context = std::make_unique<VerilatedContext>();
  std::shared_ptr<Vcoprocessor> dut =
      std::make_shared<Vcoprocessor>(context.get());
  std::shared_ptr<VerilatedVcdC> trace = std::make_shared<VerilatedVcdC>();

  int send_counter = 0;
  int recv_counter = 0;

  Verilated::traceEverOn(true);

  // Register trace object
  dut->trace(trace.get(), 10);
  trace->open("coprocessor_waveform.vcd");

  // Initial AXIS Configuration
  dut->s_axis_tvalid = 0;
  dut->s_axis_tlast = 0;
  dut->m_axis_tready = 0;

  // Reset Coprocessor
  dut->resetn = 0;     // Assert reset (active low)
  tick(dut, trace, 2); // Hold reset for 2 clock cycles
  dut->resetn = 1;     // Deassert reset
  tick(dut, trace);

  // Get Scene
  Scene scene(10.0f, 16.0f / 9.0f, 1.0f);
  uint32_t *serialised_scene = scene.serialised();

  // Send Camera Configuration
  dut->s_axis_tvalid = 1;
  while (send_counter < SCENE_PAYLOAD_SIZE) {
    if (dut->s_axis_tready) {
      dut->s_axis_tdata = serialised_scene[send_counter];

      if (send_counter == SCENE_PAYLOAD_SIZE - 1) {
        dut->s_axis_tlast = 1;
      }

      send_counter += 1;
    }
    tick(dut, trace);
  }
  dut->s_axis_tvalid = 0;
  dut->s_axis_tlast = 0;

  EXPECT_EQ(send_counter, SCENE_PAYLOAD_SIZE);

  // Receive Fragment
  dut->m_axis_tready = 1;
  int recv_cycles = 0;
  int x = 0;
  int y = 0;
  int image_width = int(scene.image_width);
  int image_height = int(scene.image_height);
  const int max_receive_cycles = 10000;
  bool is_last = dut->m_axis_tlast;
  while (!is_last && (recv_cycles < max_receive_cycles)) {
    if (dut->m_axis_tvalid) {
      recv_counter += 1;
      is_last = dut->m_axis_tlast;

      // Validation
      vec3 pixel_center = scene.pixel_00_loc + (x * scene.pixel_delta_u) +
                          (y * scene.pixel_delta_v);
      vec3 ray_direction = pixel_center - scene.camera_center;

      EXPECT_NEAR(FIX_2_FLOAT(dut->m_axis_tdata), ray_direction[0], 0.0005);

      // Image Coordinate Handling
      if (x == image_width - 1 && y == image_height - 1) { // Done
      } else if (x == image_width - 1) {
        x = 0;
        y += 1;
      } else {
        x += 1;
      }

      // Delay
      if (x == image_width - 1) {
        dut->m_axis_tready = 0;
        tick(dut, trace, 2);
        dut->m_axis_tready = 1;
      }
    }

    tick(dut, trace);
    recv_cycles += 1;
  }
  dut->m_axis_tready = 0;

  EXPECT_FALSE(recv_counter > image_width * image_height)
      << "Received more words in transaction than allowed";

  std::cout << "recv_cycles: " << recv_cycles << std::endl;
}

} // namespace