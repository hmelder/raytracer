// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

#include <verilated.h>
#include <verilated_vcd_c.h>

#include <gtest/gtest.h>

#include <memory>

#include "Vgoldschmidt_wrapper.h"

#define FP_IW 16
#define FP_QW 16
#define FP_2_POW_QW 65536
#define FP_WL 32

#define FLOAT_2_FIX(a) ((signed int)(a * FP_2_POW_QW))
#define FIX_2_FLOAT(a) ((float)((signed int)a) / FP_2_POW_QW)

namespace {

static const int CLOCK_PERIOD = 10;
static const int CLOCK_HALF_PERIOD = 5;

static void tick(std::shared_ptr<Vgoldschmidt_wrapper> dut,
                 std::shared_ptr<VerilatedVcdC> m_trace) {
  // Cycle the clock
  dut->clk ^= 1;
  dut->eval();
  m_trace->dump(Verilated::time());
  Verilated::timeInc(CLOCK_HALF_PERIOD);

  dut->clk ^= 1;
  dut->eval();
  m_trace->dump(Verilated::time());
  Verilated::timeInc(CLOCK_HALF_PERIOD);
}

class GoldschmidtTest : public testing::Test {};

TEST_F(GoldschmidtTest, SinglePipelineIteration) {
  std::shared_ptr<Vgoldschmidt_wrapper> dut =
      std::make_shared<Vgoldschmidt_wrapper>();
  std::shared_ptr<VerilatedVcdC> trace = std::make_shared<VerilatedVcdC>();

  Verilated::traceEverOn(true);

  // Register trace object
  dut->trace(trace.get(), 10);
  trace->open("goldschmidt_waveform.vcd");

  dut->resetn = 0; // Assert reset (active low)
  tick(dut, trace);
  dut->resetn = 1; // Deassert reset
  tick(dut, trace);

  float val = 591.6922f;
  float rsqrt_val = 1 / sqrtf(591.6922);
  float est = rsqrt_val * 0.5f;

  std::cout << "val: " << val << " rsqrt: " << rsqrt_val
            << " sqrt:" << sqrtf(val) << " est: " << est << std::endl;

  dut->in = FLOAT_2_FIX(val);
  dut->est = FLOAT_2_FIX(est);
  dut->start = 1;
  for (int i = 0; i < 10; i++) {
    tick(dut, trace); // Stage 0
    float rsqrt = FIX_2_FLOAT(dut->rsqrt);
    float sqrt = FIX_2_FLOAT(dut->sqrt);
    std::cout << "Valid: " << dut->valid << " rsqrt: " << rsqrt
              << " sqrt: " << sqrt << std::endl;
  }
}

} // namespace