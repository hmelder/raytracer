// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder


`include "parameters.vh"

module rt_rgu_tb;

  // 100 Mhz clock frequency, thus 10 ns per clock period
  parameter int CLOCK_PERIOD = 10;  // ns
  parameter int CLOCK_HALF_PERIOD = CLOCK_PERIOD / 2;


  logic clk;  // Synchronous clock
  logic resetn;  // System reset, active low
  logic stall = 0;

  // Clock Generation
  initial begin
    clk = 1'b0;
    forever begin
      #(CLOCK_HALF_PERIOD);
      clk = ~clk;
    end
  end

  /*
   Payload for width = 10, aspect ratio = 16/9, focal length = 1.0
   0x00071c71
   0x00280000
   0x00140000
   0x00040000
   0x00080000
   0x02f60000
   0x00100000
   0x00000000
   0x00000000
   0x00000000
   0xfff80000
   0x00000000
   0xfff80000
   0x00040000
   0xfffc0000
   0x00000000
   0x00000000
   0x00000000
   0x00019999
   0x00000000
   0x00000000
   0x00000000
   0xfffe6667
   0x00000000
   0xfff8cccd
   0x00033333
   0xfffc0000
  */

  logic start;
  logic valid;
  logic [31:0] pixel_00_loc[3] = '{32'hfff8cccd, 32'h00033333, 32'hfffc0000};
  logic [31:0] pixel_delta_u[3] = '{32'h00019999, 0, 0};
  logic [31:0] pixel_delta_v[3] = '{0, 32'hfffe6667, 0};
  logic [31:0] camera_center[3] = '{0, 0, 0};
  logic [31:0] ray_origin[3];
  logic [31:0] ray_direction[3];

  logic [31:0] x, y;

  // For test values
  logic [31:0] expected[4][3];
  logic [31:0] result  [4][3];

  // Test Stimulus and Checking
  initial begin
    $display("Starting Testbench for 'rt_rgu_5_stage'");
    $dumpfile("rt_rgu_tb.vcd");
    $readmemh("rt_rgu_tb_expected.mem", expected);
    $dumpvars(0, rt_rgu_tb);

    #(CLOCK_HALF_PERIOD);  // to make inputs and capture from testbench not aligned with clock edges
    // Reset Coprocessor
    resetn = 1'b0;  // Assert reset (active low)
    #(CLOCK_PERIOD);
    resetn = 1'b1;  // Deassert reset
    #(CLOCK_PERIOD);

    y = 1 << 18;
    start = 1;
    //  Saturate pipeline
    for (int i = 0; i < 4; i++) begin
        x = i << 18;
        assert(valid == 0);
        #(CLOCK_PERIOD);
    end
    start = 0;

      // Validation
      for (int i = 0; i < 4; i++) begin
        #(CLOCK_PERIOD);
        assert(valid == 1);
        // Check ray_direction
        for (int j = 0; j < 3; j++) begin
            assert(ray_direction[j] == expected[i][j]);
        end
      end
      
      $finish;
  end

  rt_rgu_wrapper dut (
      .clk(clk),
      .resetn(resetn),
      .start(start),
      .stall(stall),
      .valid(valid),
      .pixel_00_loc(pixel_00_loc),
      .pixel_delta_u(pixel_delta_u),
      .pixel_delta_v(pixel_delta_v),
      .camera_center(camera_center),
      .x(x),
      .y(y),
      .ray_origin(ray_origin),
      .ray_direction(ray_direction)
  );

endmodule
