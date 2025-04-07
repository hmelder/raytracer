// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

`include "rt_camera_t.svh"

`define ASSIGN_FP(A, B) \
  genvar i_``A; \
  generate \
    for (i_``A = 0; i_``A < 3; i_``A++) begin : assign_``A \
      assign A[i_``A].val = B[i_``A]; \
    end \
  endgenerate

// Ray Generation Unit (RGU)
module rt_rgu (
    // Camera Properties
    input logic [CAMERA_WL-1:0] pixel_00_loc [3],
    input logic [CAMERA_WL-1:0] pixel_delta_u[3],
    input logic [CAMERA_WL-1:0] pixel_delta_v[3],
    input logic [CAMERA_WL-1:0] camera_center[3],

    // Image Coordinates
    sfp_if.in x,
    sfp_if.in y,
    // Ray (Origin, Direction)
    sfp_if.out ray_origin[3],
    sfp_if.out ray_direction[3]
);

  // Create sfp_if instances from camera properties
  sfp_if #(
      .IW(CAMERA_IW),
      .QW(CAMERA_QW)
  )
      pixel_00_loc_fp[3] (),
      pixel_delta_u_fp[3] (),
      pixel_delta_v_fp[3] (),
      pixel_center_fp[3] (),
      camera_center_fp[3] (),
      tmp_x_delta_u_fp[3] (),
      tmp_y_delta_v_fp[3] (),
      tmp_pixel_off_fp[3] ();

  `ASSIGN_FP(pixel_00_loc_fp, pixel_00_loc)
  `ASSIGN_FP(pixel_delta_u_fp, pixel_delta_u)
  `ASSIGN_FP(pixel_delta_v_fp, pixel_delta_v)
  `ASSIGN_FP(camera_center_fp, camera_center)

  assign ray_origin = camera_center_fp;

  // tmp_x_delta_u_fp = (x * pixel_delta_u)
  sfp_vec_mul_s #(
      .CLIP(0)
  ) mul_x_delta (
      .a  (pixel_delta_u_fp),
      .s  (x),
      .out(tmp_x_delta_u_fp)
  );

  // tmp_y_delta_v_fp = (y * pixel_delta_v)
  sfp_vec_mul_s #(
      .CLIP(0)
  ) mul_y_delta (
      .a  (pixel_delta_v_fp),
      .s  (y),
      .out(tmp_y_delta_v_fp)
  );

  // tmp_pixel_off_fp = tmp_x_delta_u_fp + tmp_y_delta_v_fp
  sfp_vec_add #(
      .CLIP(0)
  ) add_pixel_off (
      .a  (tmp_x_delta_u_fp),
      .b  (tmp_y_delta_v_fp),
      .out(tmp_pixel_off_fp)
  );

  // pixel_center_fp = pixel_00_loc_fp + tmp_pixel_off_fp
  sfp_vec_add #(
      .CLIP(0)
  ) add_pixel_center (
      .a  (pixel_00_loc_fp),
      .b  (tmp_pixel_off_fp),
      .out(pixel_center_fp)
  );

  // ray_direction = pixel_center_fp - camera_center_fp;
  sfp_vec_sub #(
      .CLIP(0)
  ) sub_direction (
      .a  (pixel_center_fp),
      .b  (camera_center_fp),
      .out(ray_direction)
  );

endmodule
