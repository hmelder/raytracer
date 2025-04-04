// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

#include <verilated.h>
#include <verilated_vcd_c.h>

#include <memory>

#include "Vsfp_vec_add_s_wrapper.h"
#include "gtest/gtest.h"

namespace {

class SfpVecAddSTest : public testing::Test {};

TEST_F(SfpVecAddSTest, Basic) {
  std::unique_ptr<Vsfp_vec_add_s_wrapper> dut =
      std::make_unique<Vsfp_vec_add_s_wrapper>();

  dut->a[0] = 0x10000;
  dut->a[1] = 0x20000;
  dut->a[2] = 0x30000;
  dut->s = 0xfffe8000; // -1.5 in Q16.16

  dut->eval();
  EXPECT_EQ(dut->o[0], 0xffff8000); // -0.5
  EXPECT_EQ(dut->o[1], 0x00008000); // 0.5
  EXPECT_EQ(dut->o[2], 0x00018000); // 1.5
}

} // namespace
