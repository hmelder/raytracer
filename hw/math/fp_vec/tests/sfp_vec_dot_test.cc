// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

#include <verilated.h>
#include <verilated_vcd_c.h>

#include <memory>

#include "Vsfp_vec_dot_wrapper.h"
#include "gtest/gtest.h"

#define fix2float(a) ((float)(a) / 65536.0)

namespace {

class SfpVecDotTest : public testing::Test {};

TEST_F(SfpVecDotTest, Basic) {
  std::unique_ptr<Vsfp_vec_dot_wrapper> dut =
      std::make_unique<Vsfp_vec_dot_wrapper>();

  dut->a[0] = 0x00180000; // 24.0
  dut->a[1] = 0x00000ccd; // 0.05
  dut->a[2] = 0xfffce000; // -3.125

  dut->b[0] = 0xfffc8000; // -3.5
  dut->b[1] = 0x000d0000; // 13.0
  dut->b[2] = 0x00000666; // 0.025

  dut->eval();
  EXPECT_NEAR(fix2float(signed(dut->out)), -83.428125, 0.0001);
}

} // namespace
