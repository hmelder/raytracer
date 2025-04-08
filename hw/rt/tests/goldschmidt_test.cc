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

static int32_t msb(uint32_t fp) { return int32_t(floorf(log2(fp))) - FP_QW; }

static int32_t initial_est(int32_t fp) {
  int32_t m = msb(fp);
  return FP_2_POW_QW / (sqrt(pow(2, m)) * 1.238982962);
}

std::vector<double> linrange(double start, double end, std::size_t num_points) {
  std::vector<double> result;

  // Handle edge cases
  if (num_points == 0) {
    return result; // Return an empty vector
  }

  if (num_points == 1) {
    result.push_back(start); // Return a vector with only the start value
    return result;
  }

  // Reserve space for efficiency
  result.reserve(num_points);

  // Calculate the step size.
  // Subtracting 1.0 ensures floating-point division.
  double step = (end - start) / (static_cast<double>(num_points) - 1.0);

  // Generate the points
  for (std::size_t i = 0; i < num_points; ++i) {
    result.push_back(start + static_cast<double>(i) * step);
  }

  return result;
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

  int iterations = 4;

  auto vec = linrange(FIX_2_FLOAT(0x10000), FIX_2_FLOAT(0x7FFFFFFF), 1000);
  float avg_rsqrt_err = 0;
  float avg_sqrt_err = 0;
  for (auto val : vec) {
    float rsqrt_val = 1 / sqrtf(val);
    float sqrt_val = sqrtf(val);
    int32_t val_fix = FLOAT_2_FIX(val);
    int32_t est_fix = initial_est(val_fix);
    float est = FIX_2_FLOAT(est_fix);

    dut->in = val_fix;
    dut->est = est_fix;
    dut->start = 1;
    for (int i = 0; i < 4 * iterations; i++) {
      tick(dut, trace); // Stage 0

      if (((i + 1) % 4 == 0) && (((i + 1) / 4) != (iterations - 1))) {
        dut->start = 1;
        dut->est = dut->rsqrt;
      } else {
        dut->start = 0;
      }
    }
    float rsqrt = FIX_2_FLOAT(dut->rsqrt);
    float sqrt = FIX_2_FLOAT(dut->sqrt);

    avg_sqrt_err += abs(sqrt - sqrtf(val));
    avg_rsqrt_err += abs(rsqrt - rsqrt_val);

    EXPECT_NEAR(rsqrt, rsqrt_val, 0.0001) << "with value " << val;
    EXPECT_NEAR(sqrt, sqrt_val, 0.01) << "with value " << val;
  }

  avg_rsqrt_err /= vec.size();
  avg_sqrt_err /= vec.size();

  std::cout << "avg_rsqrt_err: " << avg_rsqrt_err
            << " avg_sqrt_err: " << avg_sqrt_err << std::endl;
}

} // namespace