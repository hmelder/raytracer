// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

`include "parameters.vh"

module rt_core (
    input logic clk,
    input logic resetn,

    input logic start,
    input logic stall,

    output logic valid,
    output logic last,
    output logic [FP_WL -1 : 0] pixel,

    // Image Properties
    input logic [COORDINATE_BITS-1:0] image_width,
    input logic [COORDINATE_BITS-1:0] image_height,

    input logic signed [FP_WL-1:0] pixel_00_loc [3],
    input logic signed [FP_WL-1:0] pixel_delta_u[3],
    input logic signed [FP_WL-1:0] pixel_delta_v[3],
    input logic signed [FP_WL-1:0] camera_center[3]
);

  // RGU control logic
  logic rgu_start;
  logic [COORDINATE_BITS-1:0] x, y;

  // RGU Outputs
  sfp_if #(FP_IW, FP_QW) ray_origin[3] (), ray_direction[3] ();
  assign pixel = ray_direction[0].val;  // FIXME: Temporary test


  rt_controller controller (
      .clk(clk),
      .resetn(resetn),
      .start(start),
      .stall(stall),
      .last(last),
      .image_width(image_width),
      .image_height(image_height),
      .rgu_start(rgu_start),
      .x(x),
      .y(y)
  );

  rt_rgu_5_stage rgu (
      .clk(clk),
      .resetn(resetn),
      .start(rgu_start),
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
