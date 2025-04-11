// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

`include "parameters.vh"

module rt_rgu_wrapper (
    // Clock and Reset
    input logic clk,
    input logic resetn,

    // Control Interface
    input  logic start,  // Start calculation for one ray
    input  logic stall,
    output logic valid,  // Calculation finished, output is valid

    input logic [FP_WL-1:0] pixel_00_loc [3],
    input logic [FP_WL-1:0] pixel_delta_u[3],
    input logic [FP_WL-1:0] pixel_delta_v[3],
    input logic [FP_WL-1:0] camera_center[3],

    // Image Coordinates
    input logic [COORDINATE_BITS-1:0] x,
    input logic [COORDINATE_BITS-1:0] y,

    // Ray (Origin, Direction)
    output logic [FP_WL-1:0] ray_origin[3],
    output logic [FP_WL-1:0] ray_direction[3]
);

  // Wrap raw fix point values into the sfp interface
  sfp_if #(
      .IW(FP_IW),
      .QW(FP_QW)
  )
      ray_origin_fp[3] (), ray_direction_fp[3] ();

  genvar i;
  generate
    for (i = 0; i < 3; i++) begin : gen_sub
      assign ray_origin[i] = ray_origin_fp[i].val;
      assign ray_direction[i] = ray_direction_fp[i].val;
    end
  endgenerate

  // Instantiate ray generation unit
  rt_rgu_5_stage rgu (
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
      .ray_origin(ray_origin_fp),
      .ray_direction(ray_direction_fp)
  );

endmodule

