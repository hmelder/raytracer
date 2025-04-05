// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

`include "rt_camera_t.svh"

module rt_rgu_wrapper (
    // Camera Properties
    input rt_camera_t cam,
    // Image Coordinates
    input logic [CAMERA_WL-1:0] x,
    input logic [CAMERA_WL-1:0] y,
    // Ray (Origin, Direction)
    output logic [CAMERA_WL-1:0] ray_origin[3],
    output logic [CAMERA_WL-1:0] ray_direction[3]
);

  sfp_if #(
      .IW(CAMERA_IW),
      .QW(CAMERA_QW)
  )
      ray_origin_fp[3] (), ray_direction_fp[3] (), x_fp (), y_fp ();

  genvar i;
  generate
    for (i = 0; i < 3; i++) begin : gen_sub
      assign ray_origin[i] = ray_origin_fp[i].val;
      assign ray_direction[i] = ray_direction_fp[i].val;
    end
  endgenerate

  assign x_fp.val = x;
  assign y_fp.val = y;

  rt_rgu rgu (
      .cam(cam),
      .x(x_fp),
      .y(y_fp),
      .ray_origin(ray_origin_fp),
      .ray_direction(ray_direction_fp)
  );

endmodule
