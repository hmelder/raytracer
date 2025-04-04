// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

#include <verilated.h>
#include <verilated_vcd_c.h>

#include <memory>

#include "Vclip_unsigned_wrapper.h"
#include "gtest/gtest.h"

namespace {

class ClippingTest : public testing::Test {};

TEST_F(ClippingTest, max_minus_one) {
  std::unique_ptr<Vclip_unsigned_wrapper> clipping =
      std::make_unique<Vclip_unsigned_wrapper>();
  clipping->in = 0xFFFE;
  clipping->eval();
  EXPECT_EQ(clipping->out, 0xFFFE);
  EXPECT_EQ(clipping->clipping, 0);
}

TEST_F(ClippingTest, min_value) {
  std::unique_ptr<Vclip_unsigned_wrapper> clipping =
      std::make_unique<Vclip_unsigned_wrapper>();
  clipping->in = 0x0000;
  clipping->eval();
  EXPECT_EQ(clipping->out, 0x0000);
  EXPECT_EQ(clipping->clipping, 0);
}

TEST_F(ClippingTest, max_value) {
  std::unique_ptr<Vclip_unsigned_wrapper> clipping =
      std::make_unique<Vclip_unsigned_wrapper>();
  clipping->in = (1 << 20) - 1; // Assuming INW=20
  clipping->eval();
  EXPECT_EQ(clipping->out, 0xFFFF); // OUTW=16
  EXPECT_EQ(clipping->clipping, 1);
}

TEST_F(ClippingTest, first_clipped_value) {
  std::unique_ptr<Vclip_unsigned_wrapper> clipping =
      std::make_unique<Vclip_unsigned_wrapper>();
  clipping->in = 0x10000; // First value exceeding 16-bit
  clipping->eval();
  EXPECT_EQ(clipping->out, 0xFFFF);
  EXPECT_EQ(clipping->clipping, 1);
}

TEST_F(ClippingTest, first_non_clipped_value) {
  std::unique_ptr<Vclip_unsigned_wrapper> clipping =
      std::make_unique<Vclip_unsigned_wrapper>();
  clipping->in = 0xFFFF; // Largest 16-bit value
  clipping->eval();
  EXPECT_EQ(clipping->out, 0xFFFF);
  EXPECT_EQ(clipping->clipping, 0);
}

TEST_F(ClippingTest, midrange_clipped_value) {
  std::unique_ptr<Vclip_unsigned_wrapper> clipping =
      std::make_unique<Vclip_unsigned_wrapper>();
  clipping->in = 0x18000; // Well into the clipped range
  clipping->eval();
  EXPECT_EQ(clipping->out, 0xFFFF);
  EXPECT_EQ(clipping->clipping, 1);
}

} // namespace