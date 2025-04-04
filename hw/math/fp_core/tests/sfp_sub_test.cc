#include <verilated.h>
#include <verilated_vcd_c.h>

#include <memory>

#include "Vsfp_sub_wrapper.h"
#include "gtest/gtest.h"

namespace {

class SfpSubTest : public testing::Test {};

TEST_F(SfpSubTest, Basic) {
  std::unique_ptr<Vsfp_sub_wrapper> dut = std::make_unique<Vsfp_sub_wrapper>();

  dut->x = 0xffff0000; // -1.0
  dut->y = 0x00008000; // 0.5
  dut->should_clip = 1;
  dut->eval();

  EXPECT_EQ(dut->out, 0xfffe8000); // -1.5
  EXPECT_EQ(dut->clipping, 0);     // No clipping
}

} // namespace