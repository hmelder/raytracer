// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

#include <verilated.h>
#include <verilated_vcd_c.h>

#include <memory>

#include "Vsfp_vec_lerp_wrapper.h"
#include "gtest/gtest.h"

namespace {

class SfpVecLerpTest : public testing::Test {};

TEST_F(SfpVecLerpTest, SimpleLerpPositive) {
  std::unique_ptr<Vsfp_vec_lerp_wrapper> dut =
      std::make_unique<Vsfp_vec_lerp_wrapper>();

  // 0.0, 0.25, 0.5, 0.75, 1.0 in Q16.16
  const int norm_vals_l = 5;
  const uint32_t norm_vals[norm_vals_l] = {0x0, 0x00004000, 0x00008000,
                                           0x0000c000, 0x00010000};

  // (1-0) * 0.25 + 0 * 0.5 = 0.25
  // (1-0.25) * 0.25 + 0.25 * 0.5 = 0.3125
  // (1-0.5) * 0.25 + 0.5 * 0.5 = 0.375
  // (1-0.75) * 0.25 + 0.75 * 0.5 = 0.4375
  // (1-1) * 0.25 + 1 * 0.5 = 0.5
  const uint32_t lerp_result_0[norm_vals_l] = {0x4000, 0x5000, 0x6000, 0x7000,
                                               0x8000};

  // (1-0) * 0.5 + 0 * 0.75 = 0.5
  // (1-0.25) * 0.5 + 0.25 * 0.75 = 0.5625
  // (1-0.5) * 0.5 + 0.5 * 0.75 = 0.625
  // (1-0.75) * 0.5 + 0.75 * 0.75 = 0.6875
  // (1-1) * 0.5 + 1 * 0.75 = 0.75
  const uint32_t lerp_result_1[norm_vals_l] = {0x8000, 0x9000, 0xa000, 0xb000,
                                               0xc000};

  // (1-0) * 0.5 + 0 * 1.0 = 0.5
  // (1-0.25) * 0.5 + 0.25 * 1.0 = 0.625
  // (1-0.5) * 0.5 + 0.5 * 1.0 = 0.75
  // (1-0.75) * 0.5 + 0.75 * 1.0 = 0.875
  // (1-1) * 0.5 + 1 * 1.0 = 1.0
  const uint32_t lerp_result_2[norm_vals_l] = {0x8000, 0xa000, 0xc000, 0xe000,
                                               0x10000};

  dut->a[0] = 0x00004000; // 0.25
  dut->a[1] = 0x00008000; // 0.5
  dut->a[2] = 0x00008000; // 0.5

  dut->b[0] = 0x00008000; // 0.5
  dut->b[1] = 0x0000c000; // 0.75
  dut->b[2] = 0x10000;    // 1.0

  for (int i = 0; i < norm_vals_l; i++) {
    dut->norm[0] = dut->norm[1] = dut->norm[2] = norm_vals[i];
    dut->eval();

    EXPECT_EQ(dut->out[0], lerp_result_0[i]);
    EXPECT_EQ(dut->out[1], lerp_result_1[i]);
    EXPECT_EQ(dut->out[2], lerp_result_2[i]);
  }
}

} // namespace