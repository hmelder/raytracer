
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

#include <verilated.h>
#include <verilated_vcd_c.h>

#include <memory>

#include "Vufp_mul_test.h"
#include "gtest/gtest.h"

namespace {

class UfpMulTest : public testing::Test {};

TEST_F(UfpMulTest, test) {
  std::unique_ptr<Vufp_mul_test> mul = std::make_unique<Vufp_mul_test>();

  mul->x = 0x20000;
  mul->y = 0x80000000;
  mul->should_clip = 0;
  mul->eval();

  EXPECT_EQ(mul->out, 0x0);
  EXPECT_EQ(mul->clipping, 0); // No clipping
}

TEST_F(UfpMulTest, test2) {
  std::unique_ptr<Vufp_mul_test> mul = std::make_unique<Vufp_mul_test>();

  mul->x = 0x20000;
  mul->y = 0x70000000;
  mul->should_clip = 0;
  mul->eval();

  EXPECT_EQ(mul->out, 0xe0000000);
  EXPECT_EQ(mul->clipping, 0); // No clipping
}

} // namespace