// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

#include <verilated.h>
#include <verilated_vcd_c.h>

#include <memory>

#include "Vsfp_vec3_cross_wrapper.h"
#include "gtest/gtest.h"

namespace {

class SfpVec3CrossTest : public testing::Test {};

TEST_F(SfpVec3CrossTest, Basic) {
  std::unique_ptr<Vsfp_vec3_cross_wrapper> dut =
      std::make_unique<Vsfp_vec3_cross_wrapper>();

  dut->a[0] = 0xfffe8000; // -1.5
  dut->a[1] = 0xfffd8000; // -2.5
  dut->a[2] = 0xfffc8000; // -3.5

  dut->b[0] = 0xfffa8000; // -5.5
  dut->b[1] = 0x00068000; // 6.5
  dut->b[2] = 0x00078000; // 7.5

  dut->eval();

  EXPECT_EQ(dut->out[0], 0x40000);    // (-2.5 * 7.5) - (-3.5 * 6.5) = 4.0
  EXPECT_EQ(dut->out[1], 0x1E8000);   // (-3.5 * -5.5) - (-1.5 * 7.5) = 30.5
  EXPECT_EQ(dut->out[2], 0xffe88000); // (-1.5 * 6.5) - (-2.5 * -5.5) = -23.5
}

} // namespace