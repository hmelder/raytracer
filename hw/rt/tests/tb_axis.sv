`timescale 1ns / 1ps

// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

module tb_axis;

  // 100 Mhz clock frequency, thus 10 ns per clock period
  parameter int CLOCK_PERIOD = 10;  // ns
  parameter int CLOCK_HALF_PERIOD = CLOCK_PERIOD / 2;


  reg           aclk;  // Synchronous clock
  reg           aresetn;  // System reset, active low

  // AXIS Slave (Input)
  wire          s_axis_tready;  // Ready to accept data in
  reg  [31 : 0] s_axis_tdata;  // Data in
  reg           s_axis_tlast;  // Optional data in qualifier
  reg           s_axis_tvalid;  // Data in is valid

  // AXIS Master (Output)
  wire          m_axis_tvalid;  // Data out is valid
  wire [31 : 0] m_axis_tdata;  // Data out
  wire          m_axis_tlast;  // Optional data out qualifier
  reg           m_axis_tready;  // Connected slave device is ready to accept data out

  // DUT Configuration
  coprocessor DUT (
      .aclk  (aclk),
      .resetn(resetn),

      .s_axis_tready(s_axis_tready),
      .s_axis_tdata (s_axis_tdata),
      .s_axis_tlast (s_axis_tlast),
      .s_axis_tvalid(s_axis_tvalid),

      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_tdata (m_axis_tdata),
      .m_axis_tlast (m_axis_tlast),
      .m_axis_tready(m_axis_tready)
  );


  // Clock Generation
  initial begin
    aclk = 1'b0;
    forever begin
      #(CLOCK_HALF_PERIOD);
      aclk = ~aclk;
    end
  end

  // Save tlast from the previous clock cycle
  reg m_axis_tlast_prev = 1'b0;
  always @(posedge aclk) m_axis_tlast_prev <= m_axis_tlast;

  int send_counter = 0;
  int recv_counter = 0;

  parameter SCENE_PAYLOAD_SIZE = 27;
  parameter EXPECTED_DATA_SIZE = 32 * 32;
  reg [31:0] config_mem[SCENE_PAYLOAD_SIZE];
  reg [31:0] expected_pixels[EXPECTED_DATA_SIZE];

  // Test Stimulus and Checking
  initial begin
    $display("Starting Testbench for 'raytracer_axis'");
    $readmemh("data/camera.mem", config_mem);
    $readmemh("data/pixels.mem", expected_pixels);
    $dumpfile("tb_axis.vcd");
    $dumpvars(0, tb_axis);

    #(CLOCK_HALF_PERIOD);  // to make inputs and capture from testbench not aligned with clock edges

    // Initial AXIS Configuration
    s_axis_tvalid = 1'b0;
    s_axis_tlast = 1'b0;
    m_axis_tready = 1'b0;

    // Reset Coprocessor
    aresetn = 1'b0;  // Assert reset (active low)
    #(CLOCK_PERIOD * 2);  // Hold reset for 2 clock cycles
    aresetn = 1'b1;  // Deassert reset

    // Send Camera Configuration
    s_axis_tvalid = 1'b1;  // Signal coprocessor that we are willing to send data
    while (send_counter < SCENE_PAYLOAD_SIZE) begin
      if (s_axis_tready) begin
        s_axis_tdata = config_mem[send_counter];

        if (send_counter == SCENE_PAYLOAD_SIZE - 1) begin
          s_axis_tlast = 1'b1;
        end

        send_counter += 1;
      end

      #(CLOCK_PERIOD);
    end
    s_axis_tvalid = 1'b0;
    s_axis_tlast  = 1'b0;

    // Receive Fragment
    // TODO: Change once we have integratred the actual renderer
    m_axis_tready = 1'b1;
    // Receive data until the falling edge of M_AXIS_TLAST
    while (m_axis_tlast | ~m_axis_tlast_prev) begin
      if (m_axis_tvalid) begin
        // TODO: change once we send actual pixels
        $display("%h", m_axis_tdata);
        assert (m_axis_tdata == expected_pixels[recv_counter])
        else
          $error(
              "Error: Received data (0x%h) does not match expected data (0x%h) at index %0d",
              m_axis_tdata,
              expected_pixels[recv_counter],
              recv_counter
          );
        recv_counter = recv_counter + 1;
      end

      if (recv_counter > EXPECTED_DATA_SIZE) begin
        $fatal(0, "Received more words in transaction than allowed: %d > %d", recv_counter,
               EXPECTED_DATA_SIZE);
      end
      #(CLOCK_PERIOD);
    end
    m_axis_tready = 1'b0;

    $finish;
  end

endmodule

