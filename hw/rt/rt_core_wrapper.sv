// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

`include "parameters.vh"

// This file only exist because of a limitation of vivados IP integrator
module rt_core_wrapper (
    input logic clk,
    input logic resetn,

    input logic start,
    input logic stall,

    output logic valid,
    output logic last,
    output logic [FP_WL -1 : 0] pixel,

    // Camera parameters
    input logic signed [FP_WL - 1:0] image_width,
    input logic signed [FP_WL - 1:0] image_height,

    input logic signed [FP_WL - 1:0] camera_center_x,
    input logic signed [FP_WL - 1:0] camera_center_y,
    input logic signed [FP_WL - 1:0] camera_center_z,

    input logic signed [FP_WL - 1:0] pixel_delta_u_x,
    input logic signed [FP_WL - 1:0] pixel_delta_u_y,
    input logic signed [FP_WL - 1:0] pixel_delta_u_z,

    input logic signed [FP_WL - 1:0] pixel_delta_v_x,
    input logic signed [FP_WL - 1:0] pixel_delta_v_y,
    input logic signed [FP_WL - 1:0] pixel_delta_v_z,

    input logic signed [FP_WL - 1:0] pixel_00_loc_x,
    input logic signed [FP_WL - 1:0] pixel_00_loc_y,
    input logic signed [FP_WL - 1:0] pixel_00_loc_z
);

  // Alias scalar inputs to 3D vectors
  logic signed [FP_WL - 1:0] camera_center[3];
  logic signed [FP_WL - 1:0] pixel_delta_u[3];
  logic signed [FP_WL - 1:0] pixel_delta_v[3];
  logic signed [FP_WL - 1:0] pixel_00_loc[3];

  logic [COORDINATE_BITS-1:0] image_width_int;
  logic [COORDINATE_BITS-1:0] image_height_int;

  always_comb begin
    camera_center[0] = camera_center_x;
    camera_center[1] = camera_center_y;
    camera_center[2] = camera_center_z;

    pixel_delta_u[0] = pixel_delta_u_x;
    pixel_delta_u[1] = pixel_delta_u_y;
    pixel_delta_u[2] = pixel_delta_u_z;

    pixel_delta_v[0] = pixel_delta_v_x;
    pixel_delta_v[1] = pixel_delta_v_y;
    pixel_delta_v[2] = pixel_delta_v_z;

    pixel_00_loc[0]  = pixel_00_loc_x;
    pixel_00_loc[1]  = pixel_00_loc_y;
    pixel_00_loc[2]  = pixel_00_loc_z;

    // Convert image_width and image_height to integers
    // TODO: Switch to unsigned format for coordinates
    image_width_int  = image_width[FP_WL-2 : FP_QW];
    image_height_int = image_height[FP_WL-2 : FP_QW];
  end

  rt_core wrapped (
      .clk(clk),
      .resetn(resetn),
      .start(start),
      .stall(stall),
      .valid(valid),
      .last(last),
      .pixel(pixel),
      .image_width(image_width_int),
      .image_height(image_height_int),
      .pixel_00_loc(pixel_00_loc),
      .pixel_delta_u(pixel_delta_u),
      .pixel_delta_v(pixel_delta_v),
      .camera_center(camera_center)
  );


endmodule
