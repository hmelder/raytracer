// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

#include <sys/_types/_u_int32_t.h>
#include <sys/_types/_u_int8_t.h>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include <memory>

#include "Vgradient.h"
#include "gtest/gtest.h"

namespace {

class GradientTest : public testing::Test {};

TEST_F(GradientTest, imageTest) {
  std::unique_ptr<Vgradient> dut = std::make_unique<Vgradient>();
  const int width = 400;
  const int height = 200;
  std::cout << "P3\n" << width << ' ' << height << "\n255\n";
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      dut->x = x;
      dut->y = y;
      dut->eval();

      u_int32_t pixel = dut->pixel;
      u_int8_t r = pixel >> 24;
      u_int8_t g = pixel >> 16;
      u_int8_t b = 0;

      std::cout << unsigned(r) << ' ' << unsigned(g) << ' ' << unsigned(b)
                << '\n';
    }
  }
}

} // namespace