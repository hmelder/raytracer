// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

#include <verilated.h>
#include <verilated_vcd_c.h>

#include <memory>

#include "Vresize_down_test.h"
#include "gtest/gtest.h"

namespace {

class ResizeDownTest : public testing::Test {};

TEST_F(ResizeDownTest, NoClippingMax) {
  std::unique_ptr<Vresize_down_test> resize =
      std::make_unique<Vresize_down_test>();

  resize->in = 0xFFFFFF; // 255.99998474121094 in 16.16
  resize->should_clip = 1;
  resize->eval();

  EXPECT_EQ(resize->out, 0xFFFF); // 0.99609375 in 8.8 format
  EXPECT_EQ(resize->clipping, 0); // No clipping
}

TEST_F(ResizeDownTest, MinClipping) {
  std::unique_ptr<Vresize_down_test> resize =
      std::make_unique<Vresize_down_test>();

  resize->in = 0x0100ffff; // 3840.999984741211 in 16.16
  resize->should_clip = 1;
  resize->eval();

  // This would cause wrapping if not clipped
  EXPECT_EQ(resize->out, 0xFFFF); // 255.99609375
  EXPECT_EQ(resize->clipping, 1); // Clipping
}

TEST_F(ResizeDownTest, DiscardingFractionalZeros) {
  std::unique_ptr<Vresize_down_test> resize =
      std::make_unique<Vresize_down_test>();

  resize->in = 0xff00;
  resize->should_clip = 1;
  resize->eval();

  EXPECT_EQ(resize->out, 0xff);
  EXPECT_EQ(resize->clipping, 0); // Clipping
}
TEST_F(ResizeDownTest, FractionalPartZeroed) {
  std::unique_ptr<Vresize_down_test> resize =
      std::make_unique<Vresize_down_test>();

  resize->in = 0x00ff;
  resize->should_clip = 1;
  resize->eval();

  EXPECT_EQ(resize->out, 0x00);
  EXPECT_EQ(resize->clipping, 0); // Clipping
}

TEST_F(ResizeDownTest, NoClippingFractionalValue) {
  std::unique_ptr<Vresize_down_test> resize =
      std::make_unique<Vresize_down_test>();

  resize->in = 0x8000; // 0.5 in 16.16 format
  resize->should_clip = 1;
  resize->eval();

  EXPECT_EQ(resize->out, 0x80);   // 0.5 in 8.8 format
  EXPECT_EQ(resize->clipping, 0); // No clipping
}

TEST_F(ResizeDownTest, NoClippingSmallValue) {
  std::unique_ptr<Vresize_down_test> resize =
      std::make_unique<Vresize_down_test>();

  resize->in = 0x10000; // 1.0 in 16.16 format
  resize->should_clip = 1;
  resize->eval();

  EXPECT_EQ(resize->out, 0x100);  // 1.0 in 8.8 format
  EXPECT_EQ(resize->clipping, 0); // No clipping
}

// Wrapping

TEST_F(ResizeDownTest, WrappingIntDecreasing) {
  std::unique_ptr<Vresize_down_test> resize =
      std::make_unique<Vresize_down_test>();

  resize->in = 0x1000000;
  resize->should_clip = 0;
  resize->eval();

  EXPECT_EQ(resize->out, 0x00);
  EXPECT_EQ(resize->clipping, 1);
}

} // namespace