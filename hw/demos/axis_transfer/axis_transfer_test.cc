// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

#include <verilated.h>
#include <verilated_vcd_c.h>

#include <memory>

#include "Vaxis_transfer.h"
#include "gtest/gtest.h"

vluint64_t sim_time = 0;

static void tick(std::shared_ptr<Vaxis_transfer> dut, VerilatedVcdC *m_trace) {
  dut->aclk ^= 1;
  dut->eval();
  m_trace->dump(sim_time);
  sim_time++;

  dut->aclk ^= 1;
  dut->eval();
  m_trace->dump(sim_time);
  sim_time++;
}

namespace {

class AxisTransferTest : public testing::Test {};

TEST_F(AxisTransferTest, print) {
  std::shared_ptr<Vaxis_transfer> dut = std::make_shared<Vaxis_transfer>();

  Verilated::traceEverOn(true);

  VerilatedVcdC *m_trace = new VerilatedVcdC;
  dut->trace(m_trace, 5);
  m_trace->open("waveform.vcd");

  dut->aresetn = 0;
  tick(dut, m_trace);
  tick(dut, m_trace);
  dut->aresetn = 1;
  tick(dut, m_trace);

  int received = 0;
  dut->m_axis_tready = 1;
  std::cout << "P3\n" << 20 << ' ' << 20 << "\n255\n";
  while (!dut->m_axis_tlast) {
    tick(dut, m_trace);

    if (dut->m_axis_tvalid) {
      received += 1;
      u_int32_t pixel = dut->m_axis_tdata;
      u_int8_t r = pixel >> 24;
      u_int8_t g = pixel >> 16;
      u_int8_t b = 0;

      std::cout << unsigned(r) << ' ' << unsigned(g) << ' ' << unsigned(b)
                << '\n';
    }
  }
  dut->m_axis_tready = 0;

  std::cout << "received " << received << " pixels"
            << " \n";

  if (!received) {
    std::cout << "Not Received";
  }

  tick(dut, m_trace);

  m_trace->close();
  delete m_trace;
}

} // namespace