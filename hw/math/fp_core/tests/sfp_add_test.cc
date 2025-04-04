// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

#include <verilated.h>
#include <verilated_vcd_c.h>

#include <memory>

#include "Vsfp_add_wrapper.h"
#include "gtest/gtest.h"

namespace {

class SfpAddTest : public testing::Test {};

TEST_F(SfpAddTest, Basic) {
  std::unique_ptr<Vsfp_add_wrapper> dut = std::make_unique<Vsfp_add_wrapper>();

  dut->x = 0xffff0000; // -1.0
  dut->y = 0x00008000; // 0.5
  dut->should_clip = 1;
  dut->eval();

  EXPECT_EQ(dut->out, 0xffff8000); // -0.5
  EXPECT_EQ(dut->clipping, 0);     // No clipping
}

} // namespace